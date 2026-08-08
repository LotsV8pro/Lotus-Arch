#!/bin/bash
# Launch Soulframe with a GE-Proton build
# Edit the PROTON / GAME / WINEPREFIX variables to match your setup.

PROTON="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton11-3/proton"
GAME="$HOME/Games/Soulframe/Downloaded/Public/Soulframe.x64.exe"
WINEPREFIX="$HOME/Games/Soulframe/pfx"

if [ ! -d "$WINEPREFIX" ]; then
    mkdir -p "$WINEPREFIX"
fi

export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="$WINEPREFIX"

"$PROTON" run "$GAME"
