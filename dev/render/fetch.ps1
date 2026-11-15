# Texture fetch for dev.ps1 render -Fetch (Windows PowerShell 5.1).
# Dot-sourced by dev.ps1, and by fetch-test.ps1 for the offline unit tests.
#
# It reads dev/render/out/textures-missing.txt ("<rel>\t<original>" per line,
# written by render.lua) and fills dev/render/textures/ with what the next
# render needs:
#   atlas/<name>  -> looks the atlas up in the UiTextureAtlasMember and
#                    UiTextureAtlas tables (wago.tools DB2 CSV exports, cached),
#                    regenerates dev/render/atlases.lua, then fetches the sheet.
#   fileid/<n>    -> names the file through the wago.tools file search, adds
#                    it to dev/render/fileids.lua, then fetches it.
#   interface/... -> a PNG from Gethe/wow-ui-textures (branch live) when that
#                    mirror has it; otherwise the client's BLP from wago.tools
#                    by file ID, converted to PNG here.
# Files neither source has go to textures/unavailable.txt ("not mirrored");
# render.lua labels those warnings. Network failures are "not fetched" and
# are retried on the next -Fetch.
#
# Everything downloaded is cached under textures/.cache/: the GitHub trees
# (60 unauthenticated API calls an hour), the two atlas CSVs and files.tsv
# (file ID <-> path). Delete the cache folder to refresh it.

$TexRepo = 'Gethe/wow-ui-textures'
$TexBranch = 'live'
$WagoBase = 'https://wago.tools'
# Empty means the latest retail build. Set it to a build such as '11.0.2.56196'
# (any build wago.tools lists) to read the atlas tables of that build instead.
$WagoBuild = ''
$TexUserAgent = 'agentcraft-dev-render'

function TexSay([string]$text) {
  if (Get-Command Say -ErrorAction SilentlyContinue) { Say $text } else { [Console]::Out.WriteLine($text) }
}

function TexDownload([string]$url, [string]$dest) {
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
  $headers = @{ 'User-Agent' = $TexUserAgent }
  if ($dest) { Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $url -OutFile $dest | Out-Null; return $null }
  return (Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $url).Content
}

function TexJson([string]$json) {
  Add-Type -AssemblyName System.Web.Extensions
  $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  $ser.MaxJsonLength = [int]::MaxValue
  return $ser.DeserializeObject($json)
}

# "Interface\\Icons\\Foo.blp" -> "interface/icons/foo" (render.lua NormalizePath).
function ConvertTo-TexRel([string]$path) {
  $p = $path.Replace('\', '/').ToLowerInvariant()
  return ($p -replace '\.(blp|tga|png)$', '')
}

# "interface/icons/foo" -> "Interface\\Icons\\foo" is not needed: fileids.lua and
# atlases.lua store the lower-case client path with backslashes.
function ConvertTo-TexClientPath([string]$rel) { return $rel.Replace('/', '\') }

# ---------------------------------------------------------------------------
# BLP2 -> PNG. Palettized (with 0/1/4/8-bit alpha), DXT1/3/5 and BGRA; the
# first mip level only.

if (-not ('AcBlp' -as [type])) {
  Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class AcBlp {
  // Returns BGRA pixels, top row first.
  public static byte[] Decode(byte[] d, out int w, out int h) {
    if (d.Length < 1172 || d[0] != 'B' || d[1] != 'L' || d[2] != 'P' || d[3] != '2') throw new Exception("not a BLP2 file");
    int comp = d[8], alphaDepth = d[9], alphaType = d[10];
    w = BitConverter.ToInt32(d, 12); h = BitConverter.ToInt32(d, 16);
    int off = BitConverter.ToInt32(d, 20);
    if (w <= 0 || h <= 0 || w > 8192 || h > 8192) throw new Exception("bad BLP size");
    byte[] o = new byte[w * h * 4];
    int n = w * h;
    if (comp == 1) {
      int a0 = off + n;
      for (int i = 0; i < n; i++) {
        int p = 148 + d[off + i] * 4;
        o[i * 4] = d[p]; o[i * 4 + 1] = d[p + 1]; o[i * 4 + 2] = d[p + 2];
        int a = 255;
        if (alphaDepth == 1) a = ((d[a0 + i / 8] >> (i % 8)) & 1) != 0 ? 255 : 0;
        else if (alphaDepth == 4) a = ((d[a0 + i / 2] >> ((i % 2) * 4)) & 0xF) * 17;
        else if (alphaDepth == 8) a = d[a0 + i];
        o[i * 4 + 3] = (byte)a;
      }
    } else if (comp == 2) {
      int fmt = alphaDepth > 1 ? (alphaType == 7 ? 5 : 3) : 1;
      int bw = (w + 3) / 4, bh = (h + 3) / 4, pos = off;
      byte[] alpha = new byte[16];
      byte[] col = new byte[16 * 4];
      for (int by = 0; by < bh; by++) {
        for (int bx = 0; bx < bw; bx++) {
          for (int k = 0; k < 16; k++) alpha[k] = 255;
          if (fmt == 3) {
            for (int k = 0; k < 8; k++) {
              alpha[k * 2] = (byte)((d[pos + k] & 0xF) * 17);
              alpha[k * 2 + 1] = (byte)((d[pos + k] >> 4) * 17);
            }
            pos += 8;
          } else if (fmt == 5) {
            int x0 = d[pos], x1 = d[pos + 1];
            int[] tab = new int[8];
            tab[0] = x0; tab[1] = x1;
            if (x0 > x1) { for (int k = 1; k < 7; k++) tab[k + 1] = ((7 - k) * x0 + k * x1) / 7; }
            else { for (int k = 1; k < 5; k++) tab[k + 1] = ((5 - k) * x0 + k * x1) / 5; tab[6] = 0; tab[7] = 255; }
            ulong bits = 0;
            for (int k = 0; k < 6; k++) bits |= (ulong)d[pos + 2 + k] << (8 * k);
            for (int k = 0; k < 16; k++) alpha[k] = (byte)tab[(int)((bits >> (3 * k)) & 7)];
            pos += 8;
          }
          DecodeColor(d, pos, col, fmt == 1, alphaDepth > 0);
          pos += 8;
          for (int py = 0; py < 4; py++) {
            int y = by * 4 + py; if (y >= h) break;
            for (int px = 0; px < 4; px++) {
              int x = bx * 4 + px; if (x >= w) break;
              int k = py * 4 + px, t = (y * w + x) * 4;
              o[t] = col[k * 4]; o[t + 1] = col[k * 4 + 1]; o[t + 2] = col[k * 4 + 2];
              o[t + 3] = fmt == 1 ? col[k * 4 + 3] : alpha[k];
            }
          }
        }
      }
    } else if (comp == 3) {
      Buffer.BlockCopy(d, off, o, 0, n * 4);
      if (alphaDepth == 0) for (int i = 0; i < n; i++) o[i * 4 + 3] = 255;
    } else {
      throw new Exception("unknown BLP compression " + comp);
    }
    return o;
  }

  static void C565(int c, out int r, out int g, out int b) {
    r = ((c >> 11) & 31) * 255 / 31; g = ((c >> 5) & 63) * 255 / 63; b = (c & 31) * 255 / 31;
  }

  // One DXT colour block into col (BGRA x16).
  static void DecodeColor(byte[] d, int pos, byte[] col, bool dxt1, bool oneBitAlpha) {
    int c0 = d[pos] | (d[pos + 1] << 8), c1 = d[pos + 2] | (d[pos + 3] << 8);
    int[] r = new int[4], g = new int[4], b = new int[4], a = { 255, 255, 255, 255 };
    C565(c0, out r[0], out g[0], out b[0]);
    C565(c1, out r[1], out g[1], out b[1]);
    if (!dxt1 || c0 > c1) {
      r[2] = (2 * r[0] + r[1]) / 3; g[2] = (2 * g[0] + g[1]) / 3; b[2] = (2 * b[0] + b[1]) / 3;
      r[3] = (r[0] + 2 * r[1]) / 3; g[3] = (g[0] + 2 * g[1]) / 3; b[3] = (b[0] + 2 * b[1]) / 3;
    } else {
      r[2] = (r[0] + r[1]) / 2; g[2] = (g[0] + g[1]) / 2; b[2] = (b[0] + b[1]) / 2;
      r[3] = 0; g[3] = 0; b[3] = 0; a[3] = oneBitAlpha ? 0 : 255;
    }
    uint idx = (uint)(d[pos + 4] | (d[pos + 5] << 8) | (d[pos + 6] << 16) | (d[pos + 7] << 24));
    for (int k = 0; k < 16; k++) {
      int i = (int)((idx >> (2 * k)) & 3);
      col[k * 4] = (byte)b[i]; col[k * 4 + 1] = (byte)g[i]; col[k * 4 + 2] = (byte)r[i]; col[k * 4 + 3] = (byte)a[i];
    }
  }

  public static void SavePng(byte[] bgra, int w, int h, string path) {
    using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
      BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
      for (int y = 0; y < h; y++) Marshal.Copy(bgra, y * w * 4, new IntPtr(bd.Scan0.ToInt64() + (long)y * bd.Stride), w * 4);
      bmp.UnlockBits(bd);
      bmp.Save(path, ImageFormat.Png);
    }
  }

  public static void BlpToPng(string blp, string png) {
    int w, h;
    byte[] px = Decode(System.IO.File.ReadAllBytes(blp), out w, out h);
    SavePng(px, w, h, png);
  }
}
'@
}

# ---------------------------------------------------------------------------
# Gethe/wow-ui-textures: exact-case path through the GitHub trees API.

function Get-TexTree([string]$sha, [string]$cacheDir) {
  if (-not $script:TexTrees) { $script:TexTrees = @{} }
  if ($script:TexTrees.ContainsKey($sha)) { return $script:TexTrees[$sha] }
  $file = Join-Path $cacheDir "tree-$sha.json"
  if (Test-Path -LiteralPath $file) { $json = [IO.File]::ReadAllText($file) }
  else {
    $url = "https://api.github.com/repos/$TexRepo/git/trees/$sha"
    TexSay "  listing $url"
    $json = TexDownload $url
    [IO.File]::WriteAllText($file, $json)
  }
  $tree = TexJson $json
  $script:TexTrees[$sha] = $tree
  return $tree
}

# "interface/buttons/ui-quickslot2" -> "Buttons/UI-Quickslot2.PNG" (the repo's
# exact case), or $null when the repo doesn't have it.
function Find-TexPath([string]$rel, [string]$cacheDir) {
  $parts = $rel -split '/'
  if ($parts.Count -lt 2 -or $parts[0] -ne 'interface') { return $null }
  $sha = $TexBranch
  $path = @()
  for ($i = 1; $i -lt $parts.Count; $i++) {
    $tree = Get-TexTree $sha $cacheDir
    $last = ($i -eq $parts.Count - 1)
    $want = if ($last) { $parts[$i] + '.png' } else { $parts[$i] }
    $hit = $null
    foreach ($e in $tree['tree']) {
      if ($e['path'] -ieq $want -and (($last -and $e['type'] -eq 'blob') -or (-not $last -and $e['type'] -eq 'tree'))) { $hit = $e; break }
    }
    if (-not $hit) { return $null }
    $path += $hit['path']
    $sha = $hit['sha']
  }
  return ($path -join '/')
}

# ---------------------------------------------------------------------------
# wago.tools: DB2 CSV exports, file search and CASC file download.

function Get-WagoCsv([string]$table, [string]$cacheDir) {
  $file = Join-Path $cacheDir "$table.csv"
  if (-not (Test-Path -LiteralPath $file)) {
    $url = "$WagoBase/db2/$table/csv"
    if ($WagoBuild) { $url += "?build=$WagoBuild" }
    TexSay "  downloading $url"
    TexDownload $url $file
  }
  return $file
}

# CSV line -> fields. wago.tools quotes a field only when it holds a comma.
function Split-CsvLine([string]$line) {
  if ($line.IndexOf('"') -lt 0) { return $line.Split(',') }
  $out = New-Object System.Collections.Generic.List[string]
  $sb = New-Object System.Text.StringBuilder
  $q = $false
  for ($i = 0; $i -lt $line.Length; $i++) {
    $c = $line[$i]
    if ($q) {
      if ($c -eq '"') { if ($i + 1 -lt $line.Length -and $line[$i + 1] -eq '"') { [void]$sb.Append('"'); $i++ } else { $q = $false } }
      else { [void]$sb.Append($c) }
    } elseif ($c -eq '"') { $q = $true }
    elseif ($c -eq ',') { $out.Add($sb.ToString()); [void]$sb.Clear() }
    else { [void]$sb.Append($c) }
  }
  $out.Add($sb.ToString())
  return $out.ToArray()
}

# Atlas names (any case) -> @{ <lower name> = @{ name; fileID; w; h; l; r; t; b; tileH; tileV } }
# from the two CSV files. Names the tables don't have are left out.
function Find-AtlasRows([string[]]$names, [string]$memberCsv, [string]$atlasCsv) {
  $want = @{}
  foreach ($n in $names) { $want[$n.ToLowerInvariant()] = $true }
  $members = @{}
  $lines = [IO.File]::ReadAllLines($memberCsv)
  $head = Split-CsvLine $lines[0]
  $col = @{}
  for ($i = 0; $i -lt $head.Count; $i++) { $col[$head[$i]] = $i }
  for ($i = 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $comma = $line.IndexOf(',')
    if ($comma -lt 1) { continue }
    $key = $line.Substring(0, $comma).Trim('"').ToLowerInvariant()
    if (-not $want.ContainsKey($key) -or $members.ContainsKey($key)) { continue }
    $members[$key] = Split-CsvLine $line
  }
  $sheets = @{}
  $alines = [IO.File]::ReadAllLines($atlasCsv)
  $ahead = Split-CsvLine $alines[0]
  $acol = @{}
  for ($i = 0; $i -lt $ahead.Count; $i++) { $acol[$ahead[$i]] = $i }
  for ($i = 1; $i -lt $alines.Count; $i++) {
    $f = Split-CsvLine $alines[$i]
    if ($f.Count -gt $acol['AtlasHeight']) { $sheets[$f[$acol['ID']]] = $f }
  }
  $out = @{}
  foreach ($key in $members.Keys) {
    $m = $members[$key]
    $s = $sheets[$m[$col['UiTextureAtlasID']]]
    if (-not $s) { continue }
    $sw = [double]$s[$acol['AtlasWidth']]; $sh = [double]$s[$acol['AtlasHeight']]
    if ($sw -le 0 -or $sh -le 0) { continue }
    $w = [int]$m[$col['Width']]; $h = [int]$m[$col['Height']]
    if ($col.ContainsKey('OverrideWidth') -and [int]$m[$col['OverrideWidth']] -gt 0) { $w = [int]$m[$col['OverrideWidth']] }
    if ($col.ContainsKey('OverrideHeight') -and [int]$m[$col['OverrideHeight']] -gt 0) { $h = [int]$m[$col['OverrideHeight']] }
    $flags = [int]$m[$col['CommittedFlags']]
    $out[$key] = @{
      name = $m[0].Trim('"'); fileID = [int]$s[$acol['FileDataID']]; w = $w; h = $h
      l = [double]$m[$col['CommittedLeft']] / $sw; r = [double]$m[$col['CommittedRight']] / $sw
      t = [double]$m[$col['CommittedTop']] / $sh; b = [double]$m[$col['CommittedBottom']] / $sh
      # CommittedFlags: 4 tiles horizontally ("_" names), 2 vertically ("!" names).
      tileH = (($flags -band 4) -ne 0); tileV = (($flags -band 2) -ne 0)
    }
  }
  return $out
}

# The data-page JSON of a wago.tools /files page -> @( @{ fdid; filename } ).
function Read-WagoFilesPage([string]$html) {
  $m = [regex]::Match($html, 'data-page="([^"]*)"')
  if (-not $m.Success) { throw 'wago.tools files page without data-page' }
  $page = TexJson ([System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value))
  $out = @()
  $files = $page['props']['files']
  if (-not $files) { return $out }
  foreach ($e in $files['data']) { $out += @{ fdid = [int]$e['fdid']; filename = [string]$e['filename'] } }
  return $out
}

# files.tsv cache: "<fileID>\t<rel or empty>" (empty: the file has no known name).
function Get-FileCache([string]$cacheDir) {
  if ($script:TexFiles) { return $script:TexFiles }
  $script:TexFiles = @{ byId = @{}; byRel = @{}; file = (Join-Path $cacheDir 'files.tsv') }
  if (Test-Path -LiteralPath $script:TexFiles.file) {
    foreach ($line in [IO.File]::ReadAllLines($script:TexFiles.file)) {
      $f = $line -split "`t"
      if ($f.Count -lt 2 -or -not ($f[0] -match '^\d+$')) { continue }
      if ([int]$f[0] -ne 0) { $script:TexFiles.byId[[int]$f[0]] = $f[1] }
      if ($f[1]) { $script:TexFiles.byRel[$f[1]] = [int]$f[0] }
    }
  }
  return $script:TexFiles
}
function Add-FileCache([string]$cacheDir, [int]$fdid, [string]$rel) {
  $c = Get-FileCache $cacheDir
  if ($fdid -and $c.byId.ContainsKey($fdid) -and $c.byId[$fdid] -eq $rel) { return }
  if ($fdid) { $c.byId[$fdid] = $rel }
  if ($rel) { $c.byRel[$rel] = $fdid }
  [IO.File]::AppendAllText($c.file, "$fdid`t$rel`n")
}

# File ID -> rel ("interface/icons/foo"), or '' when wago.tools has no name for it.
# The search lists matches by ascending ID, and any ID that contains the digits
# of N is at least N, so an exact hit is on the first page.
function Resolve-FileId([int]$fdid, [string]$cacheDir) {
  $c = Get-FileCache $cacheDir
  if ($c.byId.ContainsKey($fdid)) { return $c.byId[$fdid] }
  $rel = ''
  foreach ($e in (Read-WagoFilesPage (TexDownload "$WagoBase/files?search=$fdid"))) {
    if ($e.fdid -eq $fdid) { $rel = ConvertTo-TexRel $e.filename; break }
  }
  Add-FileCache $cacheDir $fdid $rel
  return $rel
}

# rel -> file ID, or 0 when wago.tools doesn't list the file.
function Resolve-TexRel([string]$rel, [string]$cacheDir) {
  $c = Get-FileCache $cacheDir
  if ($c.byRel.ContainsKey($rel)) { return $c.byRel[$rel] }
  foreach ($ext in @('.blp', '.tga')) {
    foreach ($e in (Read-WagoFilesPage (TexDownload ("$WagoBase/files?search=" + [Uri]::EscapeDataString($rel + $ext))))) {
      if ((ConvertTo-TexRel $e.filename) -eq $rel -and $e.filename.ToLowerInvariant().EndsWith($ext)) {
        Add-FileCache $cacheDir $e.fdid $rel
        return $e.fdid
      }
    }
  }
  Add-FileCache $cacheDir 0 $rel
  return 0
}

# The client's file by ID from wago.tools, converted to PNG at $dest.
function Get-WagoPng([int]$fdid, [string]$dest, [string]$cacheDir) {
  $tmp = Join-Path $cacheDir "$fdid.blp"
  TexDownload "$WagoBase/api/casc/$fdid" $tmp
  try {
    $bytes = [IO.File]::ReadAllBytes($tmp)
    $magic = [Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(4, $bytes.Length))
    if ($magic -ne 'BLP2') { throw "file $fdid is not a BLP2 texture ($magic)" }
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    [AcBlp]::BlpToPng($tmp, $dest)
  } finally { Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------------------------
# Generated Lua files.

function Format-LuaNum([double]$v) {
  $s = $v.ToString('0.#########', [Globalization.CultureInfo]::InvariantCulture)
  return $s
}
function Format-LuaStr([string]$s) { return '"' + $s.Replace('\', '\\').Replace('"', '\"') + '"' }

# Atlas names already in atlases.lua (its keys).
function Read-AtlasNames([string]$luaFile) {
  if (-not (Test-Path -LiteralPath $luaFile)) { return @() }
  $names = @()
  foreach ($m in [regex]::Matches([IO.File]::ReadAllText($luaFile), '(?m)^\s*\["([^"]+)"\]\s*=')) { $names += $m.Groups[1].Value }
  return $names
}

# @{ key = row } (Find-AtlasRows, each row with .file set or '') -> atlases.lua text.
function Format-AtlasesLua([hashtable]$rows) {
  $o = New-Object System.Collections.Generic.List[string]
  $o.Add('-- Generated by dev.ps1 render -Fetch (dev/render/fetch.ps1); do not edit.')
  $o.Add('-- Atlas name (lower case) -> sheet and texture coordinates, from the')
  $o.Add('-- UiTextureAtlasMember and UiTextureAtlas tables (wago.tools DB2 CSV exports).')
  $o.Add('-- file: the sheet''s client path (nil when the file has no known name);')
  $o.Add('-- fileID: its file ID; w, h: the atlas size; l, r, t, b: texture coordinates;')
  $o.Add('-- tileH, tileV: the atlas tiles across or down instead of stretching.')
  $o.Add('return {')
  foreach ($key in ($rows.Keys | Sort-Object)) {
    $a = $rows[$key]
    $parts = @()
    if ($a.file) { $parts += 'file = ' + (Format-LuaStr (ConvertTo-TexClientPath $a.file)) }
    $parts += "fileID = $($a.fileID)", "w = $($a.w)", "h = $($a.h)"
    foreach ($k in 'l', 'r', 't', 'b') { $parts += "$k = " + (Format-LuaNum $a[$k]) }
    if ($a.tileH) { $parts += 'tileH = true' }
    if ($a.tileV) { $parts += 'tileV = true' }
    $o.Add('  [' + (Format-LuaStr $key) + '] = { ' + ($parts -join ', ') + ' },')
  }
  $o.Add('}')
  return (($o -join "`n") + "`n")
}

# File IDs already in fileids.lua.
function Read-FileIdKeys([string]$luaFile) {
  $ids = @{}
  if (Test-Path -LiteralPath $luaFile) {
    foreach ($m in [regex]::Matches([IO.File]::ReadAllText($luaFile), '\[(\d+)\]\s*=')) { $ids[[int]$m.Groups[1].Value] = $true }
  }
  return $ids
}

# Inserts "[id] = "path"," lines before the closing brace of fileids.lua;
# returns how many it added.
function Add-FileIdsLua([string]$luaFile, [hashtable]$add) {
  if ($add.Count -eq 0) { return 0 }
  $text = if (Test-Path -LiteralPath $luaFile) { [IO.File]::ReadAllText($luaFile) } else { "return {`n}`n" }
  $have = Read-FileIdKeys $luaFile
  $lines = @()
  foreach ($id in ($add.Keys | Sort-Object)) {
    if ($have.ContainsKey([int]$id)) { continue }
    $lines += "  [$id] = " + (Format-LuaStr (ConvertTo-TexClientPath $add[$id])) + ','
  }
  if ($lines.Count -eq 0) { return 0 }
  $at = $text.LastIndexOf('}')
  if ($at -lt 0) { throw "$luaFile has no closing brace" }
  $text = $text.Substring(0, $at) + ($lines -join "`n") + "  -- added by render -Fetch`n" + $text.Substring($at)
  [IO.File]::WriteAllText($luaFile, $text)
  return $lines.Count
}

# ---------------------------------------------------------------------------

# Missing-list lines -> @{ atlases = @(names); fileIds = @(ids); paths = @(rels) }.
function Read-MissingList([string]$listFile) {
  $r = @{ atlases = @(); fileIds = @(); paths = @() }
  foreach ($line in [IO.File]::ReadAllLines($listFile)) {
    if (-not $line.Trim()) { continue }
    $f = $line -split "`t"
    $rel = $f[0]
    $orig = if ($f.Count -gt 1) { $f[1] } else { '' }
    if ($rel -like 'atlas/*') {
      $name = if ($orig -like 'atlas:*') { $orig.Substring(6) } else { $rel.Substring(6) }
      $r.atlases += $name
    } elseif ($rel -match '^fileid/(\d+)$') { $r.fileIds += [int]$Matches[1] }
    else { $r.paths += $rel }
  }
  return $r
}

# The whole fetch. $renderDir holds atlases.lua and fileids.lua.
function Fetch-Textures([string]$listFile, [string]$texDir, [string]$renderDir) {
  if (-not (Test-Path -LiteralPath $listFile)) { TexSay "fetch: $listFile not found"; return 1 }
  $cacheDir = Join-Path $texDir '.cache'
  New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
  $miss = Read-MissingList $listFile
  $queue = [ordered]@{}        # rel -> file ID (0: unknown)
  $sheets = @{}               # rels that back an atlas: wago.tools first
  $notMirrored = [ordered]@{}  # rel -> reason
  $notFetched = [ordered]@{}   # rel -> reason

  # Atlases: regenerate atlases.lua with every atlas it had plus the new ones.
  if ($miss.atlases.Count -gt 0) {
    $atlasLua = Join-Path $renderDir 'atlases.lua'
    try {
      $member = Get-WagoCsv 'UiTextureAtlasMember' $cacheDir
      $sheet = Get-WagoCsv 'UiTextureAtlas' $cacheDir
      $names = @(Read-AtlasNames $atlasLua) + $miss.atlases
      $rows = Find-AtlasRows $names $member $sheet
      foreach ($key in @($rows.Keys)) {
        $a = $rows[$key]
        $a.file = Resolve-FileId $a.fileID $cacheDir
        $rel = if ($a.file) { $a.file } else { "fileid/$($a.fileID)" }
        if (-not $queue.Contains($rel)) { $queue[$rel] = $a.fileID }
        $sheets[$rel] = $true
      }
      [IO.File]::WriteAllText($atlasLua, (Format-AtlasesLua $rows))
      TexSay "fetch: wrote $($rows.Count) atlases to dev/render/atlases.lua"
      foreach ($n in $miss.atlases) {
        if (-not $rows.ContainsKey($n.ToLowerInvariant())) { $notMirrored["atlas/$($n.ToLowerInvariant())"] = 'not in UiTextureAtlasMember' }
      }
    } catch { foreach ($n in $miss.atlases) { $notFetched["atlas/$($n.ToLowerInvariant())"] = "atlas tables: $($_.Exception.Message)" } }
  }

  # File IDs: name them in fileids.lua.
  $named = @{}
  foreach ($id in $miss.fileIds) {
    try {
      $rel = Resolve-FileId $id $cacheDir
      if ($rel) { $named[$id] = $rel; $queue[$rel] = $id } else { $queue["fileid/$id"] = $id }
    } catch { $notFetched["fileid/$id"] = "file search: $($_.Exception.Message)" }
  }
  $added = Add-FileIdsLua (Join-Path $renderDir 'fileids.lua') $named
  if ($added -gt 0) { TexSay "fetch: named $added file IDs in dev/render/fileids.lua" }

  # Sheets of atlases mapped earlier: a missing sheet shows up as a path line.
  $atlasLua = Join-Path $renderDir 'atlases.lua'
  if (Test-Path -LiteralPath $atlasLua) {
    foreach ($m in [regex]::Matches([IO.File]::ReadAllText($atlasLua), 'file = "([^"]+)", fileID = (\d+)')) {
      $rel = ConvertTo-TexRel ($m.Groups[1].Value.Replace('\\', '\'))
      $sheets[$rel] = $true
      if (-not $queue.Contains($rel) -and $miss.paths -contains $rel) { $queue[$rel] = [int]$m.Groups[2].Value }
    }
  }
  foreach ($rel in $miss.paths) { if (-not $queue.Contains($rel)) { $queue[$rel] = 0 } }

  $got = 0
  foreach ($rel in @($queue.Keys)) {
    $dest = Join-Path $texDir (($rel -replace '/', '\') + '.png')
    if (Test-Path -LiteralPath $dest) { continue }
    $fdid = [int]$queue[$rel]
    try {
      # An atlas sheet comes from wago.tools first: its coordinates are from the
      # current build, and the 2022 PNG may have a different layout.
      if ($sheets.ContainsKey($rel) -and $fdid) {
        try {
          Get-WagoPng $fdid $dest $cacheDir
          TexSay "  got $rel (wago.tools file $fdid, atlas sheet)"
          $got++
          continue
        } catch { TexSay "  wago.tools file $fdid failed ($($_.Exception.Message)); trying $TexRepo" }
      }
      $exact = if ($rel -like 'interface/*') { Find-TexPath $rel $cacheDir } else { $null }
      if ($exact) {
        $url = "https://raw.githubusercontent.com/$TexRepo/$TexBranch/" + (($exact -split '/' | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/')
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        TexDownload $url $dest
        TexSay "  got $exact ($TexRepo)"
        $got++
        continue
      }
      if (-not $fdid -and $rel -like 'interface/*') { $fdid = Resolve-TexRel $rel $cacheDir }
      if (-not $fdid) { $notMirrored[$rel] = "not in $TexRepo, and wago.tools lists no such file"; continue }
      Get-WagoPng $fdid $dest $cacheDir
      TexSay "  got $rel (wago.tools file $fdid)"
      $got++
    } catch {
      $msg = $_.Exception.Message
      if ($msg -match '\(404\)|not a BLP2') { $notMirrored[$rel] = $msg } else { $notFetched[$rel] = $msg }
    }
  }

  # unavailable.txt: what render.lua labels "not mirrored". Rewritten each run.
  $un = @()
  foreach ($k in $notMirrored.Keys) { $un += "$k`t$($notMirrored[$k])" }
  [IO.File]::WriteAllText((Join-Path $texDir 'unavailable.txt'), ($un -join "`n") + $(if ($un.Count) { "`n" } else { '' }))

  TexSay "fetch: downloaded $got textures to dev/render/textures"
  foreach ($k in $notMirrored.Keys) { TexSay "  not mirrored: $k ($($notMirrored[$k]))" }
  foreach ($k in $notFetched.Keys) { TexSay "  not fetched: $k ($($notFetched[$k]))" }
  return 0
}
