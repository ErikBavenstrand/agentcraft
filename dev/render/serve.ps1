# Serves dev/render (pages in out/, textures in textures/) on http://127.0.0.1:<Port>/ so the rendered pages
# can be opened in a browser (file:// is blocked in some viewers).
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File dev/render/serve.ps1 [-Port 8765]
param([int]$Port = 8765)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$types = @{ '.html' = 'text/html; charset=utf-8'; '.css' = 'text/css'; '.js' = 'application/javascript'
  '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.txt' = 'text/plain; charset=utf-8'; '.json' = 'application/json' }
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
Write-Host "Serving $root on http://127.0.0.1:$Port/ (Ctrl+C to stop)"
try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ($rel -eq '') { $ctx.Response.Redirect('/out/index.html'); $ctx.Response.Close(); continue }
    $path = [IO.Path]::GetFullPath((Join-Path $root $rel))
    $base = (Join-Path $PSScriptRoot '')
    # Only files under dev/render are served.
    if (-not $path.StartsWith([IO.Path]::GetFullPath($base), [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path $path -PathType Leaf)) {
      $ctx.Response.StatusCode = 404
    } else {
      $bytes = [IO.File]::ReadAllBytes($path)
      $ext = [IO.Path]::GetExtension($path).ToLower()
      $ctx.Response.ContentType = $(if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' })
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    }
    $ctx.Response.Close()
  }
} finally { $listener.Stop() }
