#!/usr/bin/env bash
# Game Mode. Toggles visuals + CPU/GPU performance

notif="$HOME/.config/swaync/images/note.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    # === ENABLE GAMEMODE ===
    # Visual optimizations
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    swww kill

    # CPU/GPU performance
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance | sudo tee "$cpu" > /dev/null 2>&1
    done
    nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1" 2>/dev/null

    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    sleep 0.1
    exit
else
    # === DISABLE GAMEMODE ===
    # Restore visuals
    swww-daemon --format xrgb && swww img "$HOME/.config/rofi/.current_wallpaper" &
    sleep 0.1
    ${SCRIPTSDIR}/WallustSwww.sh
    sleep 0.5
    hyprctl reload
    ${SCRIPTSDIR}/Refresh.sh

    # Restore powersave governor
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo powersave | sudo tee "$cpu" > /dev/null 2>&1
    done
    nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0" 2>/dev/null

    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
