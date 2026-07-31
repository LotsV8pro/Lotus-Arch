#!/bin/bash
# Phase 2: AUR packages

set -euo pipefail

echo "[02] Installing AUR packages..."

echo "  (press Enter to accept, or type n/N to skip each)"

AUR_PACKAGES=(
    "zen-browser-bin:Zen Browser (Firefox-based)"
    "discord:Discord Chat"
    "spotify:Spotify Music"
    "github-cli:GitHub CLI (gh)"
    "yay-bin:Yay AUR Helper (already installed)"
    "linux-wallpaperengine-bin:Wallpaper Engine"
    "cava:Terminal Audio Visualizer"
    "deepcool-digital-linux-git:DeepCool Digital"
    "openrgb:RGB Lighting Control"
    "noise-suppression-for-voice:Noise Suppression"
    "ttf-victor-mono:Victor Mono Font"
    "gtk-engine-murrine:Murrine GTK Engine"
    "arctis-sound-manager:Arctis Sound Manager"
    "obs-pipewire-audio-capture-git:OBS PipeWire Audio Capture"
    "quickshell:Quick Shell"
    "zram-generator:ZRAM Generator"
)

SELECTED=()
for entry in "${AUR_PACKAGES[@]}"; do
    pkg="${entry%%:*}"
    desc="${entry#*:}"
    echo -n "  Install $desc? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        SELECTED+=("$pkg")
    fi
done

VALID=()
for pkg in "${SELECTED[@]}"; do
    if yay -Si "$pkg" &>/dev/null 2>&1; then
        VALID+=("$pkg")
    fi
done

if [[ ${#VALID[@]} -gt 0 ]]; then
    yay -S --needed --noconfirm "${VALID[@]}" 2>/dev/null || true
else
    echo "  No AUR packages selected."
fi

echo "[02] AUR packages installed."
