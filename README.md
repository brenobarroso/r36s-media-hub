# 🎮 R36S Media Hub

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: R36S / RK3326 / RK3566 / H700](https://img.shields.io/badge/Platform-RK3326%20%7C%20RK3566%20%7C%20H700-orange.svg)](https://github.com)
[![Engine: LÖVE 11.5](https://img.shields.io/badge/Engine-L%C3%96VE%2011.5-pink.svg)](https://love2d.org)
[![PortMaster](https://img.shields.io/badge/Runtime-PortMaster-brightgreen.svg)](https://portmaster.games)

Central Multimídia moderna, fluida e completa desenvolvida sob medida para consoles portáteis **R36S**, **R35S**, **Powkiddy**, **Anbernic** e dispositivos baseados nos chips **Rockchip RK3326**, **RK3566** e **Allwinner H700** rodando **dArkOS / ArkOS / AmberELEC / JELOS / ROCKNIX / muOS** via **PortMaster**.

Transforme seu videogame portátil retrô em um reprodutor de músicas com equalizador e visualizador espectral retrô, reprodutor de vídeos com fila de playlists acelerado por hardware, galeria de fotos em tela cheia e leitor de livros digitais (PDF, EPUB, TXT) com formatação limpa e salvamento automático de progresso.

---

## 🌟 Funcionalidades Principais

* **🏠 Home Screen Intuitiva:**
  * Navegação rápida por cards 2×2 (*Músicas*, *Vídeos*, *Fotos*, *Livros*).
  * Barra superior integrada com relógio em tempo real e leitura de bateria via *sysfs* (porcentagem e indicador de carregamento com memoização de baixo consumo).
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
  * Reprodução acelerada por hardware via `mpv` (KMS/DRM) / `ffplay`.
  * **Saída Instantânea sem Travamentos:** mapeamento dedicado via `mpv_input.conf` que permite sair a qualquer momento pressionando `B`, `SELECT`, `ESC` ou `q`.

* **🖼️ Galeria de Fotos & Visualizador Fullscreen:**
  * Navegação por pastas com grade de miniaturas 4×3 e cache inteligente de redimensionamento.
  * Visualizador em tela cheia com **Zoom contínuo (até 3.5x)** e navegação panorâmica (*pan* com direcional).
  * **Rotação de 90°** com um botão (para fotos verticais).
  * **Modo Slideshow automático** com transição temporizada.

* **📖 Leitor de Livros Digitais (PDF, EPUB, TXT):**
  * Foco e precisão máxima nos três formatos fundamentais de leitura: **PDF**, **EPUB** e **TXT**.
  * **Extrator de PDF Otimizado:**
    * Tratamento de kerning inteligente (elimina palavras divididas com espaços indevidos).
    * Decodificação de códigos octais e conversão completa de páginas de código ISO-8859-1/Windows-1252 para UTF-8 genuíno (acentuação em português 100% perfeita: `ç`, `ã`, `õ`, `é`, etc.).
    * Suporte a ligaduras tipográficas TeX/PDF (`fi`, `fl`, `ff`).
  * Quebra inteligente de texto em páginas, alternância de tamanho de fonte (*Normal* e *Grande*) via botão `Y`.
  * Paletas de cor para leitura (*Padrão*, *Sépia para descanso visual* e *Preto AMOLED puro*) via botão `X`.
  * **Marcador de Página automático (`bookmarks.txt`):** memoriza a última página lida de cada livro para continuar de onde parou.

* **⚙️ Configurações & Seletor de Pastas:**
  * **Seletor Interativo de Diretórios:** defina a pasta exata da sua biblioteca de músicas, fotos, vídeos e livros navegando pelo sistema ou alternando entre `/roms` (SD1) e `/roms2` (SD2).
  * Temas visuais completos: **Escuro (Dark)**, **Preto Puro (AMOLED `#000000`)** e **Claro (Light)**.
  * Alternância entre layouts de controle **Nintendo (A confirma / B volta)** e **Xbox (B confirma / A volta)**.
  * Controle físico de iluminação do display IPS via *sysfs*.
  * **Screen Dimmer Timer:** opção para desligar a tela automaticamente após tempo inativo de reprodução musical para economizar bateria.

---

## 💡 Dicas de Otimização para o Hardware do R36S (RK3326)

O console R36S utiliza o processador Rockchip RK3326 (Quad-Core Cortex-A35 @ 1.3-1.5 GHz) com 1 GB de RAM. Para obter a melhor experiência possível:

### 🎬 Vídeos e Filmes
* **Resolução recomendada:** **640×480 (480p)** ou **1280×720 (720p)** em codec **H.264 (AVC)**.
* **Taxa de bits (Bitrate):** Entre **1500 kbps e 2500 kbps** com áudio Stereo AAC/MP3.
* **Dica:** Arquivos pesados em 1080p, 4K ou codificados em H.265/HEVC/10-bit exigem decodificação pesada por software que sobrecarrega a CPU do RK3326. Ao converter vídeos no Handbrake ou ffmpeg, use o preset *Fast 480p30* ou *Fast 720p30*.
* **Para sair do vídeo:** Pressione **B** ou **SELECT** a qualquer instante para retornar imediatamente à lista.

### 🖼️ Fotos e Imagens
* **Resolução recomendada:** Imagens redimensionadas para **1080p** (1920×1080) ou **640×480**.
* **Dica:** Fotos tiradas diretamente de smartphones modernos (24 MP a 48 MP com 4000×6000 pixels) pesam dezenas de megabytes na memória descompactada (RGBA) do LÖVE, o que causa lentidão ao carregar. Imagens otimizadas abrem de forma instantânea.

### 🎵 Músicas e 📖 Livros
* Operam com **desempenho 100% fluido e consumo mínimo de bateria**, mesmo com o equalizador sonoro ou PDFs densos ativos.

---

## 🎮 Controles Rápidos

| Botão / Atalho | Ação Principal |
|---|---|
| **D-Pad** | Navegação em listas, menus, fotos e texto |
| **A** *(ou B no layout Xbox)* | Abrir pasta / Tocar faixa / Confirmar |
| **B** *(ou A no layout Xbox)* | Voltar de pasta / Retornar ao menu anterior / Sair de vídeo |
| **X** | Alternar Playlist de vídeo (em Vídeos) ou alternar tema no leitor de livros |
| **Y** | Alternar tamanho de fonte (em Livros) ou rotação 90° (em Fotos) |
| **START** | Tocar Playlist (em Vídeos) ou Play/Pause de música (na Home) |
| **SELECT** *(na Home)* | Abre o menu de Configurações |
| **SELECT + START** | **Sair imediatamente do Media Hub** (retorna ao EmulationStation) |
| **SELECT + X** | Alternar inversão de botões A/B |
| **SELECT + Y** | Ativar HUD de depuração |
| **L1 / R1** | Faixa anterior / próxima (ou saltar páginas/itens) |
| **L2 / R2** | Volume geral − / + (ou zoom em fotos / saltar 10 páginas em livros) |

---

## 📁 Pastas de Mídia no Cartão SD

Ao inicializar, o aplicativo procura mídias automaticamente nas seguintes pastas (no Cartão 1 `/roms` ou Cartão 2 `/roms2`):
* `music/` &rarr; Suas faixas e álbuns musicais. *(Também lê `/roms2/ports/gmu-music-player/music` automaticamente).*
* `photos/` &rarr; Fotos e imagens organizadas por pastas ou na raiz.
* `videos/` &rarr; Filmes, séries e clipes.
* `books/` &rarr; Livros e textos (PDF, EPUB, TXT).

*(Você também pode alterar e apontar qualquer diretório personalizado nas **Configurações** usando o Seletor de Pastas).*

---

## 🚀 Instalação Rápida e Automática

O script de instalação rápida detecta se o seu cartão SD possui o **PortMaster** e o **LÖVE 11.5** instalados. Caso não possua, ele **baixa e configura tudo automaticamente** direto no cartão SD!

1. Conecte o cartão SD do console no computador (exemplo: unidade `E:`).
2. Execute o comando de instalação no PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\deploy_to_sd.ps1 -Drive E:
   ```
   *O script valida o PortMaster, baixa o runtime LÖVE 11.5 se necessário, cria as pastas de mídia (`music`, `photos`, `videos`, `books`) e instala o Media Hub.*
3. Insira o cartão no console e acerte: **Ports** &rarr; **R36S Media Hub**.

> 💡 **Para quem não usa Windows:** você também pode baixar o `.zip` pronto na aba [Releases](https://github.com/brenobarroso/r36s-media-hub/releases) e extrair na pasta `ports/` do cartão SD. Consulte o [Manual Completo de Uso (MANUAL.md)](MANUAL.md).

---

## 🛠️ Desenvolvimento e Testes Automatizados no PC

O projeto pode ser executado diretamente no Windows ou Linux usando o LÖVE 11.5 padrão:

```powershell
# Executar a interface no PC:
lovec game

# Executar a suíte completa de testes automatizados com captura de telas:
powershell -ExecutionPolicy Bypass -File tools\selftest.ps1 -Love <caminho_lovec.exe> -Music <pasta_musicas>
```

---

## 📄 Licença

Distribuído sob a licença **MIT**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
