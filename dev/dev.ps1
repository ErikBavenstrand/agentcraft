<#
.SYNOPSIS
  Offline dev kit for the Agentcraft addon: check changes before you /reload.
.DESCRIPTION
  Commands:
    check     run everything below that can run; tools that are missing are skipped
    toc       Agentcraft.toc: files exist, every .lua is listed, Version and load order
    rules     the owner's macro and layout rules, statically (PowerShell only), plus a
              read-only look at the live game's keybinds and macros when the game is found
    lint      luacheck with ../.luacheckrc (needs luacheck)
    lint-ui   the [lint] rules of dev/ui-rules.md, statically (dev/harness/uilint.lua; needs Lua 5.1)
    test      Lua 5.1 harness: loads the addon against a WoW API mock and runs dev/tests/*.lua
              (needs lua5.1, lua51 or luajit)
    types     lua-language-server --check with ../.luarc.json (needs LuaLS)
    globals   list the globals the addon reads and writes (to maintain .luacheckrc)
    render    draw every page of the /ac window to dev/render/out/<page>.html (needs Lua 5.1);
              -Fetch first downloads missing textures and atlas data (see dev/render/fetch.ps1). Not part of check.
  Exit codes: 0 pass, 1 findings or failures, 2 a needed tool is missing (skipped).
  Needs only Windows PowerShell 5.1 for toc, rules and globals.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File dev.ps1 check
#>
param(
  [Parameter(Position = 0)][string]$Command = 'check',
  [string]$Addon,
  [string]$WowPath,
  [switch]$NoGame,   # rules: skip the live game section
  [switch]$Strict,   # rules: warnings fail too
  [switch]$Fetch     # render: download missing textures and atlas data, then render again
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
try { [Console]::OutputEncoding = $utf8 } catch {}

$DevDir = $PSScriptRoot
$WowDir = Split-Path $DevDir
if (-not $Addon) { $Addon = Join-Path $WowDir 'addon\Agentcraft' }
$Addon = (Resolve-Path -LiteralPath $Addon).Path

function Say([string]$text) { [Console]::Out.WriteLine($text) }
function ReadText([string]$file) { return [IO.File]::ReadAllText($file, [Text.Encoding]::UTF8) }
function Rel([string]$full) {
  if ($full.StartsWith($Addon, [StringComparison]::OrdinalIgnoreCase)) { return $full.Substring($Addon.Length).TrimStart('\', '/') }
  return $full
}

# ---------------------------------------------------------------------------
# Lua literal reader. Reads table constructors (Layout.lua, L.Add({...})) from
# Lua source. Comments and string contents are blanked in a "code" copy of the
# text (same length), so structure is found there and strings are read from
# the original. Anything that isn't a literal comes back as a [LuaExpr].

class LuaExpr {
  [string]$Text
  LuaExpr([string]$t) { $this.Text = $t }
  [string] ToString() { return "<expr $($this.Text)>" }
}

class LuaTable {
  [System.Collections.ArrayList]$Arr
  [System.Collections.Specialized.OrderedDictionary]$Hash
  [int]$Line
  LuaTable([int]$line) {
    $this.Arr = New-Object System.Collections.ArrayList
    $this.Hash = New-Object System.Collections.Specialized.OrderedDictionary
    $this.Line = $line
  }
  [object] Get([string]$k) { if ($this.Hash.Contains($k)) { return $this.Hash[$k] } return $null }
  [bool] Has([string]$k) { return $this.Hash.Contains($k) }
  # Array part as strings only (spell names in a layout entry).
  [string[]] Strings() {
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($v in $this.Arr) { if ($v -is [string]) { $out.Add($v) } }
    return $out.ToArray()
  }
}

class LuaLit {
  [string]$s
  [string]$code
  [int]$i
  [int]$n
  [int[]]$lineStarts

  static [regex]$Strip = [regex]'--\[(=*)\[[\s\S]*?\]\1\]|--[^\n]*|"(?:[^"\\\n]|\\[\s\S])*"|''(?:[^''\\\n]|\\[\s\S])*''|\[(=*)\[[\s\S]*?\]\2\]'
  static [regex]$Num = [regex]'\G-?(?:0[xX][0-9a-fA-F]+|(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)'
  static [regex]$Name = [regex]'\G[A-Za-z_][A-Za-z0-9_]*(?:[.:][A-Za-z_][A-Za-z0-9_]*)*'
  static [regex]$Assign = [regex]'\G([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)'

  LuaLit([string]$text) {
    $this.s = $text -replace "`r`n", "`n"
    $this.n = $this.s.Length
    $this.i = 0
    $this.code = [LuaLit]::StripText($this.s)
    $starts = New-Object System.Collections.Generic.List[int]
    $starts.Add(0)
    for ($k = $this.s.IndexOf("`n"); $k -ge 0; $k = $this.s.IndexOf("`n", $k + 1)) { $starts.Add($k + 1) }
    $this.lineStarts = $starts.ToArray()
  }

  # Comments become spaces; every string becomes "   " of the same length.
  static [string] StripText([string]$t) {
    $ev = [System.Text.RegularExpressions.MatchEvaluator] {
      param($m)
      $v = $m.Value
      $blank = [regex]::Replace($v, '[^\n]', ' ')
      if ($v.StartsWith('--')) { return $blank }
      $chars = $blank.ToCharArray()
      $chars[0] = '"'
      $chars[$chars.Length - 1] = '"'
      return -join $chars
    }
    return [LuaLit]::Strip.Replace($t, $ev)
  }

  [int] LineAt([int]$offset) {
    $lo = 0; $hi = $this.lineStarts.Length - 1
    while ($lo -lt $hi) {
      $mid = [int][Math]::Floor(($lo + $hi + 1) / 2)
      if ($this.lineStarts[$mid] -le $offset) { $lo = $mid } else { $hi = $mid - 1 }
    }
    return $lo + 1
  }

  [void] Skip() {
    while ($this.i -lt $this.n -and [char]::IsWhiteSpace($this.code[$this.i])) { $this.i++ }
  }

  [void] Expect([char]$ch) {
    $this.Skip()
    if ($this.i -ge $this.n -or $this.code[$this.i] -ne $ch) { throw "expected '$ch' at line $($this.LineAt($this.i))" }
    $this.i++
  }

  # Skips to the next , ; } ) ] at depth 0 and returns what was skipped.
  [LuaExpr] SkipExpr() {
    $start = $this.i
    $depth = 0
    while ($this.i -lt $this.n) {
      $c = $this.code[$this.i]
      if ($c -eq '(' -or $c -eq '{' -or $c -eq '[') { $depth++ }
      elseif ($c -eq ')' -or $c -eq '}' -or $c -eq ']') {
        if ($depth -eq 0) { break }
        $depth--
      }
      elseif (($c -eq ',' -or $c -eq ';') -and $depth -eq 0) { break }
      $this.i++
    }
    return [LuaExpr]::new($this.s.Substring($start, $this.i - $start).Trim())
  }

  static [string] Unescape([string]$raw) {
    $ev = [System.Text.RegularExpressions.MatchEvaluator] {
      param($m)
      $d = $m.Groups[1].Value
      switch -CaseSensitive ($d) {
        'n' { return "`n" }
        't' { return "`t" }
        'r' { return "`r" }
        'a' { return [string][char]7 }
        "`n" { return "`n" }
      }
      if ($d -match '^\d+$') { return [string][char][int]$d }
      return $d
    }
    return [regex]::Replace($raw, '\\(\d{1,3}|[\s\S])', $ev)
  }

  [string] Str() {
    $start = $this.i
    $end = $this.code.IndexOf('"', $start + 1)
    if ($end -lt 0) { throw "unterminated string at line $($this.LineAt($start))" }
    $this.i = $end + 1
    $q = $this.s[$start]
    if ($q -eq '"' -or $q -eq "'") { return [LuaLit]::Unescape($this.s.Substring($start + 1, $end - $start - 1)) }
    # Long string [[...]] / [==[...]==]
    $open = [regex]::Match($this.s.Substring($start), '^\[=*\[')
    $len = $open.Length
    $body = $this.s.Substring($start + $len, ($end + 1 - $len) - ($start + $len))
    if ($body.StartsWith("`n")) { $body = $body.Substring(1) }
    return $body
  }

  [object] Value() {
    $this.Skip()
    if ($this.i -ge $this.n) { throw 'unexpected end of file' }
    $start = $this.i
    $c = $this.code[$this.i]
    $v = $null
    if ($c -eq '{') { $v = $this.Table() }
    elseif ($c -eq '"') {
      $v = $this.Str()
      $this.Skip()
      while ($this.i + 1 -lt $this.n -and $this.code.Substring($this.i, 2) -eq '..' -and $this.code[$this.i + 2] -ne '.') {
        $this.i += 2
        $more = $this.Value()
        if ($more -is [string]) { $v = $v + $more } else { $v = [LuaExpr]::new($this.s.Substring($start, $this.i - $start)); break }
        $this.Skip()
      }
    }
    else {
      $m = [LuaLit]::Num.Match($this.code, $this.i)
      if ($m.Success) {
        $this.i += $m.Length
        $v = [double]::Parse(($m.Value -replace '^-?0[xX].*$', '0'), [Globalization.CultureInfo]::InvariantCulture)
        if ($m.Value -match '^-?0[xX]') { $v = [double][Convert]::ToInt64(($m.Value -replace '^-?0[xX]', ''), 16) }
      } else {
        $m = [LuaLit]::Name.Match($this.code, $this.i)
        if ($m.Success) {
          $this.i += $m.Length
          if ($m.Value -eq 'true') { $v = $true }
          elseif ($m.Value -eq 'false') { $v = $false }
          elseif ($m.Value -eq 'nil') { $v = $null }
          else { $v = [LuaExpr]::new($m.Value) }
        } else {
          return $this.SkipExpr()
        }
      }
    }
    # Anything else before the separator makes it an expression.
    $this.Skip()
    if ($this.i -lt $this.n -and ',;})]'.IndexOf($this.code[$this.i]) -lt 0) {
      $this.i = $start
      return $this.SkipExpr()
    }
    return $v
  }

  [LuaTable] Table() {
    $t = [LuaTable]::new($this.LineAt($this.i))
    $this.i++
    while ($true) {
      $this.Skip()
      if ($this.i -ge $this.n) { throw "unterminated table from line $($t.Line)" }
      $c = $this.code[$this.i]
      if ($c -eq '}') { $this.i++; break }
      if ($c -eq '[') {
        $this.i++
        $k = $this.Value()
        $this.Expect([char]']')
        $this.Expect([char]'=')
        $key = [string]$k
        $t.Hash[$key] = $this.Value()
      } else {
        $m = [LuaLit]::Assign.Match($this.code, $this.i)
        if ($m.Success) {
          $this.i += $m.Length
          $t.Hash[$m.Groups[1].Value] = $this.Value()
        } else {
          [void]$t.Arr.Add($this.Value())
        }
      }
      $this.Skip()
      if ($this.i -lt $this.n -and ($this.code[$this.i] -eq ',' -or $this.code[$this.i] -eq ';')) { $this.i++ }
    }
    return $t
  }

  # Every table constructor that follows a match of $pattern (which must end
  # right before the "{"), as a list of LuaTable.
  [System.Collections.ArrayList] Tables([string]$pattern) {
    $out = New-Object System.Collections.ArrayList
    foreach ($m in [regex]::Matches($this.code, $pattern)) {
      $this.i = $m.Index + $m.Length
      $this.Skip()
      if ($this.i -lt $this.n -and $this.code[$this.i] -eq '{') { [void]$out.Add($this.Table()) }
    }
    return $out
  }
}

# ---------------------------------------------------------------------------
# Findings

$script:Findings = New-Object System.Collections.ArrayList

function Add-Finding([string]$Severity, [string]$Rule, [string]$Where, [string]$Message) {
  [void]$script:Findings.Add([pscustomobject]@{ Severity = $Severity; Rule = $Rule; Where = $Where; Message = $Message })
}

function Write-Findings([string]$title) {
  $order = @{ ERROR = 0; WARN = 1; INFO = 2 }
  # "File.lua:48" sorts before "File.lua:164": file name, then line number.
  $list = @($script:Findings | Sort-Object @{ e = { $order[$_.Severity] } },
    @{ e = { $_.Where -replace ':\d+$', '' } },
    @{ e = { if ($_.Where -match ':(\d+)$') { [int]$Matches[1] } else { 0 } } })
  Say ""
  Say "== $title =="
  if ($list.Count -eq 0) { Say "  no findings" }
  foreach ($f in $list) {
    Say ("{0,-5} [{1}] {2}" -f $f.Severity, $f.Rule, $f.Where)
    Say ("      {0}" -f $f.Message)
  }
  $e = @($list | Where-Object Severity -eq 'ERROR').Count
  $w = @($list | Where-Object Severity -eq 'WARN').Count
  $n = @($list | Where-Object Severity -eq 'INFO').Count
  Say ""
  Say "$title`: $e error(s), $w warning(s), $n info"
  $failed = $e -gt 0 -or ($Strict -and $w -gt 0)
  $script:Findings.Clear()
  if ($failed) { return 1 }
  return 0
}

# ---------------------------------------------------------------------------
# toc

function Read-Toc {
  $tocFile = Get-ChildItem -LiteralPath $Addon -Filter '*.toc' | Select-Object -First 1
  if (-not $tocFile) { throw "no .toc in $Addon" }
  $meta = [ordered]@{}
  $files = New-Object System.Collections.Generic.List[object]
  $lineNo = 0
  foreach ($line in [IO.File]::ReadAllLines($tocFile.FullName, [Text.Encoding]::UTF8)) {
    $lineNo++
    $t = $line.Trim()
    if ($t -eq '') { continue }
    if ($t -match '^##\s*([^:]+?)\s*:\s*(.*)$') { $meta[$Matches[1]] = @{ Value = $Matches[2].Trim(); Line = $lineNo }; continue }
    if ($t.StartsWith('#')) { continue }
    $files.Add([pscustomobject]@{ Path = $t; Line = $lineNo })
  }
  return [pscustomobject]@{ File = $tocFile; Meta = $meta; Files = $files }
}

function Cmd-Toc {
  $toc = Read-Toc
  $tocName = $toc.File.Name
  $listed = @{}
  $index = @{}
  $pos = 0
  foreach ($f in $toc.Files) {
    $where = "${tocName}:$($f.Line)"
    $norm = $f.Path -replace '/', '\'
    $key = $norm.ToLowerInvariant()
    if ($listed.ContainsKey($key)) { Add-Finding ERROR toc-duplicate $where "$($f.Path) is listed twice" }
    $listed[$key] = $f
    $index[$key] = $pos++
    if ($norm.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0 -or $norm -match '[\x00-\x1f]') {
      Add-Finding ERROR toc-path $where "line has characters that can't be in a file name: '$($f.Path)'"
      continue
    }
    $full = Join-Path $Addon $norm
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
      Add-Finding ERROR toc-missing $where "$($f.Path) is listed but does not exist"
      continue
    }
    # Exact case: the game is case-insensitive on Windows but not on every OS.
    $dir = Split-Path $full
    $leaf = Split-Path $full -Leaf
    $actual = (Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Name -ieq $leaf } | Select-Object -First 1).Name
    if ($actual -cne $leaf) { Add-Finding WARN toc-case $where "$($f.Path) is '$actual' on disk" }
    # Every file reads the addon varargs.
    $head = (ReadText $full) -split "`n" | Where-Object { $_ -notmatch '^\s*(--.*)?\s*$' } | Select-Object -First 1
    if ($full -like '*.lua' -and $head -notmatch '^local\s+[A-Za-z_]+\s*,\s*ns\s*=\s*\.\.\.') {
      Add-Finding WARN toc-header $where "$($f.Path): first code line is not 'local ADDON, ns = ...' (got: $head)"
    }
  }

  foreach ($lua in Get-ChildItem -LiteralPath $Addon -Recurse -File -Filter '*.lua') {
    $rel = Rel $lua.FullName
    if (-not $listed.ContainsKey($rel.ToLowerInvariant())) {
      if ($lua.Name.StartsWith('_')) { Add-Finding INFO toc-unlisted $rel "not in the TOC (an underscore file: a template, never loaded; fine if intended)" }
      else { Add-Finding ERROR toc-unlisted $rel "not in the TOC, so the game never loads it" }
    }
  }

  # Metadata.
  $ver = $toc.Meta['Version']
  if (-not $ver) { Add-Finding ERROR toc-version $tocName "no '## Version:' line" }
  elseif ($ver.Value -notmatch '^\d+\.\d+\.\d+$') { Add-Finding ERROR toc-version "${tocName}:$($ver.Line)" "Version '$($ver.Value)' is not MAJOR.MINOR.PATCH" }
  else { Add-Finding INFO toc-version "${tocName}:$($ver.Line)" "Version $($ver.Value)" }
  $iface = $toc.Meta['Interface']
  if (-not $iface) { Add-Finding ERROR toc-interface $tocName "no '## Interface:' line" }
  else {
    foreach ($v in ($iface.Value -split ',')) {
      if ($v.Trim() -notmatch '^\d{5,6}$') { Add-Finding ERROR toc-interface "${tocName}:$($iface.Line)" "Interface value '$($v.Trim())' is not a 5-6 digit build number" }
    }
    if ($iface.Value -notmatch '\b12\d{4}\b') { Add-Finding WARN toc-interface "${tocName}:$($iface.Line)" "no 12xxxx Interface value; the WoW Forever client is 12.x and may list the addon as out of date" }
  }
  foreach ($sv in 'SavedVariables', 'SavedVariablesPerCharacter') {
    if (-not $toc.Meta[$sv]) { Add-Finding WARN toc-savedvars $tocName "no '## ${sv}:' line" }
  }
  if ($toc.Meta['SavedVariables'] -and $toc.Meta['SavedVariables'].Value -ne 'AgentcraftDB') { Add-Finding ERROR toc-savedvars $tocName "SavedVariables is '$($toc.Meta['SavedVariables'].Value)'; Core.lua uses AgentcraftDB" }
  if ($toc.Meta['SavedVariablesPerCharacter'] -and $toc.Meta['SavedVariablesPerCharacter'].Value -ne 'AgentcraftCharDB') { Add-Finding ERROR toc-savedvars $tocName "SavedVariablesPerCharacter is '$($toc.Meta['SavedVariablesPerCharacter'].Value)'; Core.lua uses AgentcraftCharDB" }

  # Load order the code depends on.
  function Pos([string]$p) { $k = $p.ToLowerInvariant(); if ($index.ContainsKey($k)) { return $index[$k] } return $null }
  $order = @(
    @('Core.lua', '*', 'Core.lua must load first: it creates ns.RegisterModule and the event frame'),
    @('UI\Widgets.lua', 'Modules\Controller.lua', 'Controller reads ns.UI at load time'),
    @('Modules\Snapshot.lua', 'Modules\SnapshotMore.lua', 'SnapshotMore reads ns.modules.snapshot at load time'),
    @('Modules\Snapshot.lua', 'Modules\SnapshotCached.lua', 'SnapshotCached reads ns.modules.snapshot at load time'),
    @('Macros\Library.lua', 'Macros\Page.lua', 'Page uses ns.MacroLibrary')
  )
  foreach ($o in $order) {
    $a = Pos $o[0]
    if ($null -eq $a) { continue }
    if ($o[1] -eq '*') { if ($a -ne 0) { Add-Finding ERROR toc-order $tocName $o[2] }; continue }
    $b = Pos $o[1]
    if ($null -ne $b -and $a -gt $b) { Add-Finding ERROR toc-order $tocName "$($o[0]) loads after $($o[1]): $($o[2])" }
  }
  $lib = Pos 'Macros\Library.lua'; $page = Pos 'Macros\Page.lua'; $window = Pos 'UI\Window.lua'
  foreach ($f in $toc.Files) {
    $p = $f.Path -replace '/', '\'
    $k = Pos $p
    if ($p -like 'Macros\Data\*') {
      if ($null -ne $lib -and $k -lt $lib) { Add-Finding ERROR toc-order "${tocName}:$($f.Line)" "$p loads before Macros\Library.lua (L.Add would be nil)" }
      if ($null -ne $page -and $k -gt $page) { Add-Finding WARN toc-order "${tocName}:$($f.Line)" "$p loads after Macros\Page.lua; data files go above it" }
    }
    if ($p -like 'Layouts\*') {
      $lay = Pos 'Modules\Layout.lua'
      if ($null -ne $lay -and $k -lt $lay) { Add-Finding ERROR toc-order "${tocName}:$($f.Line)" "$p loads before Modules\Layout.lua (ns.Layout.Register would be nil)" }
      $ab = Pos 'Modules\ActionBars.lua'
      if ($null -ne $ab -and $k -gt $ab) { Add-Finding WARN toc-order "${tocName}:$($f.Line)" "$p loads after Modules\ActionBars.lua; class layouts go right below Modules\Layout.lua" }
    }
    if ($null -ne $window -and $k -gt $window -and $p -notlike 'UI\*') { Add-Finding WARN toc-order "${tocName}:$($f.Line)" "$p loads after UI\Window.lua; new files go above it" }
  }
  # Every macro data file on disk is listed (caught above too, but say why it matters).
  return Write-Findings 'toc'
}

# ---------------------------------------------------------------------------
# rules: macro library

$ItemCommands = @('/use', '/equip', '/equipslot', '/userandom')
$MenuCommands = @{
  '/camp' = 'logout is in the game menu'; '/logout' = 'logout is in the game menu'; '/quit' = 'quit is in the game menu'
  '/exit' = 'quit is in the game menu'; '/readycheck' = 'ready check is in the group menu'; '/screenshot' = 'Steam and the game take screenshots'
  '/map' = 'the map has its own key and menu'; '/repair' = 'the vendor window repairs'
}
$MenuRun = 'ToggleWorldMap|RepairAllItems|Screenshot\s*\(|Logout\s*\(|Quit\s*\(|DoReadyCheck|UseContainerItem|SellAllJunk|ChatFrame_OpenChat|cameraDistanceMax'

# "[cond] a; [cond] b" -> @('a', 'b'), conditions removed.
function Get-Targets([string]$argText) {
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($part in ($argText -split ';')) {
    $t = ([regex]::Replace($part, '\[[^\]]*\]', '')).Trim()
    if ($t.StartsWith('!')) { $t = $t.Substring(1).Trim() }
    if ($t -ne '') { $out.Add($t) }
  }
  return $out.ToArray()
}

# "/castsequence [cond] reset=5 A, B" arguments -> "A; B" (conditions dropped first,
# since they contain commas too).
function Split-List([string]$argText) {
  $t = [regex]::Replace($argText, '\[[^\]]*\]', '')
  $t = [regex]::Replace($t, 'reset=\S+', '')
  return ($t -replace ',', ';')
}

function Read-Macros {
  $macros = New-Object System.Collections.Generic.List[object]
  $retired = @{}
  $dataDir = Join-Path $Addon 'Macros\Data'
  foreach ($file in Get-ChildItem -LiteralPath $dataDir -Filter '*.lua' | Sort-Object Name) {
    $rel = Rel $file.FullName
    $lit = [LuaLit]::new((ReadText $file.FullName))
    foreach ($t in $lit.Tables('\bL\.Add\s*\(\s*(?=\{)')) {
      $name = $t.Get('name'); $body = $t.Get('body')
      if ($body -isnot [string]) { Add-Finding ERROR macro-parse "${rel}:$($t.Line)" "macro '$name' has no plain string body; the checker can't read it"; continue }
      $macros.Add([pscustomobject]@{ Name = [string]$name; Body = $body; File = $rel; Line = $t.Line; T = $t
        Class = $t.Get('class'); Race = $t.Get('race'); Untested = ($t.Get('untested') -eq $true); Generated = $t.Get('generated') })
    }
    foreach ($t in $lit.Tables('\bL\.retired\s*=\s*(?=\{)')) {
      foreach ($k in $t.Hash.Keys) { $retired[[string]$k] = @{ Body = $t.Hash[$k]; Where = "${rel}:$($t.Line)" } }
    }
  }
  return [pscustomobject]@{ Macros = $macros; Retired = $retired }
}

# Item names the addon itself knows (ActionBars utility lists, Layout items):
# a /cast of one of these is an item in disguise.
function Read-ItemNames {
  $names = @{}
  $ab = Join-Path $Addon 'Modules\ActionBars.lua'
  if (Test-Path -LiteralPath $ab) {
    $lit = [LuaLit]::new((ReadText $ab))
    foreach ($t in $lit.Tables('\bM\.utility\s*=\s*(?=\{)')) {
      foreach ($e in $t.Arr) { if ($e -is [LuaTable]) { foreach ($s in $e.Strings()) { $names[$s] = $true } } }
    }
  }
  foreach ($n in 'Hearthstone', 'Shiny Bauble', 'Nightcrawlers', 'Bright Baubles', 'Aquadynamic Fish Attractor') { $names[$n] = $true }
  # The item macros' lists (Macros\Items.lua, L.ITEMS = { poles = { { "Name", level = n }, ... }, ... }).
  $items = Join-Path $Addon 'Macros\Items.lua'
  if (Test-Path -LiteralPath $items) {
    $lit = [LuaLit]::new((ReadText $items))
    foreach ($t in $lit.Tables('\bL\.ITEMS\s*=\s*(?=\{)')) {
      foreach ($k in $t.Hash.Keys) {
        $list = $t.Hash[$k]
        if ($list -is [LuaTable]) { foreach ($e in $list.Arr) { if ($e -is [LuaTable]) { foreach ($s in $e.Strings()) { $names[$s] = $true } } } }
      }
    }
  }
  return $names
}

function Test-Macro($m, $items) {
  $where = "$($m.File):$($m.Line)"
  $label = "'$($m.Name)'"
  $fishItems = New-Object System.Collections.Generic.List[string]
  if ($m.Name.Length -gt 16) { Add-Finding ERROR macro-name $where "$label is longer than 16 characters (L.Add asserts)" }
  $bytes = [Text.Encoding]::UTF8.GetByteCount($m.Body)
  if ($bytes -gt 255) { Add-Finding ERROR macro-length $where "$label body is $bytes characters; the game limit is 255" }
  $lines = $m.Body -split "`n"
  if (-not $lines[0].StartsWith('#showtooltip')) { Add-Finding INFO macro-showtooltip $where "$label doesn't start with #showtooltip (Library.lua convention; fine for pure slash-command macros)" }
  foreach ($line in $lines) {
    $t = $line.Trim()
    if ($t -eq '') { continue }
    if ($t -match '^#show(tooltip)?\s+(.+)$') {
      if ($items.ContainsKey($Matches[2].Trim())) {
        if ($m.Generated) { $fishItems.Add($Matches[2].Trim()) }
        else { Add-Finding ERROR macro-item $where "$label shows item '$($Matches[2].Trim())' in #showtooltip" }
      }
      continue
    }
    if ($t.StartsWith('#')) { continue }
    if ($t -notmatch '^(/\S+)\s*(.*)$') { Add-Finding WARN macro-syntax $where "$label line is not a slash command: $t"; continue }
    $cmd = $Matches[1].ToLowerInvariant(); $rest = $Matches[2]

    foreach ($cm in [regex]::Matches($rest, '\[([^\]]*)\]')) {
      foreach ($cond in ($cm.Groups[1].Value -split ',')) {
        $c = $cond.Trim().ToLowerInvariant()
        if ($c -match '^(no)?mod(ifier)?(:|$)') {
          if ($c -match 'alt' -and $c -notmatch 'shift|ctrl') { Add-Finding WARN macro-modifier $where "$label uses [$c] (Alt modifier; Shift/Ctrl are banned, Alt is the utility bar layer)" }
          else { Add-Finding ERROR macro-modifier $where "$label uses [$c]: no Shift/Ctrl modifier variants (they are bar layers)" }
        }
        elseif ($c -match '^@(mouseover|cursor)' -or $c -match '^target\s*=\s*(mouseover|cursor)') { Add-Finding ERROR macro-mouse $where "$label uses [$c]: no @mouseover/@cursor (a controller has no mouse)" }
        elseif ($c -match '^(no)?(btn|button)(:|$)') { Add-Finding WARN macro-mouse $where "$label uses [$c]: mouse-button conditions don't work from a controller" }
      }
    }

    if ($cmd -eq '/petpassive') { Add-Finding ERROR macro-petpassive $where "$label uses /petpassive (sticks after the fight; the pet stops defending you)" }
    elseif ($cmd -eq '/petattack') { Add-Finding ERROR macro-petattack $where "$label uses /petattack: the owner wants no /petattack in any macro" }
    elseif ($ItemCommands -contains $cmd) {
      foreach ($target in (Get-Targets $rest)) {
        $tg = $target
        if ($cmd -eq '/equipslot') { $tg = ($target -replace '^\d+\s*', '') }
        if ($tg -match '^\d+(\s+\d+)?$') { Add-Finding INFO macro-slot $where "$label $cmd $tg uses an inventory slot, not an item name (allowed)" }
        elseif ($m.Generated) { $fishItems.Add($tg) }
        else { Add-Finding ERROR macro-item $where "$label $cmd $tg names an item; items go on bars as item buttons" }
      }
    }
    elseif ($cmd -eq '/equipset') { Add-Finding WARN macro-equipset $where "$label uses /equipset (latest rule: no equipment sets)" }
    elseif ($cmd -in '/cast', '/castsequence', '/castrandom') {
      $argText = $rest
      if ($cmd -eq '/castsequence' -or $cmd -eq '/castrandom') { $argText = Split-List $rest }
      foreach ($target in (Get-Targets $argText)) {
        if ($items.ContainsKey($target)) { Add-Finding ERROR macro-item $where "$label $cmd $target casts an item by name" }
      }
    }
    elseif ($MenuCommands.ContainsKey($cmd)) { Add-Finding ERROR macro-menu $where "$label uses $cmd ($($MenuCommands[$cmd]))" }
    elseif ($cmd -in '/run', '/script', '/dump', '/console') {
      if ($rest -match $MenuRun) { Add-Finding ERROR macro-menu $where "$label /run does what a game menu already does ($($Matches[0]))" }
    }
  }
  if ($fishItems.Count -gt 0) { Add-Finding INFO macro-item $where "$label names $($fishItems.Count) items: $($fishItems -join ', ') (generated from your bags, owner-approved)" }
  if ($m.Generated) { Add-Finding INFO macro-generated $where "$label is a generated item macro ('$($m.Generated)', Macros\Items.lua): its text names the best item you carry and Agentcraft rewrites it (generated from your bags, owner-approved); this body is its no-item text" }
  if ($m.Untested) { Add-Finding INFO macro-untested $where "$label is marked untested (needs an in-game confirmation)" }
}

# ---------------------------------------------------------------------------
# rules: layouts

$KbKeys = @('Q', 'E', 'R', 'T', 'F', 'G', 'C', 'V', '1', '2', '3', '4')
$PadKey = @{ L4 = 'F13'; L5 = 'F14'; R4 = 'F15'; R5 = 'F16' }

function Get-Bar($tbl, [int]$n) {
  $v = $tbl.Get([string]$n)
  if (-not $v) { $v = $tbl.Get("$n.0") }
  if (-not $v -and $tbl.Arr.Count -ge $n) { $v = $tbl.Arr[$n - 1] }
  return $v
}

# What an entry occupies, for the one-home check: its spells, plus your racial,
# an item, a utility slot, a macro or a flyout (those can be placed twice too).
function Get-HomeNames($e) {
  $out = New-Object System.Collections.Generic.List[string]
  if ($e -isnot [LuaTable]) { return $out.ToArray() }
  foreach ($s in $e.Strings()) { $out.Add($s) }
  if ($e.Get('racial') -eq $true) { $out.Add('<racial>') }
  if ($e.Has('item')) { $out.Add("<item $($e.Get('item'))>") }
  if ($e.Has('utility')) { $out.Add("<utility $($e.Get('utility'))>") }
  # A macro or a radial is a home too (two { macro = "Skull" } entries, or a
  # flyout twice, break "one home"). petauto and overflow entries are not homes.
  if ($e.Has('macro')) { $out.Add("<macro $($e.Get('macro'))>") }
  if ($e.Has('flyout')) { $out.Add("<flyout $($e.Get('flyout'))>") }
  if ($e.Has('profession')) { $out.Add("<profession $($e.Get('profession'))>") }
  return $out.ToArray()
}

# Spells a macro body casts (for the "also casts" note).
function Get-CastSpells([string]$body) {
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($line in ($body -split "`n")) {
    if ($line.Trim() -match '^/(cast|castsequence|castrandom)\s+(.*)$') {
      $argText = $Matches[2]
      if ($Matches[1] -ne 'cast') { $argText = Split-List $argText }
      foreach ($t in (Get-Targets $argText)) { $out.Add($t) }
    }
  }
  return $out.ToArray()
}

# Fields a layout entry may have besides its spell names.
$EntryFields = @('macro', 'flyout', 'utility', 'item', 'racial', 'petauto', 'overflow', 'upgrade', 'covers', 'profession')
# Spells of Layout.PROFESSIONS (Modules/Layout.lua; keep in step): their home
# is the shared { profession = n } slots, never a class layout.
$ProfessionSpells = @('Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Herbalism', 'Inscription',
  'Jewelcrafting', 'Leatherworking', 'Mining', 'Skinning', 'Tailoring', 'Cooking', 'First Aid', 'Bait and Tackle',
  'Find Minerals', 'Find Herbs', 'Smelting', 'Disenchant', 'Prospecting', 'Milling', 'Survey')
# The shared controller buttons (Layouts/Shared.lua): page number -> LuaTable
# of entries, read by Read-SharedLayout before the class layouts.
$script:SharedPages = @{}
$SpecFields = @('key', 'name', 'tab', 'default', 'keyboard', 'controller')
# Classic bonus bar offsets per stance key (Layout.STANCE_OFFSETS, rules.lua).
$StanceOffsets = @{
  WARRIOR = @{ battle = 1; defensive = 2; berserker = 3 }
  DRUID   = @{ cat = 1; bear = 3; moonkin = 4 }
  ROGUE   = @{ stealth = 1 }
  PRIEST  = @{ shadowform = 1 }
}

function Test-Entry($entry, [string]$class, [string]$device, [string]$where, [string]$label, $lib, $retired) {
  # false in a keyboard bar: a key left empty on purpose.
  if ($device -eq 'keyboard' -and $entry -is [bool] -and -not $entry) { return }
  if ($entry -isnot [LuaTable]) { Add-Finding ERROR layout-entry $where "$label is not a table entry"; return }
  foreach ($k in $entry.Hash.Keys) {
    if ($EntryFields -notcontains $k) { Add-Finding ERROR layout-entry $where "${label}: unknown field '$k' (fields: $($EntryFields -join ', '))" }
  }
  foreach ($v in $entry.Arr) {
    if ($v -isnot [string]) { Add-Finding ERROR layout-entry $where "${label}: '$v' is not a spell name (entries list names only)" }
    elseif ($ProfessionSpells -contains $v) { Add-Finding ERROR layout-profession $where "${label}: '$v' is a profession spell; the shared profession slots (Layouts\Shared.lua) are its home" }
  }
  if ($entry.Has('profession')) {
    $pn = $entry.Get('profession')
    if (-not ($pn -is [double]) -or $pn -lt 1 -or $pn -ne [Math]::Floor($pn)) { Add-Finding ERROR layout-entry $where "${label}: profession must be 1 or more (the Nth profession spell)" }
  }
  if ($device -eq 'keyboard') {
    foreach ($k in 'flyout', 'petauto', 'overflow', 'profession') {
      if ($entry.Has($k)) { Add-Finding ERROR layout-keyboard $where "$label uses { $k = ... }: the keyboard layout is plain keybinds, no flyouts/controller-only entries" }
    }
  }
  $macro = $entry.Get('macro')
  if ($macro) {
    if (-not $lib.ContainsKey($macro)) {
      if ($retired.ContainsKey($macro)) { Add-Finding ERROR layout-macro $where "$label uses macro '$macro', which is retired (Apply deletes it)" }
      else { Add-Finding ERROR layout-macro $where "$label uses macro '$macro', which is not in the macro library" }
    } else {
      $m = $lib[$macro]
      if ($m.Class -and $m.Class -ne $class) { Add-Finding ERROR layout-macro $where "$label uses macro '$macro', a $($m.Class) macro, in the $class layout" }
      if ($m.Race) { Add-Finding WARN layout-macro $where "$label uses macro '$macro', which only fits race $($m.Race)" }
    }
    if ($entry.Strings().Count -eq 0 -and -not $entry.Get('covers')) {
      Add-Finding INFO layout-macro-only $where "$label is macro '$macro' only: empty (unbound) until the owner installs it"
    }
  }
}

# A keyboard bar or stance page: exactly 12 positional entries (false = a key
# left empty on purpose).
function Test-Twelve($entries, [string]$where, [string]$label) {
  if ($entries -isnot [LuaTable]) { Add-Finding ERROR layout-keyboard $where "$label is not a table"; return $false }
  if ($entries.Arr.Count -gt 12) { Add-Finding ERROR layout-keyboard $where "$label has $($entries.Arr.Count) entries; it has 12 keys" }
  elseif ($entries.Arr.Count -lt 12) { Add-Finding ERROR layout-keyboard $where "$label has $($entries.Arr.Count) entries; write all 12 (false for a key left empty)" }
  return $true
}

# One spec's (or the shared) keyboard layout. $who names it in messages.
function Test-KeyboardLayout($layout, [string]$class, [string]$who, [string]$rel, $lib, $retired) {
  if ($layout -isnot [LuaTable]) { Add-Finding ERROR layout-parse $rel "$who keyboard is not a table"; return }
  foreach ($k in $layout.Hash.Keys) {
    if (@('1', '2', '3', '4', 'stances') -notcontains $k) { Add-Finding ERROR layout-keyboard "${rel}:$($layout.Line)" "$who keyboard: unknown field '$k' (bars [1], [2], [4] and stances)" }
  }
  # Keyed bars from the layout: 1 plain, 2 Shift, 4 Ctrl. Bar 3 (Alt) is the
  # utility bar, filled by ActionBars, so a [3] here is never read.
  $bar3 = Get-Bar $layout 3
  if ($bar3) { Add-Finding WARN layout-keyboard "${rel}:$($bar3.Line)" "$who keyboard bar 3 is the Alt utility bar (ActionBars.utility); the layout's [3] is ignored" }
  $kbMod = @{ 1 = ''; 2 = 'Shift+'; 4 = 'Ctrl+' }
  # name -> @{ Key; Bar1 (key index on a Bar 1 page, or -1); Pages }
  $homes = @{}
  $homeList = @{} # name -> list of homes (for Test-MacroCasts)
  $addHome = {
    param($e, [string]$key, [string]$page, [int]$i)
    foreach ($s in (Get-HomeNames $e)) {
      if (-not $homeList.ContainsKey($s)) { $homeList[$s] = New-Object System.Collections.Generic.List[string] }
      $homeList[$s].Add("$key (line $($e.Line))")
      if (-not $homes.ContainsKey($s)) {
        $b1 = -1; if ($page) { $b1 = $i }
        $homes[$s] = @{ Key = "$key (line $($e.Line))"; Bar1 = $b1; Pages = @{ $page = $true } }
      } elseif ($page -and $homes[$s].Bar1 -eq $i -and -not $homes[$s].Pages.ContainsKey($page)) {
        $homes[$s].Pages[$page] = $true  # the same key on another stance page: still one home
      } else {
        Add-Finding ERROR layout-two-homes "${rel}:$($e.Line)" "$who keyboard: '$s' at $($homes[$s].Key) and $key"
      }
    }
  }
  foreach ($bar in 1, 2, 4) {
    $entries = Get-Bar $layout $bar
    if (-not $entries) { continue }
    $label = "$who keyboard bar $bar"
    if (-not (Test-Twelve $entries "${rel}:$($entries.Line)" $label)) { continue }
    if ($entries.Hash.Count -gt 0) { Add-Finding WARN layout-keyboard "${rel}:$($entries.Line)" "$label has keyed entries ($($entries.Hash.Keys -join ', ')); only the 12-entry list is read" }
    for ($i = 0; $i -lt [Math]::Min(12, $entries.Arr.Count); $i++) {
      $e = $entries.Arr[$i]
      $key = $kbMod[$bar] + $KbKeys[$i]
      $line = $entries.Line; if ($e -is [LuaTable]) { $line = $e.Line }
      Test-Entry $e $class 'keyboard' "${rel}:$line" "$who keyboard $key" $lib $retired
      if ($e -is [LuaTable]) { $page = ''; if ($bar -eq 1) { $page = 'base' }; & $addHome $e $key $page $i }
    }
  }
  $stances = $layout.Get('stances')
  if ($null -ne $stances) {
    if ($stances -isnot [LuaTable]) { Add-Finding ERROR layout-stance "${rel}:$($layout.Line)" "$who keyboard stances is not a table" }
    else {
      $offsets = @{}
      $known = $StanceOffsets[$class]
      foreach ($sk in $stances.Hash.Keys) {
        $st = $stances.Hash[$sk]
        $label = "$who stance page $sk"
        if ($st -isnot [LuaTable]) { if ($st -ne $false) { Add-Finding ERROR layout-stance "${rel}:$($stances.Line)" "$label is not a table" }; continue }
        $where = "${rel}:$($st.Line)"
        foreach ($k in $st.Hash.Keys) {
          if (@('offset', 'label') -notcontains $k) { Add-Finding ERROR layout-stance $where "${label}: unknown field '$k' (offset, label and 12 entries)" }
        }
        $off = $st.Get('offset')
        if (-not ($off -is [double]) -or $off -lt 1 -or $off -gt 4 -or $off -ne [Math]::Floor($off)) {
          Add-Finding ERROR layout-stance $where "${label}: offset must be 1-4 (bonus bars 7-10, slots 73-120)"
        } else {
          $o = [int]$off
          if ($offsets.ContainsKey($o)) { Add-Finding ERROR layout-stance $where "${label}: offset $o is also stance page $($offsets[$o])" }
          $offsets[$o] = $sk
          if (-not $known) { Add-Finding WARN layout-stance $where "${label}: $class has no stance, form or stealth paging" }
          elseif (-not $known.ContainsKey($sk)) { Add-Finding WARN layout-stance $where "${label}: not a known $class stance (known: $(($known.Keys | Sort-Object) -join ', '))" }
          elseif ($known[$sk] -ne $o) { Add-Finding WARN layout-stance $where "${label}: offset $o, but $sk is bonus bar offset $($known[$sk])" }
        }
        $stLabel = $st.Get('label'); if (-not ($stLabel -is [string])) { $stLabel = $sk }
        if (-not (Test-Twelve $st $where $label)) { continue }
        for ($i = 0; $i -lt [Math]::Min(12, $st.Arr.Count); $i++) {
          $e = $st.Arr[$i]
          $key = "${stLabel}: $($KbKeys[$i])"
          $line = $st.Line; if ($e -is [LuaTable]) { $line = $e.Line }
          Test-Entry $e $class 'keyboard' "${rel}:$line" "$who keyboard $key" $lib $retired
          if ($e -is [LuaTable]) { & $addHome $e $key $sk $i }
        }
      }
    }
  }
  Test-MacroCasts $layout $class 'keyboard' $homeList $lib $rel
}

# One spec's (or the shared) controller layout.
function Test-ControllerLayout($layout, [string]$class, [string]$who, [string]$rel, $lib, $retired) {
  if ($layout -isnot [LuaTable]) { Add-Finding ERROR layout-parse $rel "$who controller is not a table"; return }
  $pages = $layout.Get('pages')
  $paddles = $layout.Get('paddles')
  $homes = @{}      # spell -> list of page homes
  $homePages = @{}  # spell -> pages (1-3) it has a home on
  $padHomes = @{}   # spell -> list of paddle homes
  if (-not $pages) { Add-Finding ERROR layout-parse "${rel}:$($layout.Line)" "$who controller layout has no pages"; return }
  $nPages = $pages.Arr.Count
  foreach ($sp in $script:SharedPages.Keys) { if ($sp -gt $nPages) { $nPages = $sp } }
  for ($p = 0; $p -lt $nPages; $p++) {
    $page = $null
    if ($p -lt $pages.Arr.Count) { $page = $pages.Arr[$p] }
    $sharedPage = $script:SharedPages[$p + 1]
    # The page's own entries, then the shared buttons merged into it (Layout.WithShared).
    $items = New-Object System.Collections.Generic.List[object]
    if ($page -is [LuaTable]) {
      foreach ($key in $page.Hash.Keys) {
        if ($key -eq 'title') { continue }
        if ($sharedPage -and $sharedPage.Hash.Contains($key)) {
          Add-Finding ERROR layout-shared "${rel}:$($page.Hash[$key].Line)" "$who controller page $($p + 1) [$key] is a shared button (Layouts\Shared.lua); leave it out of the class page"
          continue
        }
        $items.Add(@($key, $page.Hash[$key], $rel))
      }
    }
    if ($sharedPage) {
      foreach ($key in $sharedPage.Hash.Keys) { if ($key -ne 'title') { $items.Add(@($key, $sharedPage.Hash[$key], $script:SharedRel)) } }
    }
    foreach ($it in $items) {
      $key = $it[0]; $e = $it[1]
      $where = "$($it[2]):$($e.Line)"
      $label = "$who controller page $($p + 1) [$key]"
      # Shared buttons are checked once, in Read-SharedLayout; here they count as homes.
      if ($it[2] -eq $rel) {
        if ($key -notmatch '^(none|LT|RT|LT\+RT) (A|X|B|Y|Up|Down|Left|Right)$') { Add-Finding ERROR layout-key $where "$label is not '<none|LT|RT|LT+RT> <A|X|B|Y|Up|Down|Left|Right>'" }
        elseif ($key -match '^none (A|X|B|Y)$') { Add-Finding ERROR layout-key $where "${label}: the Top bar's face buttons are fixed by the Gamepad UI" }
        Test-Entry $e $class 'controller' $where $label $lib $retired
      }
      if ($e -is [LuaTable]) {
        $hereName = "p$($p + 1) $key (line $($e.Line))"
        if ($it[2] -ne $rel) { $hereName = "p$($p + 1) $key (shared)" }
        foreach ($s in (Get-HomeNames $e)) {
          if (-not $homes.ContainsKey($s)) { $homes[$s] = New-Object System.Collections.Generic.List[string] }
          $homes[$s].Add($hereName)
          if (-not $homePages.ContainsKey($s)) { $homePages[$s] = @{} }
          $homePages[$s][$p + 1] = $true
        }
      }
    }
  }
  if ($paddles) {
    foreach ($key in $paddles.Hash.Keys) {
      $e = $paddles.Hash[$key]
      $where = "${rel}:$($e.Line)"
      $base = $key -replace '^LT\+', ''
      $label = "$who back button $key"
      if (-not $PadKey.ContainsKey($base)) { Add-Finding ERROR layout-key $where "$label is not L4/L5/R4/R5 (optionally LT+)" }
      else { $label = "$label ($(if ($key -like 'LT+*') { 'SHIFT-' })$($PadKey[$base]))" }
      Test-Entry $e $class 'controller' $where $label $lib $retired
      if ($e -is [LuaTable]) {
        foreach ($s in (Get-HomeNames $e)) {
          if (-not $padHomes.ContainsKey($s)) { $padHomes[$s] = New-Object System.Collections.Generic.List[string] }
          $padHomes[$s].Add("$key (line $($e.Line))")
        }
      }
    }
  }
  foreach ($s in $homes.Keys) {
    if ($homes[$s].Count -gt 1) { Add-Finding ERROR layout-two-homes "${rel}:$($layout.Line)" "$who controller: '$s' has $($homes[$s].Count) homes: $($homes[$s] -join ', ')" }
  }
  $mirrors = [ordered]@{}
  foreach ($s in $padHomes.Keys) {
    if ($padHomes[$s].Count -gt 1) { Add-Finding ERROR layout-two-homes "${rel}:$($layout.Line)" "$who back buttons: '$s' is on $($padHomes[$s].Count) back buttons: $($padHomes[$s] -join ', ')" }
    if ($homes.ContainsKey($s)) {
      # Owner rule: a back button may mirror a page-1 spell only. A home on
      # page 2 or 3 makes the back button a second home.
      $offPage1 = @($homePages[$s].Keys | Where-Object { $_ -ne 1 })
      if ($offPage1.Count -gt 0) {
        Add-Finding ERROR layout-two-homes "${rel}:$($layout.Line)" "$who controller: '$s' is on back button $($padHomes[$s] -join ', ') and has its home on page $($offPage1 -join ', ') ($($homes[$s] -join ', ')); back buttons may mirror page-1 spells only"
        continue
      }
      $pair = "back button $($padHomes[$s] -join ', ') and $($homes[$s] -join ', ')"
      if (-not $mirrors.Contains($pair)) { $mirrors[$pair] = New-Object System.Collections.Generic.List[string] }
      $mirrors[$pair].Add("'$s'")
    }
  }
  foreach ($pair in $mirrors.Keys) {
    Add-Finding INFO layout-paddle-mirror "${rel}:$($layout.Line)" "$who controller: $($mirrors[$pair] -join ', ') on $pair (a mirror of a page-1 spell: allowed by the owner)"
  }
  $all = @{}
  foreach ($s in $homes.Keys) { $all[$s] = $homes[$s] }
  foreach ($s in $padHomes.Keys) { if (-not $all.ContainsKey($s)) { $all[$s] = $padHomes[$s] } }
  Test-MacroCasts $layout $class 'controller' $all $lib $rel
}

# A spec's keyboard over the shared one: a spec bar replaces that bar, a
# stance page replaces that page (false drops it). Mirrors Layout.lua.
function Merge-Keyboard($base, $over) {
  if (-not $base) { return $over }
  $out = [LuaTable]::new($over.Line)
  foreach ($k in $base.Hash.Keys) { $out.Hash[$k] = $base.Hash[$k] }
  foreach ($k in $over.Hash.Keys) {
    if ($k -eq 'stances' -and $over.Hash[$k] -is [LuaTable]) {
      $st = [LuaTable]::new($over.Hash[$k].Line)
      $bs = $base.Get('stances')
      if ($bs -is [LuaTable]) { foreach ($sk in $bs.Hash.Keys) { $st.Hash[$sk] = $bs.Hash[$sk] } }
      foreach ($sk in $over.Hash[$k].Hash.Keys) {
        $v = $over.Hash[$k].Hash[$sk]
        if ($v -is [bool] -and -not $v) { $st.Hash.Remove($sk) } else { $st.Hash[$sk] = $v }
      }
      $out.Hash['stances'] = $st
    } else { $out.Hash[$k] = $over.Hash[$k] }
  }
  return $out
}

# A spec's controller over the shared one: pages[n] replaces page n, paddles replace paddles.
function Merge-Controller($base, $over) {
  if (-not $base) { return $over }
  $out = [LuaTable]::new($over.Line)
  $bp = $base.Get('pages'); $op = $over.Get('pages')
  $pages = [LuaTable]::new($over.Line)
  $n = 3
  if ($bp -and $bp.Arr.Count -gt $n) { $n = $bp.Arr.Count }
  for ($i = 1; $i -le $n; $i++) {
    $pg = $null
    if ($op) { $pg = Get-Bar $op $i }
    if (-not $pg -and $bp) { $pg = Get-Bar $bp $i }
    if ($pg) { [void]$pages.Arr.Add($pg) }
  }
  $out.Hash['pages'] = $pages
  $out.Hash['paddles'] = $base.Get('paddles')
  if ($over.Has('paddles')) { $out.Hash['paddles'] = $over.Get('paddles') }
  return $out
}

# Specs: keys unique, tabs 1-3 unique, exactly one leveling default.
function Test-Specs($def, [string]$class, [string]$rel) {
  $specs = $def.Get('specs')
  $where = "${rel}:$($def.Line)"
  if (-not ($specs -is [LuaTable]) -or $specs.Arr.Count -eq 0) { Add-Finding ERROR layout-spec $where "$class declares no specs"; return @() }
  $keys = @{}; $tabs = @{}; $defaults = 0
  $i = 0
  foreach ($s in $specs.Arr) {
    $i++
    if ($s -isnot [LuaTable]) { Add-Finding ERROR layout-spec $where "$class spec $i is not a table"; continue }
    $w = "${rel}:$($s.Line)"
    foreach ($k in $s.Hash.Keys) { if ($SpecFields -notcontains $k) { Add-Finding ERROR layout-spec $w "$class spec ${i}: unknown field '$k'" } }
    $key = $s.Get('key')
    if (-not ($key -is [string]) -or $key -eq '') { Add-Finding ERROR layout-spec $w "$class spec $i has no key" }
    elseif ($keys.ContainsKey($key)) { Add-Finding ERROR layout-spec $w "$class spec ${i}: key '$key' is used twice" }
    else { $keys[$key] = $true }
    $name = $s.Get('name')
    if (-not ($name -is [string]) -or $name -eq '') { Add-Finding ERROR layout-spec $w "$class spec $i has no name" }
    $tab = $s.Get('tab')
    if (-not ($tab -is [double]) -or $tab -lt 1 -or $tab -gt 3) { Add-Finding ERROR layout-spec $w "$class spec ${i}: tab must be 1-3 (the talent tab)" }
    elseif ($tabs.ContainsKey([int]$tab)) { Add-Finding ERROR layout-spec $w "$class spec ${i}: tab $tab is also spec $($tabs[[int]$tab])" }
    else { $tabs[[int]$tab] = $key }
    if ($s.Get('default') -eq $true) { $defaults++ }
    $ctl = $s.Get('controller')
    if ($ctl -is [LuaTable]) {
      foreach ($k in $ctl.Hash.Keys) { if (@('pages', 'paddles') -notcontains $k) { Add-Finding ERROR layout-spec $w "$class spec $i controller: unknown field '$k' (pages, paddles)" } }
    }
  }
  if ($defaults -ne 1) { Add-Finding ERROR layout-spec $where "$class has $defaults default specs; mark exactly one (the leveling spec)" }
  return @($specs.Arr | Where-Object { $_ -is [LuaTable] })
}

# Layouts/Shared.lua: ns.Layout.RegisterShared({ controller = { pages = { [n] = { ... } } } }),
# the controller buttons every class gets. Fills $script:SharedPages and
# checks its entries once (classless: a shared macro must be classless too).
function Read-SharedLayout($file, $lib, $retired) {
  $rel = Rel $file.FullName
  $script:SharedRel = $rel
  $lit = [LuaLit]::new((ReadText $file.FullName))
  $m = [regex]::Match($lit.code, '\bLayout\.RegisterShared\s*\(\s*(?=\{)')
  if (-not $m.Success) { Add-Finding ERROR layout-parse $rel "no ns.Layout.RegisterShared({ ... }) found"; return }
  $lit.i = $m.Index + $m.Length
  $def = $null
  try { $def = $lit.Table() } catch { Add-Finding ERROR layout-parse "${rel}:$($lit.LineAt($m.Index))" "can't read the shared layout: $_"; return }
  foreach ($k in $def.Hash.Keys) {
    if ($k -ne 'controller') { Add-Finding ERROR layout-parse "${rel}:$($def.Line)" "shared layout: unknown field '$k' (controller)" }
  }
  $ct = $def.Get('controller')
  $pages = $null
  if ($ct -is [LuaTable]) { $pages = $ct.Get('pages') }
  if ($pages -isnot [LuaTable]) { Add-Finding ERROR layout-parse "${rel}:$($def.Line)" "shared layout has no controller.pages"; return }
  $homes = @{}
  foreach ($pk in @($pages.Hash.Keys)) {
    $n = 0
    if (-not [int]::TryParse(($pk -replace '\.0$', ''), [ref]$n) -or $n -lt 1 -or $n -gt 3) { Add-Finding ERROR layout-parse "${rel}:$($pages.Line)" "shared controller page [$pk] is not 1-3"; continue }
    $page = $pages.Hash[$pk]
    if ($page -isnot [LuaTable]) { continue }
    $script:SharedPages[$n] = $page
    foreach ($key in $page.Hash.Keys) {
      if ($key -eq 'title') { continue }
      $e = $page.Hash[$key]
      $where = "${rel}:$($e.Line)"
      $label = "shared controller page $n [$key]"
      if ($key -notmatch '^(none|LT|RT|LT\+RT) (A|X|B|Y|Up|Down|Left|Right)$') { Add-Finding ERROR layout-key $where "$label is not '<none|LT|RT|LT+RT> <A|X|B|Y|Up|Down|Left|Right>'" }
      elseif ($key -match '^none (A|X|B|Y)$') { Add-Finding ERROR layout-key $where "${label}: the Top bar's face buttons are fixed by the Gamepad UI" }
      Test-Entry $e '' 'controller' $where $label $lib $retired
      foreach ($s in (Get-HomeNames $e)) {
        if ($homes.ContainsKey($s)) { Add-Finding ERROR layout-two-homes $where "shared controller: '$s' at $($homes[$s]) and page $n $key" }
        else { $homes[$s] = "page $n $key" }
      }
    }
  }
}

# Layouts/<Class>.lua: one ns.Layout.Register("CLASS", { ... }) each. The data
# must be literal tables (this reader doesn't run Lua).
function Test-Layout($lib, $retired) {
  $dir = Join-Path $Addon 'Layouts'
  $files = @(Get-ChildItem -LiteralPath $dir -Filter '*.lua' -File -ErrorAction SilentlyContinue)
  if ($files.Count -eq 0) { Add-Finding ERROR layout-parse 'Layouts' "no Layouts\*.lua files"; return }
  $seen = @{}
  $script:LayoutClasses = 0
  $script:SharedPages = @{}
  $sharedFile = $files | Where-Object { $_.Name -eq 'Shared.lua' } | Select-Object -First 1
  if ($sharedFile) { Read-SharedLayout $sharedFile $lib $retired }
  else { Add-Finding ERROR layout-parse 'Layouts' "no Layouts\Shared.lua (the shared controller buttons)" }
  foreach ($file in $files) {
    if ($file.Name -eq 'Shared.lua') { continue }
    $rel = Rel $file.FullName
    $lit = [LuaLit]::new((ReadText $file.FullName))
    # The class name is a string, blank in the code copy: read it from the source.
    $found = 0
    foreach ($m in [regex]::Matches($lit.code, '\bLayout\.Register\s*\(\s*("[^"]*")\s*,\s*(?=\{)')) {
      $found++
      $class = $lit.s.Substring($m.Groups[1].Index + 1, $m.Groups[1].Length - 2)
      $lit.i = $m.Index + $m.Length
      $def = $null
      try { $def = $lit.Table() } catch { Add-Finding ERROR layout-parse "${rel}:$($lit.LineAt($m.Index))" "can't read the $class layout: $_"; continue }
      if ($seen.ContainsKey($class)) { Add-Finding ERROR layout-parse "${rel}:$($def.Line)" "$class is also registered in $($seen[$class])" }
      $seen[$class] = $rel
      $script:LayoutClasses++
      foreach ($k in $def.Hash.Keys) {
        if (@('specs', 'keyboard', 'controller') -notcontains $k) { Add-Finding ERROR layout-parse "${rel}:$($def.Line)" "$class layout: unknown field '$k' (specs, keyboard, controller)" }
      }
      foreach ($v in $def.Hash.Values) {
        if ($v -is [LuaExpr]) { Add-Finding ERROR layout-parse "${rel}:$($def.Line)" "$class layout has a non-literal value ($($v.Text)); keep the data literal" }
      }
      $specs = Test-Specs $def $class $rel
      $kb = $def.Get('keyboard')
      $ct = $def.Get('controller')
      if ($null -ne $kb) { Test-KeyboardLayout $kb $class $class $rel $lib $retired }
      if ($null -ne $ct) { Test-ControllerLayout $ct $class $class $rel $lib $retired }
      # A spec override re-checks the merged layout; a finding the shared
      # layout already gave is not repeated for each spec.
      $shared = @{}
      foreach ($f in $script:Findings) { $shared[$f.Message] = $true }
      foreach ($s in $specs) {
        $key = $s.Get('key')
        $who = "$class ($key)"
        $before = $script:Findings.Count
        $skb = $s.Get('keyboard')
        if ($skb -is [LuaTable]) { Test-KeyboardLayout (Merge-Keyboard $kb $skb) $class $who $rel $lib $retired }
        $sct = $s.Get('controller')
        if ($sct -is [LuaTable]) { Test-ControllerLayout (Merge-Controller $ct $sct) $class $who $rel $lib $retired }
        for ($j = $script:Findings.Count - 1; $j -ge $before; $j--) {
          if ($shared.ContainsKey($script:Findings[$j].Message.Replace($who, $class))) { $script:Findings.RemoveAt($j) }
        }
      }
    }
    if ($found -eq 0) { Add-Finding ERROR layout-parse $rel "no ns.Layout.Register(""CLASS"", { ... }) found" }
  }
}


# A macro home that casts spells with their own home on the same device.
function Test-MacroCasts($layout, [string]$class, [string]$device, $homes, $lib, [string]$rel) {
  $seen = @{}
  $stack = New-Object System.Collections.Stack
  $stack.Push($layout)
  while ($stack.Count -gt 0) {
    $t = $stack.Pop()
    $macro = $t.Get('macro')
    if ($macro -and $lib.ContainsKey($macro) ) {
      $own = @($t.Strings())
      $covers = $t.Get('covers')
      $also = @()
      foreach ($s in (Get-CastSpells $lib[$macro].Body)) {
        if ($own -contains $s) { continue }
        if ($covers -is [LuaTable] -and ($covers.Strings() -contains $s)) { continue }
        if ($homes.ContainsKey($s)) { $also += "$s ($($homes[$s][0] -replace ' \(line \d+\)', ''))" }
      }
      if ($also.Count -gt 0) { $msg = "$class ${device}: macro '$macro' also casts spells that have their own home: $($also -join ', ')"; if (-not $seen.ContainsKey($msg)) { $seen[$msg] = $true; Add-Finding INFO layout-macro-casts "${rel}:$($t.Line)" $msg } }
    }
    foreach ($v in $t.Hash.Values) { if ($v -is [LuaTable]) { $stack.Push($v) } }
    foreach ($v in $t.Arr) { if ($v -is [LuaTable]) { $stack.Push($v) } }
  }
}

# ---------------------------------------------------------------------------
# rules: code that creates macros outside the library

function Test-MacroWriters {
  foreach ($file in Get-ChildItem -LiteralPath $Addon -Recurse -File -Filter '*.lua') {
    $rel = Rel $file.FullName
    if ($rel -ieq 'Macros\Library.lua') { continue }
    $lit = [LuaLit]::new((ReadText $file.FullName))
    foreach ($m in [regex]::Matches($lit.code, '\b(CreateMacro|EditMacro)\b')) {
      Add-Finding WARN code-creates-macro "${rel}:$($lit.LineAt($m.Index))" "$($m.Value) outside Macros\Library.lua: rule 'applying bars never installs macros' (Controller petauto toggles land here; owner decides if they are exempt)"
    }
  }
}

# ---------------------------------------------------------------------------
# rules: live game (read-only)

function Find-WowGame {
  # An explicit -WowPath or WOW_PATH may name a flavor folder (_forever_ etc.)
  # and is used as given. The registry usually points at a flavor folder too
  # (often _retail_), so step up from it and prefer _forever_ below.
  $root = $WowPath
  if (-not $root) { $root = $env:WOW_PATH }
  if ($root) {
    $root = $root.TrimEnd('\')
    if ((Test-Path -LiteralPath $root) -and ((Split-Path $root -Leaf) -match '^_.+_$')) { return $root }
  }
  if (-not $root) {
    foreach ($key in 'HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft', 'HKLM:\SOFTWARE\Blizzard Entertainment\World of Warcraft') {
      try { $p = (Get-ItemProperty -Path $key -ErrorAction Stop).InstallPath; if ($p) { $root = $p.TrimEnd('\'); if ((Split-Path $root -Leaf) -match '^_.+_$') { $root = Split-Path $root }; break } } catch {}
    }
  }
  if (-not $root) {
    foreach ($p in 'C:\Program Files (x86)\World of Warcraft', 'C:\Program Files\World of Warcraft', 'D:\World of Warcraft', 'D:\Games\World of Warcraft') {
      if (Test-Path -LiteralPath $p) { $root = $p; break }
    }
  }
  if (-not $root -or -not (Test-Path -LiteralPath $root)) { return $null }
  foreach ($f in '_forever_', '_retail_', '_classic_era_', '_classic_', '_anniversary_') {
    $g = Join-Path $root $f
    if (Test-Path -LiteralPath (Join-Path $g 'WTF')) { return $g }
  }
  return $null
}

function Read-MacroCache([string]$file) {
  $out = @{}
  if (-not (Test-Path -LiteralPath $file)) { return $out }
  $name = $null; $body = New-Object System.Collections.Generic.List[string]
  foreach ($line in [IO.File]::ReadAllLines($file, [Text.Encoding]::UTF8)) {
    if ($line -match '^VER \d+ \S+ "(.*)" ') { $name = $Matches[1]; $body.Clear(); continue }
    if ($line -eq 'END' -and $name) { $out[$name] = ($body -join "`n"); $name = $null; continue }
    if ($name) { $body.Add($line) }
  }
  return $out
}

function Test-LiveGame($lib, $retired) {
  if ($NoGame) { return }
  $game = Find-WowGame
  if (-not $game) { Add-Finding INFO live-skipped 'game' "World of Warcraft not found (pass -WowPath or set WOW_PATH); live checks skipped"; return }
  $acctBase = Join-Path $game 'WTF\Account'
  $acct = Get-ChildItem -LiteralPath $acctBase -Directory -ErrorAction SilentlyContinue | Where-Object Name -ne 'SavedVariables' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $acct) { Add-Finding INFO live-skipped 'game' "no WTF account folder; live checks skipped"; return }
  $chars = @(Get-ChildItem -LiteralPath $acct.FullName -Directory | Where-Object Name -ne 'SavedVariables' |
    ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory } | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SavedVariables') } |
    Sort-Object LastWriteTime -Descending)
  $char = $chars | Select-Object -First 1

  $macros = Read-MacroCache (Join-Path $acct.FullName 'macros-cache.txt')
  $charMacros = @{}
  if ($char) { $charMacros = Read-MacroCache (Join-Path $char.FullName 'macros-cache.txt') }
  $installed = @{}
  foreach ($k in $macros.Keys) { $installed[$k] = @{ Body = $macros[$k]; Scope = 'account' } }
  foreach ($k in $charMacros.Keys) { $installed[$k] = @{ Body = $charMacros[$k]; Scope = 'character' } }

  $bindFiles = @()
  if ($char -and (Test-Path -LiteralPath (Join-Path $char.FullName 'bindings-cache.wtf'))) { $bindFiles += @{ File = (Join-Path $char.FullName 'bindings-cache.wtf'); Scope = 'character' } }
  if (Test-Path -LiteralPath (Join-Path $acct.FullName 'bindings-cache.wtf')) { $bindFiles += @{ File = (Join-Path $acct.FullName 'bindings-cache.wtf'); Scope = 'account' } }
  $paddleOf = @{ F13 = 'L4'; F14 = 'L5'; F15 = 'R4'; F16 = 'R5'; 'SHIFT-F13' = 'LT+L4'; 'SHIFT-F14' = 'LT+L5'; 'SHIFT-F15' = 'LT+R4'; 'SHIFT-F16' = 'LT+R5' }
  foreach ($bf in $bindFiles | Select-Object -First 1) {
    foreach ($line in [IO.File]::ReadAllLines($bf.File, [Text.Encoding]::UTF8)) {
      if ($line -notmatch '^bind\s+(\S+)\s+MACRO\s+(.+)$') { continue }
      $key = $Matches[1]; $name = $Matches[2].Trim()
      $pad = ''
      if ($paddleOf.ContainsKey($key)) { $pad = " (back button $($paddleOf[$key]))" }
      if (-not $installed.ContainsKey($name)) {
        $why = 'no such macro in /macro'
        if ($retired.ContainsKey($name)) { $why += "; '$name' is a retired Agentcraft macro (in L.retired: Controller Apply deletes it, and a later Apply would rebind this key)" }
        Add-Finding ERROR live-binding "$($bf.Scope) bindings-cache.wtf" "$key$pad is bound to MACRO $name, but $why. Pressing it does nothing"
      }
    }
  }
  foreach ($name in $installed.Keys) {
    if ($lib.ContainsKey($name) -and $lib[$name].Generated) {
      # A generated item macro's text follows your bags; it never matches the library body.
    } elseif ($lib.ContainsKey($name)) {
      $want = ($lib[$name].Body -replace '\s+$', '')
      $have = ($installed[$name].Body -replace '\s+$', '')
      if ($want -ne $have) { Add-Finding INFO live-macro-outdated "$($installed[$name].Scope) macros-cache.txt" "installed macro '$name' differs from the library (Update on the Macros page)" }
    } elseif ($retired.ContainsKey($name)) {
      Add-Finding INFO live-macro-retired "$($installed[$name].Scope) macros-cache.txt" "installed macro '$name' is retired; Controller Apply deletes it while its text is unchanged (texts players often write, and the Eat/Feed shapes, only when Agentcraft recorded writing them)"
    }
  }
  Add-Finding INFO live-read 'game' "read $($installed.Count) installed macros and $(@($bindFiles).Count) bindings file(s) from the newest account/character (macros-cache.txt and bindings-cache.wtf are written on logout or /reload)"
}

function Cmd-Rules {
  $data = Read-Macros
  $items = Read-ItemNames
  $lib = @{}
  $firstAt = @{}
  foreach ($m in $data.Macros) {
    if ($firstAt.ContainsKey($m.Name)) { Add-Finding ERROR macro-duplicate "$($m.File):$($m.Line)" "macro name '$($m.Name)' is also defined at $($firstAt[$m.Name])" }
    else { $firstAt[$m.Name] = "$($m.File):$($m.Line)"; $lib[$m.Name] = $m }
    Test-Macro $m $items
    if ($data.Retired.ContainsKey($m.Name)) {
      Add-Finding INFO macro-retired-name "$($m.File):$($m.Line)" "'$($m.Name)' is live and in L.retired ($($data.Retired[$m.Name].Where)): Apply keeps it; the Macros page shows Update while its text equals the retired text"
    }
  }
  Test-Layout $lib $data.Retired
  Test-MacroWriters
  Test-LiveGame $lib $data.Retired
  Say "rules: $($data.Macros.Count) library macros, $($data.Retired.Count) retired names, checked against $($script:LayoutClasses) class layouts in Layouts\*.lua"
  return Write-Findings 'rules'
}

# ---------------------------------------------------------------------------
# globals: what the addon reads and writes as globals (for .luacheckrc)

$LuaKeywords = 'and break do else elseif end false for function if in local nil not or repeat return then true until while self' -split ' '

function Cmd-Globals {
  $toc = Read-Toc
  $reads = @{}; $writes = @{}
  foreach ($f in $toc.Files) {
    $full = Join-Path $Addon ($f.Path -replace '/', '\')
    if (-not (Test-Path -LiteralPath $full)) { continue }
    $code = ([LuaLit]::new((ReadText $full))).code
    $locals = @{}
    foreach ($m in [regex]::Matches($code, '\blocal\s+function\s+([A-Za-z_]\w*)')) { $locals[$m.Groups[1].Value] = 1 }
    foreach ($m in [regex]::Matches($code, '\blocal\s+((?:[A-Za-z_]\w*\s*,\s*)*[A-Za-z_]\w*)')) { foreach ($v in ($m.Groups[1].Value -split ',')) { $locals[$v.Trim()] = 1 } }
    foreach ($m in [regex]::Matches($code, '\bfunction\b[^(]*\(([^)]*)\)')) { foreach ($v in ($m.Groups[1].Value -split ',')) { $locals[$v.Trim()] = 1 } }
    foreach ($m in [regex]::Matches($code, '\bfor\s+((?:[A-Za-z_]\w*\s*,\s*)*[A-Za-z_]\w*)\s+in\b')) { foreach ($v in ($m.Groups[1].Value -split ',')) { $locals[$v.Trim()] = 1 } }
    foreach ($m in [regex]::Matches($code, '\bfor\s+([A-Za-z_]\w*)\s*=')) { $locals[$m.Groups[1].Value] = 1 }
    foreach ($m in [regex]::Matches($code, '(?<![\w.:])([A-Za-z_]\w*)')) {
      $name = $m.Groups[1].Value
      if ($LuaKeywords -contains $name -or $locals.ContainsKey($name)) { continue }
      $before = $code.Substring(0, $m.Index).TrimEnd()
      $after = $code.Substring($m.Index + $m.Length)
      $isAssign = $after -match '^\s*=(?!=)'
      if ($isAssign -and ($before.EndsWith('{') -or $before.EndsWith(','))) { continue } # table field key
      # A field (t.x, t:x) has one '.' before it; '..' (concat) and '...' (varargs) don't count.
      if ($before -match '(?<!\.)\.$' -or $before.EndsWith(':')) { continue }
      $target = $reads
      if ($isAssign) { $target = $writes }
      if (-not $target.ContainsKey($name)) { $target[$name] = New-Object System.Collections.Generic.List[string] }
      $target[$name].Add($f.Path)
    }
  }
  Say "-- globals written (luacheck 'globals'; anything unexpected here is an accidental global):"
  foreach ($k in ($writes.Keys | Sort-Object)) { Say ("  {0,-28} {1}" -f $k, (($writes[$k] | Select-Object -Unique) -join ', ')) }
  Say "-- globals read (luacheck 'read_globals'; review: some are fields the heuristic missed):"
  foreach ($k in ($reads.Keys | Where-Object { -not $writes.ContainsKey($_) } | Sort-Object)) { Say ("  {0,-40} {1}" -f $k, $reads[$k].Count) }
  return 0
}

# ---------------------------------------------------------------------------
# External tools

# dev\tools first, then PATH, then where per-user installs land without
# touching PATH in an already open shell (winget user scope, manual unzip).
function Find-Tool([string[]]$names) {
  foreach ($n in $names) {
    $local = Join-Path $DevDir "tools\$n.exe"
    if (Test-Path -LiteralPath $local) { return $local }
    $c = Get-Command $n -ErrorAction SilentlyContinue | Where-Object { $_.CommandType -eq 'Application' } | Select-Object -First 1
    if ($c) { return $c.Source }
    if ($env:LOCALAPPDATA) {
      $globs = @(
        (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\$n.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\*\$n.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\*\bin\$n.exe"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\*\$n.exe"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\*\bin\$n.exe")
      )
      foreach ($g in $globs) {
        $hit = Get-Item -Path $g -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
      }
    }
  }
  return $null
}

function Missing([string]$what, [string[]]$install) {
  Say "SKIP: $what is not installed. Install one of:"
  foreach ($i in $install) { Say "  $i" }
  return 2
}

# Lua and luacheck read argv, the working directory and file names through
# the ANSI code page, which can't hold every character a user folder may have
# (luacheck then can't even find .luacheckrc). So a non-ASCII path is passed
# as its 8.3 short name, and tools get paths relative to their working dir.
function AsciiPath([string]$full) {
  if ($full -notmatch '[^\x20-\x7e]') { return $full }
  try {
    $fso = New-Object -ComObject Scripting.FileSystemObject
    $short = if (Test-Path -LiteralPath $full -PathType Container) { $fso.GetFolder($full).ShortPath } else { $fso.GetFile($full).ShortPath }
    if ($short -and $short -notmatch '[^\x20-\x7e]') { return $short }
  } catch {}
  Say "note: '$full' has non-ASCII characters and no 8.3 short name; Lua tools may not open it"
  return $full
}

# A path relative to $WowDir with forward slashes when $full is inside it, else
# an ASCII-safe absolute path.
function WowRel([string]$full) {
  if ($full.StartsWith($WowDir + '\', [StringComparison]::OrdinalIgnoreCase)) { return $full.Substring($WowDir.Length + 1).Replace('\', '/') }
  return (AsciiPath $full)
}

# Runs a native tool in $cwd and returns @{ Code; Out; Err }. Uses
# System.Diagnostics.Process, not "& exe 2>&1": Windows PowerShell 5.1 turns
# every stderr line into a terminating error under $ErrorActionPreference =
# 'Stop' (Lua 5.1 prints its version and tracebacks to stderr), and PowerShell
# expands an 8.3 working directory back to the long name, which luacheck
# can't read.
function Run-Native([string]$exe, [string[]]$argv, [string]$cwd) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $exe
  $quoted = foreach ($a in $argv) { if ($a -match '[\s"]' -or $a -eq '') { '"' + ($a -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"' } else { $a } }
  $psi.Arguments = $quoted -join ' '
  if ($cwd) { $psi.WorkingDirectory = AsciiPath $cwd }
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.StandardOutputEncoding = $utf8
  $psi.StandardErrorEncoding = $utf8
  $p = [System.Diagnostics.Process]::Start($psi)
  $errTask = $p.StandardError.ReadToEndAsync()
  $out = $p.StandardOutput.ReadToEnd()
  $p.WaitForExit()
  return @{ Code = $p.ExitCode; Out = $out; Err = $errTask.Result }
}

# Runs a native tool and prints its output (stdout, then stderr). Returns the exit code.
function Invoke-Native([string]$exe, [string[]]$argv, [string]$cwd) {
  $r = Run-Native $exe $argv $cwd
  foreach ($text in $r.Out, $r.Err) {
    $t = ($text -replace "`r`n", "`n").TrimEnd()
    if ($t) { Say $t }
  }
  return $r.Code
}

function Cmd-Lint {
  $exe = Find-Tool @('luacheck')
  if (-not $exe) { return Missing 'luacheck' @('scoop install luacheck', "download https://github.com/lunarmodules/luacheck/releases/download/v1.2.0/luacheck.exe to $DevDir\tools\luacheck.exe") }
  Say "lint: $exe"
  # Relative paths, so the files["addon/Agentcraft/..."] sections in .luacheckrc match.
  # luacheck exits 0 clean, 1 warnings, 2 errors, 3+ crash.
  $code = Invoke-Native $exe @((WowRel $Addon), 'dev/harness', 'dev/tests', 'dev/render', '--config', '.luacheckrc', '--quiet', '--no-color') $WowDir
  if ($code -eq 0) { return 0 }
  return 1
}

function Find-Lua {
  foreach ($n in 'lua5.1', 'lua51', 'luajit', 'lua') {
    $exe = Find-Tool @($n)
    if (-not $exe) { continue }
    $r = Run-Native $exe @('-v') $null
    $ver = "$($r.Out)$($r.Err)".Trim()
    if ($ver -match 'Lua 5\.1|LuaJIT') { return $exe }
    Say "note: $exe is '$ver', not Lua 5.1; skipping it"
  }
  return $null
}

function Cmd-Test {
  $exe = Find-Lua
  if (-not $exe) { return Missing 'Lua 5.1' @('scoop bucket add versions; scoop install lua51', 'winget install --id DEVCOM.LuaJIT -e') }
  Say "test: $exe"
  $code = Invoke-Native $exe @('dev/harness/run.lua', (WowRel $Addon), 'dev/tests') $WowDir
  if ($code -eq 0) { return 0 }
  return 1
}

# Static UI lint: the [lint] rules in dev/ui-rules.md (dev/harness/uilint.lua).
# Errors fail; warnings print and pass. "-- ui-ok: <reason>" suppresses a line.
function Cmd-LintUi {
  $exe = Find-Lua
  if (-not $exe) { return Missing 'Lua 5.1' @('scoop bucket add versions; scoop install lua51', 'winget install --id DEVCOM.LuaJIT -e') }
  Say "lint-ui: $exe"
  $code = Invoke-Native $exe @('dev/harness/uilint.lua', (WowRel $Addon)) $WowDir
  if ($code -eq 0) { return 0 }
  return 1
}

function Cmd-Types {
  $exe = Find-Tool @('lua-language-server')
  if (-not $exe) { return Missing 'lua-language-server' @('winget install --id LuaLS.lua-language-server -e') }
  Say "types: $exe"
  $code = Invoke-Native $exe @('--check', $Addon, '--configpath', (Join-Path $WowDir '.luarc.json'), '--checklevel=Warning') $WowDir
  if ($code -eq 0) { return 0 }
  return 1
}


# Offline render of the /ac window: dev/render/render.lua writes one HTML file
# per page to dev/render/out, plus textures-missing.txt. -Fetch fills
# dev/render/textures (and generates dev/render/atlases.lua) through
# dev/render/fetch.ps1, then renders again.
. (Join-Path $DevDir 'render\fetch.ps1')

function Cmd-Render {
  $exe = Find-Lua
  if (-not $exe) { return Missing 'Lua 5.1' @('scoop bucket add versions; scoop install lua51', 'winget install --id DEVCOM.LuaJIT -e') }
  $outDir = Join-Path $DevDir 'render\out'
  $texDir = Join-Path $DevDir 'render\textures'
  New-Item -ItemType Directory -Force -Path $outDir, $texDir | Out-Null
  Say "render: $exe"
  $argv = @('dev/render/render.lua', (WowRel $Addon), 'dev/render/out', 'dev/render/textures')
  if ($Fetch) {
    # A first, quiet pass lists the missing textures.
    $first = Run-Native $exe $argv $WowDir
    if ($first.Err) { Say $first.Err.TrimEnd() }
    Say "fetch: missing textures from github.com/$TexRepo ($TexBranch), atlases and other files from wago.tools"
    $null = Fetch-Textures (Join-Path $outDir 'textures-missing.txt') $texDir (Join-Path $DevDir 'render')
    Say ""
  }
  $code = Invoke-Native $exe $argv $WowDir
  Say "open $(Rel (Join-Path $outDir 'index.html'))"
  if ($code -eq 0) { return 0 }
  return 1
}

function Run-Step([string]$name, [scriptblock]$fn) {
  Say ""
  Say "################ $name ################"
  try { $r = & $fn; return [int]($r | Select-Object -Last 1) }
  catch { Say "FAIL: $name crashed: $($_.Exception.Message) ($($_.InvocationInfo.ScriptLineNumber))"; return 1 }
}

function Cmd-Check {
  $results = [ordered]@{}
  $results['toc'] = Run-Step 'toc' { Cmd-Toc }
  $results['rules'] = Run-Step 'rules' { Cmd-Rules }
  $results['lint'] = Run-Step 'lint' { Cmd-Lint }
  $results['lint-ui'] = Run-Step 'lint-ui' { Cmd-LintUi }
  $results['types'] = Run-Step 'types' { Cmd-Types }
  $results['test'] = Run-Step 'test' { Cmd-Test }
  Say ""
  Say "################ summary ################"
  $fail = $false
  foreach ($k in $results.Keys) {
    $label = switch ($results[$k]) { 0 { 'pass' } 2 { 'skipped (tool missing)' } default { 'FAIL' } }
    if ($results[$k] -eq 1) { $fail = $true }
    Say ("  {0,-8} {1}" -f $k, $label)
  }
  if ($fail) { return 1 }
  return 0
}

$code = 0
try {
  switch ($Command.ToLowerInvariant()) {
    'check' { $code = Cmd-Check }
    'toc' { $code = Cmd-Toc }
    'rules' { $code = Cmd-Rules }
    'lint' { $code = Cmd-Lint }
    'lint-ui' { $code = Cmd-LintUi }
    'test' { $code = Cmd-Test }
    'types' { $code = Cmd-Types }
    'globals' { $code = Cmd-Globals }
    'render' { $code = Cmd-Render }
    default { Say "unknown command '$Command'. Commands: check, toc, rules, lint, lint-ui, test, types, globals, render"; $code = 1 }
  }
} catch {
  Say "dev.ps1 crashed: $($_.Exception.Message) at line $($_.InvocationInfo.ScriptLineNumber)"
  $code = 1
}
exit ([int]($code | Select-Object -Last 1))
