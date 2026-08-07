#!/usr/bin/env bash

# Hyprland startup script to reload waybar and check charging status

sleep 3

# Reload waybar via hyprctl
hyprctl reload waybar

# Check if waybar is running
if ! pgrep -x waybar > /dev/null; then
    echo "Waybar not running, starting..."
    waybar &
else
    echo "Waybar is running"
fi

# Check charging status and notify
check_battery_status() {
    for i in {0..3}; do
        if [ -f /sys/class/power_supply/BAT$i/status ]; then
            local status=$(cat /sys/class/power_supply/BAT$i/status)
            local capacity=$(cat /sys/class/power_supply/BAT$i/capacity)
            
            if [ "$status" = "Charging" ]; then
                echo "Charging: BAT$capacity%"
            elif [ "$status" = "Discharging" ]; then
                echo "Discharging: BAT$capacity%"
            fi
        fi
    done
}

check_battery_status
