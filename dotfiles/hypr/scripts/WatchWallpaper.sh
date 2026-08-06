#!/usr/bin/env bash
# WatchWallpaper.sh — auto-sync the lock-screen blur and SDDM login background
# whenever the wallpaper changes (including direct `swww img` calls that skip
# the wallpaper scripts). Runs as a light daemon started from Startup_Apps.lua.
set -uo pipefail

SYNC="$HOME/.config/hypr/scripts/SyncSddmWallpaper.sh"

last=""
while true; do
    # Snapshot of the current per-monitor wallpaper paths from swww
    current="$(swww query 2>/dev/null | awk '/image:/{sub(/^.*image: /, ""); print}' | sort)"
    if [[ "$current" != "$last" ]]; then
        last="$current"
        sleep 1
        [[ -n "$current" ]] && "$SYNC" >/dev/null 2>&1 &
    fi
    sleep 3
done
