# Runs the app on Windows in self-test mode (plays a track, saves screenshots, quits).
# Usage: powershell -File tools\selftest.ps1 -Love <path-to-lovec.exe> -Music <folder-with-mp3>
param(
  [Parameter(Mandatory = $true)][string]$Love,
  [Parameter(Mandatory = $true)][string]$Music,
  [int]$TimeoutSec = 20
)

$game = Join-Path $PSScriptRoot "..\game" | Resolve-Path
$env:R36S_AUTOTEST = "1"
$env:R36S_MUSIC_DIR = $Music
$out = Join-Path $env:TEMP "r36s-selftest-out.txt"
$err = Join-Path $env:TEMP "r36s-selftest-err.txt"

$p = Start-Process $Love -ArgumentList "`"$game`"" -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
if (-not $p.WaitForExit($TimeoutSec * 1000)) {
  Write-Host "TIMEOUT - killing"
  $p.Kill()
}
Write-Host "--- stdout"; Get-Content $out
Write-Host "--- stderr"; Get-Content $err
Write-Host "Screenshots: $env:APPDATA\LOVE\r36s-music-player"
