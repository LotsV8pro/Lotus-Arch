#!/bin/bash
# Quick installer — run on a fresh Arch server install
# Downloads and runs the full installer

set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║   Arch DedSec — Quick Installer          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Ensure git is installed
if ! command -v git &>/dev/null; then
    echo "[i] Installing git..."
    sudo pacman -S --needed --noconfirm git
fi

# Clone or update
REPO_DIR="$HOME/Arch-DedSec"
if [[ -d "$REPO_DIR" ]]; then
    echo "[i] Updating existing clone..."
    cd "$REPO_DIR" && git pull
else
    echo "[i] Cloning repository..."
    git clone https://github.com/LotsV8pro/Arch-DedSec.git "$REPO_DIR"
    cd "$REPO_DIR"
fi

chmod +x install.sh
./install.sh
