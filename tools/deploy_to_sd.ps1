# Deploys R36S Media Hub to SD card with automatic dependency verification (PortMaster + LOVE 11.5).
# Usage: powershell -ExecutionPolicy Bypass -File tools\deploy_to_sd.ps1 -Drive E:
param(
  [string]$Drive = "E:"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Drive)) {
  throw "Unidade '$Drive' nao encontrada. Verifique se o cartao SD esta conectado no computador como $Drive"
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$zip = Join-Path $root "dist\r36s-music-player.zip"
$dest = Join-Path $Drive "ports"

# Step 1: Run dependency check and auto-install PortMaster & LOVE 11.5 if missing
$setupScript = Join-Path $PSScriptRoot "setup_dependencies.ps1"
if (Test-Path $setupScript) {
  & $setupScript -Drive $Drive
}

# Step 2: Ensure package is fresh and up-to-date
Write-Host "Compilando pacote mais recente do Media Hub..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "package.ps1")

if (-not (Test-Path $dest)) {
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
}

Write-Host "Copiando $zip para $dest..." -ForegroundColor Cyan
Copy-Item $zip -Destination $dest -Force

Write-Host "Extraindo no cartao SD ($dest)..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
try {
  foreach ($entry in $archive.Entries) {
    $targetPath = Join-Path $dest ($entry.FullName -replace "/", "\")
    $targetDir = Split-Path $targetPath -Parent
    if (-not (Test-Path $targetDir)) {
      New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
    if ($entry.Name -ne "") {
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath, $true)
    }
  }
} finally {
  $archive.Dispose()
}

# Ensure media folders exist on the SD card root
$folders = @("music", "photos", "videos", "books")
foreach ($f in $folders) {
  $path = Join-Path $Drive $f
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    Write-Host "Criada pasta de midia: $path"
  }
}

# Create READMEs in media folders if not already present
$readmePhotos = Join-Path $Drive "photos\COLOQUE_FOTOS_AQUI.txt"
if (-not (Test-Path $readmePhotos)) {
  Set-Content -Path $readmePhotos -Value "Coloque suas fotos e imagens nesta pasta.`r`nFormatos suportados: JPG, JPEG, PNG, BMP, WEBP.`r`nVoce tambem pode criar subpastas (ex: Ferias, Familia, Papeis de Parede)." -Encoding UTF8
}

$readmeVideos = Join-Path $Drive "videos\COLOQUE_VIDEOS_AQUI.txt"
if (-not (Test-Path $readmeVideos)) {
  Set-Content -Path $readmeVideos -Value "Coloque seus filmes, series e clipes nesta pasta.`r`nFormatos suportados: MP4, MKV, AVI, MOV, WMV, WEBM.`r`nRecomendacao para o R36S: 480p ou 720p em H.264 (AVC).`r`nPara sair do video no console, pressione B ou SELECT a qualquer momento." -Encoding UTF8
}

$readmeBooks = Join-Path $Drive "books\COLOQUE_LIVROS_AQUI.txt"
Set-Content -Path $readmeBooks -Value "Coloque seus livros, artigos e textos nesta pasta.`r`nFormatos suportados: PDF, EPUB e TXT.`r`nO leitor salva seu progresso e a ultima pagina lida automaticamente." -Encoding UTF8

# Remove old launcher script if present
$oldSh = Join-Path $dest "R36S Music Player.sh"
if (Test-Path $oldSh) {
  Remove-Item $oldSh -Force
  Write-Host "Removido launcher antigo: $oldSh"
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " [OK] Instalacao concluida com sucesso no cartao SD!" -ForegroundColor Green
Write-Host "      - PortMaster e LOVE 11.5 prontos para execucao." -ForegroundColor Green
Write-Host "      - R36S Media Hub instalado em $dest" -ForegroundColor Green
Write-Host "      - Pastas /music, /photos, /videos e /books configuradas." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
