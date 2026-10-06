# Deploys the built package to drive E:\
param(
  [string]$Drive = "E:"
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$zip = Join-Path $root "dist\r36s-music-player.zip"
$dest = Join-Path $Drive "ports"

if (-not (Test-Path $dest)) {
  throw "Folder '$dest' not found. Make sure SD card is connected at $Drive"
}

Write-Host "Copying $zip to $dest..."
Copy-Item $zip -Destination $dest -Force

Write-Host "Extracting into $dest..."
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
    Write-Host "Created folder: $path"
  }
}

# Create READMEs in media folders if not already present
$readmePhotos = Join-Path $Drive "photos\COLOQUE_FOTOS_AQUI.txt"
if (-not (Test-Path $readmePhotos)) {
  Set-Content -Path $readmePhotos -Value "Coloque suas fotos e imagens nesta pasta.`r`nFormatos suportados: JPG, JPEG, PNG, BMP, WEBP.`r`nVoce tambem pode criar subpastas (ex: Ferias, Família, Papéis de Parede)." -Encoding UTF8
}

$readmeVideos = Join-Path $Drive "videos\COLOQUE_VIDEOS_AQUI.txt"
if (-not (Test-Path $readmeVideos)) {
  Set-Content -Path $readmeVideos -Value "Coloque seus filmes, series e clipes nesta pasta.`r`nFormatos suportados: MP4, MKV, AVI, MOV, WMV, WEBM.`r`nPara exibir uma capa de filme personalizada, coloque uma imagem com o mesmo nome do video (ex: Matrix.mp4 e Matrix.jpg) ou uma imagem chamada poster.jpg dentro da subpasta do filme." -Encoding UTF8
}

$readmeBooks = Join-Path $Drive "books\COLOQUE_LIVROS_AQUI.txt"
Set-Content -Path $readmeBooks -Value "Coloque seus livros, artigos e textos nesta pasta.`r`nFormatos suportados: PDF, EPUB e TXT.`r`nO leitor salva seu progresso e a ultima pagina lida automaticamente." -Encoding UTF8

# Remove old launcher script if present
$oldSh = Join-Path $dest "R36S Music Player.sh"
if (Test-Path $oldSh) {
  Remove-Item $oldSh -Force
  Write-Host "Removed old launcher: $oldSh"
}

Write-Host "Deployment completed successfully to $Drive\!"
