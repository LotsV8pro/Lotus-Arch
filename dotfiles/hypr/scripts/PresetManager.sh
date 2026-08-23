#!/usr/bin/env bash
# LOTUS Preset Manager — Save / Load / Delete full desktop presets
# Saves: palette, waybar style, waybar layout, wallpaper, decorations, shell/bar state

set -euo pipefail

PRESETS_DIR="$HOME/.config/lotus-palette/presets"
PALETTE="$HOME/.config/lotus-palette/colors.conf"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
WAYBAR_CONFIG="$HOME/.config/waybar/config"
ROFI_THEME="$HOME/.config/rofi/themes/lotus-palette.rasi"
MENU_THEME="$HOME/.config/rofi/themes/lotus-palette.rasi"

mkdir -p "$PRESETS_DIR"

# ── Shell/bar state helpers ────────────────────────────────────
# Extra quickshell shells = any running "qs -c <cfg>" except the overview overlay
list_extra_qs() {
    local out
    out=$(pgrep -ax qs 2>/dev/null | awk '$2=="-c" {print $4}' | grep -vx overview) || true
    echo "$out"
}

# Converge waybar + extra quickshell shells to a preset's shell-state.txt
# (missing file / missing keys = defaults: waybar on, no extra shells)
apply_shell_state() {
    local state_file="$1"
    local want_waybar="yes"
    if [[ -f "$state_file" ]]; then
        want_waybar=$(grep '^waybar=' "$state_file" | tail -1 | cut -d= -f2- || true)
        [[ -z "$want_waybar" ]] && want_waybar="yes"
    fi

    if [[ "$want_waybar" == "no" ]]; then
        pkill -x waybar 2>/dev/null || true
    else
        pgrep -x waybar >/dev/null 2>&1 || { setsid -f waybar >/dev/null 2>&1 || true; }
    fi

    # Stop extra quickshell shells this preset doesn't want (exact cmdline match)
    local cur want keep wanted_qs
    wanted_qs=$(grep '^qs=' "$state_file" 2>/dev/null | cut -d= -f2- || true)
    while read -r cur; do
        [[ -z "$cur" ]] && continue
        keep=false
        while read -r want; do
            [[ "$want" == "$cur" ]] && keep=true
        done <<< "$wanted_qs"
        [[ "$keep" == "false" ]] && pkill -xf "qs -c $cur" 2>/dev/null || true
    done <<< "$(list_extra_qs)"

    # Launch wanted ones that aren't running yet
    while read -r want; do
        [[ -z "$want" ]] && continue
        pgrep -xf "qs -c $want" >/dev/null 2>&1 || { setsid -f qs -c "$want" >/dev/null 2>&1 || true; }
    done <<< "$wanted_qs"
}

# ── Save current state to a preset ─────────────────────────────
save_preset() {
    local name
    name=$(rofi -dmenu -p "  Save Preset As" -config "$MENU_THEME" 2>/dev/null)
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

    # 4. Wallpaper (current swww image per monitor, saved as "monitor<TAB>path")
    swww query 2>/dev/null | awk '
        /^: / && /scale:/ { mon=$2; gsub(":", "", mon) }
        /currently displaying: image:/ && mon != "" {
            sub(/^.*image: /, "")
            print mon "\t" $0
            mon = ""
        }' > "$dir/wallpapers.txt" || true

    # 5. UserDecorations.lua
    cp "$HOME/.config/hypr/UserConfigs/UserDecorations.lua" "$dir/UserDecorations.lua" 2>/dev/null || true

    # 6. UserAnimations.lua
    cp "$HOME/.config/hypr/UserConfigs/UserAnimations.lua" "$dir/UserAnimations.lua" 2>/dev/null || true

    # 7. Shell/bar state (waybar + extra quickshell shells)
    {
        if pgrep -x waybar >/dev/null 2>&1; then echo "waybar=yes"; else echo "waybar=no"; fi
        list_extra_qs | sed 's/^/qs=/'
    } > "$dir/shell-state.txt"

    notify-send "Preset Saved" "$name" -i dialog-save
    echo "$name"
}

# ── Save only the waybar layout + style into a preset ─────────
save_waybar_only() {
    local presets=()
    for d in "$PRESETS_DIR"/*/; do
        [[ -d "$d" ]] || continue
        presets+=(" $(basename "$d")")
    done

    presets+=(" ➕ New preset...")

    local chosen
    chosen=$(printf '%s\n' "${presets[@]}" | rofi -dmenu -p "  Save Waybar Into" -config "$MENU_THEME" -no-custom 2>/dev/null)
    [[ -z "$chosen" ]] && exit 0
    chosen=$(echo "$chosen" | xargs)

    local name dir
    if [[ "$chosen" == "➕ New preset..." ]]; then
        name=$(rofi -dmenu -p "  New Waybar Preset Name" -config "$MENU_THEME" 2>/dev/null)
        [[ -z "$name" ]] && exit 0
        name=$(echo "$name" | tr ' /' '_' | tr -cd 'a-zA-Z0-9_-')
        dir="$PRESETS_DIR/$name"
        mkdir -p "$dir"
    else
        name="$chosen"
        dir="$PRESETS_DIR/$name"
    fi

    # Waybar style (actual file, not symlink)
    cp "$(readlink -f "$WAYBAR_STYLE")" "$dir/waybar-style.css"
    echo "$(basename "$(readlink -f "$WAYBAR_STYLE")")" > "$dir/waybar-style-name.txt"

    # Waybar layout (actual file, not symlink)
    cp "$(readlink -f "$WAYBAR_CONFIG")" "$dir/waybar-layout.conf"
    echo "$(basename "$(readlink -f "$WAYBAR_CONFIG")")" > "$dir/waybar-layout-name.txt"

    notify-send "Waybar Saved" "$name (style + layout)" -i dialog-save
}

# ── Load a preset ──────────────────────────────────────────────
load_preset() {
    local preset_dir="$1"
    local name
    name=$(basename "$preset_dir")

    # 1. Apply palette
    if [[ -f "$preset_dir/colors.conf" ]]; then
        cp "$preset_dir/colors.conf" "$PALETTE"
        bash "$HOME/.config/lotus-palette/apply-colors.sh" &>/dev/null
    fi

    # 2. Restore waybar style
    if [[ -f "$preset_dir/waybar-style.css" ]]; then
        local style_name style_target
        style_name=$(cat "$preset_dir/waybar-style-name.txt" 2>/dev/null || basename "$preset_dir/waybar-style.css")
        style_target="$HOME/.config/waybar/style/$style_name"
        # Back up any existing style before overwriting (prevents losing custom styles)
        if [[ -f "$style_target" ]]; then
            mkdir -p "$HOME/.config/waybar/style/.preset-backups"
            cp "$style_target" "$HOME/.config/waybar/style/.preset-backups/$style_name.$(date +%Y%m%d-%H%M%S)"
        fi
        cp "$preset_dir/waybar-style.css" "$style_target"
        ln -sf "$style_target" "$WAYBAR_STYLE"
    fi

    # 3. Restore waybar layout
    if [[ -f "$preset_dir/waybar-layout.conf" ]]; then
        local layout_name layout_target
        layout_name=$(cat "$preset_dir/waybar-layout-name.txt" 2>/dev/null || basename "$preset_dir/waybar-layout.conf")
        layout_target="$HOME/.config/waybar/configs/$layout_name"
        # Back up any existing config before overwriting (prevents losing custom layouts)
        if [[ -f "$layout_target" ]] && [[ "$layout_target" != "$(readlink -f "$WAYBAR_CONFIG")" ]]; then
            mkdir -p "$HOME/.config/waybar/configs/.preset-backups"
            cp "$layout_target" "$HOME/.config/waybar/configs/.preset-backups/$layout_name.$(date +%Y%m%d-%H%M%S)"
        fi
        cp "$preset_dir/waybar-layout.conf" "$layout_target"
        ln -sf "$layout_target" "$WAYBAR_CONFIG"
    fi

    # 4. Restore wallpaper (with same transition as SUPER+W)
    if [[ -f "$preset_dir/wallpapers.txt" ]]; then
        local SWWW_PARAMS="--transition-fps 60 --transition-type any --transition-duration 2 --transition-bezier .43,1.19,1,.4"
        local mon wp
        while IFS=$'\t' read -r mon wp; do
            # Old presets stored bare paths (one per line) without a monitor
            if [[ -z "$wp" ]]; then
                wp="$mon"
                mon=""
            fi
            # Expand portable $HOME / ~ prefixes (shipped presets use $HOME)
            wp="${wp/#\$HOME/$HOME}"
            wp="${wp/#\~\//$HOME/}"
            if [[ -f "$wp" ]]; then
                if [[ -n "$mon" ]]; then
                    swww img -o "$mon" "$wp" $SWWW_PARAMS 2>/dev/null &
                else
                    swww img "$wp" $SWWW_PARAMS 2>/dev/null &
                fi
            fi
        done < "$preset_dir/wallpapers.txt"
        wait || true
        # Persist the restored wallpapers so they survive the next reboot
        "$HOME/.config/hypr/scripts/WallpaperState.sh" save >/dev/null 2>&1 || true
        # Regenerate colors from the restored wallpaper
        "$HOME/.config/hypr/scripts/WallustSwww.sh" >/dev/null 2>&1 &
    fi

    # 5. Restore decorations
    [[ -f "$preset_dir/UserDecorations.lua" ]] && cp "$preset_dir/UserDecorations.lua" "$HOME/.config/hypr/UserConfigs/UserDecorations.lua"
    [[ -f "$preset_dir/UserAnimations.lua" ]] && cp "$preset_dir/UserAnimations.lua" "$HOME/.config/hypr/UserConfigs/UserAnimations.lua"

    # Apply border/shadow colors via hyprctl keyword (no full reload - that would break OBS PipeWire capture)
    if [[ -f "$preset_dir/colors.conf" ]]; then
        local p
        p="$preset_dir/colors.conf"
        local pc; pc=$(grep '^primary ' "$p" | head -1 | awk '{print $2}' | sed 's/^#//')
        local pd; pd=$(grep '^primary_dim ' "$p" | head -1 | awk '{print $2}' | sed 's/^#//')
        if [[ -n "$pc" && -n "$pd" ]]; then
            hyprctl keyword general:col.active_border "rgba(${pc}cc) rgba(${pd}cc) 135deg" 2>/dev/null || true
            hyprctl keyword general:col.inactive_border "rgba(${pc}22) rgba(${pd}22) 135deg" 2>/dev/null || true
            hyprctl keyword decoration:shadow:color "rgba(${pc}30)" 2>/dev/null || true
            hyprctl keyword decoration:shadow:color_inactive "rgba(${pd}15)" 2>/dev/null || true
            hyprctl keyword group:col.border_active "rgba(${pc}cc)" 2>/dev/null || true
            hyprctl keyword group:col.border_inactive "rgba(${pd}33)" 2>/dev/null || true
            hyprctl keyword group:groupbar:col.active "rgba(${pc}cc)" 2>/dev/null || true
            hyprctl keyword group:groupbar:col.inactive "rgba(${pd}33)" 2>/dev/null || true
        fi
    fi

    # 6. Converge shell/bar state (waybar on/off + extra quickshell shells)
    apply_shell_state "$preset_dir/shell-state.txt"

    notify-send "Preset Loaded" "$name (decor/anim apply on next restart)" -i dialog-ok
}

# ── Delete a preset ────────────────────────────────────────────
delete_preset() {
    local preset_dir="$1"
    local name
    name=$(basename "$preset_dir")

    local confirm
    confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "  Delete '$name'?" -config "$MENU_THEME" 2>/dev/null)
    [[ "$confirm" != "Yes" ]] && return

    rm -rf "$preset_dir"
    notify-send "Preset Deleted" "$name"
}

# ── Main menu ──────────────────────────────────────────────────
action=$(printf '%s\n' "  Save Current" "  Save Waybar Only" "  Load Preset" "  Delete Preset" | rofi -dmenu -p "  Preset Manager" -config "$MENU_THEME" -no-custom 2>/dev/null)
[[ -z "$action" ]] && exit 0

case "$action" in
    *Waybar*)
        save_waybar_only
        ;;
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

        chosen=$(printf '%s\n' "${presets[@]}" | rofi -dmenu -p "  Load Preset" -config "$MENU_THEME" 2>/dev/null)
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

        chosen=$(printf '%s\n' "${presets[@]}" | rofi -dmenu -p "  Delete Preset" -config "$MENU_THEME" 2>/dev/null)
        [[ -z "$chosen" ]] && exit 0

        chosen=$(echo "$chosen" | xargs)
        delete_preset "$PRESETS_DIR/$chosen"
        ;;
esac
