#!/bin/bash
# Dynamic AMD GPU fan curve based on temperature (hwmon sysfs)

INTERVAL=5

# Locate the amdgpu hwmon device exposing fan control
HWMON=""
for d in /sys/class/drm/card*/device/hwmon/hwmon*; do
    [ -d "$d" ] || continue
    [ -f "$d/fan1_input" ] || continue
    if grep -q "amdgpu" "$d/name" 2>/dev/null; then
        HWMON="$d"
        break
    fi
done

[ -n "$HWMON" ] || exit 0

PWM_MAX=$(cat "$HWMON/pwm1_max" 2>/dev/null || echo 255)
PWM_ENABLE="$(cat "$HWMON/pwm1_enable" 2>/dev/null || echo 0)"

fan_curve_pct() {
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

# Enable manual fan control (1 = manual, some cards need 2)
if [ "$PWM_ENABLE" != "1" ]; then
    echo 1 > "$HWMON/pwm1_enable" 2>/dev/null || echo 2 > "$HWMON/pwm1_enable" 2>/dev/null
fi

while true; do
    temp=$(cat "$HWMON/temp1_input" 2>/dev/null)
    temp=$(( temp / 1000 ))
    pct=$(fan_curve_pct "$temp")
    pwm=$(( pct * PWM_MAX / 100 ))
    echo "$pwm" > "$HWMON/pwm1" 2>/dev/null
    sleep "$INTERVAL"
done
