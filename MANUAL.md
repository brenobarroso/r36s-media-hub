# Manual Completo de Instalação e Uso — R36S Media Hub

> **Versão:** 0.2.0  
> **Compatibilidade:** R36S e consoles RK3326 (dArkOSRE, ArkOS, AmberELEC, JELOS, UnofficialOS)  
> **Engine:** LÖVE 2D 11.5 (Mysterious Mysteries) sob PortMaster  
> **Resolução nativa:** 640×480 @ ~30 FPS (otimizado para bateria)

---

## Índice
1. [Visão Geral](#1-visão-geral)
2. [Dependências e Requisitos do Sistema](#2-dependências-e-requisitos-do-sistema)
   - [PortMaster e Runtime love_11.5](#21-portmaster-e-runtime-love_115)
   - [Aceleração de Vídeo (mpv / ffplay)](#22-aceleração-de-vídeo-mpv--ffplay)
   - [Interface com Hardware (sysfs)](#23-interface-com-hardware-sysfs)
3. [Instalação](#3-instalação)
   - [Método 1: Script Automatizado (Windows/PC)](#31-método-1-script-automatizado-windowspc)
   - [Método 2: Instalação Manual via ZIP](#32-método-2-instalação-manual-via-zip)
   - [O que fazer se o PortMaster não tiver o love_11.5](#33-o-que-fazer-se-o-portmaster-não-tiver-o-love_115)
4. [Estrutura de Pastas e Mídias no Cartão SD](#4-estrutura-de-pastas-e-mídias-no-cartão-sd)
5. [Guia de Utilização por Módulo](#5-guia-de-utilização-por-módulo)
   - [5.1 Home Screen & Mini-Player](#51-home-screen--mini-player)
   - [5.2 Músicas & Equalizador de Áudio](#52-músicas--equalizador-de-áudio)
   - [5.3 Galeria de Fotos & Visualizador](#53-galeria-de-fotos--visualizador)
   - [5.4 Vídeos & Filmes](#54-vídeos--filmes)
   - [5.5 Livros Digitais & Leitor de Mangás](#55-livros-digitais--leitor-de-mangás)
   - [5.6 Configurações do Sistema & Economia de Energia](#56-configurações-do-sistema--economia-de-energia)
6. [Tabela de Controles e Atalhos Globais](#6-tabela-de-controles-e-atalhos-globais)
7. [Resolução de Problemas (FAQ)](#7-resolução-de-problemas-faq)

---

## 1. Visão Geral

O **R36S Media Hub** transforma o console portátil R36S em uma central multimídia moderna, unificada e intuitiva. Desenvolvido em Lua sob o framework LÖVE 11.5 e integrado ao ecossistema PortMaster, o aplicativo elimina a necessidade de alternar entre aplicativos antigos ou consoles de linha de comando para ouvir música, assistir a filmes, ver fotos e ler livros ou quadrinhos.

---

## 2. Dependências e Requisitos do Sistema

### 2.1 PortMaster e Runtime love_11.5
O aplicativo roda como um **Port nativo** do PortMaster:
* **PortMaster Control Scripts:** `control.txt` e suas variáveis de ambiente (`$controlfolder`, `$LOVE_RUN`, `$LOVE_GPTK`).
* **Runtime love_11.5:** Localizado em `$controlfolder/runtimes/love_11.5/love.txt`. Fornece os binários ARM64 do LÖVE 11.5 compilados com suporte a OpenAL, OpenGL ES e decodificadores de imagem/áudio.
* **gptokeyb:** Utilitário responsável pelo mapeamento do controle físico para eventos de joystick/teclado.

### 2.2 Aceleração de Vídeo (mpv / ffplay)
Para reproduzir arquivos de vídeo modernos em alta definição (MP4, MKV, AVI H.264) no chip Rockchip RK3326:
* O sistema operacional (dArkOS / ArkOS) já inclui por padrão o utilitário `/usr/bin/mpv` ou `/usr/bin/ffplay`.
* O launcher invoca o player em modo KMS/DRM (`mpv --fs --vo=drm`), garantindo decodificação acelerada sem sobrecarregar a memória do LÖVE. Ao sair do vídeo, o Media Hub é retomado instantaneamente.

### 2.3 Interface com Hardware (sysfs)
O aplicativo conversa diretamente com os nós do kernel Linux:
* **Bateria:** Leitura em `/sys/class/power_supply/battery/capacity` e `status` (exibe porcentagem e ícone animado de carregamento).
* **Controle de Brilho & Screen Dimmer:** Leitura e escrita em `/sys/class/backlight/backlight/brightness` (ou `pwm-backlight`), permitindo controle pelo menu e corte total do backlight para economizar bateria enquanto toca música.

---

## 3. Instalação

### 3.1 Método 1: Script Automatizado (Windows/PC)
Se o repositório estiver clonado no seu PC e o cartão SD do console estiver inserido (exemplo: letra `E:`):
```powershell
# No PowerShell, dentro da pasta do projeto:
powershell -ExecutionPolicy Bypass -File tools\deploy_to_sd.ps1 -Drive E:
```
O script compila o pacote, extrai os arquivos nos caminhos corretos, garante quebras de linha Unix (LF) e cria as pastas `photos`, `videos` e `books` na raiz do SD.

### 3.2 Método 2: Instalação Manual via ZIP
1. Gere o pacote de distribuição:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\package.ps1
   ```
   *(Ou baixe o arquivo `r36s-music-player.zip` na aba Releases do GitHub).*
2. Conecte o cartão SD no computador.
3. Extraia o conteúdo do zip dentro da pasta `ports` do cartão SD (normalmente `E:\ports\` ou `roms2/ports/`).
4. A estrutura final deve ficar assim:
   ```
   [SD CARD]/
   ├── ports/
   │   ├── R36S Music Player.sh
   │   └── r36smusic/
   │       ├── game/
   │       │   ├── main.lua
   │       │   ├── conf.lua
   │       │   ├── assets/
   │       │   └── src/
   │       ├── r36smusic.gptk
   │       └── music_dir.txt
   ├── music/
   ├── photos/
   ├── videos/
   └── books/
   ```
5. Insira o cartão no R36S, ligue o console e acerte a lista: vá em **Ports** &rarr; **R36S Music Player**.

### 3.3 O que fazer se o PortMaster não tiver o love_11.5
Se ao clicar no jogo ele voltar para o menu do console imediatamente:
1. Conecte o R36S ao Wi-Fi (via dongle USB ou tethering).
2. Abra o **PortMaster** no console.
3. Vá em **Manage Ports** ou **Runtimes** e instale o runtime `love-11.5`.
4. Alternativamente, qualquer outro port baseado em Love2D 11.5 instalado pelo PortMaster baixa esse runtime automaticamente.

---

## 4. Estrutura de Pastas e Mídias no Cartão SD

O Media Hub foi desenhado para detectar automaticamente as mídias tanto no Cartão 1 (`/roms`) quanto no Cartão 2 (`/roms2`):

| Mídia | Pastas Verificadas (em ordem) | Formatos Suportados |
|---|---|---|
| **Músicas** | `/roms2/ports/gmu-music-player/music`<br>`/roms2/music`<br>`/roms/music`<br>`~/Music` | `.mp3`, `.ogg`, `.flac`, `.wav` |
| **Fotos** | `/roms2/photos`<br>`/roms/photos`<br>`/roms2/pictures`<br>`~/Pictures` | `.jpg`, `.jpeg`, `.png`, `.bmp`, `.webp` |
| **Vídeos** | `/roms2/videos`<br>`/roms/videos`<br>`/roms2/movies`<br>`/roms/movies` | `.mp4`, `.mkv`, `.avi`, `.mov`, `.wmv`, `.webm`, `.ogv` |
| **Livros / Mangás** | `/roms2/books`<br>`/roms/books`<br>`/roms2/ebooks`<br>`/roms2/comics` | `.epub`, `.mobi`, `.azw`, `.txt`, `.cbz`, `.pdf` |

> [!TIP]
> **Caminho personalizado de música:** Se suas músicas estiverem em outra pasta, crie ou edite o arquivo `ports/r36smusic/music_dir.txt` e adicione o caminho desejado na primeira linha.

---

## 5. Guia de Utilização por Módulo

### 5.1 Home Screen & Mini-Player
* Navegue entre os 4 cards principais usando o **D-Pad**.
* Pressione **A** (ou **B**, dependendo do layout escolhido) para entrar no módulo selecionado.
* Pressione **SELECT** para abrir o painel de **Configurações**.
* **Mini-Player:** Se você estiver ouvindo uma música e retornar para a Home, uma barra elegante na parte inferior mostrará a faixa em reprodução. Pressione **START** para pausar/retomar, ou **X** para saltar direto para a tela cheia do player.

---

### 5.2 Músicas & Equalizador de Áudio
* **Navegação de Pastas:** Mostra primeiro as pastas e depois as faixas em ordem alfabética natural.
* **Tocando Agora:** Exibe arte do álbum (embutida no arquivo ou arquivos `cover.jpg`/`folder.jpg`), título, artista, álbum, duração total e posição atual.
* **Equalizador OpenAL integrado:**
  - 6 perfis sonoros calibrados: *Flat (Desligado)*, *Bass Boost (Grave reforçado para fones)*, *Rock*, *Pop*, *Voz / Acústico* e *Eletrônica*.
  - O perfil ativo é exibido na tela de reprodução e pode ser alternado nas Configurações.
* **Controles na reprodução:**
  - **D-Pad Cima / Baixo:** Ajusta o volume gradualmente (0 a 100%).
  - **D-Pad Esquerda / Direita:** Avança ou retrocede 5 segundos na música.
  - **L1 / R1:** Faixa anterior / próxima.
  - **L2 / R2:** Volume rápido − / +.
  - **X:** Alterna modo Aleatório (*Shuffle*).
  - **Y:** Alterna modo de Repetição (*Desligado*, *Repetir Todas*, *Repetir Uma*).

---

### 5.3 Galeria de Fotos & Visualizador
* **Grade 4×3:** Apresenta miniaturas das imagens e pastas. As miniaturas são redimensionadas na memória para não sobrecarregar a GPU Mali do console.
* **Visualizador Fullscreen:**
  - **D-Pad Esquerda / Direita:** Foto anterior / próxima.
  - **L2 / R2 ou D-Pad Cima / Baixo (em zoom):** Controle de Zoom contínuo (de 1.0x até 3.5x).
  - **D-Pad (quando ampliado):** Navegação panorâmica (*pan*) pelos detalhes da imagem.
  - **Y ou L1:** Rotação de 90° (ideal para visualizar fotos tiradas na vertical).
  - **A:** Reseta o zoom para 1.0x ou amplia direto para 2.0x.
  - **START:** Ativa o modo **Slideshow automático** (troca de foto a cada 4 segundos com transição limpa).

---

### 5.4 Vídeos & Filmes
* Lista todos os vídeos e pastas com informações de extensão e tamanho formatado (ex: `720 MB`, `1.4 GB`).
* **Capas e Pôsteres:** Se houver uma imagem com o mesmo nome do vídeo (ex: `Matrix.mp4` e `Matrix.jpg`) ou uma imagem `poster.jpg`/`cover.jpg` dentro da pasta, ela será exibida como pôster na lateral.
* Ao pressionar **A**, o aplicativo pausa qualquer música de fundo e inicializa a reprodução com aceleração de hardware via `mpv`/`ffplay`. Ao término ou ao apertar o botão de sair do player, você retorna exatamente de onde parou.

---

### 5.5 Livros Digitais & Leitor de Mangás
* **Leitor de Texto (EPUB, MOBI, TXT, PDF):**
  - Quebra e paginação inteligente de texto desenhada para leitura confortável em tela IPS de 3.5".
  - **Y:** Alterna o tamanho da fonte entre *Normal* (18px) e *Grande* (22px).
  - **X:** Alterna o esquema de cores:
    - *Tema Padrão:* segue as cores da interface.
    - *Sépia:* fundo creme com letras escuras (reduz a fadiga ocular em leituras longas).
    - *AMOLED:* fundo preto absoluto com texto claro.
  - **L2 / R2:** Salta 10 páginas para trás ou para frente.
* **Leitor de Mangás e Quadrinhos (CBZ):**
  - Descompactação e montagem de imagens transparentes.
  - Suporte total a **Zoom (2x/3x)** e movimentação pelo direcional para facilitar a leitura de pequenos balões de diálogo.
* **Marcador de Página Automático:** Cada livro ou mangá salva sua página atual em `bookmarks.txt`. Ao reabrir o livro, você volta imediatamente para a página onde parou.

---

### 5.6 Configurações do Sistema & Economia de Energia
Pressione **SELECT** na Home para acessar as opções:
1. **Tema Visual:**
   - *Escuro (Dark):* Azul escuro elegante com detalhes em verde menta.
   - *Preto Puro (AMOLED):* Fundo `#000000` absoluto com máximo contraste.
   - *Claro (Light):* Tons suaves para uso em ambientes claros.
2. **Layout dos Botões A/B:**
   - *Nintendo:* **A** confirma / **B** volta.
   - *Xbox:* **B** confirma / **A** volta.
3. **Brilho da Tela:** Controle de 10% a 100% que ajusta a iluminação física do console em tempo real.
4. **Apagar Tela ao Tocar Música:** Timer configurável (*Desativado*, *30s*, *1m*, *2m*, *5m*). Desliga a luz de fundo durante a reprodução de músicas para economia expressiva de bateria. Pressionar qualquer botão religa a tela instantaneamente.
5. **Volume Principal:** Ajuste percentual geral do sistema de áudio.
6. **Equalizador de Áudio:** Seleção rápida de perfis sonoros.

---

## 6. Tabela de Controles e Atalhos Globais

| Atalho / Botão | Ação Global |
|---|---|
| **SELECT + START** | **Sair imediatamente do Media Hub** (retorna ao EmulationStation) |
| **SELECT + X** | Inverte rapidamente os botões **A / B** |
| **SELECT + Y** | Exibe HUD de depuração técnica (inputs, joysticks, caminhos) |
| **START** | Play / Pause da música de fundo em qualquer tela |
| **L1 / R1** | Faixa de música anterior / próxima (global) |
| **L2 / R2** | Volume geral − / + (global) |

---

## 7. Resolução de Problemas (FAQ)

### O app não aparece na lista de Ports do console
* Certifique-se de que o arquivo `R36S Music Player.sh` está diretamente dentro da pasta `ports` do seu cartão SD (e não dentro de uma subpasta).
* Pressione **Start** no console e selecione **Restart EmulationStation** para recarregar a lista de jogos/ports.

### O app fecha logo após abrir (tela preta rápida)
* Verifique se o PortMaster possui o runtime `love-11.5`. Abra o PortMaster com Wi-Fi ativo e instale o runtime ou verifique o arquivo `ports/r36smusic/log.txt` gerado no cartão para ver o motivo.

### Os botões A e B estão invertidos em relação ao que gosto
* Pressione **SELECT + X** a qualquer momento ou acesse as **Configurações (SELECT na Home)** e altere o layout entre Nintendo e Xbox. A preferência é salva automaticamente.

### Nenhuma música ou foto aparece
* Verifique se você colocou seus arquivos nas pastas corretas (`/music`, `/photos`, `/videos`, `/books` na raiz do cartão SD).
* Para músicas que já estavam no GMU Player, o aplicativo já detecta automaticamente a pasta `/roms2/ports/gmu-music-player/music`.
