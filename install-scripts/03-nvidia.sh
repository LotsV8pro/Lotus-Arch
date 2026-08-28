#!/bin/bash
# Phase 3: GPU driver setup, gated by the graphics card selected in install.sh
# (LOTUS_GPU = nvidia | amd | intel). NVIDIA drivers install only when the user
# selects an NVIDIA graphics card. The overclock/OC config is a separate
# opt-in handled by Phase 10 (performance tweaks).

set -euo pipefail

GPU="${LOTUS_GPU:-}"
if [[ -z "$GPU" ]]; then
    echo -n "  Graphics card [nvidia/amd/intel] (default: nvidia): "
    read -r gpu_ans
    GPU="${gpu_ans:-nvidia}"
fi

case "$GPU" in
    amd|AMD)
        echo "[03] Setting up AMD GPU drivers..."
        sudo pacman -S --needed --noconfirm mesa vulkan-radeon lib32-vulkan-radeon \
            libva-mesa-driver lib32-libva-mesa-driver 2>/dev/null || true
        echo "[03] AMD configured."
        exit 0 ;;
    intel|INTEL)
        echo "[03] Integrated Intel graphics — no discrete driver needed."
        exit 0 ;;
    nvidia|NVIDIA|*)
        : # fall through to NVIDIA below
        ;;
esac

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
sudo mkdir -p /etc/environment.d
sudo tee /etc/environment.d/nvidia.conf >/dev/null << 'EOF'
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
EOF

# Enable nvidia-persistenced
sudo systemctl enable nvidia-persistenced 2>/dev/null || true

echo "[03] NVIDIA configured."
