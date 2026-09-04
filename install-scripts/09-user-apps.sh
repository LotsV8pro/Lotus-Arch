#!/bin/bash
# Phase 9: User apps — prompt per app from your saved package lists

set -euo pipefail

echo "[09] Restoring user packages and themes..."
echo ""

confirm() {
  echo -n "  Install $1? [Y/n]: "
  read -r ans
  [[ "$ans" =~ ^[Nn] ]] && return 1 || return 0
}

PACMAN_FILE="$SCRIPT_DIR/../packages/pacman.txt"
AUR_FILE="$SCRIPT_DIR/../packages/aur.txt"
FLATPAK_FILE="$SCRIPT_DIR/../packages/flatpak.txt"

# ── Notable apps — asked individually ──
NOTABLE_APPS=(
  "steam:Steam (gaming platform)"
  "lutris:Lutris (game manager)"
  "discord:Discord Chat"
  "spotify:Spotify Music"
  "qpwgraph:QPWGraph (PipeWire routing)"
  "obs-studio:OBS Studio (recording/streaming)"
  "gamescope:Gamescope (gaming compositor)"
  "mangohud:MangoHud (gaming overlay)"
  "gamemode:Gamemode (game optimization)"
  "zen-browser-bin:Zen Browser (Firefox-based)"
  "protontricks:Protontricks (Proton tools)"
  "btop:Btop (system monitor)"
  "fastfetch:Fastfetch (system info)"
  "cava:Cava (audio visualizer)"
  "neovim:Neovim (text editor)"
  "openrgb:OpenRGB (RGB control)"
  "linux-wallpaperengine-bin:Wallpaper Engine"
)

SELECTED_PACMAN=()
SELECTED_AUR=()

for entry in "${NOTABLE_APPS[@]}"; do
  pkg="${entry%%:*}"
  desc="${entry#*:}"
  if confirm "$desc"; then
    # Check if it's in pacman or aur list
    if grep -q "^$pkg$" "$PACMAN_FILE" 2>/dev/null; then
      SELECTED_PACMAN+=("$pkg")
    elif grep -q "^$pkg$" "$AUR_FILE" 2>/dev/null; then
      SELECTED_AUR+=("$pkg")
    fi
  fi
done

# ── Rest of packages — grouped by category ──
echo ""
echo "  --- Remaining packages (grouped by type) ---"

# Define categories using package name patterns
declare -A CATEGORIES
CATEGORIES["Desktop Apps"]="discord vesktop-bin spotify zen-browser-bin github-cli"
CATEGORIES["Gaming"]="steam lutris mangohud gamemode gamescope protontricks steam-devices wine winetricks"
CATEGORIES["Media"]="mpv mpv-mpris ffmpeg ffmpegthumbnailer loupe mousepad obs-studio obs-studio-plugin-browser obs-pipewire-audio-capture-git"
CATEGORIES["Audio"]="pipewire pipewire-alsa pipewire-audio pipewire-pulse wireplumber pamixer pavucontrol playerctl qpwgraph cava"
CATEGORIES["Dev Tools"]="neovim nodejs npm python python-pip rust gcc cmake ninja meson deno jdk-openjdk"
CATEGORIES["System Utils"]="fastfetch btop lsd fzf jq ripgrep htop yazi inxi nvtop"
CATEGORIES["Bluetooth"]="blueman bluez bluez-utils"
CATEGORIES["Theming"]="kvantum qt5ct qt6ct nwg-look nwg-displays gtk-engine-murrine"
CATEGORIES["ASUS Hardware"]="asusctl deepcool-digital-linux-git openrgb"
CATEGORIES["Printing"]="cups system-config-printer"

for cat_name in "${!CATEGORIES[@]}"; do
  # Get category packages that are in saved list and not already selected
  cat_pkgs=()
  for pkg in ${CATEGORIES[$cat_name]}; do
    if grep -q "^$pkg$" "$PACMAN_FILE" 2>/dev/null; then
      if [[ ! " ${SELECTED_PACMAN[*]} " =~ " $pkg " ]]; then
        cat_pkgs+=("$pkg")
      fi
    elif grep -q "^$pkg$" "$AUR_FILE" 2>/dev/null; then
      if [[ ! " ${SELECTED_AUR[*]} " =~ " $pkg " ]]; then
        cat_pkgs+=("$pkg")
      fi
    fi
  done

  [[ ${#cat_pkgs[@]} -eq 0 ]] && continue

  cat_desc="${cat_name} (${cat_pkgs[*]})"
  if confirm "$cat_desc"; then
    for pkg in "${cat_pkgs[@]}"; do
      if grep -q "^$pkg$" "$PACMAN_FILE" 2>/dev/null; then
        SELECTED_PACMAN+=("$pkg")
      else
        SELECTED_AUR+=("$pkg")
      fi
    done
  fi
done

# ── Rest of unassigned packages ──
REST_PACMAN=()
while IFS= read -r pkg; do
  [[ -z "$pkg" ]] && continue
  # Skip if already selected or in a category
  if [[ ! " ${SELECTED_PACMAN[*]} " =~ " $pkg " ]]; then
    skip=false
    for cat_pkgs in "${CATEGORIES[@]}"; do
      if [[ " $cat_pkgs " =~ " $pkg " ]]; then
        skip=true; break
      fi
    done
    $skip || REST_PACMAN+=("$pkg")
  fi
done < "$PACMAN_FILE"

REST_AUR=()
while IFS= read -r pkg; do
  [[ -z "$pkg" ]] && continue
  if [[ ! " ${SELECTED_AUR[*]} " =~ " $pkg " ]]; then
    skip=false
    for cat_pkgs in "${CATEGORIES[@]}"; do
      if [[ " $cat_pkgs " =~ " $pkg " ]]; then
        skip=true; break
      fi
    done
    $skip || REST_AUR+=("$pkg")
  fi
done < "$AUR_FILE"

if [[ ${#REST_PACMAN[@]} -gt 0 ]]; then
  if confirm "All remaining pacman packages (${#REST_PACMAN[@]} — system deps, fonts, etc)"; then
    SELECTED_PACMAN+=("${REST_PACMAN[@]}")
  fi
fi

if [[ ${#REST_AUR[@]} -gt 0 ]]; then
  if confirm "All remaining AUR packages (${#REST_AUR[@]})"; then
    SELECTED_AUR+=("${REST_AUR[@]}")
  fi
fi

# ── Flatpaks ──
if [[ -f "$FLATPAK_FILE" ]] && [[ -s "$FLATPAK_FILE" ]]; then
  if confirm "Flatpak apps ($(tr '\n' ' ' < "$FLATPAK_FILE"))"; then
    while IFS= read -r app; do
      [[ -z "$app" ]] && continue
      flatpak install --noninteractive -y "$app" 2>&1 | tail -1 || true
    done < "$FLATPAK_FILE"
  fi
fi

# ── Install selected ──
if [[ ${#SELECTED_PACMAN[@]} -gt 0 ]]; then
  echo "  → Installing selected pacman packages..."
  sudo pacman -S --needed --noconfirm "${SELECTED_PACMAN[@]}" 2>&1 | tail -3 || true
fi

if [[ ${#SELECTED_AUR[@]} -gt 0 ]]; then
  echo "  → Installing selected AUR packages..."
  yay -S --needed --noconfirm "${SELECTED_AUR[@]}" 2>&1 | tail -3 || true
fi

# ── Apply Spicetify Lotus theme ──
if confirm "Apply Lotus Spicetify theme (Spotify)"; then
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
fi

# ── Apply Discord Vencord Lotus theme ──
if confirm "Install Lotus Discord theme (Vencord)"; then
  VENCORD_DIR="$HOME/.config/Vencord/themes"
  if [[ -d "$VENCORD_DIR" ]]; then
    if [[ -f "$SCRIPT_DIR/../dotfiles/Vencord/themes/lotus-purple.theme.css" ]]; then
      cp "$SCRIPT_DIR/../dotfiles/Vencord/themes/lotus-purple.theme.css" "$VENCORD_DIR/"
      echo "  ✓ Discord Lotus theme installed"
      echo "  → Enable it in Vencord Settings > Themes > Lotus Purple"
    fi
  fi
fi

# ── Audio setup: EasyEffects + OBS virtual mic ──
echo ""
echo "  --- Audio pipeline setup ---"

SERVICES=(
  "virtual-mic.service:OBS Virtual Microphone (loopback from OBS virtual sink)"
  "easyeffects.service:Easy Effects mic processing (OBS virtual mic EQ)"
)

for entry in "${SERVICES[@]}"; do
  svc="${entry%%:*}"
  desc="${entry#*:}"
  if confirm "$desc"; then
    systemctl --user enable "$svc" 2>/dev/null || true
    systemctl --user start "$svc" 2>/dev/null || true
    echo "    enabled ✓"
  fi
done

echo "[09] User packages, themes, and audio services restored."
