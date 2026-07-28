#!/bin/bash
# Phase 2: AUR packages

set -euo pipefail

echo "[02] Installing AUR packages..."

AUR_PACKAGES=(
    zen-browser-bin
    discord
    spotify
    github-cli
    yay-bin
    linux-wallpaperengine-bin
    cava
    deepcool-digital-linux-git
    openrgb
    noise-suppression-for-voice
    ttf-victor-mono
    gtk-engine-murrine
    arctis-sound-manager
    quickshell
    zram-generator
)

# Filter valid AUR packages
VALID=()
for pkg in "${AUR_PACKAGES[@]}"; do
    if yay -Si "$pkg" &>/dev/null 2>&1; then
        VALID+=("$pkg")
    fi
done

if [[ ${#VALID[@]} -gt 0 ]]; then
    yay -S --needed --noconfirm "${VALID[@]}" 2>/dev/null || true
fi

echo "[02] AUR packages installed."
