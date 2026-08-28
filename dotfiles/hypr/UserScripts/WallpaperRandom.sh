#!/usr/bin/env bash
# Script for Random Wallpaper ( CTRL ALT W)

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.pnm" -o -name "*.tga" -o -name "*.tiff" -o -name "*.webp" -o -name "*.bmp" -o -name "*.farbfeld" -o -name "*.gif" \) -print0 2>/dev/null)

# Guard: no wallpapers found → tell the user instead of doing nothing.
if [[ ${#PICS[@]} -eq 0 ]]; then
    notify-send -i "$HOME/.config/swaync/images/error.png" "No wallpapers" "No wallpapers found in $wallDIR"
    exit 1
fi

RANDOMPICS="${PICS[$((RANDOM % ${#PICS[@]}))]}"

# Guard: only set a wallpaper that actually exists and is non-empty.
if [[ ! -f "$RANDOMPICS" || ! -s "$RANDOMPICS" ]]; then
    notify-send -i "$HOME/.config/swaync/images/error.png" "Invalid wallpaper" "Picked file is missing or empty: $RANDOMPICS"
    exit 1
fi


# Transition config
FPS=30
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"


swww query || swww-daemon --format xrgb && swww img -o "$focused_monitor" "$RANDOMPICS" $SWWW_PARAMS

wait $!
"$SCRIPTSDIR/WallustSwww.sh" &&

wait $!
sleep 2
"$SCRIPTSDIR/Refresh.sh"

