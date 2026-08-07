#!/bin/bash
# Launch Soulframe with GE-Proton11-3
PROTON="/home/lots/.local/share/Steam/compatibilitytools.d/GE-Proton11-3/proton"
GAME="/home/lots/Games/Soulframe/Downloaded/Public/Soulframe.x64.exe"
WINEPREFIX="/home/lots/Games/Soulframe/pfx"

if [ ! -d "$WINEPREFIX" ]; then
    mkdir -p "$WINEPREFIX"
fi

export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/lots/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="$WINEPREFIX"

"$PROTON" run "$GAME"
