# Verifies and automatically installs PortMaster and the LOVE 11.5 runtime on the SD card if missing.
# Usage: powershell -ExecutionPolicy Bypass -File tools\setup_dependencies.ps1 -Drive E:
param(
  [string]$Drive = "E:"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Drive)) {
  throw "Unidade '$Drive' nao encontrada. Conecte o cartao SD no computador."
}

Write-Host "=== Verificacao de Dependencias: PortMaster & LOVE 11.5 ===" -ForegroundColor Cyan
Write-Host "Analisando cartao SD na unidade $Drive\..."

# Possible locations where PortMaster can live on the SD card
$pmCandidates = @(
  (Join-Path $Drive "tools\PortMaster"),
  (Join-Path $Drive "ports\PortMaster")
)

$hasPortMaster = $false
$foundPmPath = $null
foreach ($p in $pmCandidates) {
  if (Test-Path (Join-Path $p "control.txt")) {
    $hasPortMaster = $true
    $foundPmPath = $p
    break
  }
}

# Check if love_11.5 runtime exists in PortMaster or in local port fallback
$hasLoveRuntime = $false
if ($hasPortMaster) {
  if ((Test-Path (Join-Path $foundPmPath "runtimes\love_11.5\love.txt")) -or
      (Test-Path (Join-Path $foundPmPath "runtimes\love_11.5.txt")) -or
      (Test-Path (Join-Path $foundPmPath "libs\love_11.5.squashfs"))) {
    $hasLoveRuntime = $true
  }
}

$localLoveFallback = Join-Path $Drive "ports\r36smusic\runtimes\love_11.5\love.txt"
if (Test-Path $localLoveFallback) {
  $hasLoveRuntime = $true
}

if ($hasPortMaster -and $hasLoveRuntime) {
  Write-Host "[OK] PortMaster e runtime LOVE 11.5 encontrados no cartao SD!" -ForegroundColor Green
  Write-Host "     PortMaster: $foundPmPath"
  return
}

# Something is missing - auto download and install!
Write-Host ""
if (-not $hasPortMaster) {
  Write-Host "[-] PortMaster NAO encontrado no cartao SD." -ForegroundColor Yellow
}
if (-not $hasLoveRuntime) {
  Write-Host "[-] Runtime LOVE 11.5 NAO encontrado." -ForegroundColor Yellow
}

Write-Host "[+] Baixando pacote oficial PortMaster (com LOVE 11.5 incluso, ~23 MB)..." -ForegroundColor Cyan
$pmZipUrl = "https://github.com/PortsMaster/PortMaster-GUI/releases/latest/download/PortMaster.zip"
$tmpZip = Join-Path $env:TEMP "PortMaster_install.zip"
$tmpExtract = Join-Path $env:TEMP "PortMaster_extracted"

try {
  if (Test-Path $tmpZip) { Remove-Item $tmpZip -Force }
  if (Test-Path $tmpExtract) { Remove-Item $tmpExtract -Recurse -Force }

  # Download PortMaster.zip
  $webClient = New-Object System.Net.WebClient
  $webClient.Headers.Add("User-Agent", "PowerShell-R36S-Setup")
  $webClient.DownloadFile($pmZipUrl, $tmpZip)
  Write-Host "[+] Download concluido com sucesso!" -ForegroundColor Green

  Write-Host "[+] Extraindo PortMaster e LOVE 11.5..." -ForegroundColor Cyan
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZip, $tmpExtract)

  $extractedPm = Join-Path $tmpExtract "PortMaster"
  if (-not (Test-Path $extractedPm)) {
    $extractedPm = $tmpExtract
  }

  # Ensure target directories exist on SD card
  $targetToolsPm = Join-Path $Drive "tools\PortMaster"
  $targetPortsPm = Join-Path $Drive "ports\PortMaster"
  $targetPortsMusic = Join-Path $Drive "ports\r36smusic\runtimes\love_11.5"

  New-Item -ItemType Directory -Force -Path (Join-Path $Drive "tools") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $Drive "ports") | Out-Null

  # Copy to tools\PortMaster
  Write-Host "[+] Instalando em $targetToolsPm..."
  Copy-Item -Path $extractedPm -Destination (Join-Path $Drive "tools") -Recurse -Force

  # Copy to ports\PortMaster
  Write-Host "[+] Instalando em $targetPortsPm..."
  Copy-Item -Path $extractedPm -Destination (Join-Path $Drive "ports") -Recurse -Force

  # Copy PortMaster.sh launcher if present
  $pmSh = Join-Path $extractedPm "PortMaster.sh"
  if (Test-Path $pmSh) {
    Copy-Item $pmSh -Destination (Join-Path $Drive "ports\PortMaster.sh") -Force
    Copy-Item $pmSh -Destination (Join-Path $Drive "tools\PortMaster.sh") -Force
  }

  # Also place a standalone copy of love_11.5 inside r36smusic as safe fallback
  $extractedLove = Join-Path $extractedPm "runtimes\love_11.5"
  if (Test-Path $extractedLove) {
    Write-Host "[+] Criando copia de contingencia do LOVE 11.5 em $targetPortsMusic..."
    New-Item -ItemType Directory -Force -Path (Split-Path $targetPortsMusic -Parent) | Out-Null
    Copy-Item -Path $extractedLove -Destination (Split-Path $targetPortsMusic -Parent) -Recurse -Force
  }

  Write-Host "[OK] PortMaster e LOVE 11.5 instalados com sucesso no cartao SD!" -ForegroundColor Green
  Write-Host ""
} finally {
  if (Test-Path $tmpZip) { Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue }
  if (Test-Path $tmpExtract) { Remove-Item $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue }
}
