# Builds dist\r36s-music-player.zip ready to extract into the SD card's "ports" folder:
#   R36S Music Player.sh
#   r36smusic\game\...        (the LÖVE project)
# Zip entries use "/" separators (Compress-Archive on Windows PowerShell 5.1 does not).
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$dist = Join-Path $root "dist"
$zipPath = Join-Path $dist "r36s-music-player.zip"
New-Item -ItemType Directory -Force $dist | Out-Null
if (Test-Path $zipPath) { Remove-Item $zipPath }

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")
try {
  function Add-File($full, $entryName) {
    $entry = $zip.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $in = [System.IO.File]::OpenRead($full)
    $out = $entry.Open()
    try { $in.CopyTo($out) } finally { $out.Dispose(); $in.Dispose() }
  }

  # Launcher: force LF line endings so bash is happy.
  $sh = Join-Path $root "portmaster\R36S Music Player.sh"
  $tmp = [System.IO.Path]::GetTempFileName()
  $text = [System.IO.File]::ReadAllText($sh) -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($tmp, $text, (New-Object System.Text.UTF8Encoding($false)))
  Add-File $tmp "R36S Music Player.sh"
  # GPTK fallback: force LF line endings.
  $gptk = Join-Path $root "portmaster\r36smusic.gptk"
  if (Test-Path $gptk) {
    $tmp2 = [System.IO.Path]::GetTempFileName()
    $text2 = [System.IO.File]::ReadAllText($gptk) -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($tmp2, $text2, (New-Object System.Text.UTF8Encoding($false)))
    Add-File $tmp2 "r36smusic/r36smusic.gptk"
    Remove-Item $tmp2
  }

  $gameDir = (Resolve-Path (Join-Path $root "game")).Path
  Get-ChildItem $gameDir -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($gameDir.Length + 1) -replace "\\", "/"
    Add-File $_.FullName ("r36smusic/game/" + $rel)
  }
} finally {
  $zip.Dispose()
}
Write-Host "Created $zipPath"
