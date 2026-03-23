param([int]$Port = 0)
if ($Port -eq 0) { $Port = if ($env:PORT) { [int]$env:PORT } else { 3000 } }
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/"
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response
  $path = $req.Url.LocalPath -replace '^/', ''
  if ($path -eq '') { $path = 'index.html' }
  $file = Join-Path $root $path
  if (Test-Path $file -PathType Leaf) {
    $mime = switch ([System.IO.Path]::GetExtension($file)) {
      '.html' { 'text/html; charset=utf-8' }
      '.css'  { 'text/css' }
      '.js'   { 'application/javascript' }
      '.json' { 'application/json' }
      '.png'  { 'image/png' }
      '.jpg'  { 'image/jpeg' }
      '.svg'  { 'image/svg+xml' }
      default { 'application/octet-stream' }
    }
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $res.ContentType = $mime
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $res.StatusCode = 404
  }
  $res.Close()
}
