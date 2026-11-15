# Offline unit tests for fetch.ps1: parsing, path normalisation, the BLP
# decoder, the generated Lua and the cache logic, against hand-made samples.
# No network: TexDownload is replaced by a fake that serves the samples.
#   powershell -NoProfile -ExecutionPolicy Bypass -File dev/render/fetch-test.ps1
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'fetch.ps1')

$script:fails = 0
$script:count = 0
function Eq($got, $want, [string]$what) {
  $script:count++
  if ("$got" -ne "$want") { $script:fails++; [Console]::Out.WriteLine("FAIL $what`n  got:  $got`n  want: $want") }
}
function Near([double]$got, [double]$want, [string]$what) {
  $script:count++
  if ([Math]::Abs($got - $want) -gt 1e-9) { $script:fails++; [Console]::Out.WriteLine("FAIL $what`n  got:  $got`n  want: $want") }
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("ac-fetch-test-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
  # --- paths ---------------------------------------------------------------
  Eq (ConvertTo-TexRel 'Interface\Icons\INV_Misc_Gear_01.blp') 'interface/icons/inv_misc_gear_01' 'rel from client path'
  Eq (ConvertTo-TexRel 'interface/common/minimalcheckbox.BLP') 'interface/common/minimalcheckbox' 'rel strips extension in any case'
  Eq (ConvertTo-TexClientPath 'interface/common/help-i') 'interface\common\help-i' 'client path'

  # --- CSV and atlas rows ----------------------------------------------------
  Eq ((Split-CsvLine 'a,"b,c",d') -join '|') 'a|b,c|d' 'quoted CSV field'
  Eq ((Split-CsvLine 'a,"say ""hi""",') -join '|') 'a|say "hi"|' 'escaped quote and empty last field'
  $member = Join-Path $tmp 'UiTextureAtlasMember.csv'
  $sheet = Join-Path $tmp 'UiTextureAtlas.csv'
  [IO.File]::WriteAllText($member, @"
CommittedName,ID,UiTextureAtlasID,Width,Height,CommittedLeft,CommittedRight,CommittedTop,CommittedBottom,UiTextureAtlasElementID,OverrideWidth,OverrideHeight,CommittedFlags,UiCanvasID
checkbox-minimal,14713,1983,30,29,1,31,1,30,18779,0,0,0,0
_Options-Edge,1,7,64,8,0,64,8,16,1,0,0,4,0
!Options-Side,2,7,8,64,0,8,0,64,1,0,0,2,0
Big-Thing,3,7,10,10,0,10,0,10,1,40,20,0,0
orphan,4,999,10,10,0,10,0,10,1,0,0,0,0
"@)
  [IO.File]::WriteAllText($sheet, @"
ID,FileDataID,UiTextureAtlasSetID,AtlasWidth,AtlasHeight,UiCanvasID
1983,4614134,0,64,64,1
7,555,0,64,32,1
"@)
  $rows = Find-AtlasRows @('Checkbox-Minimal', '_options-edge', '!Options-Side', 'Big-Thing', 'orphan', 'nope') $member $sheet
  Eq $rows.Count 4 'atlas rows found (orphan sheet and unknown name left out)'
  $c = $rows['checkbox-minimal']
  Eq $c.fileID 4614134 'atlas sheet file ID'
  Eq "$($c.w)x$($c.h)" '30x29' 'atlas size'
  Near $c.l (1 / 64) 'atlas l'; Near $c.r (31 / 64) 'atlas r'; Near $c.t (1 / 64) 'atlas t'; Near $c.b (30 / 64) 'atlas b'
  Eq $c.name 'checkbox-minimal' 'atlas name kept'
  Eq "$($rows['_options-edge'].tileH)/$($rows['_options-edge'].tileV)" 'True/False' 'flag 4 tiles horizontally'
  Eq "$($rows['!options-side'].tileH)/$($rows['!options-side'].tileV)" 'False/True' 'flag 2 tiles vertically'
  Near $rows['_options-edge'].t 0.25 'atlas t on a non-square sheet'
  Eq "$($rows['big-thing'].w)x$($rows['big-thing'].h)" '40x20' 'override size wins'

  # --- generated atlases.lua ---------------------------------------------------
  $c.file = 'interface/common/minimalcheckbox'
  $rows['_options-edge'].file = ''
  $rows['!options-side'].file = 'interface/x/side'
  $rows['big-thing'].file = 'interface/x/big'
  $lua = Format-AtlasesLua $rows
  $luaFile = Join-Path $tmp 'atlases.lua'
  [IO.File]::WriteAllText($luaFile, $lua)
  Eq ((Read-AtlasNames $luaFile | Sort-Object) -join ',') '!options-side,_options-edge,big-thing,checkbox-minimal' 'atlas names read back'
  Eq ($lua -match [regex]::Escape('["checkbox-minimal"] = { file = "interface\\common\\minimalcheckbox", fileID = 4614134, w = 30, h = 29, l = 0.015625, r = 0.484375, t = 0.015625, b = 0.46875 },')) $true 'atlas line'
  Eq ($lua -match [regex]::Escape('["_options-edge"] = { fileID = 555,')) $true 'unnamed sheet has no file field'
  Eq ($lua -match 'tileH = true') $true 'tileH written'
  Eq (Read-AtlasNames (Join-Path $tmp 'none.lua')).Count 0 'no atlases.lua yet'

  # --- fileids.lua -------------------------------------------------------------
  $fid = Join-Path $tmp 'fileids.lua'
  [IO.File]::WriteAllText($fid, "-- header`nreturn {`n  [134400] = `"Interface\\Icons\\INV_Misc_QuestionMark`",  -- note`n}`n")
  $null = Add-FileIdsLua $fid @{ 134400 = 'interface/icons/other'; 132278 = 'interface/icons/ability_druid_rake' }
  $text = [IO.File]::ReadAllText($fid)
  Eq ($text -match [regex]::Escape('[132278] = "interface\\icons\\ability_druid_rake",')) $true 'file ID added'
  Eq ([regex]::Matches($text, '\[134400\]').Count) 1 'existing file ID kept, not duplicated'
  Eq ($text.TrimEnd().EndsWith('}')) $true 'closing brace kept'
  $keys = Read-FileIdKeys $fid
  Eq $keys.Count 2 'file IDs read back'

  # --- missing list ------------------------------------------------------------
  $list = Join-Path $tmp 'missing.txt'
  [IO.File]::WriteAllText($list, "atlas/options_list_active`tatlas:Options_List_Active`nfileid/132270`tfileID:132270`ninterface/common/help-i`tInterface\common\help-i`n`n")
  $m = Read-MissingList $list
  Eq ($m.atlases -join ',') 'Options_List_Active' 'atlas name with its case'
  Eq ($m.fileIds -join ',') '132270' 'file ID'
  Eq ($m.paths -join ',') 'interface/common/help-i' 'path'

  # --- wago.tools files page -----------------------------------------------------
  $json = '{"component":"Files","props":{"files":{"data":[{"fdid":616343,"filename":"interface\/common\/help-i.blp"},{"fdid":6163430,"filename":"x.ogg"}]}}}'
  $html = '<div id="app" data-page="' + [System.Net.WebUtility]::HtmlEncode($json) + '"></div>'
  $e = Read-WagoFilesPage $html
  Eq $e.Count 2 'files page entries'
  Eq "$($e[0].fdid) $($e[0].filename)" '616343 interface/common/help-i.blp' 'files page entry'

  # --- BLP decoding ------------------------------------------------------------
  function New-Blp([int]$comp, [int]$alphaDepth, [int]$alphaType, [int]$w, [int]$h, [byte[]]$data, [byte[]]$palette) {
    $hdr = New-Object byte[] 1172
    [Text.Encoding]::ASCII.GetBytes('BLP2').CopyTo($hdr, 0)
    $hdr[4] = 1; $hdr[8] = $comp; $hdr[9] = $alphaDepth; $hdr[10] = $alphaType
    [BitConverter]::GetBytes($w).CopyTo($hdr, 12); [BitConverter]::GetBytes($h).CopyTo($hdr, 16)
    [BitConverter]::GetBytes(1172).CopyTo($hdr, 20); [BitConverter]::GetBytes($data.Length).CopyTo($hdr, 84)
    if ($palette) { $palette.CopyTo($hdr, 148) }
    return [byte[]]($hdr + $data)
  }
  $w = 0; $h = 0
  # Uncompressed BGRA 2x1: blue, half-transparent red.
  $px = [AcBlp]::Decode((New-Blp 3 8 0 2 1 ([byte[]](255, 0, 0, 255, 0, 0, 255, 128)) $null), [ref]$w, [ref]$h)
  Eq "$w x $h" '2 x 1' 'BGRA size'
  Eq ($px -join ',') '255,0,0,255,0,0,255,128' 'BGRA pixels'
  # Palettized 2x1 with 1-bit alpha: palette 0 green, 1 white; alpha bits 0b01.
  $pal = New-Object byte[] 1024
  $pal[1] = 255; $pal[4] = 255; $pal[5] = 255; $pal[6] = 255
  $px = [AcBlp]::Decode((New-Blp 1 1 0 2 1 ([byte[]](0, 1, 1)) $pal), [ref]$w, [ref]$h)
  Eq ($px -join ',') '0,255,0,255,255,255,255,0' 'palettized pixels with 1-bit alpha'
  # DXT1 4x4: c0 = white, c1 = black, all indices 1 (c1) except pixel 0 (c0).
  $blk = [byte[]](0xFF, 0xFF, 0x00, 0x00, 0x54, 0x55, 0x55, 0x55)
  $px = [AcBlp]::Decode((New-Blp 2 0 0 4 4 $blk $null), [ref]$w, [ref]$h)
  Eq (($px[0..3]) -join ',') '255,255,255,255' 'DXT1 pixel 0 is c0'
  Eq (($px[4..7]) -join ',') '0,0,0,255' 'DXT1 pixel 1 is c1'
  # DXT1 3-colour mode with 1-bit alpha: c0 < c1, index 3 is transparent.
  $blk = [byte[]](0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF)
  $px = [AcBlp]::Decode((New-Blp 2 1 0 4 4 $blk $null), [ref]$w, [ref]$h)
  Eq $px[3] 0 'DXT1 punch-through alpha'
  # DXT5 2x2 (a partial block): alpha endpoints 255/0, every index 1 -> alpha 0.
  $blk = [byte[]](255, 0, 0x49, 0x92, 0x24, 0x49, 0x92, 0x24, 0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0)
  $px = [AcBlp]::Decode((New-Blp 2 8 7 2 2 $blk $null), [ref]$w, [ref]$h)
  Eq $px.Length 16 'DXT5 partial block size'
  Eq (($px[0..3]) -join ',') '255,255,255,0' 'DXT5 colour and alpha'
  # DXT3: explicit alpha nibbles 0xF and 0x0.
  $blk = [byte[]](0x0F, 0, 0, 0, 0, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0)
  $px = [AcBlp]::Decode((New-Blp 2 8 1 4 4 $blk $null), [ref]$w, [ref]$h)
  Eq "$($px[3]),$($px[7])" '255,0' 'DXT3 alpha'
  $bad = $false
  try { [void][AcBlp]::Decode([byte[]](1, 2, 3), [ref]$w, [ref]$h) } catch { $bad = $true }
  Eq $bad $true 'not a BLP raises'
  # PNG round trip.
  $blpFile = Join-Path $tmp 'a.blp'; $pngFile = Join-Path $tmp 'a.png'
  [IO.File]::WriteAllBytes($blpFile, (New-Blp 3 8 0 2 1 ([byte[]](255, 0, 0, 255, 0, 0, 255, 128)) $null))
  [AcBlp]::BlpToPng($blpFile, $pngFile)
  Add-Type -AssemblyName System.Drawing
  $bmp = New-Object System.Drawing.Bitmap $pngFile
  Eq "$($bmp.Width)x$($bmp.Height) $($bmp.GetPixel(1, 0).R),$($bmp.GetPixel(1, 0).A)" '2x1 255,128' 'PNG written'
  $bmp.Dispose()

  # --- whole fetch against a fake network -----------------------------------------
  $tex = Join-Path $tmp 'textures'; $cache = Join-Path $tex '.cache'
  New-Item -ItemType Directory -Force -Path $cache | Out-Null
  $render = Join-Path $tmp 'render'
  New-Item -ItemType Directory -Force -Path $render | Out-Null
  [IO.File]::WriteAllText((Join-Path $render 'fileids.lua'), "return {`n}`n")
  # A Gethe tree (the repo root is Interface) with Common/Help-I.PNG.
  [IO.File]::WriteAllText((Join-Path $cache "tree-$TexBranch.json"), '{"tree":[{"path":"Common","type":"tree","sha":"s2"}]}')
  [IO.File]::WriteAllText((Join-Path $cache 'tree-s2.json'), '{"tree":[{"path":"Help-I.PNG","type":"blob","sha":"b"}]}')
  Copy-Item $member (Join-Path $cache 'UiTextureAtlasMember.csv')
  Copy-Item $sheet (Join-Path $cache 'UiTextureAtlas.csv')
  $blpBytes = New-Blp 3 8 0 2 1 ([byte[]](255, 0, 0, 255, 0, 0, 255, 128)) $null
  $script:urls = @()
  function TexDownload([string]$url, [string]$dest) {
    $script:urls += $url
    $page = { param($j) '<div data-page="' + [System.Net.WebUtility]::HtmlEncode($j) + '"></div>' }
    if ($url -like '*raw.githubusercontent.com*') { [IO.File]::WriteAllBytes($dest, [byte[]](137, 80, 78, 71)); return }
    if ($url -like '*/api/casc/4614134') { [IO.File]::WriteAllBytes($dest, $blpBytes); return }
    if ($url -like '*/api/casc/132270') { [IO.File]::WriteAllBytes($dest, $blpBytes); return }
    if ($url -like '*/api/casc/*') { throw 'The remote server returned an error: (404) Not Found.' }
    if ($url -like '*files?search=4614134') { return (& $page '{"props":{"files":{"data":[{"fdid":4614134,"filename":"interface/common/minimalcheckbox.blp"}]}}}') }
    if ($url -like '*files?search=132270') { return (& $page '{"props":{"files":{"data":[{"fdid":132270,"filename":"interface/icons/ability_physical_taunt.blp"},{"fdid":1322700,"filename":"x.blp"}]}}}') }
    if ($url -like '*files?search=*') { return (& $page '{"props":{"files":{"data":[]}}}') }
    throw "unexpected URL $url"
  }
  [IO.File]::WriteAllText($list, "atlas/checkbox-minimal`tatlas:checkbox-minimal`natlas/nope`tatlas:Nope`nfileid/132270`tfileID:132270`ninterface/common/help-i`tInterface\common\help-i`ninterface/framegeneral/ui-background-marble`tInterface\FrameGeneral\UI-Background-Marble`n")
  $script:TexFiles = $null; $script:TexTrees = $null
  $out = Fetch-Textures $list $tex $render
  Eq $out 0 'fetch returns 0'
  Eq (Test-Path (Join-Path $tex 'interface\common\minimalcheckbox.png')) $true 'atlas sheet converted from wago.tools'
  Eq (Test-Path (Join-Path $tex 'interface\icons\ability_physical_taunt.png')) $true 'file ID texture saved at its path'
  Eq (Test-Path (Join-Path $tex 'interface\common\help-i.png')) $true 'Gethe texture downloaded'
  Eq (($script:urls | Where-Object { $_ -like '*raw.githubusercontent.com*' }) -join ',') "https://raw.githubusercontent.com/$TexRepo/$TexBranch/Common/Help-I.PNG" 'Gethe URL uses the exact case'
  $alua = [IO.File]::ReadAllText((Join-Path $render 'atlases.lua'))
  Eq ($alua -match [regex]::Escape('["checkbox-minimal"] = { file = "interface\\common\\minimalcheckbox", fileID = 4614134')) $true 'atlases.lua generated'
  Eq ([IO.File]::ReadAllText((Join-Path $render 'fileids.lua')) -match [regex]::Escape('[132270] = "interface\\icons\\ability_physical_taunt"')) $true 'fileids.lua extended'
  $un = [IO.File]::ReadAllText((Join-Path $tex 'unavailable.txt'))
  Eq ($un -match 'atlas/nope') $true 'unknown atlas is not mirrored'
  Eq ($un -match 'interface/framegeneral/ui-background-marble') $true 'file nobody has is not mirrored'
  Eq ((Get-Content (Join-Path $cache 'files.tsv')) -join '|') ("4614134`tinterface/common/minimalcheckbox|132270`tinterface/icons/ability_physical_taunt|0`tinterface/framegeneral/ui-background-marble") 'files.tsv cache'
  Eq (Test-Path (Join-Path $cache '4614134.blp')) $false 'BLP temp removed'

  # A second run with the same list is served from the caches.
  $script:urls = @(); $script:TexFiles = $null; $script:TexTrees = $null
  $null = Fetch-Textures $list $tex $render
  Eq $script:urls.Count 0 'second run: no downloads'
  Eq ((Read-AtlasNames (Join-Path $render 'atlases.lua')) -join ',') 'checkbox-minimal' 'atlases kept across runs'

  # A mapped atlas whose sheet PNG is gone comes back as a path line; the sheet
  # still comes from wago.tools by its file ID, not from the 2022 mirror.
  Remove-Item (Join-Path $tex 'interface\common\minimalcheckbox.png')
  [IO.File]::WriteAllText($list, "interface/common/minimalcheckbox`tatlas:checkbox-minimal`n")
  $script:urls = @(); $script:TexFiles = $null; $script:TexTrees = $null
  $null = Fetch-Textures $list $tex $render
  Eq ($script:urls -join ',') 'https://wago.tools/api/casc/4614134' 'missing atlas sheet fetched by file ID'
  Eq (Test-Path (Join-Path $tex 'interface\common\minimalcheckbox.png')) $true 'atlas sheet back'
} finally {
  Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
}

[Console]::Out.WriteLine("fetch-test: $($script:count - $script:fails)/$($script:count) passed")
if ($script:fails) { exit 1 } else { exit 0 }
