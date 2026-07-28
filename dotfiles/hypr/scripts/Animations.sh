#!/usr/bin/env bash
# For applying Animations from different users
# NOTE: Animation presets are in legacy .conf format
# They are copied to UserAnimations.conf as a reference
# The active lua config is UserAnimations.lua

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Variables
iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
animations_dir="$HOME/.config/hypr/animations"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
msg='❗NOTE:❗ Animation presets are in legacy .conf format. Active config is UserAnimations.lua'
# list of animation files, sorted alphabetically with numbers first
animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

# Rofi Menu
chosen_file=$(echo "$animations_list" | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

# Check if a file was selected
if [[ -n "$chosen_file" ]]; then
    full_path="$animations_dir/$chosen_file.conf"    
    cp "$full_path" "$UserConfigs/UserAnimations.conf"    
    notify-send -u low -i "$iDIR/note.png" "$chosen_file" "Animation preset saved (restart Hyprland to apply)"
fi

sleep 1
"$SCRIPTSDIR/RefreshNoWaybar.sh"
