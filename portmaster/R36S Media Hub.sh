#!/bin/bash
# R36S Media Hub - PortMaster launcher (LÖVE 11.5 runtime)
#
# Install: copy "R36S Media Hub.sh" and the "r36smusic" folder into the
# "ports" folder of your SD card (e.g. /roms/ports or /roms2/ports), then
# restart EmulationStation. It shows up in the Ports list.

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -n "$directory" ] && [ -d "/$directory/ports/r36smusic" ]; then
  GAMEDIR="/$directory/ports/r36smusic"
else
  GAMEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/r36smusic"
fi

# Detect PortMaster control folder across internal and SD card paths
if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
elif [ -d "/roms2/tools/PortMaster/" ]; then
  controlfolder="/roms2/tools/PortMaster"
elif [ -d "/roms/tools/PortMaster/" ]; then
  controlfolder="/roms/tools/PortMaster"
elif [ -d "/roms2/ports/PortMaster/" ]; then
  controlfolder="/roms2/ports/PortMaster"
elif [ -d "/roms/ports/PortMaster/" ]; then
  controlfolder="/roms/ports/PortMaster"
elif [ -d "$GAMEDIR/../PortMaster/" ]; then
  controlfolder="$GAMEDIR/../PortMaster"
elif [ -d "$GAMEDIR/../../tools/PortMaster/" ]; then
  controlfolder="$GAMEDIR/../../tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

if [ -f "$controlfolder/control.txt" ]; then
  source "$controlfolder/control.txt"
  get_controls
  [ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
fi

# Keep LÖVE's save data (state.txt) inside the port folder.
export XDG_DATA_HOME="$GAMEDIR/saves"
export XDG_CONFIG_HOME="$GAMEDIR/saves"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"

# Detect which SD card this port is installed on (/roms or /roms2)
SD_ROOT="$(cd "$GAMEDIR/../.." 2>/dev/null && pwd)"
if [ -d "$SD_ROOT" ] && [ "$SD_ROOT" != "/" ]; then
  mkdir -p "$SD_ROOT/music" "$SD_ROOT/photos" "$SD_ROOT/videos" "$SD_ROOT/books" 2>/dev/null
fi

# Clean up any dummy empty directories accidentally created on rootfs /roms2
if [ -d "/roms2" ] && ! grep -qs '/roms2 ' /proc/mounts; then
  rmdir /roms2/photos /roms2/videos /roms2/books /roms2/music 2>/dev/null
fi

cd "$GAMEDIR" || exit 1

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Locate LÖVE 11.5 runtime (PortMaster, local fallback, or relative SD path)
LOVE_TXT=""
if [ -f "$controlfolder/runtimes/love_11.5/love.txt" ]; then
  LOVE_TXT="$controlfolder/runtimes/love_11.5/love.txt"
elif [ -f "$controlfolder/runtimes/love_11.5.txt" ]; then
  LOVE_TXT="$controlfolder/runtimes/love_11.5.txt"
elif [ -f "$GAMEDIR/runtimes/love_11.5/love.txt" ]; then
  LOVE_TXT="$GAMEDIR/runtimes/love_11.5/love.txt"
elif [ -f "$GAMEDIR/../PortMaster/runtimes/love_11.5/love.txt" ]; then
  LOVE_TXT="$GAMEDIR/../PortMaster/runtimes/love_11.5/love.txt"
elif [ -f "$GAMEDIR/../../tools/PortMaster/runtimes/love_11.5/love.txt" ]; then
  LOVE_TXT="$GAMEDIR/../../tools/PortMaster/runtimes/love_11.5/love.txt"
fi

# If runtime is missing, attempt auto-download via harbourmaster if available
if [ -z "$LOVE_TXT" ] || [ ! -f "$LOVE_TXT" ]; then
  if [ -f "$controlfolder/harbourmaster" ]; then
    echo "Baixando runtime love_11.5 via PortMaster..." > /dev/tty0 2>/dev/null
    $ESUDO "$controlfolder/harbourmaster" --quiet --no-check runtime_check "love_11.5"
    if [ -f "$controlfolder/runtimes/love_11.5/love.txt" ]; then
      LOVE_TXT="$controlfolder/runtimes/love_11.5/love.txt"
    fi
  fi
fi

# Fallback error message if runtime is still missing
if [ -z "$LOVE_TXT" ] || [ ! -f "$LOVE_TXT" ]; then
  echo "ERRO: Runtime love_11.5 nao encontrado!" > /dev/tty0 2>/dev/null
  echo "Execute o script deploy_to_sd.ps1 no PC para instalar automaticamente." > /dev/tty0 2>/dev/null
  sleep 5
  exit 1
fi

source "$LOVE_TXT"

export R36S_FULLSCREEN=1

pm_platform_helper "$LOVE_BINARY"

GPTK_CONF="${LOVE_GPTK}"
if [ -z "$GPTK_CONF" ] || [ ! -f "$GPTK_CONF" ]; then
  GPTK_CONF="$GAMEDIR/r36smusic.gptk"
fi

if [ -n "$GPTOKEYB" ]; then
  $GPTOKEYB "$GPTK_CONF" &
fi
$LOVE_RUN "$GAMEDIR/game"

pm_finish
