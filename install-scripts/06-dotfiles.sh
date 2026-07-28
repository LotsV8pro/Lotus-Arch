#!/bin/bash
# Phase 6: Deploy dotfiles

set -euo pipefail

echo "[06] Deploying dotfiles..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR/../dotfiles"
BACKUP_DIR="$HOME/.config/dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

backup_and_copy() {
    local src="$1"
    local dst="$2"

    if [[ -e "$dst" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$dst" "$BACKUP_DIR/" 2>/dev/null || true
    fi

    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
}

# ── Hyprland ──
echo "  → Hyprland configs..."
if [[ -d "$DOTFILES/.config/hypr" ]]; then
    backup_and_copy "$DOTFILES/.config/hypr" "$HOME/.config/hypr"
fi

# ── Waybar ──
echo "  → Waybar configs..."
if [[ -d "$DOTFILES/.config/waybar" ]]; then
    backup_and_copy "$DOTFILES/.config/waybar" "$HOME/.config/waybar"
fi

# ── Rofi ──
echo "  → Rofi configs..."
if [[ -d "$DOTFILES/.config/rofi" ]]; then
    backup_and_copy "$DOTFILES/.config/rofi" "$HOME/.config/rofi"
fi

# ── Kitty ──
echo "  → Kitty configs..."
if [[ -d "$DOTFILES/.config/kitty" ]]; then
    backup_and_copy "$DOTFILES/.config/kitty" "$HOME/.config/kitty"
fi

# ── DedSec Palette ──
echo "  → DedSec palette..."
if [[ -d "$DOTFILES/.config/dedsec-palette" ]]; then
    backup_and_copy "$DOTFILES/.config/dedsec-palette" "$HOME/.config/dedsec-palette"
fi

# ── Swaync ──
echo "  → Swaync..."
if [[ -d "$DOTFILES/.config/swaync" ]]; then
    backup_and_copy "$DOTFILES/.config/swaync" "$HOME/.config/swaync"
fi

# ── Wlogout ──
echo "  → Wlogout..."
if [[ -d "$DOTFILES/.config/wlogout" ]]; then
    backup_and_copy "$DOTFILES/.config/wlogout" "$HOME/.config/wlogout"
fi

# ── Qt/GTK theming ──
echo "  → Qt/GTK theming..."
for d in qt5ct qt6ct Kvantum gtk-3.0 gtk-4.0; do
    if [[ -d "$DOTFILES/.config/$d" ]]; then
        backup_and_copy "$DOTFILES/.config/$d" "$HOME/.config/$d"
    fi
done

# ── Btop / Fastfetch ──
echo "  → Btop & Fastfetch..."
for d in btop fastfetch; do
    if [[ -d "$DOTFILES/.config/$d" ]]; then
        backup_and_copy "$DOTFILES/.config/$d" "$HOME/.config/$d"
    fi
done

# ── ZSH ──
echo "  → ZSH config..."
if [[ -f "$DOTFILES/.zshrc" ]]; then
    backup_and_copy "$DOTFILES/.zshrc" "$HOME/.zshrc"
fi
if [[ -f "$DOTFILES/.zshenv" ]]; then
    backup_and_copy "$DOTFILES/.zshenv" "$HOME/.zshenv"
fi
if [[ -d "$DOTFILES/.oh-my-zsh/custom" ]]; then
    mkdir -p "$HOME/.oh-my-zsh/custom"
    cp -r "$DOTFILES/.oh-my-zsh/custom/"* "$HOME/.oh-my-zsh/custom/" 2>/dev/null || true
fi

# ── Local binaries ──
echo "  → Local binaries..."
if [[ -d "$DOTFILES/.local/bin" ]]; then
    mkdir -p "$HOME/.local/bin"
    cp -r "$DOTFILES/.local/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
fi

# ── nwg-look / nwg-displays ──
for d in nwg-look nwg-displays; do
    if [[ -d "$DOTFILES/.config/$d" ]]; then
        backup_and_copy "$DOTFILES/.config/$d" "$HOME/.config/$d"
    fi
done

# ── Steam gamescope ──
if [[ -f "$HOME/.local/bin/steam-gamescope.sh" ]]; then
    chmod +x "$HOME/.local/bin/steam-gamescope.sh"
fi

# Make all hypr scripts executable
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/UserScripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/dedsec-palette/"*.sh 2>/dev/null || true

# Make scripts in other dirs executable
chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true

if [[ -d "$BACKUP_DIR" ]]; then
    echo "  → Old configs backed up to: $BACKUP_DIR"
fi

echo "[06] Dotfiles deployed."
