#!/usr/bin/env bash
# Game Mode. Toggles visuals + CPU/GPU performance

notif="$HOME/.config/swaync/images/note.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = "true" ] || [ "$HYPRGAMEMODE" = "1" ] ; then
    # === ENABLE GAMEMODE ===
    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = {
            shadow = { enabled = false },
            blur = { enabled = false },
            rounding = 0
        },
        general = {
            gaps_in = 0,
            gaps_out = 0,
            border_size = 1
        }
    })' 2>/dev/null
    swww kill

    nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1" 2>/dev/null

    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    exit
else
    # === DISABLE GAMEMODE ===
    swww-daemon --format xrgb && swww img "$HOME/.config/rofi/.current_wallpaper" &
    sleep 0.1
    ${SCRIPTSDIR}/WallustSwww.sh
    sleep 0.5
    ${SCRIPTSDIR}/ReloadConfig.sh
    ${SCRIPTSDIR}/Refresh.sh
    nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0" 2>/dev/null

    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
