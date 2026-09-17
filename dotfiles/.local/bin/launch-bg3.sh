#!/bin/bash
cd "$HOME/Games/Baldurs Gate 3/bin" || exit 1
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="$HOME/.local/share/Steam/steamapps/compatdata/3081823252"
export SteamOS=1
export NVPRESENT_ENABLE_SMOOTH_MOTION=1
export NVPRESENT_QUEUE_FAMILY=1
export __GL_SHADER_DISK_CACHE_SIZE=2147483648
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
exec mangohud "$HOME/.local/share/Steam/steamapps/common/Proton - Experimental/proton" run "./bg3.exe"
