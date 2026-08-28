#!/bin/bash
# Phase 12: Niri session + iNiR shell (optional)
# - Verifies quickshell / niri packages (Phase 1 "NIRI" category)
# - Installs iNiR from upstream (github.com/snowarch/iNiR)
# - Overlays the Lotus-Arch niri + inir configs on top
# - Enables the inir user service for the niri session
#
# Skipped automatically unless the NIRI category was selected.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR/../dotfiles"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

command -v niri &>/dev/null || { echo "[12] niri not selected — skipping."; exit 0; }

echo "[12] Setting up Niri + iNiR..."

# ── 1. Dependencies ──────────────────────────────────────────────────────────
for pkg in quickshell brightnessctl swaybg; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        echo "  → installing $pkg"
        sudo pacman -S --needed --noconfirm "$pkg" || true
    fi
done

# ── 2. iNiR from upstream ────────────────────────────────────────────────────
INIR_SRC="${INIR_SRC:-/tmp/inir-upstream}"
if [[ ! -x "$HOME/.local/bin/inir" ]]; then
    echo "  → Cloning iNiR (snowarch) ..."
    rm -rf "$INIR_SRC"
    git clone --depth 1 https://github.com/snowarch/iNiR.git "$INIR_SRC"

    # Run upstream setup when present; fall back to manual launcher install.
    if [[ -x "$INIR_SRC/setup" ]]; then
        (cd "$INIR_SRC" && ./setup) || true
    elif [[ -x "$INIR_SRC/install.sh" ]]; then
        (cd "$INIR_SRC" && ./install.sh) || true
    fi

    if [[ ! -x "$HOME/.local/bin/inir" && -f "$INIR_SRC/bin/inir" ]]; then
        mkdir -p "$HOME/.local/bin"
        cp -r "$INIR_SRC/." "$HOME/.local/share/inir/"
        cp "$INIR_SRC/bin/inir" "$HOME/.local/bin/inir"
    fi
fi

if [[ ! -x "$HOME/.local/bin/inir" ]]; then
    echo -e "${YELLOW}[!] iNiR launcher not found after setup.${NC}"
    echo "    Install it manually from https://github.com/snowarch/iNiR"
    echo "    Lotus-Arch configs are already in place and will be picked up."
    exit 0
fi
echo -e "${GREEN}[✓]${NC} iNiR launcher ready"

# ── 3. Re-overlay Lotus-Arch configs (upstream setup may overwrite them) ────
mkdir -p "$HOME/.config/inir" "$HOME/.config/niri/config.d"
[[ -d "$DOTFILES/inir" ]]      && cp -r "$DOTFILES/inir/."      "$HOME/.config/inir/"
[[ -d "$DOTFILES/niri" ]]      && cp -r "$DOTFILES/niri/."      "$HOME/.config/niri/"
[[ -d "$DOTFILES/quickshell/lotus-shell" ]] && {
    mkdir -p "$HOME/.config/quickshell/lotus-shell"
    cp -r "$DOTFILES/quickshell/lotus-shell/." "$HOME/.config/quickshell/lotus-shell/"
}

# Quickshell font + icon config
[[ -f "$DOTFILES/quickshell/config.json" ]] && {
    cp "$DOTFILES/quickshell/config.json" "$HOME/.config/quickshell/config.json"
}

# Quickshell iNiR shell overlays — mirror upstream iNiR's layout under
# ~/.config/quickshell/inir/ (modules + services) so the pill bar update
# indicator, font fixes and waffle tweaks land in the live shell.
[[ -d "$DOTFILES/quickshell/inir" ]] && {
    mkdir -p "$HOME/.config/quickshell/inir"
    cp -r "$DOTFILES/quickshell/inir/." "$HOME/.config/quickshell/inir/"
}

# User units (inir.service + helpers) — %h expands to $HOME at load time
mkdir -p "$HOME/.config/systemd/user"
cp "$DOTFILES/systemd/user/"*.service "$HOME/.config/systemd/user/" 2>/dev/null || true
systemctl --user daemon-reload || true

# ── 4. Wire the session ──────────────────────────────────────────────────────
"$HOME/.local/bin/inir" service enable 2>/dev/null || true
systemctl --user enable inir.service 2>/dev/null || true

# Wallpaper Engine auto-sync watcher (optional; activates when its workshop
# cache appears, e.g. after Wallpaper Engine is first run on this machine)
systemctl --user enable we-wallpaper-sync.path 2>/dev/null || true
systemctl --user enable we-wallpaper-sync.service 2>/dev/null || true

echo ""
echo -e "${GREEN}[✓]${NC} Niri + iNiR configured."
echo -e "     Select ${CYAN}Niri${NC} at the SDDM login screen."
echo -e "     Cheatsheet: ${CYAN}Mod+/${NC}   Settings: ${CYAN}Mod+Comma${NC}"
