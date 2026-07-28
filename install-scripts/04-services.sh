#!/bin/bash
# Phase 4: Enable services

set -euo pipefail

echo "[04] Enabling services..."

# Display manager
sudo systemctl enable sddm.service 2>/dev/null || true

# Network
sudo systemctl enable NetworkManager.service 2>/dev/null || true
sudo systemctl enable bluetooth.service 2>/dev/null || true

# Audio
systemctl --user enable pipewire.service 2>/dev/null || true
systemctl --user enable pipewire-pulse.service 2>/dev/null || true
systemctl --user enable wireplumber.service 2>/dev/null || true

# Power
sudo systemctl enable power-profiles-daemon.service 2>/dev/null || true

# ZRAM
sudo systemctl enable systemd-zram-setup@zram0.service 2>/dev/null || true

# Polkit for GUI auth
sudo systemctl enable polkit.service 2>/dev/null || true

echo "[04] Services enabled."
