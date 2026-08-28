#!/usr/bin/env bash
# grub-theme-sync.sh - Sync the current wallpaper + Material You palette to the
# GRUB theme (background image + menu colors) for the 'dedsec' theme.
# Runs as root (see /etc/sudoers.d/grub-theme-sync).
# Usage: sudo -n /usr/local/bin/grub-theme-sync.sh [wallpaper_path]
set -uo pipefail

THEME_DIR="/boot/grub/themes/dedsec"
RES="1920x1080"

# Resolve the real user (this script runs via sudo)
USER_HOME="${SUDO_USER:+$(getent passwd "$SUDO_USER" | cut -d: -f6)}"
[ -n "$USER_HOME" ] || USER_HOME="$HOME"

# --- 1. Determine the wallpaper to use (niri/iNiR state) ---
STATE_DIR="${XDG_STATE_HOME:-$USER_HOME/.local/state}/quickshell/user/generated"
WALLPAPER_STATE="$STATE_DIR/wallpaper/path.txt"
CONFIG_JSON="${XDG_CONFIG_HOME:-$USER_HOME/.config}/inir/config.json"

src="${1:-}"
if [ -z "$src" ] || [ ! -f "$src" ]; then
    # iNiR records the set wallpaper path here
    if [ -f "$WALLPAPER_STATE" ]; then
        src="$(cat "$WALLPAPER_STATE")"
        src="${src#file://}"
    fi
    # Fallback: read from iNiR config.json
    if [ -z "$src" ] || [ ! -f "$src" ]; then
        if command -v jq >/dev/null 2>&1 && [ -f "$CONFIG_JSON" ]; then
            src="$(jq -r '.background.wallpaperPath // empty' "$CONFIG_JSON" 2>/dev/null)"
            src="${src#file://}"
        fi
    fi
fi
if [ -z "$src" ] || [ ! -f "$src" ]; then
    echo "no wallpaper found" >&2
    exit 0
fi

# --- 2. Pull colors from the iNiR Material You palette (JSON) ---
palette_json="$(ls "$STATE_DIR"/app-palette.json "$STATE_DIR"/palette.json "$STATE_DIR"/colors.json 2>/dev/null | head -n1)"
getc() { # getc <varname> -> #rrggbb or empty
    [ -n "$palette_json" ] || return 0
    python3 - "$palette_json" "$1" <<'PY'
import json,sys
try:
    d=json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
if "colors" in d and isinstance(d["colors"],dict):
    dk=d["colors"].get("dark",{})
    v=dk.get(sys.argv[2]) or dk.get("app_"+sys.argv[2])
else:
    v=d.get(sys.argv[2]) or d.get("app_"+sys.argv[2])
if v is None:
    v=d.get("app_"+sys.argv[2])
if isinstance(v,dict):
    v=v.get("hex") or v.get("default",{}).get("hex")
import re
m=re.search(r'([0-9A-Fa-f]{6})',str(v) if v is not None else "")
print("#"+m.group(1).upper() if m else "")
PY
}
background="$(getc background)";      [ -n "$background" ] || background="#141218"
foreground="$(getc on_background)";   [ -n "$foreground" ] || foreground="#D8D0E8"
accent="$(getc primary)";             [ -n "$accent" ] || accent="#C8B8D8"
[ -n "$accent" ] || accent="$(getc app_accent)"
[ -n "$accent" ] || accent="#C8B8D8"
[ -n "$foreground" ] || foreground="#D8D0E8"
[ -n "$background" ] || background="#141218"

mix() { # mix <#a> <#b> -> 50/50 blend
    printf '#%02X%02X%02X' \
        "$(( (16#${1:1:2} + 16#${2:1:2}) / 2 ))" \
        "$(( (16#${1:3:2} + 16#${2:3:2}) / 2 ))" \
        "$(( (16#${1:5:2} + 16#${2:5:2}) / 2 ))"
}
item_color="$(mix "$foreground" "$background")"

# --- 3. Build the background image ---
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if command -v magick >/dev/null 2>&1; then
    # first frame if animated (gif/webp)
    if [[ "$src" =~ \.(gif|mng)$ ]]; then src="${src}[0]"; fi
    magick "$src" -background black -alpha remove -alpha off \
        -resize "${RES}^" -gravity center -extent "$RES" -strip \
        -define png:compression-level=9 "$tmp/background.png"
else
    cp -f "$src" "$tmp/background.png"
fi

# --- 4. Generate theme.txt with palette colors ---
cat > "$tmp/theme.txt" << EOF
# GRUB theme - synced from wallpaper + Material You palette

desktop-image: "background.png"
title-text: ""
terminal-font: "Hack Bold 22"
terminal-left: "20%"
terminal-top: "35%"
terminal-width: "60%"
terminal-height: "40%"
terminal-box: "menu_bkg_*.png"

+ boot_menu {
    menu_pixmap_style = "boot_menu_*.png"
    left = 20%
    width = 60%
    top = 30%
    height = 40%
    item_font = "Norwester Regular 28"
    item_color = "${item_color}"
    selected_item_font = "Norwester Regular 30"
    selected_item_color = "${accent}"
    icon_width = 48
    icon_height = 48
    item_icon_space = 24
    item_height = 56
    item_padding = 8
    item_spacing = 16
    selected_item_pixmap_style = "select_*.png"
    scrollbar = true
    scrollbar_width = 10
    scrollbar_thumb = "slider_*.png"
}

+ progress_bar {
    id = "__timeout__"
    left = 25%
    width = 50%
    top = 75%
    height = 20
    text = ""
    text_color = "${foreground}"
    font = "Norwester Regular 24"
    bar_style = "progress_bar_*.png"
    highlight_style = "progress_highlight_*.png"
}
EOF

# --- 5. Deploy (root-owned) ---
mkdir -p "$THEME_DIR"
cp -f "$tmp/background.png" "$THEME_DIR/background.png"
cp -f "$tmp/theme.txt" "$THEME_DIR/theme.txt"
chown root:root "$THEME_DIR/background.png" "$THEME_DIR/theme.txt"

echo "GRUB theme synced from: $src"
