#!/usr/bin/env bash
# presets.sh - manage shell config presets for iNiR
# Usage:
#   presets.sh --save <name> [description]
#   presets.sh --ensure-initial <name> [description]
#   presets.sh --remove <name> [--online] [--imported]
#   presets.sh --apply <name> [--online] [--imported]
#   presets.sh --export-zip <name>
#   presets.sh --import-zip <zip_path>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/config-path.sh
source "$SCRIPT_DIR/lib/config-path.sh"
CONFIG_FILE="$(inir_config_file)"

LOCAL_PRESETS_DIR="$(inir_config_dir)/presets"
ONLINE_PRESETS_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/presets"
IMPORTED_PRESETS_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/presets_imported"
SWITCHWALL="$SCRIPT_DIR/colors/switchwall.sh"

mkdir -p "$LOCAL_PRESETS_DIR" "$ONLINE_PRESETS_DIR" "$IMPORTED_PRESETS_DIR"

# Blacklist: filter personal/machine data, keep visual/look presets
# General: time, battery, audio, sounds, language, workSafety
# Services: ai (API keys!), networking, musicRecognition, search, screenRecord, updates, voiceSearch
# Personal: calendar.externalSync (ICS URLs with emails), apps (machine paths), clipboard
# Machine: display, compositor, hotspot, keyboardIndicators, idle, powerProfiles, performance, gameMode, modules
# Paths: wallpapers.directory, wallpaperSelector, regionSelector
# Sensitive: sidebar.booru.*.apiKey, sidebar.wallhaven.apiKey, bar.weather (API key), resources
# Runtime: screenTime, shellUpdates, reloadToasts, bootGreeting, welcomeWizard, FirstRunExperience
BLACKLIST_FILTER='del(._presetMeta)
  | del(.time, .battery, .audio, .sounds, .language, .workSafety)
  | del(.ai, .networking, .musicRecognition, .search, .screenRecord, .updates, .voiceSearch)
  | del(.calendar.externalSync)
  | del(.apps, .display, .compositor, .hotspot, .keyboardIndicators)
  | del(.idle, .powerProfiles, .performance, .gameMode, .modules)
  | del(.wallpapers.directory, .wallpaperSelector)
  | del(.regionSelector, .resources, .clipboard, .screenTime)
  | del(.shellUpdates, .reloadToasts, .bootGreeting, .welcomeWizard)
  | del(.sidebar.booru.gelbooru.apiKey, .sidebar.wallhaven.apiKey, .sidebar.booru.downloadPath)
  | del(.policies)'

action="$1"
shift

online=false
args=()
imported=false
for arg in "$@"; do
    if [ "$arg" = "--online" ]; then
        online=true
    elif [ "$arg" = "--imported" ]; then
        imported=true
    else
        args+=("$arg")
    fi
done

name="${args[0]}"
description="${args[1]}"

if [ "$action" = "--import-zip" ]; then
    if [ -z "$name" ]; then
        echo "Error: missing zip path" >&2
        exit 1
    fi
    zip_path="$name"
    if [ ! -f "$zip_path" ]; then
        echo "Error: zip not found: $zip_path" >&2
        exit 1
    fi
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$zip_path" -d "$tmpdir"
    else
        python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip_path" "$tmpdir"
    fi
    json_file=$(find "$tmpdir" -maxdepth 4 -name "*.json" ! -name "meta.json" | head -n1)
    if [ -z "$json_file" ]; then
        echo "Error: no preset json in zip" >&2
        exit 1
    fi
    base=$(basename "$json_file" .json)
    asset_files=$(find "$(dirname "$json_file")" -maxdepth 1 -type f ! -name "*.json" ! -name "meta.json" -exec basename {} \; | jq -R . | jq -s .)
    asset_cache="$IMPORTED_PRESETS_DIR/assets/$base"
    mkdir -p "$asset_cache"
    find "$(dirname "$json_file")" -maxdepth 1 -type f ! -name "*.json" ! -name "meta.json" -exec cp -L {} "$asset_cache/" \; 2>/dev/null || true
    jq --arg dir "$asset_cache" --argjson files "$asset_files" '
      $files as $files | walk(if type == "string" then ((split("/") | last) as $base | if ($files | index($base)) then ($dir + "/" + $base) else . end) else . end)
      | del(._presetMeta) | ._presetMeta.source = "imported"
    ' "$json_file" | jq "$BLACKLIST_FILTER" > "$IMPORTED_PRESETS_DIR/${base}.json"
    echo "Imported $base to $IMPORTED_PRESETS_DIR/${base}.json with assets in $asset_cache"
    trap - EXIT
    rm -rf "$tmpdir"
    exit 0
fi

if [ -z "$name" ]; then
    echo "Error: missing preset name" >&2
    exit 1
fi

if $imported; then
    PRESETS_DIR="$IMPORTED_PRESETS_DIR"
elif $online; then
    PRESETS_DIR="$ONLINE_PRESETS_DIR"
else
    PRESETS_DIR="$LOCAL_PRESETS_DIR"
fi

case "$action" in
    --ensure-initial)
        marker="$LOCAL_PRESETS_DIR/.initialized"
        if [ ! -f "$marker" ]; then
            jq "$BLACKLIST_FILTER" "$CONFIG_FILE" > "$PRESETS_DIR/${name}.json"
            if [ -n "$description" ]; then
                jq --arg desc "$description" '._presetMeta = {"description": $desc}' \
                    "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                    && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
            fi
            touch "$marker"
            echo "Initial preset $name created"
        fi
        ;;
    --save)
        jq "$BLACKLIST_FILTER" "$CONFIG_FILE" > "$PRESETS_DIR/${name}.json"
        if [ -n "$description" ]; then
            jq --arg desc "$description" '._presetMeta = {"description": $desc}' \
                "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
        fi
        ;;
    --remove)
        rm -f "$PRESETS_DIR/${name}.json"
        if $online; then
            rm -rf "$ONLINE_PRESETS_DIR/assets/${name}"
        elif $imported; then
            rm -rf "$IMPORTED_PRESETS_DIR/assets/${name}"
        fi
        ;;
    --apply)
        preset_file="$PRESETS_DIR/${name}.json"
        if [ ! -f "$preset_file" ]; then
            echo "Error: preset not found: $name" >&2
            exit 1
        fi
        tmp=$(mktemp)
        jq "$BLACKLIST_FILTER" "$preset_file" > "$tmp"
        jq -s '.[0] * .[1] | del(._presetMeta)' "$CONFIG_FILE" "$tmp" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        rm -f "$tmp"
        if [ -x "$SWITCHWALL" ]; then
            "$SWITCHWALL" --noswitch
        fi
        ;;
    --export-zip)
        preset_file="$PRESETS_DIR/${name}.json"
        if [ ! -f "$preset_file" ]; then
            echo "Error: preset not found: $name" >&2
            exit 1
        fi
        tmpdir=$(mktemp -d)
        trap 'rm -rf "$tmpdir"' EXIT
        filtered="$tmpdir/${name}.json"
        jq "$BLACKLIST_FILTER" "$preset_file" > "$filtered"
        collect_asset() {
            local src="$1"
            local key="$2"
            if [ -n "$src" ] && [ -f "$src" ]; then
                cp -L "$src" "$tmpdir/" 2>/dev/null || true
                echo "$(basename "$src")"
            fi
        }
        wallpaper=$(jq -r '.background.wallpaperPath // empty' "$filtered")
        lockwall=$(jq -r '.lock.wallpaperPath // empty' "$filtered")
        wallpapers="[]"
        if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then wallpapers=$(jq -n --arg b "$(basename "$wallpaper")" '[$b]'); fi
        meta_lock=""
        [ -n "$lockwall" ] && meta_lock=$(collect_asset "$lockwall")
        [ -n "$wallpaper" ] && collect_asset "$wallpaper" >/dev/null
        jq -n --argjson w "$wallpapers" \
              --arg lock "$meta_lock" \
              '{preview: "", screenshots: [], wallpapers: $w}
               + (if $lock != "" then {lockWall: $lock} else {} end)' > "$tmpdir/meta.json"
        zip_name="${name}.zip"
        if command -v zip >/dev/null 2>&1; then
            (cd "$tmpdir" && zip -r "$LOCAL_PRESETS_DIR/$zip_name" . >/dev/null)
        else
            python3 -c "import zipfile, pathlib, sys; z=zipfile.ZipFile(sys.argv[1],'w',zipfile.ZIP_DEFLATED); [z.write(str(p), arcname=p.name) for p in pathlib.Path(sys.argv[2]).iterdir()]; z.close()" "$LOCAL_PRESETS_DIR/$zip_name" "$tmpdir"
        fi
        echo "Exported $LOCAL_PRESETS_DIR/$zip_name"
        trap - EXIT
        rm -rf "$tmpdir"
        ;;
    *)
        echo "Error: unknown action: $action" >&2
        exit 1
        ;;
esac
