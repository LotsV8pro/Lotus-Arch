#!/bin/bash
# Phase 6: Deploy dotfiles
# Layout: dotfiles/<name>/...  →  ~/.config/<name>/...

set -euo pipefail

echo "[06] Deploying dotfiles..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR/../dotfiles"
BACKUP_DIR="$HOME/.config/dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# ── Install-time choices (set by install.sh, overridable via env) ────────────
#   LOTUS_SESSION   hypr | niri | both     (default: hypr)
#   LOTUS_AUDIO     arctis | basic         (default: arctis)
#   LOTUS_STREAMING yes | no               (default: yes)
SESSION="${LOTUS_SESSION:-hypr}"
AUDIO_MODE="${LOTUS_AUDIO:-arctis}"
STREAMING="${LOTUS_STREAMING:-yes}"

backup_and_copy() {
    local src="$1"
    local dst="$2"

    if [[ -e "$dst" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$dst" "$BACKUP_DIR/" 2>/dev/null || true
        # True mirror: replace dst entirely so re-syncs don't nest src inside dst
        rm -rf "$dst"
    fi

    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
}

if [[ ! -d "$DOTFILES" ]]; then
    echo "[!] No dotfiles directory found at $DOTFILES"
    exit 0
fi

# Copy every directory under dotfiles/ directly to ~/.config/
for dir in "$DOTFILES"/*/; do
    [[ ! -d "$dir" ]] && continue
    name="$(basename "$dir")"

    # Skip if not a real config we want
    case "$name" in
        # Skip non-config dirs
        .git) continue ;;
    esac

    # ── Quickshell: overlay, never wholesale-replace ──
    # upstream iNiR owns the bulk of ~/.config/quickshell/inir/ during Phase 12.
    # A true-mirror rm -rf here would wipe out all upstream shell modules that
    # Lotus-Arch doesn't vendor. Instead, copy config.json + generic modules/
    # + services/ + the inir/ overlay files on top, leaving upstream files intact.
    if [[ "$name" == "quickshell" ]]; then
        echo "  → quickshell (overlay, preserves upstream iNiR)"
        [[ -f "$dir/config.json" ]] && {
            mkdir -p "$HOME/.config/quickshell"; cp "$dir/config.json" "$HOME/.config/quickshell/config.json"
        }
        for sub in modules services inir; do
            [[ -d "$dir/$sub" ]] && {
                mkdir -p "$HOME/.config/quickshell/$sub"
                cp -r "$dir/$sub/." "$HOME/.config/quickshell/$sub/"
            }
        done
        continue
    fi

    echo "  → $name"
    backup_and_copy "$dir" "$HOME/.config/$name"

    # ── Session-aware pruning ──
    # On a Niri-only install, Hyprland's compositor config is dead weight.
    # Shared pieces (scripts, wallust templates, wallpaper effects) stay —
    # the palette engine and wallpaper tooling depend on them in both sessions.
    if [[ "$name" == "hypr" && "$SESSION" == "niri" ]]; then
        echo "    ↳ niri session: pruning Hyprland-only compositor config"
        for sub in hyprland.lua monitors.lua configs UserConfigs UserScripts animations Monitor_Profiles; do
            rm -rf "$HOME/.config/hypr/$sub"
        done
    fi

    # ── Audio gating: strip the Arctis/Sonar pipeline on basic audio ──
    if [[ "$AUDIO_MODE" != "arctis" ]]; then
        case "$name" in
            pipewire)
                rm -f "$HOME/.config/pipewire/filter-chain.conf.d/"sonar-*.conf \
                      "$HOME/.config/pipewire/filter-chain.conf.d/"sink-virtual-surround*.conf
                [[ -d "$HOME/.config/pipewire/filter-chain.conf.d" ]] \
                    && find "$HOME/.config/pipewire/filter-chain.conf.d" -maxdepth 0 -empty -delete 2>/dev/null || true ;;
            wireplumber)
                rm -f "$HOME/.config/wireplumber/wireplumber.conf.d/50-arctis.conf" ;;
            easyeffects)
                # EasyEffects IS the Arctis OBS virtual-mic chain — skip it on basic audio
                rm -rf "$HOME/.config/easyeffects" ;;
        esac
    fi

    # ── Streaming gating: no OBS configs / stream units unless opted in ──
    if [[ "$STREAMING" != "yes" ]]; then
        [[ "$name" == "obs-studio" ]] && rm -rf "$HOME/.config/obs-studio"
    fi

    # Arctis units follow the audio choice; streaming units the stream choice
    if [[ "$name" == "systemd" ]]; then
        [[ "$AUDIO_MODE" != "arctis" ]] && \
            rm -f "$HOME/.config/systemd/user/"arctis-*.service \
                  "$HOME/.config/systemd/user/"auto-link-ee.service \
                  "$HOME/.config/systemd/user/"easyeffects.service
        [[ "$STREAMING" != "yes" ]] && \
            rm -f "$HOME/.config/systemd/user/"virtual-mic.service \
                  "$HOME/.config/systemd/user/"auto-link-obs.service
    fi
done

# ── Machine-specific monitor overlay (optional) ──
# The default niri/Hyprland configs are portable (no output names hardcoded), so
# a clone works on any machine/display out of the box. If THIS machine has the
# Lotus reference build's exact output connectors connected, we re-apply its
# precise layout across niri, Hyprland and the iNiR shell. Detection is
# compositor-independent (works even mid-install, before any Wayland session):
# it reads DRM connector status from /sys/class/drm.
detect_reference_outputs() {
    local dp2="" hdmi=""
    for c in /sys/class/drm/card*-DP-2/status; do
        [[ "$(cat "$c" 2>/dev/null)" == "connected" ]] && dp2=1
    done
    for c in /sys/class/drm/card*-HDMI-A-1/status; do
        [[ "$(cat "$c" 2>/dev/null)" == "connected" ]] && hdmi=1
    done
    [[ -n "$dp2" && -n "$hdmi" ]]
}

if detect_reference_outputs; then
    echo "  → applying Lotus reference monitor overlay (DP-2 + HDMI-A-1 detected)"

    # Niri: swap the portable monitor.kdl for this machine's exact layout
    if [[ -f "$HOME/.config/niri/monitor.lotus.kdl" ]]; then
        cp -f "$HOME/.config/niri/monitor.lotus.kdl" "$HOME/.config/niri/monitor.kdl"
    fi

    # Hyprland: swap the portable monitors.lua for this machine's layout/workspaces
    if [[ -f "$HOME/.config/hypr/monitors.lotus.lua" ]]; then
        cp -f "$HOME/.config/hypr/monitors.lotus.lua" "$HOME/.config/hypr/monitors.lua"
    fi

    # iNiR shell: merge the machine-specific config.lotus.json into config.json
    # (restores wallpapersByMonitor, outputOverrides, screenCastOutput, primaryMonitor)
    if command -v jq >/dev/null 2>&1 \
       && [[ -f "$HOME/.config/inir/config.lotus.json" ]] \
       && [[ -f "$HOME/.config/inir/config.json" ]]; then
        if jq --slurpfile o "$HOME/.config/inir/config.lotus.json" \
            '.background.wallpapersByMonitor = $o[0].background.wallpapersByMonitor
             | .background.widgets.outputOverrides = $o[0].background.widgets.outputOverrides
             | .bar.utilButtons.screenCastOutput = $o[0].bar.utilButtons.screenCastOutput
             | .display.primaryMonitor = $o[0].display.primaryMonitor' \
            "$HOME/.config/inir/config.json" > "$HOME/.config/inir/config.json.tmp" 2>/dev/null; then
            mv -f "$HOME/.config/inir/config.json.tmp" "$HOME/.config/inir/config.json"
        else
            rm -f "$HOME/.config/inir/config.json.tmp"
        fi
    fi
else
    echo "  → portable monitor configs in use (any display auto-detected)"
fi

# Copy top-level dotfiles
for f in "$DOTFILES"/*; do
    if [[ -f "$f" ]]; then
        name="$(basename "$f")"
        echo "  → $name (file)"
        if [[ -e "$HOME/.config/$name" ]]; then
            mkdir -p "$BACKUP_DIR"
            cp "$HOME/.config/$name" "$BACKUP_DIR/" 2>/dev/null || true
        fi
        cp "$f" "$HOME/.config/$name"
    fi
done

# ── ZSH (lives in $HOME, not .config) ──
echo "  → zsh config..."
if [[ -f "$DOTFILES/.zshrc" ]]; then
    backup_and_copy "$DOTFILES/.zshrc" "$HOME/.zshrc"
fi
if [[ -f "$DOTFILES/.zshenv" ]]; then
    backup_and_copy "$DOTFILES/.zshenv" "$HOME/.zshenv"
fi
if [[ -d "$DOTFILES/.oh-my-zsh" ]]; then
    cp -r "$DOTFILES/.oh-my-zsh" "$HOME/" 2>/dev/null || true
fi

# ── Local binaries ──
echo "  → local binaries..."
if [[ -d "$DOTFILES/.local/bin" ]]; then
    mkdir -p "$HOME/.local/bin"
    cp -r "$DOTFILES/.local/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
fi

# ── Local share files (HRIR, icons, etc) ──
for share_dir in "$DOTFILES/.local/share/"*/; do
    [[ ! -d "$share_dir" ]] && continue
    name="$(basename "$share_dir")"
    # HeSuVi HRIR convolution data is Arctis-pipeline-only
    [[ "$name" == "pipewire" && "$AUDIO_MODE" != "arctis" ]] && continue
    # EasyEffects presets are the Arctis OBS virtual-mic chain — skip on basic audio
    [[ "$name" == "easyeffects" && "$AUDIO_MODE" != "arctis" ]] && continue
    echo "  → .local/share/$name..."
    mkdir -p "$HOME/.local/share/$name"
    cp -r "$share_dir"* "$HOME/.local/share/$name/" 2>/dev/null || true
done

# ── Rewrite any hardcoded home paths to the current user's home ──
# Configs use the @HOME@ sentinel (and, for live mirrors, legacy /home/lots) so
# every deployed config targets the real home directory and works for any username.
echo "  → rewriting @HOME@ / legacy /home/lots paths..."
find "$HOME/.config" -path "$HOME/.config/dotfiles-backup" -prune -o -type f -exec grep -Il . {} + 2>/dev/null | while IFS= read -r f; do
    sed -i -e "s|@HOME@|$HOME|g" -e "s|/home/lots|$HOME|g" "$f" 2>/dev/null || true
done
sed -i -e "s|@HOME@|$HOME|g" -e "s|/home/lots|$HOME|g" "$HOME/.local/bin/"* 2>/dev/null || true
sed -i -e "s|@HOME@|$HOME|g" -e "s|/home/lots|$HOME|g" "$HOME/.zshrc" "$HOME/.zshenv" 2>/dev/null || true

# ── swww → awww compatibility symlinks ──
# swww is deprecated; awww (extra repo) is its successor. The configs still
# call `swww`/`swww-daemon`, so expose them as symlinks to awww.
echo "  → linking swww compatibility binaries..."
if command -v awww &>/dev/null && command -v awww-daemon &>/dev/null; then
    sudo ln -sf /usr/bin/awww /usr/bin/swww 2>/dev/null || true
    sudo ln -sf /usr/bin/awww-daemon /usr/bin/swww-daemon 2>/dev/null || true
fi

# ── Seed starter wallpapers if the user has none ──
echo "  → seeding starter wallpapers..."
WP_DIR="$HOME/Pictures/wallpapers"
mkdir -p "$WP_DIR"
if [[ -d "$SCRIPT_DIR/../wallpapers" ]]; then
    if ! find "$WP_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) 2>/dev/null | grep -q .; then
        cp -rn "$SCRIPT_DIR/../wallpapers/"* "$WP_DIR/" 2>/dev/null || true
    fi
fi

# Seed a default wallpaper so initial-boot.sh (wallust + swww) has something
if [[ ! -f "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current" ]]; then
    first_wp="$(find "$WP_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | head -1)"
    if [[ -n "$first_wp" ]]; then
        mkdir -p "$HOME/.config/hypr/wallpaper_effects"
        cp "$first_wp" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current" 2>/dev/null || true
    fi
fi

# ── Make scripts executable ──
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/UserScripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/lotus-palette/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/initial-boot.sh" 2>/dev/null || true
chmod +x "$HOME/.config/hypr/auto_link_obs.sh" 2>/dev/null || true

if [[ -d "$BACKUP_DIR" ]]; then
    echo "  → Old configs backed up to: $BACKUP_DIR"
fi

echo "[06] Dotfiles deployed."
