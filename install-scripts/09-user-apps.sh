#!/bin/bash
# Phase 9: Restore user packages and themes.
# No prompts: phases 1 and 2 already asked. Packages explicitly rejected there
# are recorded in .lotus-excluded and skipped here.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[09] Restoring user packages and themes..."

EXCLUDE_FILE="$SCRIPT_DIR/../.lotus-excluded"
PACMAN_FILE="$SCRIPT_DIR/../packages/pacman.txt"
AUR_FILE="$SCRIPT_DIR/../packages/aur.txt"
FLATPAK_FILE="$SCRIPT_DIR/../packages/flatpak.txt"

declare -A EXCLUDED=()
if [[ -f "$EXCLUDE_FILE" ]]; then
  while IFS= read -r line; do
    for pkg in $line; do EXCLUDED["$pkg"]=1; done
  done < "$EXCLUDE_FILE"
fi

SESSION="$(cat "$SCRIPT_DIR/../.lotus-session" 2>/dev/null || echo "${LOTUS_SESSION:-hypr}")"
wanted() {
  local p="$1"
  [[ -n "${EXCLUDED[$p]:-}" ]] && return 1
  # Hyprland packages never belong to a Niri-only install.
  if [[ "$SESSION" == "niri" && "$p" =~ ^(hypr|xdg-desktop-portal-hyprland) ]]; then
    return 1
  fi
  return 0
}

# Collect packages from both saved lists, minus rejected ones.
PACMAN_PKGS=()
while IFS= read -r p; do
  [[ -z "$p" || "$p" == \#* ]] && continue
  wanted "$p" && PACMAN_PKGS+=("$p")
done < "$PACMAN_FILE"

AUR_PKGS=()
while IFS= read -r p; do
  [[ -z "$p" || "$p" == \#* ]] && continue
  wanted "$p" && AUR_PKGS+=("$p")
done < "$AUR_FILE"

if [[ ${#PACMAN_PKGS[@]} -gt 0 ]]; then
  echo "  → Installing ${#PACMAN_PKGS[@]} pacman packages..."
  sudo -n pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" >/dev/null 2>&1 || true
fi

if [[ ${#AUR_PKGS[@]} -gt 0 ]] && command -v yay &>/dev/null; then
  echo "  → Installing ${#AUR_PKGS[@]} AUR packages..."
  if ! yay -S --needed --noconfirm "${AUR_PKGS[@]}" >/dev/null 2>&1; then
    echo "  [!] Some AUR packages failed (conflicts); continuing."
  fi
fi

# Flatpak apps (skip platform packages that need extra permissions).
if [[ -f "$FLATPAK_FILE" ]] && command -v flatpak &>/dev/null; then
  while IFS= read -r app; do
    [[ -z "$app" || "$app" == org.gnome.Platform* ]] && continue
    flatpak install --noninteractive -y "$app" >/dev/null 2>&1 || true
  done < "$FLATPAK_FILE"
fi

# ── Apply Discord Vencord Lotus theme ──
VENCORD_DIR="$HOME/.config/Vencord/themes"
if [[ -d "$VENCORD_DIR" ]]; then
  for t in lotus-purple caelestia; do
    [[ -f "$SCRIPT_DIR/../dotfiles/Vencord/themes/$t.theme.css" ]] && \
      cp "$SCRIPT_DIR/../dotfiles/Vencord/themes/$t.theme.css" "$VENCORD_DIR/" 2>/dev/null || true
  done
  echo "  → Discord Lotus themes installed (enable in Vencord Settings > Themes)"
fi

echo "[09] Done."
