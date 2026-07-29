#!/bin/bash
# Phase 9: User apps — reinstalls your current packages and applies themes

set -euo pipefail

echo "[09] Restoring user packages and themes..."

# ── 1. Restore official packages ──
echo "  → Restoring official packages..."
if [[ -f "$SCRIPT_DIR/../packages/pacman.txt" ]]; then
  sudo pacman -S --noconfirm --needed - < "$SCRIPT_DIR/../packages/pacman.txt" 2>&1 | tail -3 || true
fi

# ── 2. Restore AUR packages ──
echo "  → Restoring AUR packages..."
if [[ -f "$SCRIPT_DIR/../packages/aur.txt" ]]; then
  yay -S --noconfirm --needed - < "$SCRIPT_DIR/../packages/aur.txt" 2>&1 | tail -3 || true
fi

# ── 3. Restore Flatpaks ──
echo "  → Restoring Flatpak apps..."
if [[ -f "$SCRIPT_DIR/../packages/flatpak.txt" ]]; then
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    flatpak install --noninteractive -y "$app" 2>&1 | tail -1 || true
  done < "$SCRIPT_DIR/../packages/flatpak.txt"
fi

# ── 4. Apply Spicetify Lotus theme ──
echo "  → Applying Spicetify Lotus theme..."
if command -v spicetify &>/dev/null; then
  THEME_DIR="$HOME/.config/spicetify/Themes/Lotus"
  if [[ -d "$SCRIPT_DIR/../dotfiles/spicetify/Themes/Lotus" ]]; then
    mkdir -p "$THEME_DIR"
    cp -r "$SCRIPT_DIR/../dotfiles/spicetify/Themes/Lotus/"* "$THEME_DIR/"
    spicetify config current_theme Lotus 2>/dev/null || true
    spicetify config color_scheme "Lotus Purple" 2>/dev/null || true
    spicetify apply 2>&1 | tail -3 || true
    echo "  ✓ Spicetify Lotus theme applied"
  fi
fi

# ── 5. Apply Discord Vencord Lotus theme ──
echo "  → Applying Discord Lotus theme..."
VENCORD_DIR="$HOME/.config/Vencord/themes"
if [[ -d "$VENCORD_DIR" ]]; then
  if [[ -f "$SCRIPT_DIR/../dotfiles/Vencord/themes/lotus-purple.theme.css" ]]; then
    cp "$SCRIPT_DIR/../dotfiles/Vencord/themes/lotus-purple.theme.css" "$VENCORD_DIR/"
    echo "  ✓ Discord Lotus theme installed"
    echo "  → Enable it in Vencord Settings > Themes > Lotus Purple"
  fi
fi

echo "[09] User apps and themes restored."
