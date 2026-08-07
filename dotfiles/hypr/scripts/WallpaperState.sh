#!/usr/bin/env bash
# Persist and restore per-monitor wallpapers across reboots.
# State file: one "monitor<TAB>path" entry per line (paths may contain spaces).

set -uo pipefail

STATE="$HOME/.config/hypr/wallpaper_effects/.wallpapers_state"
SWWW_PARAMS="--transition-fps 60 --transition-type any --transition-duration 2"

save() {
    mkdir -p "$(dirname "$STATE")"
    swww query 2>/dev/null | awk '
        /^: / && /scale:/ { mon=$2; gsub(":", "", mon) }
        /currently displaying: image:/ && mon != "" {
            sub(/^.*image: /, "")
            print mon "\t" $0
            mon = ""
        }' > "$STATE"
}

restore() {
    # Wait until the swww daemon is actually up and connected
    local waited=0
    while ! swww query >/dev/null 2>&1; do
        (( waited += 1 ))
        [[ $waited -ge 60 ]] && return 1
        sleep 0.2
    done

    if [[ ! -f "$STATE" ]]; then
        return 0
    fi

    local mon wp
    while IFS=$'\t' read -r mon wp; do
        [[ -z "$mon" ]] && continue
        [[ -f "$wp" ]] && swww img -o "$mon" "$wp" $SWWW_PARAMS 2>/dev/null
    done < "$STATE"

    # Regenerate colors from the restored wallpaper and refresh UI
    "$HOME/.config/hypr/scripts/WallustSwww.sh" >/dev/null 2>&1 &
}

case "${1:-}" in
    save)    save ;;
    restore) restore ;;
    *)
        echo "usage: WallpaperState.sh save|restore" >&2
        exit 1
        ;;
esac
