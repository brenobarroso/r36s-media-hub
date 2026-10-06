# Manual Completo de Instalação e Uso — R36S Media Hub

> **Versão:** 0.3.0  
> **Compatibilidade Principal:** R36S, R35S e portáteis RK3326 / RK3566 / H700  
> **Firmwares Suportados:** dArkOSRE, ArkOS, AmberELEC, JELOS, ROCKNIX, muOS, Knulli/Batocera  
> **Engine:** LÖVE 2D 11.5 (Mysterious Mysteries) sob PortMaster  
> **Resolução nativa:** 640×480 @ ~30 FPS (otimizado para bateria e tela IPS)

---

## Índice
1. [Visão Geral](#1-visão-geral)
2. [Compatibilidade com Portáteis e Firmwares](#2-compatibilidade-com-portáteis-e-firmwares)
   - [2.1 Consoles e Chips (SoCs) Suportados](#21-consoles-e-chips-socs-suportados)
   - [2.2 Compatibilidade por Sistema / Firmware](#22-compatibilidade-por-sistema--firmware)
3. [Dependências e Requisitos do Sistema](#3-dependências-e-requisitos-do-sistema)
   - [PortMaster e Runtime love_11.5](#31-portmaster-e-runtime-love_115)
   - [Aceleração de Vídeo (mpv / ffplay)](#32-aceleração-de-vídeo-mpv--ffplay)
   - [Interface com Hardware (sysfs)](#33-interface-com-hardware-sysfs)
4. [Instalação](#4-instalação)
   - [4.1 Método 1: Script Automatizado (Windows/PC)](#41-método-1-script-automatizado-windowspc)
   - [4.2 Método 2: Instalação Manual via ZIP](#42-método-2-instalação-manual-via-zip)
   - [4.3 O que fazer se o PortMaster não tiver o love_11.5](#43-o-que-fazer-se-o-portmaster-não-tiver-o-love_115)
5. [Estrutura de Pastas e Configuração de Diretórios](#5-estrutura-de-pastas-e-configuração-de-diretórios)
   - [5.1 Pastas Padrão no Cartão SD](#51-pastas-padrão-no-cartão-sd)
   - [5.2 Seletor Interativo de Pastas (Folder Picker)](#52-seletor-interativo-de-pastas-folder-picker)
6. [Guia de Utilização por Módulo](#6-guia-de-utilização-por-módulo)
   - [6.1 Home Screen & Mini-Player](#61-home-screen--mini-player)
   - [6.2 Músicas, Equalizador & Visualizador Retrô WMP](#62-músicas-equalizador--visualizador-retrô-wmp)
   - [6.3 Galeria de Fotos & Visualizador](#63-galeria-de-fotos--visualizador)
   - [6.4 Vídeos, Filmes & Sistema de Playlists](#64-vídeos-filmes--sistema-de-playlists)
   - [6.5 Livros Digitais (PDF, EPUB, TXT)](#65-livros-digitais-pdf-epub-txt)
   - [6.6 Configurações do Sistema & Economia de Bateria](#66-configurações-do-sistema--economia-de-bateria)
7. [Tabela de Controles e Atalhos Globais](#7-tabela-de-controles-e-atalhos-globais)
8. [Resolução de Problemas (FAQ)](#8-resolução-de-problemas-faq)

---

## 1. Visão Geral

O **R36S Media Hub** transforma o console portátil em uma central multimídia completa, moderna e intuitiva. Desenvolvido em Lua sob o framework LÖVE 11.5 e integrado ao ecossistema PortMaster, ele substitui ferramentas arcaicas de linha de comando ou leitores isolados por uma interface unificada que gerencia:
* **Músicas:** Player com equalizador paramétrico OpenAL EFX e visualizador espectral retrô estilo Windows Media Player / Winamp quando não há capa de álbum.
* **Vídeos:** Gerenciador com suporte a pôsteres, thumbnails e criação dinâmica de **Playlists** para reprodução sequencial acelerada por hardware via `mpv`.
* **Fotos:** Galeria em grade 4×3 com zoom contínuo, rotação 90° e modo slideshow automático.
* **Livros & Mangás:** Leitor de texto para EPUB, MOBI, TXT e PDF com quebra de página por software e leitor de quadrinhos CBZ com memória de última página (*bookmarks*).
* **Configurações Globais:** Seletor interativo de pastas para múltiplos cartões SD, temas visuais (Dark, Light, AMOLED puro) e timer de desligamento de tela para poupar bateria.

---

## 2. Compatibilidade com Portáteis e Firmwares

O R36S Media Hub foi construído sobre padrões abertos de POSIX Linux, LÖVE 11.5 ARM64 e `gptokeyb` do PortMaster. Por essa razão, sua compatibilidade vai muito além do R36S.

### 2.1 Consoles e Chips (SoCs) Suportados

| Chipset (SoC) | Dispositivos Exemplares | Nível de Suporte | Observações |
|---|---|---|---|
| **Rockchip RK3326** | **R36S**, R35S, Powkiddy RGB20S, Anbernic RG351P / RG351M / RG351V / RG351MP, Gameforce Chi | **100% Nativo (Referência)** | Testado exaustivamente no R36S. Desempenho impecável a 640×480. |
| **Rockchip RK3566** | Powkiddy RGB30, RK2023, x55, RGB10 Max 3, Anbernic RG353P / RG353V / RG353M, RG ARC-D/S | **100% Compatível** | O runtime love_11.5 e o mpv funcionam nativamente com ainda mais folga de CPU/GPU. |
| **Allwinner H700** | Anbernic RG35XX Plus, RG35XX H, RG35XX SP, RG40XX H / V, RG28XX | **Compatível via PortMaster** | Requer firmware com PortMaster ativo (ex: muOS Banana/Beans ou Knulli). |
| **Amlogic (S905/S922)** | Odroid Go Advance / Super, Powkiddy A20 | **Compatível** | Via ArkOS ou AmberELEC. |

### 2.2 Compatibilidade por Sistema / Firmware

1. **ArkOS / dArkOSRE (Recomendado):**
   * Compatibilidade total (100%).
   * Suporte nativo a leitura de bateria em `/sys/class/power_supply/battery/capacity`.
   * Suporte a controle de backlight físico em `/sys/class/backlight/...`.
   * Reprodução de vídeos integrada via `/usr/bin/mpv` com decodificação KMS/DRM.

2. **AmberELEC:**
   * Totalmente compatível. O AmberELEC possui runtime PortMaster com LÖVE 11.5 pronto para uso.
   * O script launcher detecta automaticamente o diretório de mídias e controles.

3. **JELOS / ROCKNIX:**
   * Totalmente compatível nos consoles RK3326 e RK3566.
   * As portas e o runtime do PortMaster rodam diretamente da partição de jogos.

4. **muOS (Consoles Anbernic RG35XX Plus/H/SP H700):**
   * Compatível desde que o instalador do PortMaster para muOS esteja presente.
   * Os diretórios de mídias são lidos normalmente do cartão `SD1` ou `SD2` via o Seletor de Pastas do app.

5. **Knulli / Batocera:**
   * Compatível através do subsistema PortMaster embutido.

> [!NOTE]
> Sistemas minimalistas como o **MinUI** não possuem a pilha do PortMaster / LÖVE 11.5 por padrão, sendo necessário pacotes adicionais criados pela comunidade caso deseje rodar ports neles.

---

## 3. Dependências e Requisitos do Sistema

### 3.1 PortMaster e Runtime love_11.5
O aplicativo roda como um **Port nativo** do PortMaster:
* **PortMaster Control Scripts:** `control.txt` e suas variáveis de ambiente (`$controlfolder`, `$LOVE_RUN`, `$LOVE_GPTK`).
* **Runtime love_11.5:** Localizado em `$controlfolder/runtimes/love_11.5/love.txt`. Fornece os binários ARM64 do LÖVE 11.5 compilados com suporte a OpenAL, OpenGL ES e decodificadores de imagem/áudio.
* **gptokeyb:** Utilitário responsável pelo mapeamento do controle físico para eventos de joystick e teclado virtual.

### 3.2 Aceleração de Vídeo (mpv / ffplay)
Para reproduzir arquivos de vídeo modernos em alta definição (MP4, MKV, AVI H.264) no chip Rockchip RK3326:
* O sistema operacional (dArkOS / ArkOS) já inclui por padrão o utilitário `/usr/bin/mpv` ou `/usr/bin/ffplay`.
* O launcher invoca o player em modo KMS/DRM (`mpv --fs --vo=drm`), garantindo decodificação acelerada sem sobrecarregar a memória do LÖVE. Ao sair do vídeo, o Media Hub é retomado instantaneamente.
* **Saída Instantânea sem Travamentos (`mpv_input.conf`):** O aplicativo injeta um arquivo de configuração de entrada dedicado que mapeia os botões **B**, **SELECT**, **ESC** e **q** diretamente para o comando de encerramento (`quit`), permitindo retornar ao menu a qualquer momento sem prender o usuário ou exigir reinicialização do console.
* **Playlists:** Múltiplos arquivos selecionados na fila são passados em sequência direta para o `mpv`, que os toca sucessivamente sem fechar a tela.

### 3.3 Interface com Hardware (sysfs)
O aplicativo conversa diretamente com os nós do kernel Linux:
* **Bateria:** Leitura em `/sys/class/power_supply/battery/capacity` e `status` (exibe porcentagem e ícone animado de carregamento na barra superior).
* **Controle de Brilho & Screen Dimmer:** Leitura e escrita em `/sys/class/backlight/backlight/brightness` (ou `pwm-backlight`), permitindo controle pelo menu e corte total do backlight para economizar bateria enquanto toca música.

---

## 4. Instalação

### 4.1 Método 1: Script Automatizado (Windows/PC)
Com o cartão SD conectado no PC (exemplo: unidade `E:`):
```powershell
# No PowerShell, dentro da pasta do projeto:
powershell -ExecutionPolicy Bypass -File tools\deploy_to_sd.ps1 -Drive E:
```
O script compila o pacote, extrai os arquivos nos caminhos corretos, garante quebras de linha Unix (LF) e cria as pastas `photos`, `videos` e `books` na raiz do SD.

### 4.2 Método 2: Instalação Manual via ZIP
1. Gere o pacote de distribuição:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\package.ps1
   ```
   *(Ou baixe o arquivo `r36s-music-player.zip` na aba Releases do GitHub).*
2. Conecte o cartão SD no computador.
3. Extraia o conteúdo do zip dentro da pasta `ports` do cartão SD (normalmente `E:\ports\` ou `/roms2/ports/`).
4. A estrutura final deve ficar assim:
   ```
   [SD CARD]/
   ├── ports/
   │   ├── R36S Media Hub.sh
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
5. Insira o cartão no console, ligue o portátil e vá em **Ports** &rarr; **R36S Media Hub**.

### 4.3 O que fazer se o PortMaster não tiver o love_11.5
Se ao clicar no jogo ele voltar para o menu do console imediatamente:
1. Conecte o portátil ao Wi-Fi (via dongle USB ou tethering por celular).
2. Abra o **PortMaster** no console.
3. Vá em **Manage Ports** ou **Runtimes** e instale o runtime `love-11.5`.
4. Alternativamente, qualquer outro port baseado em Love2D 11.5 instalado pelo PortMaster baixa esse runtime automaticamente.

---

## 5. Estrutura de Pastas e Configuração de Diretórios

### 5.1 Pastas Padrão no Cartão SD

O Media Hub foi desenhado para detectar automaticamente as mídias tanto no Cartão 1 (`/roms`) quanto no Cartão 2 (`/roms2`):

| Mídia | Pastas Verificadas Automaticamente | Formatos Suportados |
|---|---|---|
| **Músicas** | `/roms/ports/gmu-music-player/music`<br>`/roms2/ports/gmu-music-player/music`<br>`/roms/music`<br>`/roms2/music`<br>`~/Music` | `.mp3`, `.ogg`, `.flac`, `.wav` |
| **Fotos** | `/roms/photos`<br>`/roms2/photos`<br>`/roms/pictures`<br>`/roms2/pictures`<br>`~/Pictures` | `.jpg`, `.jpeg`, `.png`, `.bmp`, `.webp` |
| **Vídeos** | `/roms/videos`<br>`/roms2/videos`<br>`/roms/movies`<br>`/roms2/movies`<br>`/roms/ports/videos` | `.mp4`, `.mkv`, `.avi`, `.mov`, `.wmv`, `.webm`, `.ogv`, `.3gp` |
| **Livros / Mangás** | `/roms/books`<br>`/roms2/books`<br>`/roms/ebooks`<br>`/roms2/ebooks`<br>`/roms/comics` | `.epub`, `.mobi`, `.azw`, `.txt`, `.cbz`, `.pdf`, `.md` |

### 5.2 Seletor Interativo de Pastas (Folder Picker)

Caso suas mídias estejam em pastas com outros nomes ou em um disco externo:
1. Abra o Media Hub e pressione **SELECT** (ou aperte o botão de Configurações no topo da Home).
2. Role a lista até as opções de diretório:
   - *Pasta de Músicas*
   - *Pasta de Fotos*
   - *Pasta de Vídeos*
   - *Pasta de Livros & Mangás*
3. Pressione **A** na opção desejada para abrir o navegador de diretórios.
4. Navegue pelas pastas usando o D-Pad:
   - Selecione **.. (Subir pasta)** ou pressione **B** para voltar um nível.
   - Pressione **A** para entrar em uma subpasta.
   - Navegue facilmente entre `/roms` (Cartão 1) e `/roms2` (Cartão 2).
5. Ao estar dentro da pasta desejada, pressione **START** ou **X** para confirmar. A configuração é salva e aplicada instantaneamente em todas as telas!

---

## 6. Guia de Utilização por Módulo

### 6.1 Home Screen & Mini-Player
* Navegue entre os 4 cards principais usando o **D-Pad**.
* Pressione **A** (ou **B**, dependendo do layout escolhido) para entrar no módulo selecionado.
* Pressione **SELECT** ou **Y** para abrir o painel de **Configurações**.
* **Mini-Player:** Se você estiver ouvindo uma música e retornar para a Home, uma barra elegante na parte inferior mostrará a faixa em reprodução. Pressione **START** para pausar/retomar, ou **X** para saltar direto para a tela cheia do player.

---

### 6.2 Músicas, Equalizador & Visualizador Retrô WMP
* **Navegação de Pastas:** Mostra primeiro as pastas e depois as faixas em ordem alfabética natural.
* **Tocando Agora:** Exibe arte do álbum (embutida no arquivo ou arquivos `cover.jpg`/`folder.jpg`), título, artista, álbum, duração total e posição atual.
* **Visualizador Espectral Retrô (Estilo Windows Media Player / Winamp):**
  - Quando a faixa **não possuir arte de capa**, o aplicativo ativa automaticamente um visualizador de espectro sonoro com **16 barras de LED coloridas** em degrade (verde &rarr; amarelo &rarr; laranja &rarr; vermelho).
  - Inclui marcadores flutuantes de pico com física de gravidade e animação fluida a 30 FPS.
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

### 6.3 Galeria de Fotos & Visualizador
* **Grade 4×3:** Apresenta miniaturas das imagens e pastas. As miniaturas são redimensionadas na memória para não sobrecarregar a GPU Mali do console.
* **Visualizador Fullscreen:**
  - **D-Pad Esquerda / Direita:** Foto anterior / próxima.
  - **L2 / R2 ou D-Pad Cima / Baixo (em zoom):** Controle de Zoom contínuo (de 1.0x até 3.5x).
  - **D-Pad (quando ampliado):** Navegação panorâmica (*pan*) pelos detalhes da imagem.
  - **Y ou L1:** Rotação de 90° (ideal para visualizar fotos tiradas na vertical).
  - **A:** Reseta o zoom para 1.0x ou amplia direto para 2.0x.
  - **START:** Ativa o modo **Slideshow automático** (troca de foto a cada 4 segundos com transição limpa).

---

### 6.4 Vídeos, Filmes & Sistema de Playlists
* Lista todos os vídeos e pastas com informações de extensão e tamanho formatado (ex: `720 MB`, `1.4 GB`).
* **Capas e Pôsteres:** Se houver uma imagem com o mesmo nome do vídeo (ex: `Matrix.mp4` e `Matrix.jpg`) ou uma imagem `poster.jpg`/`cover.jpg` dentro da pasta, ela será exibida como pôster na lateral.
* **Sistema de Playlists / Fila de Vídeos:**
  - **Botão X:** Adiciona ou remove o vídeo selecionado da Playlist. Um marcador numerado (`#1`, `#2`, etc.) surge no canto superior da thumbnail para indicar a ordem da fila.
  - **Botão START:**
    - Se houver itens na Playlist, inicia a reprodução contínua da lista via `mpv`.
    - Se a Playlist estiver vazia, toca todos os vídeos da pasta atual sequencialmente.
  - **Botão SELECT:** Limpa toda a fila de vídeos atual.
  - **Botão A:** Toca imediatamente o vídeo selecionado de forma individual.
* **Saída Instantânea:** Pressione **B** ou **SELECT** a qualquer instante durante a reprodução para retornar imediatamente à lista.
* **Dicas de Desempenho no RK3326:**
  - Para reprodução suave sem engasgos, recomenda-se vídeos codificados em **H.264 (AVC)** com resolução de **640×480 (480p)** ou **1280×720 (720p)** e taxa de bits entre **1500 kbps e 2500 kbps**.
  - Evite arquivos em 1080p pesados ou H.265/HEVC, pois demandam processamento pesado por software que excede a capacidade do processador portátil.
* Ao reproduzir vídeos, o aplicativo pausa qualquer música de fundo ativa automaticamente.

---

### 6.5 Livros Digitais (PDF, EPUB, TXT)
* **Foco em Qualidade e Legibilidade:**
  - O leitor foi otimizado estritamente para **PDF**, **EPUB** e **TXT**, garantindo carregamento rápido, consumo mínimo de memória e paginação uniforme.
* **Mecanismo de Extração de PDF:**
  - **Compensação Inteligente de Kerning:** Resolve o problema comum de espaços indevidos inseridos entre letras (ex: `Barr oso` &rarr; `Barroso`).
  - **Correção Completa de Acentuação:** Converte páginas de código ISO-8859-1 e Windows-1252 para UTF-8 genuíno, preservando acentos em português (`ç`, `ã`, `õ`, `é`, `í`, `ó`).
  - **Ligaduras Tipográficas TeX/PDF:** Reconhece e decodifica caracteres ligados (`fi`, `fl`, `ff`).
* **Controles no Leitor:**
  - **D-Pad Esquerda / Direita ou L1 / R1:** Página anterior / próxima.
  - **L2 / R2:** Salta 10 páginas para trás ou para frente.
  - **Y:** Alterna o tamanho da fonte entre *Normal* (18px) e *Grande* (22px).
  - **X:** Alterna o esquema visual de leitura:
    - *Tema Padrão:* segue as cores da interface.
    - *Sépia:* fundo creme suave que reduz a fadiga ocular em leituras prolongadas.
    - *AMOLED:* fundo preto absoluto (`#000000`) com texto claro, ideal para leitura noturna com economia máxima de bateria.
  - **B:** Retorna à lista de livros.
* **Marcador de Página Automático:** Cada documento salva sua posição em `bookmarks.txt`. Ao reabrir o arquivo, você volta imediatamente para a página onde parou.

---

### 6.6 Configurações do Sistema & Economia de Bateria
Pressione **SELECT** na Home para acessar as opções:
1. **Tema Visual:**
   - *Escuro (Dark):* Azul escuro elegante com detalhes em verde menta.
   - *Preto Puro (AMOLED):* Fundo `#000000` absoluto com máximo contraste.
   - *Claro (Light):* Tons suaves para uso em ambientes claros.
2. **Layout dos Botões A/B:**
   - *Nintendo:* **A** confirma / **B** volta.
   - *Xbox:* **B** confirma / **A** volta.
3. **Brilho da Tela:** Controle de 10% a 100% que ajusta a iluminação física do console em tempo real via *sysfs*.
4. **Apagar Tela ao Tocar Música:** Timer configurável (*Desativado*, *30s*, *1m*, *2m*, *5m*). Desliga a luz de fundo durante a reprodução de músicas para economia expressiva de bateria. Pressionar qualquer botão religa a tela instantaneamente.
5. **Volume Principal:** Ajuste percentual geral do sistema de áudio.
6. **Equalizador de Áudio:** Seleção rápida de perfis sonoros.
7. **Pastas de Mídia (Músicas, Fotos, Vídeos, Livros):** Abre o navegador de pastas para selecionar qualquer pasta no SD1 ou SD2.

---

## 7. Tabela de Controles e Atalhos Globais

| Atalho / Botão | Ação no Menu / Global | Ação no Módulo Ativo |
|---|---|---|
| **SELECT + START** | **Sair imediatamente do Media Hub** | Retorna ao menu principal de jogos (EmulationStation) |
| **SELECT + X** | Inverte rapidamente os botões **A / B** | Alterna entre padrão Nintendo e Xbox |
| **SELECT + Y** | Exibe HUD de depuração técnica | Mostra inputs, joystick ID e caminhos em tempo real |
| **START** | Play / Pause da música de fundo (na Home) | Na tela de Vídeos: toca a Playlist inteira / tudo |
| **X** | Abre Now Playing (na Home se tocando) | Na tela de Vídeos: adiciona/remove da Playlist / Em Livros: alterna tema de cor |
| **Y** | Abre Configurações (na Home) | Em Fotos: rotação 90° / Em Livros: alterna tamanho da fonte |
| **L1 / R1** | Faixa anterior / próxima (na Home / Música) | Pula 6 itens em listas / 1 página no leitor |
| **L2 / R2** | Volume geral − / + | Zoom contínuo em fotos / Salta 10 páginas no leitor |
| **B / SELECT** | Retornar ao menu anterior | **Durante vídeo:** Encerra a reprodução e volta à lista |

---

## 8. Resolução de Problemas (FAQ)

### Como sair de um vídeo durante a reprodução?
* Pressione **B** ou **SELECT** no console. O player de vídeo (`mpv`) foi configurado para encerrar imediatamente e devolver o controle ao Media Hub sem necessidade de reiniciar o console.

### Vídeos ou Fotos demoram para abrir ou engasgam
* **Limitações do hardware (RK3326):** O processador do R36S possui 4 núcleos Cortex-A35 e 1 GB de RAM.
  - **Para vídeos:** Use arquivos em resolução **480p** ou **720p** codificados em **H.264 (AVC)** com bitrate até 2500 kbps. Evite vídeos em 1080p, 4K ou H.265.
  - **Para fotos:** Fotos de 20+ megapixels tiradas em smartphones modernos exigem dezenas de megabytes para descompactar na RAM. Redimensione suas imagens para **1080p** ou **640×480** antes de colocar no cartão SD para carregamento instantâneo.

### O app não aparece na lista de Ports do console
* Certifique-se de que o arquivo `R36S Media Hub.sh` está diretamente dentro da pasta `ports` do seu cartão SD (e não dentro de uma subpasta).
* Pressione **Start** no console e selecione **Restart EmulationStation** para recarregar a lista de jogos/ports.

### O app fecha logo após abrir (tela preta rápida)
* Verifique se o PortMaster possui o runtime `love-11.5`. Abra o PortMaster com Wi-Fi ativo e instale o runtime ou verifique o arquivo `ports/r36smusic/log.txt` gerado no cartão para ver o motivo.

### Os botões A e B estão invertidos em relação ao que gosto
* Pressione **SELECT + X** a qualquer momento ou acesse as **Configurações (SELECT na Home)** e altere o layout entre Nintendo e Xbox. A preferência é salva automaticamente.

### Não encontrou meus vídeos, fotos ou livros
* Vá até **Configurações (SELECT na Home)** e role até **Pasta de Vídeos / Fotos / Livros**.
* Pressione **A**, navegue até o diretório exato onde seus arquivos estão e aperte **START** ou **X** para selecionar.

### As capas de álbuns não aparecem em algumas músicas
* O Media Hub exibe automaticamente as capas embutidas em ID3v2 ou imagens `cover.jpg` / `folder.jpg` na pasta do álbum.
* Caso uma faixa não tenha capa, o aplicativo exibe o novo **Equalizador Espectral Animado**, com barras multicoloridas estilo vintage do Windows Media Player!
