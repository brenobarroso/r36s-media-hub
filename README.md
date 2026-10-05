# 🎮 R36S Media Hub

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: R36S / RK3326 / RK3566 / H700](https://img.shields.io/badge/Platform-RK3326%20%7C%20RK3566%20%7C%20H700-orange.svg)](https://github.com)
[![Engine: LÖVE 11.5](https://img.shields.io/badge/Engine-L%C3%96VE%2011.5-pink.svg)](https://love2d.org)
[![PortMaster](https://img.shields.io/badge/Runtime-PortMaster-brightgreen.svg)](https://portmaster.games)

Central Multimídia moderna, fluida e completa desenvolvida sob medida para consoles portáteis **R36S**, **R35S**, **Powkiddy**, **Anbernic** e dispositivos baseados nos chips **Rockchip RK3326**, **RK3566** e **Allwinner H700** rodando **dArkOSRE / ArkOS / AmberELEC / JELOS / ROCKNIX / muOS** via **PortMaster**.

Transforme seu videogame portátil retrô em um reprodutor de músicas com equalizador e visualizador retrô, reprodutor de vídeos com playlists, galeria de fotos em tela cheia e leitor de livros digitais e mangás com salvamento automático de progresso.

---

## 🌟 Funcionalidades Principais

* **🏠 Home Screen Intuitiva:**
  * Navegação suave por cards 2×2 (*Músicas*, *Vídeos*, *Fotos*, *Livros*).
  * Barra superior integrada com relógio em tempo real e leitura de bateria via *sysfs* (porcentagem e indicador de carregamento).
  * **Mini-Player integrado:** exibe a música ativa no rodapé ao navegar pelo menu, com controle rápido de reprodução (`START`).

* **🎵 Músicas, Equalizador & Visualizador Retrô WMP:**
  * Reprodução contínua de arquivos `.mp3`, `.ogg`, `.flac`, `.wav` com navegação estruturada por pastas.
  * Extração nativa de tags ID3v1/ID3v2 e artes de capa integradas ou acompanhantes (`cover.jpg`, `folder.jpg`).
  * **Visualizador Espectral Retrô Estilo Windows Media Player / Winamp:** na ausência de arte de capa, o app exibe 16 barras coloridas de equalizador com marcadores de pico dinâmicos com física de gravidade.
  * **Equalizador de Áudio Integrado (OpenAL EFX):** 6 predefinições sonoras afinadas para fones e alto-falante (*Flat*, *Bass Boost*, *Rock*, *Pop*, *Voz / Acústico*, *Eletrônica*).
  * Modos Aleatório (*Shuffle*), Repetição e controle de volume preciso.

* **🎬 Vídeos, Filmes & Playlists:**
  * Suporte aos principais formatos de vídeo: `.mp4`, `.mkv`, `.avi`, `.mov`, `.wmv`, `.webm`, `.ogv`, `.3gp`.
  * Detecção de cartazes e pôsteres acompanhantes (`filme.jpg` ou `poster.jpg`).
  * **Sistema de Playlists / Fila:** selecione múltiplos vídeos com o botão `X` e aperte `START` para reprodução contínua sem interrupções.
  * Reprodução acelerada por hardware via `mpv` (KMS/DRM) / `ffplay`, pausando e retomando a interface sem engasgos.

* **🖼️ Galeria de Fotos & Visualizador Fullscreen:**
  * Navegação por pastas com grade de miniaturas 4×3 e cache de redimensionamento eficiente para economizar RAM.
  * Visualizador em tela cheia com **Zoom contínuo (até 3.5x)** e navegação panorâmica (*pan* com direcional).
  * **Rotação de 90°** com um botão (para fotos verticais).
  * **Modo Slideshow automático** com transição temporizada.

* **📖 Leitor de Livros Digitais & Mangás:**
  * Suporte nativo a **EPUB**, **MOBI / AZW** (Kindle descomprimido nativamente em PalmDOC), **TXT**, **PDF** e quadrinhos/mangás **CBZ**.
  * Quebra inteligente de texto em páginas, alternância de tamanho de fonte (*Normal* e *Grande*) e paletas de cor para leitura (*Padrão*, *Sépia para descanso visual* e *Preto AMOLED*).
  * Leitor de mangás com zoom e movimentação panorâmica para leitura de balões de texto pequenos.
  * **Marcador de Página automático (`bookmarks.txt`):** memoriza a última página lida de cada livro para continuar exatamente de onde parou.

* **⚙️ Configurações & Seletor de Pastas:**
  * **Seletor Interativo de Diretórios:** defina a pasta exata da sua biblioteca de músicas, fotos, vídeos e livros navegando pelo sistema ou alternando entre `/roms` (SD1) e `/roms2` (SD2).
  * Temas visuais completos: **Escuro (Dark)**, **Preto Puro (AMOLED `#000000`)** e **Claro (Light)**.
  * Alternância entre layouts de controle **Nintendo (A confirma / B volta)** e **Xbox (B confirma / A volta)**.
  * Controle físico de iluminação do display IPS via *sysfs*.
  * **Screen Dimmer Timer:** opção para desligar a tela automaticamente após tempo inativo de reprodução musical para economizar bateria.

---

## 🎮 Controles Rápidos

| Botão / Atalho | Ação Principal |
|---|---|
| **D-Pad** | Navegação em listas, menus, fotos e texto |
| **A** *(ou B no layout Xbox)* | Abrir pasta / Tocar faixa / Confirmar |
| **B** *(ou A no layout Xbox)* | Voltar de pasta / Retornar ao menu anterior |
| **X** | Alternar Playlist de vídeo (em Vídeos) ou ir para Now Playing (na Home) |
| **START** | Tocar Playlist (em Vídeos) ou Play/Pause de música (na Home) |
| **SELECT** *(na Home)* | Abre o menu de Configurações |
| **SELECT + START** | **Sair imediatamente do Media Hub** (retorna ao EmulationStation) |
| **SELECT + X** | Alternar inversão de botões A/B |
| **SELECT + Y** | Ativar HUD de depuração |
| **L1 / R1** | Faixa anterior / próxima (ou saltar páginas/itens) |
| **L2 / R2** | Volume geral − / + (ou zoom em fotos/mangás) |

---

## 📁 Pastas de Mídia no Cartão SD

Ao inicializar, o aplicativo procura mídias automaticamente nas seguintes pastas (no Cartão 1 `/roms` ou Cartão 2 `/roms2`):
* `music/` &rarr; Suas faixas e álbuns musicais. *(Também lê `/roms2/ports/gmu-music-player/music` automaticamente).*
* `photos/` &rarr; Fotos e imagens organizadas por pastas ou na raiz.
* `videos/` &rarr; Filmes, séries e vídeos.
* `books/` &rarr; E-books (EPUB, MOBI, TXT, PDF) e mangás (CBZ).

*(Você também pode alterar e apontar qualquer diretório personalizado nas **Configurações** usando o Seletor de Pastas).*

---

## 🚀 Instalação Rápida

1. Gere o pacote de distribuição executando no PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\package.ps1
   ```
2. Ou envie diretamente para o cartão SD conectado no PC:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\deploy_to_sd.ps1 -Drive E:
   ```
3. No console, acerte a lista e execute: **Ports** &rarr; **R36S Media Hub**.

> 📖 **Para instruções detalhadas de instalação, compatibilidade com outros consoles e firmwares, consulte o [Manual Completo de Uso (MANUAL.md)](MANUAL.md).**

---

## 🛠️ Desenvolvimento e Testes Automatizados no PC

O projeto pode ser executado diretamente no Windows ou Linux usando o LÖVE 11.5 padrão:

```powershell
# Executar a interface no PC:
lovec game

# Executar a suíte completa de smoke-tests com captura de telas:
powershell -ExecutionPolicy Bypass -File tools\selftest.ps1 -Love <caminho_lovec.exe> -Music <pasta_musicas>
```

---

## 📄 Licença

Distribuído sob a licença **MIT**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
