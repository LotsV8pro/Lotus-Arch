#!/bin/bash
# Quick installer — run on a fresh Arch install (as root or as a user)
# Clones the repo and runs install.sh, which handles the operator user itself.

set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║   Arch Lotus — Quick Installer          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if ! command -v git &>/dev/null; then
    if [[ ${EUID} -eq 0 ]]; then
        pacman -S --needed --noconfirm git
    else
        sudo pacman -S --needed --noconfirm git
    fi
fi

REPO_DIR="${HOME}/Lotus-Arch"
[[ ${EUID} -eq 0 ]] && REPO_DIR="/root/Lotus-Arch"

if [[ -d "$REPO_DIR" ]]; then
    echo "[i] Updating existing clone ..."
    git -C "$REPO_DIR" pull || true
else
    echo "[i] Cloning repository ..."
    git clone https://github.com/LotsV8pro/Lotus-Arch.git "$REPO_DIR"
fi

chmod +x "$REPO_DIR/install.sh"
exec "$REPO_DIR/install.sh" "$@"
