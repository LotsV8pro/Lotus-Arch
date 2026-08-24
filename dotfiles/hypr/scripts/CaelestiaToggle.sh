#!/usr/bin/env bash
# Toggle between the Caelestia shell and the classic setup (waybar + swaync + qs overview)

if qs list --all 2> /dev/null | grep -q 'caelestia/shell.qml'; then
    # Caelestia -> classic
    caelestia shell -k 2> /dev/null
    sleep 0.5
    pgrep -x waybar > /dev/null || { waybar > /dev/null 2>&1 & disown; }
    pgrep -x swaync > /dev/null || { swaync > /dev/null 2>&1 & disown; }
    qs list --all 2> /dev/null | grep -q 'overview/shell.qml' || { qs -c overview > /dev/null 2>&1 & disown; }
else
    # Classic -> Caelestia (keep qs overview running; SUPER+A uses it)
    pkill -x waybar 2> /dev/null
    pkill -x swaync 2> /dev/null
    sleep 0.3
    caelestia shell -d > /dev/null 2>&1
fi
