#!/bin/bash
# Quick installer — run on a fresh Arch install (as root)
# Creates the operator user if needed, then runs the full installer as that user.

set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║   Arch Lotus — Quick Installer          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

TARGET_USER="${LOTUS_USER:-lots}"

if [[ ${EUID} -ne 0 ]]; then
    echo "[i] Not root; running the installer as $(whoami)."
    exec bash -c 'curl -fsSL https://raw.githubusercontent.com/LotsV8pro/Lotus-Arch/main/install.sh | bash'
fi

# On a live ISO / fresh install there is only root. install.sh writes to $HOME
# and registers --user units, so it needs a real user.
if ! id "$TARGET_USER" &>/dev/null; then
    echo "[i] Creating user $TARGET_USER ..."
    useradd -m -G wheel -s /bin/bash "$TARGET_USER"
    echo "$TARGET_USER ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/$TARGET_USER"
    chmod 440 "/etc/sudoers.d/$TARGET_USER"
    echo "[i] Set a password for $TARGET_USER when prompted (or leave empty)."
    passwd "$TARGET_USER" || true
fi

echo "[i] Installing git if needed ..."
pacman -S --needed --noconfirm git || true

REPO_DIR="/home/$TARGET_USER/Lotus-Arch"
if [[ -d "$REPO_DIR" ]]; then
    echo "[i] Updating existing clone ..."
    git -C "$REPO_DIR" pull || true
else
    echo "[i] Cloning repository ..."
    git clone https://github.com/LotsV8pro/Lotus-Arch.git "$REPO_DIR"
fi
chown -R "$TARGET_USER:$TARGET_USER" "$REPO_DIR"
chmod +x "$REPO_DIR/install.sh"

echo "[i] Running install.sh as $TARGET_USER ..."
exec su - "$TARGET_USER" -c "cd '$REPO_DIR' && ./install.sh"
