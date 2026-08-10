#!/usr/bin/env bash
# wlogout (Power, Screen Lock, Suspend, etc)

# Set variables for parameters. First numbers corresponts to Monitor Resolution
# i.e 2160 means 2160p
A_2160=600
B_2160=600
A_1600=400
B_1600=400
A_1440=400
B_1440=400
A_1080=200
B_1080=200
A_720=50
B_720=50

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Detect the monitor where the menu was opened (under the cursor) and its resolution/scale
read cx cy <<<"$(hyprctl cursorpos | tr -d ',')"
monitors_json=$(hyprctl -j monitors)
target_mon=$(printf '%s' "$monitors_json" | jq -r --argjson x "$cx" --argjson y "$cy" '
    (first(.[] | select(.x <= $x and $x < (.x + .width) and .y <= $y and $y < (.y + .height))) | .name)
    // (first(.[] | select(.focused == true)) | .name)')
target_idx=$(printf '%s' "$monitors_json" | jq -r --arg m "$target_mon" 'map(.name) | index($m)')
resolution=$(printf '%s' "$monitors_json" | jq -r --arg m "$target_mon" '.[] | select(.name==$m) | .height / .scale' | awk -F'.' '{print $1}')
hypr_scale=$(printf '%s' "$monitors_json" | jq -r --arg m "$target_mon" '.[] | select(.name==$m) | .scale')

# Set parameters based on screen resolution and scaling factor
if ((resolution >= 2160)); then
    T_val=$(awk "BEGIN {printf \"%.0f\", $A_2160 * 2160 * $hypr_scale / $resolution}")
    B_val=$(awk "BEGIN {printf \"%.0f\", $B_2160 * 2160 * $hypr_scale / $resolution}")
    echo "Setting parameters for resolution >= 4k"
elif ((resolution >= 1600 && resolution < 2160)); then
    T_val=$(awk "BEGIN {printf \"%.0f\", $A_1600 * 1600 * $hypr_scale / $resolution}")
    B_val=$(awk "BEGIN {printf \"%.0f\", $B_1600 * 1600 * $hypr_scale / $resolution}")
    echo "Setting parameters for resolution >= 2.5k and < 4k"
elif ((resolution >= 1440 && resolution < 1600)); then
    T_val=$(awk "BEGIN {printf \"%.0f\", $A_1440 * 1440 * $hypr_scale / $resolution}")
    B_val=$(awk "BEGIN {printf \"%.0f\", $B_1440 * 1440 * $hypr_scale / $resolution}")
    echo "Setting parameters for resolution >= 2k and < 2.5k"
elif ((resolution >= 1080 && resolution < 1440)); then
    T_val=$(awk "BEGIN {printf \"%.0f\", $A_1080 * 1080 * $hypr_scale / $resolution}")
    B_val=$(awk "BEGIN {printf \"%.0f\", $B_1080 * 1080 * $hypr_scale / $resolution}")
    echo "Setting parameters for resolution >= 1080p and < 2k"
elif ((resolution >= 720 && resolution < 1080)); then
    T_val=$(awk "BEGIN {printf \"%.0f\", $A_720 * 720 * $hypr_scale / $resolution}")
    B_val=$(awk "BEGIN {printf \"%.0f\", $B_720 * 720 * $hypr_scale / $resolution}")
    echo "Setting parameters for resolution >= 720p and < 1080p"
else
    T_val=0
    B_val=0
fi

GLASS_CSS="$HOME/.config/wlogout/style-glass.css"
GLASS_LAYOUT="$HOME/.config/wlogout/layout-glass"
MAIN_CSS="$HOME/.config/wlogout/style.css"

# Scale the button CSS down so the grid fits the target monitor width
# (the natural grid width ~2272px overflows 1080p screens otherwise)
CSS_ARG="-C $MAIN_CSS"
if (( resolution < 1440 )); then
    css_factor=$(awk "BEGIN { printf \"%.4f\", $resolution / 1440 }")
    SCALED_CSS="$HOME/.config/wlogout/style-${resolution}p.css"
    perl -pe 's/(\d+)px/sprintf("%.0f", $1 * '"$css_factor"') . "px"/ge' "$MAIN_CSS" > "$SCALED_CSS"
    CSS_ARG="-C $SCALED_CSS"
    L_val=$(awk "BEGIN { printf \"%.0f\", 230 * $css_factor }")
    R_val="$L_val"
else
    L_val=230
    R_val=230
fi

# Buttons + HyprGlass on the monitor where the menu was opened
wlogout --protocol layer-shell -b 6 -n -P "$target_idx" -T "$T_val" -B "$B_val" -L "$L_val" -R "$R_val" $CSS_ARG &
buttons_pid=$!

# Glass-only layer on every other monitor (no buttons)
glass_pids=()
for idx in $(printf '%s' "$monitors_json" | jq -r 'keys[]'); do
    [[ "$idx" == "$target_idx" ]] && continue
    wlogout --protocol layer-shell -b 6 -n -P "$idx" -C "$GLASS_CSS" -l "$GLASS_LAYOUT" &
    glass_pids+=("$!")
done

# Watchdog: dismissing the menu on any monitor must close every instance,
# otherwise the HyprGlass effect lingers on the other screens
if (( ${#glass_pids[@]} == 0 )); then
    wait "$buttons_pid"
    exit 0
fi

while :; do
    if ! kill -0 "$buttons_pid" 2>/dev/null; then
        pkill -x wlogout
        break
    fi
    for p in "${glass_pids[@]}"; do
        if ! kill -0 "$p" 2>/dev/null; then
            pkill -x wlogout
            exit 0
        fi
    done
    sleep 0.25
done
