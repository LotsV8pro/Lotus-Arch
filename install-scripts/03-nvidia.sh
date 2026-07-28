#!/bin/bash
# Phase 3: NVIDIA driver setup

set -euo pipefail

echo "[03] Setting up NVIDIA..."

# Install nvidia-open-dkms if not already
if ! pacman -Qi nvidia-open-dkms &>/dev/null; then
    sudo pacman -S --needed --noconfirm nvidia-open-dkms dkms linux-headers
fi

# Ensure nvidia modules are in mkinitcpio
if ! grep -q "nvidia" /etc/mkinitcpio.conf 2>/dev/null; then
    sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
    sudo mkinitcpio -P 2>/dev/null || true
fi

# Create nvidia.conf for Hyprland env
sudo tee /etc/environment.d/nvidia.conf >/dev/null << 'EOF'
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
EOF

# Enable nvidia-persistenced
sudo systemctl enable nvidia-persistenced 2>/dev/null || true

echo "[03] NVIDIA configured."
