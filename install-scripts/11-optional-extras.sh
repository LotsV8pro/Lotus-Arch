#!/bin/bash
# Phase 11: Optional desktop extras
# - Extra look presets (monochrome, Pixel, Shrek, White_monochrome)
# - Persona 3 Reload Quickshell theme (optional full-shell alternative)
#
# Both are OPTIONAL. The base install ships only the Lotus preset.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR/../dotfiles"
PRESETS_DIR="$HOME/.config/lotus-palette/presets"
QS_DIR="$HOME/.config/quickshell"

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

install_persona() {
    echo "  → Cloning Persona-Quickshell (Yujonpradhananga)..."
    git clone --depth 1 https://github.com/Yujonpradhananga/Persona-Quickshell.git \
        "$QS_DIR/Persona-Quickshell"

    local target="$QS_DIR/Persona-Quickshell"
    if [[ ! -f "$target/shell.qml" ]]; then
        echo "[!] Clone failed — skipping Persona theme"
        return 0
    fi

    # Lotus-Arch patches: desktop fixes (no battery on PCs, calendar/font bugfixes,
    # cava plugin dependency removed)
    echo "  → Applying Lotus-Arch patches..."
    cp -r "$DOTFILES/quickshell/persona-overrides/." "$target/"

    # Remove the cava plugin dependency (visualizer widget stripped from override)
    rm -f "$target/Widgets/CavaVisualizer.qml"

    # Fonts the upstream repo forgot to ship
    echo "  → Downloading fonts..."
    mkdir -p "$target/Assets/fonts" "$HOME/.local/share/fonts"
    curl -sfLo "$target/Assets/fonts/BebasNeue-Regular.ttf" \
        "https://github.com/google/fonts/raw/main/ofl/bebasneue/BebasNeue-Regular.ttf"
    curl -sfLo "$target/Assets/fonts/Montserrat-Light.ttf" \
        "https://github.com/JulietaUla/Montserrat/raw/master/fonts/ttf/Montserrat-Light.ttf"
    curl -sfLo "$HOME/.local/share/fonts/MaterialSymbolsRounded.ttf" \
        "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
    curl -sfLo "$HOME/.local/share/fonts/Montserrat-Regular.ttf" \
        "https://github.com/JulietaUla/Montserrat/raw/master/fonts/ttf/Montserrat-Regular.ttf"
    curl -sfLo "$HOME/.local/share/fonts/Montserrat-Bold.ttf" \
        "https://github.com/JulietaUla/Montserrat/raw/master/fonts/ttf/Montserrat-Bold.ttf"
    fc-cache -f >/dev/null 2>&1 || true

    # Register it as a Preset Manager preset (kills waybar, starts the persona shell)
    mkdir -p "$PRESETS_DIR/Persona"
    printf 'waybar=no\nqs=Persona-Quickshell\n' > "$PRESETS_DIR/Persona/shell-state.txt"

    echo -e "${GREEN}[✓]${NC} Persona theme installed"
    echo -e "     Load it via ${CYAN}SUPER+CTRL+P → Load Preset → Persona${NC}"
    echo -e "     App drawer: ${CYAN}SUPER+R${NC} (only while Persona is active)"
}

echo "[11] Optional desktop extras..."

if [[ -d "$DOTFILES/lotus-palette/presets-optional" ]]; then
    if ask "  Install extra look presets? (monochrome, Pixel, Shrek, White_monochrome)"; then
        install_extra_presets
    else
        echo "  Skipped extra presets (Lotus stays the only preset)"
    fi
fi

if ask "  Install Persona 3 Reload Quickshell theme? (~130 MB clone, replaces waybar when loaded)"; then
    install_persona
else
    echo "  Skipped Persona theme"
fi

echo "[11] Optional extras done."
