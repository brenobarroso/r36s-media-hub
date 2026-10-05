#!/bin/bash
# R36S Music Player - PortMaster launcher (LÖVE 11.5 runtime)
#
# Install: copy "R36S Music Player.sh" and the "r36smusic" folder into the
# "ports" folder of your SD card (e.g. /roms/ports or /roms2/ports), then
# restart EmulationStation. It shows up in the Ports list.

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt"

get_controls
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

GAMEDIR="/$directory/ports/r36smusic"

# Keep LÖVE's save data (state.txt) inside the port folder.
export XDG_DATA_HOME="$GAMEDIR/saves"
export XDG_CONFIG_HOME="$GAMEDIR/saves"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"

cd "$GAMEDIR" || exit 1

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Provides $LOVE_BINARY, $LOVE_RUN and $LOVE_GPTK (and mounts the runtime).
source "$controlfolder/runtimes/love_11.5/love.txt"

# Optional: put a music folder path in $GAMEDIR/music_dir.txt (first line),
# or export R36S_MUSIC_DIR here. Defaults: /roms2/music, /roms/music, ...
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
