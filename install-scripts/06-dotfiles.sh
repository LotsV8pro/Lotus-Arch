#!/bin/bash
# Phase 6: Deploy dotfiles
# Layout: dotfiles/<name>/...  →  ~/.config/<name>/...

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

if [[ ! -d "$DOTFILES" ]]; then
    echo "[!] No dotfiles directory found at $DOTFILES"
    exit 0
fi

# Copy every directory under dotfiles/ directly to ~/.config/
for dir in "$DOTFILES"/*/; do
    [[ ! -d "$dir" ]] && continue
    name="$(basename "$dir")"

    # Skip if not a real config we want
    case "$name" in
        # Skip non-config dirs
        .git) continue ;;
    esac

    echo "  → $name"
    backup_and_copy "$dir" "$HOME/.config/$name"
done

# Copy top-level dotfiles
for f in "$DOTFILES"/*; do
    if [[ -f "$f" ]]; then
        name="$(basename "$f")"
        echo "  → $name (file)"
        if [[ -e "$HOME/.config/$name" ]]; then
            mkdir -p "$BACKUP_DIR"
            cp "$HOME/.config/$name" "$BACKUP_DIR/" 2>/dev/null || true
        fi
        cp "$f" "$HOME/.config/$name"
    fi
done

# ── ZSH (lives in $HOME, not .config) ──
echo "  → zsh config..."
if [[ -f "$DOTFILES/.zshrc" ]]; then
    backup_and_copy "$DOTFILES/.zshrc" "$HOME/.zshrc"
fi
if [[ -f "$DOTFILES/.zshenv" ]]; then
    backup_and_copy "$DOTFILES/.zshenv" "$HOME/.zshenv"
fi
if [[ -d "$DOTFILES/.oh-my-zsh" ]]; then
    cp -r "$DOTFILES/.oh-my-zsh" "$HOME/" 2>/dev/null || true
fi

# ── Local binaries ──
echo "  → local binaries..."
if [[ -d "$DOTFILES/.local/bin" ]]; then
    mkdir -p "$HOME/.local/bin"
    cp -r "$DOTFILES/.local/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
fi

# ── Local share files (HRIR, icons, etc) ──
for share_dir in "$DOTFILES/.local/share/"*/; do
    [[ ! -d "$share_dir" ]] && continue
    name="$(basename "$share_dir")"
    echo "  → .local/share/$name..."
    mkdir -p "$HOME/.local/share/$name"
    cp -r "$share_dir"* "$HOME/.local/share/$name/" 2>/dev/null || true
done

# ── Make scripts executable ──
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/UserScripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/lotus-palette/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/initial-boot.sh" 2>/dev/null || true
chmod +x "$HOME/.config/hypr/auto_link_obs.sh" 2>/dev/null || true

if [[ -d "$BACKUP_DIR" ]]; then
    echo "  → Old configs backed up to: $BACKUP_DIR"
fi

echo "[06] Dotfiles deployed."
