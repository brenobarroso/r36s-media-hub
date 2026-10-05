# R36S Music Player

Player de música (MP3) para o R36S (dArkOS/ArkOS) feito em **LÖVE 11.5** e empacotado como **PortMaster**.

## Funcionalidades (v0.1)
- Navegador de pastas (pastas primeiro, ordem natural; só mostra mp3/ogg/flac/wav)
- Tela **Tocando agora**: capa (embutida no ID3 ou `cover.jpg`/`folder.jpg`), título/artista/álbum, progresso, volume, shuffle/repeat
- Fila automática da pasta, próxima faixa automática, shuffle, repeat (off/todas/uma)
- Continua tocando enquanto você navega nas pastas (mini player no rodapé)
- Lembra última pasta, volume, shuffle e repeat

## Controles
| Botão | Navegador | Tocando agora |
|---|---|---|
| D-pad ↑↓ | mover | volume |
| D-pad ←→ | página ↑↓ | buscar ∓5 s |
| A | abrir pasta / tocar | play/pause |
| B | voltar | voltar ao navegador |
| X | ir para "Tocando" | shuffle |
| Y | tocar pasta (recursivo) | repeat |
| L1 / R1 | faixa anterior / próxima (global) | idem |
| L2 / R2 | volume −/+ (global) | idem |
| START | play/pause (global) | idem |
| **SELECT+START** | sair | sair |
| SELECT+X | trocar A/B (se o layout vier invertido) | |
| SELECT+Y | overlay de debug (botões, joystick) | |

> Se A/B vierem trocados no seu aparelho, use **SELECT+X** (fica salvo).

## Pasta de músicas
Ordem de busca: variável `R36S_MUSIC_DIR` → primeira linha de `music_dir.txt` (dentro de `ports/r36smusic/`) →
`/roms2/music`, `/roms/music`, `/roms2/bgmusic`, `/roms/bgmusic`, `~/Music`, `/roms`.

## Instalar no R36S
1. `powershell -File tools\package.ps1` → gera `dist\r36s-music-player.zip`
2. Extraia na pasta `ports` do cartão SD (`/roms/ports` ou `/roms2/ports`), de forma que fiquem
   `ports/R36S Music Player.sh` e `ports/r36smusic/game/...`
3. Reinicie o EmulationStation → Ports → **R36S Music Player**
4. Requer o PortMaster instalado com o runtime `love_11.5` (o PortMaster baixa sozinho).

## Desenvolver no PC (Windows)
```powershell
# precisa do LÖVE 11.5 (https://love2d.org)
$env:R36S_MUSIC_DIR = "C:/Users/voce/Music"
love game
```
- Teclado: setas, Enter (A), Backspace (B), X, Y, Q/E (L1/R1), A/D (L2/R2), Espaço (Start), Tab (Select).
- Em Windows, caminhos com acentos não abrem via `io.open` (limitação do Windows/LuaJIT). No Linux/R36S não há problema.
- Smoke test automatizado: `tools\selftest.ps1 -Love <lovec.exe> -Music <pasta>` (toca, busca, pausa, tira screenshots).

## Estrutura
```
game/            projeto LÖVE (main.lua, conf.lua, src/, assets/)
portmaster/      launcher .sh do PortMaster
tools/           package.ps1, selftest.ps1
```

## Pendências / ideias
- Validar o launcher e o mapeamento de botões no aparelho real
- Gapless, apagar a tela durante a reprodução (backlight), playlists/favoritos, busca
