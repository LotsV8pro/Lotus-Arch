#!/usr/bin/env bash
# grub-theme-sync.sh - Sync the current wallpaper + wallust palette to the
# GRUB theme (background image + menu colors).
# Runs as root (see /etc/sudoers.d/grub-theme-sync).
# Usage: sudo -n /usr/local/bin/grub-theme-sync.sh [wallpaper_path]
set -uo pipefail

THEME_DIR="/boot/grub/themes/dedsec"
RES="1920x1080"

# Resolve the real user (this script runs via sudo)
USER_HOME="${SUDO_USER:+$(getent passwd "$SUDO_USER" | cut -d: -f6)}"
[ -n "$USER_HOME" ] || USER_HOME="$HOME"
wallpaper_current="$USER_HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# --- 1. Determine the wallpaper to use ---
src="${1:-}"
if [ -z "$src" ] || [ ! -f "$src" ]; then
    if [ -n "${SUDO_USER:-}" ] && command -v swww >/dev/null 2>&1; then
        src="$(sudo -u "$SUDO_USER" swww query 2>/dev/null | awk '/image:/{sub(/^.*image: /,""); print; exit}')"
    fi
fi
if [ -z "$src" ] || [ ! -f "$src" ]; then
    src="$wallpaper_current"
fi
[ -n "$src" ] && [ -f "$src" ] || { echo "no wallpaper found"; exit 0; }

# --- 2. Pull colors from the wallust palette ---
palette="$USER_HOME/.config/hypr/wallust/wallust-hyprland.conf"
getc() { # getc <varname> -> #rrggbb
    local v
    v="$(grep "^\$$1 *=" "$palette" 2>/dev/null | head -n1 | sed -n 's/.*rgb(\([0-9A-Fa-f]\{6\}\)).*/\1/p')"
    [ -n "$v" ] && echo "#${v}"
}
background="$(getc background)";   [ -n "$background" ] || background="#141218"
foreground="$(getc foreground)";   [ -n "$foreground" ] || foreground="#D8D0E8"
accent="$(getc color13)";          [ -n "$accent" ] || accent="#C8B8D8"

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
    magick "$src" -background black -alpha remove -alpha off \
        -resize "${RES}^" -gravity center -extent "$RES" -strip \
        -define png:compression-level=9 "$tmp/background.png"
else
    cp -f "$src" "$tmp/background.png"
fi

# --- 4. Generate theme.txt with palette colors ---
cat > "$tmp/theme.txt" << EOF
# GRUB theme - synced from wallpaper + wallust palette

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
