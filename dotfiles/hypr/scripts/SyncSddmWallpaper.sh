#!/usr/bin/env bash
# Sync the FIRST monitor's wallpaper to the pixie SDDM login background
# and the blurred hyprlock background.
# Usage: SyncSddmWallpaper.sh [image_path]
#   [image_path] is only used as a fallback; the primary (first) monitor's
#   wallpaper is always preferred so login screens mirror the primary display.

set -euo pipefail

out="/usr/local/share/sddm/background.jpg"
blurred_out="$HOME/.config/hypr/wallpaper_effects/.wallpaper_blurred"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Only meaningful inside an active graphical session
{ [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; } || exit 0

# Resolve the primary (first) monitor's name
primary_monitor=""
if command -v hyprctl >/dev/null 2>&1; then
    if command -v jq >/dev/null 2>&1; then
        primary_monitor=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name // empty' 2>/dev/null)
    fi
    if [ -z "$primary_monitor" ]; then
        primary_monitor=$(hyprctl monitors 2>/dev/null | awk '/^Monitor/{print $2; exit}' | tr -d ':')
    fi
fi
[ -n "$primary_monitor" ] || primary_monitor="HDMI-A-1"

# Grab that monitor's current image from `swww query`
get_monitor_image() {
    swww query 2>/dev/null | awk -v mon="$primary_monitor" '
        /^: / { split($2, a, ":"); cur = a[1] }
        /^Monitor / { cur = $2; gsub(":", "", cur) }
        cur == mon && /image:/ { sub(/^.*image: /, ""); print; exit }
    '
}

src=""
for _ in {1..10}; do
    src="$(get_monitor_image || true)"
    if [ -n "$src" ] && [ -f "$src" ]; then
        break
    fi
    src=""
    sleep 0.1
done

# Fall back to the most recently applied wallpaper if the query failed
if [ -z "$src" ] || [ ! -f "$src" ]; then
    if [ -n "${1:-}" ] && [ -f "$1" ]; then
        src="$1"
    elif [ -f "$wallpaper_current" ]; then
        src="$wallpaper_current"
    fi
fi

[ -n "$src" ] && [ -f "$src" ] || exit 0

if command -v magick >/dev/null 2>&1; then
    magick "$src" -background black -alpha remove -alpha off \
        -resize 2560x1440^ -gravity center -extent 2560x1440 \
        -quality 90 "$out"
    magick "$src" -background black -alpha remove -alpha off \
        -resize 2560x1440^ -gravity center -extent 2560x1440 \
        -blur 0x35 "$blurred_out"
else
    cp -f "$src" "$out"
fi
