#!/usr/bin/env bash
# For applying Animations from different users
# Converts legacy .conf presets to UserAnimations.lua

if pidof rofi > /dev/null; then
  pkill rofi
fi

iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
animations_dir="$HOME/.config/hypr/animations"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
msg='Animation presets (legacy .conf → auto-converted to .lua)'

animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

chosen_file=$(echo "$animations_list" | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

if [[ -n "$chosen_file" ]]; then
    full_path="$animations_dir/$chosen_file.conf"
    lua_file="$UserConfigs/UserAnimations.lua"

    # Convert .conf animation preset to .lua format
    {
        echo "-- Converted from: $chosen_file.conf"
        echo "-- $(date)"
        echo ""

        # Extract bezier lines and convert
        grep -E "^\s*bezier\s*=" "$full_path" | while IFS= read -r line; do
            name=$(echo "$line" | sed 's/.*bezier\s*=\s*//;s/\s*,.*//' | tr -d ' ')
            points=$(echo "$line" | sed 's/.*bezier\s*=\s*[^,]*,\s*//;s/\s*$//' | tr -d ' ')
            x1=$(echo "$points" | cut -d',' -f1 | tr -d ' ')
            y1=$(echo "$points" | cut -d',' -f2 | tr -d ' ')
            x2=$(echo "$points" | cut -d',' -f3 | tr -d ' ')
            y2=$(echo "$points" | cut -d',' -f4 | tr -d ' ')
            echo "hl.curve(\"$name\", { type = \"bezier\", points = { {$x1, $y1}, {$x2, $y2} } })"
        done

        echo ""

        # Extract animation lines and convert
        grep -E "^\s*animation\s*=" "$full_path" | while IFS= read -r line; do
            content=$(echo "$line" | sed 's/.*animation\s*=\s*//;s/\s*$//')
            leaf=$(echo "$content" | cut -d',' -f1 | tr -d ' ')
            enabled=$(echo "$content" | cut -d',' -f2 | tr -d ' ')
            speed=$(echo "$content" | cut -d',' -f3 | tr -d ' ')
            bezier_name=$(echo "$content" | cut -d',' -f4 | tr -d ' ')
            style=$(echo "$content" | cut -d',' -f5 | tr -d ' ')

            # Build lua animation call
            args="leaf = \"$leaf\", enabled = true, speed = $speed"
            if [[ -n "$bezier_name" && "$bezier_name" != "default" ]]; then
                args="$args, bezier = \"$bezier_name\""
            fi
            if [[ -n "$style" ]]; then
                args="$args, style = \"$style\""
            fi
            echo "hl.animation({ $args })"
        done
    } > "$lua_file"

    notify-send -u low -i "$iDIR/note.png" "$chosen_file" "Animation preset applied (restart Hyprland to apply)"
fi

sleep 1
"$SCRIPTSDIR/RefreshNoWaybar.sh"
