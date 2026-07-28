#!/bin/bash
# Phase 7: Cleanup & final touches

set -euo pipefail

echo "[07] Final cleanup..."

# Create common directories
mkdir -p "$HOME/Pictures/wallpapers"
mkdir -p "$HOME/.cache/gif_preview"
mkdir -p "$HOME/.cache/video_preview"
mkdir -p "$HOME/.cache/wallpaper_effects"

# Set up xdg user dirs
xdg-user-dirs-update 2>/dev/null || true

# Configure git with safe defaults
if ! git config --global user.name &>/dev/null; then
    echo "  → Set your git name: git config --global user.name 'Your Name'"
fi
if ! git config --global user.email &>/dev/null; then
    echo "  → Set your git email: git config --global user.email 'you@email.com'"
fi

# Clean yay cache
yay -Scc --noconfirm 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       Installation Complete!             ║"
echo "╠══════════════════════════════════════════╣"
echo "║                                          ║"
echo "║  1. Reboot your system                   ║"
echo "║  2. Select Hyprland in SDDM              ║"
echo "║  3. Enjoy your DedSec desktop!           ║"
echo "║                                          ║"
echo "║  Keybinds: SUPER + H                     ║"
echo "║  Palette:  SUPER + P                     ║"
echo "║  Wallpaper: SUPER + W                    ║"
echo "║                                          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

echo "[07] Done."
