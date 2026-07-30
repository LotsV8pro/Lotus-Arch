#!/bin/bash
# Dynamic NVIDIA fan curve based on GPU temperature
# Requires Coolbits=4 or higher in X config

INTERVAL=5
GPU=0
DISPLAY=${DISPLAY:-:1}

# Apply core OC (needs display + root — service runs as root)
/usr/bin/nvidia-settings -c "$DISPLAY" -a "[gpu:${GPU}]/GPUGraphicsClockOffsetAllPerformanceLevels=130" > /dev/null 2>&1

enable_fan_control() {
    /usr/bin/nvidia-settings -c "$DISPLAY" -a "[gpu:${GPU}]/GPUFanControlState=1" > /dev/null 2>&1
}

set_fan_speed() {
    /usr/bin/nvidia-settings -c "$DISPLAY" -a "[gpu:${GPU}]/GPUTargetFanSpeed=$1" > /dev/null 2>&1
}

get_temp() {
    /usr/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader -i "$GPU"
}

fan_curve() {
    local temp=$1
    if   [ "$temp" -lt 45 ]; then echo 30
    elif [ "$temp" -lt 55 ]; then echo 40
    elif [ "$temp" -lt 65 ]; then echo 50
    elif [ "$temp" -lt 70 ]; then echo 60
    elif [ "$temp" -lt 75 ]; then echo 70
    elif [ "$temp" -lt 80 ]; then echo 85
    else                         echo 100
    fi
}

enable_fan_control

while true; do
    temp=$(get_temp)
    speed=$(fan_curve "$temp")
    set_fan_speed "$speed"
    sleep "$INTERVAL"
done
