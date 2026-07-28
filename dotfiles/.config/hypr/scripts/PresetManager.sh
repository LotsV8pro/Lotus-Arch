#!/usr/bin/env bash
# D̷E̷D̷S̷E̷C̷ Preset Manager — Save / Load / Delete full desktop presets
# Saves: palette, waybar style, waybar layout, wallpaper, decorations

set -euo pipefail

PRESETS_DIR="$HOME/.config/dedsec-palette/presets"
PALETTE="$HOME/.config/dedsec-palette/colors.conf"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
WAYBAR_CONFIG="$HOME/.config/waybar/config"
ROFI_THEME="$HOME/.config/rofi/themes/dedsec-palette.rasi"
MENU_THEME="$HOME/.config/rofi/themes/dedsec-palette.rasi"

mkdir -p "$PRESETS_DIR"

# ── Save current state to a preset ─────────────────────────────
save_preset() {
    local name
    name=$(rofi -dmenu -p "  Save Preset As" -theme "$MENU_THEME" 2>/dev/null)
    [[ -z "$name" ]] && exit 0

    name=$(echo "$name" | tr ' /' '_' | tr -cd 'a-zA-Z0-9_-')
    local dir="$PRESETS_DIR/$name"
    mkdir -p "$dir"

    # 1. Palette
    cp "$PALETTE" "$dir/colors.conf"

    # 2. Waybar style (actual file, not symlink)
    cp "$(readlink -f "$WAYBAR_STYLE")" "$dir/waybar-style.css"
    echo "$(basename "$(readlink -f "$WAYBAR_STYLE")")" > "$dir/waybar-style-name.txt"

    # 3. Waybar layout (actual file, not symlink)
    cp "$(readlink -f "$WAYBAR_CONFIG")" "$dir/waybar-layout.conf"
    echo "$(basename "$(readlink -f "$WAYBAR_CONFIG")")" > "$dir/waybar-layout-name.txt"

    # 4. Wallpaper (current swww image per monitor)
    swww query 2>/dev/null | grep "currently displaying: image:" | sed 's/.*image: //' > "$dir/wallpapers.txt" || true

    # 5. UserDecorations.lua
    cp "$HOME/.config/hypr/UserConfigs/UserDecorations.lua" "$dir/UserDecorations.lua" 2>/dev/null || true

    # 6. UserAnimations.lua
    cp "$HOME/.config/hypr/UserConfigs/UserAnimations.lua" "$dir/UserAnimations.lua" 2>/dev/null || true

    notify-send "Preset Saved" "$name" -i dialog-save
    echo "$name"
}

# ── Load a preset ──────────────────────────────────────────────
load_preset() {
    local preset_dir="$1"
    local name
    name=$(basename "$preset_dir")

    # 1. Apply palette
    if [[ -f "$preset_dir/colors.conf" ]]; then
        cp "$preset_dir/colors.conf" "$PALETTE"
        bash "$HOME/.config/dedsec-palette/apply-colors.sh" &>/dev/null
    fi

    # 2. Restore waybar style
    if [[ -f "$preset_dir/waybar-style.css" ]]; then
        local style_name
        style_name=$(cat "$preset_dir/waybar-style-name.txt" 2>/dev/null || basename "$preset_dir/waybar-style.css")
        cp "$preset_dir/waybar-style.css" "$HOME/.config/waybar/style/$style_name"
        ln -sf "$HOME/.config/waybar/style/$style_name" "$WAYBAR_STYLE"
    fi

    # 3. Restore waybar layout
    if [[ -f "$preset_dir/waybar-layout.conf" ]]; then
        local layout_name
        layout_name=$(cat "$preset_dir/waybar-layout-name.txt" 2>/dev/null || basename "$preset_dir/waybar-layout.conf")
        cp "$preset_dir/waybar-layout.conf" "$HOME/.config/waybar/configs/$layout_name"
        ln -sf "$HOME/.config/waybar/configs/$layout_name" "$WAYBAR_CONFIG"
    fi

    # 4. Restore wallpaper (with same transition as SUPER+W)
    if [[ -f "$preset_dir/wallpapers.txt" ]]; then
        local SWWW_PARAMS="--transition-fps 60 --transition-type any --transition-duration 2 --transition-bezier .43,1.19,1,.4"
        local i=0
        while IFS= read -r wp; do
            [[ -f "$wp" ]] && swww img "$wp" $SWWW_PARAMS 2>/dev/null &
            ((i++)) || true
        done < "$preset_dir/wallpapers.txt"
    fi

    # 5. Restore decorations
    [[ -f "$preset_dir/UserDecorations.lua" ]] && cp "$preset_dir/UserDecorations.lua" "$HOME/.config/hypr/UserConfigs/UserDecorations.lua"
    [[ -f "$preset_dir/UserAnimations.lua" ]] && cp "$preset_dir/UserAnimations.lua" "$HOME/.config/hypr/UserConfigs/UserAnimations.lua"

    # Reload
    hyprctl reload 2>/dev/null
    killall waybar 2>/dev/null; sleep 0.3; waybar &>/dev/null &

    notify-send "Preset Loaded" "$name" -i dialog-ok
}

# ── Delete a preset ────────────────────────────────────────────
delete_preset() {
    local preset_dir="$1"
    local name
    name=$(basename "$preset_dir")

    local confirm
    confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "  Delete '$name'?" -theme "$MENU_THEME" 2>/dev/null)
    [[ "$confirm" != "Yes" ]] && return

    rm -rf "$preset_dir"
    notify-send "Preset Deleted" "$name"
}

# ── Main menu ──────────────────────────────────────────────────
action=$(printf '%s\n' "  Save Current" "  Load Preset" "  Delete Preset" | rofi -dmenu -p "  Preset Manager" -theme "$MENU_THEME" -no-custom 2>/dev/null)
[[ -z "$action" ]] && exit 0

case "$action" in
    *Save*)
        save_preset
        ;;
    *Load*)
        presets=()
        for d in "$PRESETS_DIR"/*/; do
            [[ -d "$d" ]] || continue
            presets+=(" $(basename "$d")")
        done

        [[ ${#presets[@]} -eq 0 ]] && { notify-send "No Presets" "Save one first"; exit 0; }

        chosen=$(printf '%s\n' "${presets[@]}" | rofi -dmenu -p "  Load Preset" -theme "$MENU_THEME" 2>/dev/null)
        [[ -z "$chosen" ]] && exit 0

        chosen=$(echo "$chosen" | xargs)
        load_preset "$PRESETS_DIR/$chosen"
        ;;
    *Delete*)
        presets=()
        for d in "$PRESETS_DIR"/*/; do
            [[ -d "$d" ]] || continue
            presets+=(" $(basename "$d")")
        done

        [[ ${#presets[@]} -eq 0 ]] && { notify-send "No Presets" "Nothing to delete"; exit 0; }

        chosen=$(printf '%s\n' "${presets[@]}" | rofi -dmenu -p "  Delete Preset" -theme "$MENU_THEME" 2>/dev/null)
        [[ -z "$chosen" ]] && exit 0

        chosen=$(echo "$chosen" | xargs)
        delete_preset "$PRESETS_DIR/$chosen"
        ;;
esac
