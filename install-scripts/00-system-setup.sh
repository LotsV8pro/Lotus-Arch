#!/bin/bash
# Phase 0: System Setup - mirrors, repos, basic tools

set -euo pipefail

echo "[00] Setting up system..."

# Enable multilib
if ! grep -q "^\[multilib\]" /etc/pacman.conf 2>/dev/null; then
    sudo sed -i '/^#\[multilib\]/,+2 s/^#//' /etc/pacman.conf
fi

# Rate mirrors
if command -v reflector &>/dev/null; then
    sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true
fi

# Update system
sudo pacman -Syu --noconfirm

# Essential build tools
sudo pacman -S --needed --noconfirm base-devel git cmake ninja meson

echo "[00] System setup done."
