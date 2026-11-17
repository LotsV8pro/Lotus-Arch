#!/bin/bash
# Phase 8: Cleanup & final touches

set -euo pipefail

echo "[08] Final cleanup..."

mkdir -p "$HOME/Pictures/wallpapers"
mkdir -p "$HOME/.cache/gif_preview"
mkdir -p "$HOME/.cache/video_preview"
mkdir -p "$HOME/.cache/wallpaper_effects"

xdg-user-dirs-update 2>/dev/null || true

if ! git config --global user.name &>/dev/null; then
    echo "  → Set your git name: git config --global user.name 'Your Name'"
fi
if ! git config --global user.email &>/dev/null; then
    echo "  → Set your git email: git config --global user.email 'you@email.com'"
fi

# Clean caches unattended. --noconfirm is enough for pacman; yay needs --noconfirm
# in the right position and may still prompt for repo caches.
pacman -Sc --noconfirm 2>/dev/null || true
yay -Scc --noconfirm 2>/dev/null || true
yay -Yc --noconfirm 2>/dev/null || true

echo "[08] Done."
