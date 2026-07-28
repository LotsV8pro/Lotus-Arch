#!/usr/bin/env bash
# ROG Raikiri / Xbox Guide Button → Steam Big Picture

STEAM_BP="steam://open/bigpicture"

find_controller() {
    local dev name handler_line
    for dev in $(ls /dev/input/event* 2>/dev/null | sort -V -r); do
        local bname
        bname=$(basename "$dev")
        handler_line=$(grep "H:.*Handlers=" /proc/bus/input/devices 2>/dev/null | grep -E "(^| )${bname}( |\$)")
        [ -z "$handler_line" ] && continue
        name=$(grep -B10 -F "$handler_line" /proc/bus/input/devices 2>/dev/null | grep "N: Name" | sed 's/N: Name="//;s/"//')
        if echo "$name" | grep -qi "ROG\|RAIKIRI\|Xbox\|Microsoft\|gamepad\|controller\|x360\|xinput\|ASUS"; then
            DEVICE="$dev"
            CONTROLLER_NAME="$name"
            return 0
        fi
    done
    return 1
}

if ! find_controller; then
    echo "No controller found. Waiting for one..."
    while true; do
        inotifywait -q /dev/input -e create 2>/dev/null
        if find_controller; then
            break
        fi
    done
fi

echo "Found: $CONTROLLER_NAME on $DEVICE"
echo "Listening for Guide button..."

evtest "$DEVICE" 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -q "EV_KEY" && echo "$line" | grep -q "value 1"; then
        if echo "$line" | grep -qE "BTN_MODE|BTN_TRIGGER_GUIDE|BTN_TRIGGER_HOMEX|BTN_HOME|code 316|code 314|code 305"; then
            # Debounce: skip if Steam was opened in last 2 seconds
            now=$(date +%s)
            if [ -n "$LAST_PRESS" ] && [ $((now - LAST_PRESS)) -lt 2 ]; then
                continue
            fi
            LAST_PRESS=$now

            if pgrep -f "bigpicture" >/dev/null 2>&1; then
                continue
            fi
            if pgrep -x steam >/dev/null 2>&1; then
                xdg-open "$STEAM_BP" 2>/dev/null &
            else
                steam -bigpicture &>/dev/null &
            fi
            echo "$(date): Guide button pressed → Steam Big Picture"
        fi
    fi
done
