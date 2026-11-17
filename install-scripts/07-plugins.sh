#!/bin/bash
# Phase 8: Hyprland plugins (hyprpm)
# Installs HyprGlass and other plugins via hyprpm

set -euo pipefail

# HyprGlass belongs to the Hyprland session only.
if [[ "${LOTUS_SESSION:-}" == "niri" ]]; then
    echo "  Skipping Hyprland plugins (Niri-only session)."
    exit 0
fi
if [[ -z "${LOTUS_UNATTENDED:-}" ]]; then
    echo -n "  Install HyprGlass plugin (glass blur effects)? [Y/n]: "
    read -r plugin_ans
else
    plugin_ans="y"
fi
if [[ "$plugin_ans" =~ ^[Nn] ]]; then
    echo "  Skipping Hyprland plugins."
    exit 0
fi

echo "[08] Installing Hyprland plugins..."

# Ensure hyprpm is available
if ! command -v hyprpm &>/dev/null; then
    echo "[!] hyprpm not found, skipping plugin install"
    exit 0
fi

# Add and enable HyprGlass
echo "  → Installing HyprGlass plugin..."
sudo hyprpm add https://github.com/hyprnux/hyprglass 2>&1 | tail -5 || true
sudo hyprpm enable hyprglass 2>&1 | tail -5 || true
pgrep -x Hyprland && hyprpm reload -n 2>&1 | tail -3 || true

echo "[08] Plugins installed."
