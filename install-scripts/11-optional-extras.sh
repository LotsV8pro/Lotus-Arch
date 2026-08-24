#!/bin/bash
# Phase 11: Optional desktop extras (compositor-agnostic — work on Hyprland AND Niri)
# - Extra look presets (monochrome, Pixel, White_monochrome)
# - GPU tuning pack (GWE profiles, vkSumi, vkBasalt + ReShade shaders)
# - GT Racing wallpaper pack (~82 MB, copied to ~/Pictures/wallpapers)
# - movie-tui config
#
# All OPTIONAL. The base install ships only the Lotus preset.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR/../dotfiles"
OPTIONAL="$SCRIPT_DIR/../optional"
WALLPAPERS="$SCRIPT_DIR/../wallpapers"
PRESETS_DIR="$HOME/.config/lotus-palette/presets"
PIC_WALLS="$HOME/Pictures/wallpapers"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ask() {
    local prompt="$1"
    local answer
    read -p "$prompt [y/N]: " answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

install_extra_presets() {
    echo "  → Installing extra look presets..."
    mkdir -p "$PRESETS_DIR"
    cp -r "$DOTFILES/lotus-palette/presets-optional/"* "$PRESETS_DIR/" 2>/dev/null || true
    # Shell/bar state defaults for presets saved before this field existed
    for d in "$PRESETS_DIR"/*/; do
        [[ -f "$d/shell-state.txt" ]] || printf 'waybar=yes\n' > "$d/shell-state.txt"
    done
    echo -e "${GREEN}[✓]${NC} Extra presets installed (switch with SUPER+CTRL+P)"
}

install_gpu_pack() {
    echo "  → Installing GPU tuning configs..."
    if [[ -d "$OPTIONAL/gpu" ]]; then
        cp -r "$OPTIONAL/gpu/." "$HOME/.config/"
    fi

    # vkBasalt: layer + ReShade shaders (upstream repo, ~60 MB)
    if ! [[ -d "$HOME/.config/vkBasalt/reshade-shaders" ]]; then
        echo "  → Cloning reshade-shaders (cdozdil/OptiScaler's vkBasalt preset set)..."
        mkdir -p "$HOME/.config/vkBasalt"
        git clone --depth 1 https://github.com/DadSchoorse/vkBasalt.git /tmp/vkbasalt-src 2>/dev/null || true
        if [[ -d /tmp/vkbasalt-src ]]; then
            git clone --depth 1 https://github.com/cdozdil/ReShade-shaders.git \
                "$HOME/.config/vkBasalt/reshade-shaders" 2>/dev/null \
            || echo -e "${YELLOW}[!]${NC} reshade-shaders clone failed — vkBasalt will use defaults"
            rm -rf /tmp/vkbasalt-src
        fi
    fi
    echo -e "${GREEN}[✓]${NC} GPU tuning pack installed (MangoHud is part of the base install)"
}

install_gt_wallpapers() {
    echo "  → Installing GT Racing wallpaper pack (~82 MB)..."
    if [[ ! -d "$WALLPAPERS/GT Racing" ]]; then
        echo -e "${YELLOW}[!]${NC} wallpapers/GT Racing not found in repo — skipping"
        return 0
    fi
    mkdir -p "$PIC_WALLS"
    cp -rn "$WALLPAPERS/GT Racing" "$PIC_WALLS/" 2>/dev/null || cp -r "$WALLPAPERS/GT Racing" "$PIC_WALLS/"
    echo -e "${GREEN}[✓]${NC} GT Racing pack → $PIC_WALLS/GT Racing"
}

install_movie_tui() {
    echo "  → Installing movie-tui config..."
    if [[ -d "$OPTIONAL/movie-tui" ]]; then
        mkdir -p "$HOME/.config/movie-tui"
        cp -r "$OPTIONAL/movie-tui/." "$HOME/.config/movie-tui/"
        echo -e "${GREEN}[✓]${NC} movie-tui config installed (add your TMDB API key inside)"
    else
        echo -e "${YELLOW}[!]${NC} optional/movie-tui not found — skipping"
    fi
}

echo ""
echo "── Optional extras ──────────────────────────────"

if ask "  Install extra look presets? (monochrome / Pixel / White_monochrome)"; then
    install_extra_presets
fi

if ask "  Install GPU tuning pack? (GWE fan/OC profiles, vkSumi, vkBasalt)"; then
    install_gpu_pack
fi

if ask "  Install GT Racing wallpaper pack? (~82 MB car wallpapers)"; then
    install_gt_wallpapers
fi

if ask "  Install movie-tui config? (terminal movie browser — needs a TMDB key)"; then
    install_movie_tui
fi

echo ""
echo "[11] Optional extras done."
