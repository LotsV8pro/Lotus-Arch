#!/usr/bin/env bash
set -euo pipefail

monitor_ctl() {
    case "$1" in
        get) ddcutil getvcp 10 --noverify --display "$2" 2>/dev/null | grep -oE 'value = +[0-9]+' | grep -oE '[0-9]+' | head -1 ;;
        set) ddcutil setvcp 10 "$3" --noverify --display "$2" >/dev/null 2>&1 ;;
    esac
}

DISPLAYS=(1 2)

get_brightness() {
    local total=0 cnt=0
    for d in "${DISPLAYS[@]}"; do
        local v
        v=$(monitor_ctl get "$d") || continue
        total=$((total + v)); cnt=$((cnt + 1))
    done
    if (( cnt == 0 )); then
        echo "100"
        return 1
    fi
    echo $(( total / cnt ))
}

set_brightness() {
    local target="$1"
    if [[ "$target" =~ ^([0-9]+)%([+-])$ ]]; then
        local step="${BASH_REMATCH[1]}" op="${BASH_REMATCH[2]}"
        local cur
        cur=$(get_brightness)
        if [[ "$op" == "+" ]]; then
            target=$((cur + step))
        else
            target=$((cur - step))
        fi
        (( target > 100 )) && target=100
        (( target < 10 )) && target=10
    elif [[ "$target" =~ ^[0-9]+%?$ ]]; then
        target="${target//%/}"
    fi
    for d in "${DISPLAYS[@]}"; do
        monitor_ctl set "$d" "$target"
    done
}

if [[ "${1:-}" == "get" ]]; then
    printf '{"text": "%s", "percentage": %s, "tooltip": "Brightness: %s%%"}\n' "$(get_brightness)" "$(get_brightness)" "$(get_brightness)"
elif [[ "${1:-}" == "raw" ]]; then
    get_brightness
elif [[ "${1:-}" =~ ^[0-9]+%?$ || "${1:-}" =~ ^[0-9]+%[+-]$ ]]; then
    set_brightness "$1"
    printf '{"text": "%s", "percentage": %s, "tooltip": "Brightness: %s%%"}\n' "$(get_brightness)" "$(get_brightness)" "$(get_brightness)"
else
    get_brightness
fi