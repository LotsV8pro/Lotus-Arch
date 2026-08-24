#!/bin/bash
# Phase 1: Core Packages - everything from the actual system

set -euo pipefail

echo "[01] Installing core packages..."

# ── Hyprland Core ──
HYPR=(
    hyprland hyprlock hypridle hyprpolkitagent
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    hyprgraphics hyprlang hyprutils hyprcursor hyprtoolkit
    xdg-user-dirs xdg-utils
    uwsm
)

# ── Niri Session (optional alternative to Hyprland) ──
NIRI=(
    niri
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk
    xdg-user-dirs xdg-utils
    quickshell
    brightnessctl
    swaybg
    fuzzel
)

# iNiR shell (Quickshell-based, optional) — cloned from upstream in Phase 12.
# Requires: quickshell (above).

# ── Graphics / NVIDIA ──
GRAPHICS=(
    mesa libva-nvidia-driver vulkan-tools
    vulkan-icd-loader lib32-vulkan-icd-loader
    nvidia-open-dkms nvidia-settings nvidia-utils lib32-nvidia-utils
    egl-wayland egl-wayland2
    libva libvdpau
)

# ── Waybar ──
BAR=( waybar )

# ── App Launcher ──
LAUNCHER=( rofi )

# ── Terminal ──
TERMINAL=( kitty kitty-shell-integration kitty-terminfo )

# ── File Manager ──
FILEMANAGER=(
    thunar thunar-archive-plugin thunar-volman
    gvfs gvfs-mtp tumbler
)

# ── Notification ──
NOTIFY=( swaync )

# ── Audio (PipeWire) ──
AUDIO=(
    pipewire pipewire-alsa pipewire-audio pipewire-pulse
    wireplumber
    pamixer pavucontrol
    playerctl
    libpulse
)

# ── Display Manager ──
DM=( sddm )

# ── Screenshot / Recording ──
SCREENSHOT=(
    grim slurp swappy
    obs-studio obs-studio-plugin-browser
)

# ── Theming ──
THEME=(
    kvantum qt5ct qt6ct
    nwg-look nwg-displays
    gtk-engine-murrine
    adwaita-icon-theme adwaita-fonts
)

# ── Fonts ──
FONTS=(
    noto-fonts noto-fonts-emoji noto-fonts-cjk
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd
    ttf-fira-code ttf-fantasque-nerd
    ttf-dejavu ttf-droid ttf-liberation
    ttf-victor-mono otf-font-awesome
    adobe-source-code-pro-fonts
    gnu-free-fonts
)

# ── System Utils ──
UTILS=(
    fastfetch inxi btop lsd fzf jq ripgrep
    wget curl git rsync unzip p7zip xarchiver
    brightnessctl stow bc tree
    base-devel pacman-contrib sbctl
    nano neovim
    lsof htop procps-ng
)

# ── Media ──
MEDIA=(
    mpv mpv-mpris ffmpeg ffmpeg4.4 ffmpegthumbnailer
    loupe mousepad imagemagick
)

# ── Bluetooth ──
BLUETOOTH=(
    blueman bluez bluez-utils
)

# ── Network ──
NETWORK=(
    networkmanager network-manager-applet
    wpa_supplicant
)

# ── Misc Desktop ──
MISC=(
    wlogout cliphist wl-clipboard
    polkit polkit-qt6
    power-profiles-daemon
    xdg-desktop-portal
    catimg
    zsh zsh-completions
    flatpak
)

# ── Gaming ──
GAMING=(
    steam steam-devices
    gamemode
    libratbag
    gamescope
    mangohud
    lutris wine winetricks
    protontricks
)

# ── ASUS / Hardware ──
HARDWARE=(
    asusctl
)

# ── Laptop (install but some may not apply) ──
LAPTOP=(
    power-profiles-daemon
)

# ── 32-bit libs for gaming ──
LIBS32=(
    lib32-gamemode lib32-mangohud
    lib32-libva lib32-vulkan-intel
    lib32-mesa lib32-glu
)

# ── Build / Dev tools ──
DEV=(
    cmake ninja meson
    python python-pip
    deno
)

# ── Interactive category selection ──
confirm() {
    echo -e -n "\n  Install $1? [Y/n]: "
    read -r ans
    [[ "$ans" =~ ^[Nn] ]] && return 1 || return 0
}

# Session-aware confirm: pre-answers based on $LOTUS_SESSION (hypr|niri|both).
# Still interactive — the default just changes.
SESSION="${LOTUS_SESSION:-hypr}"
confirm_session() { # <category> <desc>
    local cat="$1" desc="$2" def="Y"
    case "$cat" in
        HYPR) [[ "$SESSION" == "niri" ]] && def="N" ;;
        NIRI) [[ "$SESSION" != "niri" && "$SESSION" != "both" ]] && def="N" ;;
    esac
    echo -e -n "\n  Install $desc? [y/n] (default: $def): "
    read -r ans
    ans="${ans:-$def}"
    [[ "$ans" =~ ^[Yy] ]]
}

CATEGORIES=(
    "HYPR:Hyprland Core (hyprland, hyprlock, hypridle, portals)"
    "NIRI:Niri Session + Quickshell (iNiR shell installed in Phase 12) [optional]"
    "GRAPHICS:Graphics (mesa, vulkan-tools, NVIDIA/Intel drivers)"
    "BAR:Waybar Status Bar"
    "LAUNCHER:Rofi App Launcher"
    "TERMINAL:Kitty Terminal"
    "FILEMANAGER:Thunar File Manager"
    "NOTIFY:Swaync Notifications"
    "AUDIO:PipeWire Audio Stack"
    "DM:SDDM Display Manager"
    "SCREENSHOT:Screenshot & Recording (grim, slurp, OBS)"
    "THEME:Theming Tools (KVantum, qt5ct/6ct, nwg-look)"
    "FONTS:Fonts (JetBrains Mono, Fira Code, Nerd Fonts)"
    "UTILS:System Utilities (fastfetch, btop, neovim, git, etc)"
    "MEDIA:Media Apps (MPV, loupe, ImageMagick)"
    "BLUETOOTH:Bluetooth Support"
    "NETWORK:NetworkManager Stack"
    "MISC:Misc (wlogout, cliphist, power-profiles, flatpak)"
    "GAMING:Gaming (Steam, Lutris, MangoHud, Gamescope)"
    "HARDWARE:ASUS Hardware Support (asusctl)"
    "LIBS32:32-bit Libraries (for gaming compatibility)"
    "DEV:Dev Tools (cmake, python, deno)"
)

SELECTED=()
for entry in "${CATEGORIES[@]}"; do
    name="${entry%%:*}"
    desc="${entry#*:}"
    case "$name" in
        HYPR|NIRI) confirm_session "$name" "$desc" || continue ;;
        *)         confirm "$desc" || continue ;;
    esac
    case "$name" in
        HYPR)       SELECTED+=("${HYPR[@]}") ;;
        NIRI)       SELECTED+=("${NIRI[@]}") ;;
            GRAPHICS)   SELECTED+=("${GRAPHICS[@]}") ;;
            BAR)        SELECTED+=("${BAR[@]}") ;;
            LAUNCHER)   SELECTED+=("${LAUNCHER[@]}") ;;
            TERMINAL)   SELECTED+=("${TERMINAL[@]}") ;;
            FILEMANAGER) SELECTED+=("${FILEMANAGER[@]}") ;;
            NOTIFY)     SELECTED+=("${NOTIFY[@]}") ;;
            AUDIO)      SELECTED+=("${AUDIO[@]}") ;;
            DM)         SELECTED+=("${DM[@]}") ;;
            SCREENSHOT) SELECTED+=("${SCREENSHOT[@]}") ;;
            THEME)      SELECTED+=("${THEME[@]}") ;;
            FONTS)      SELECTED+=("${FONTS[@]}") ;;
            UTILS)      SELECTED+=("${UTILS[@]}") ;;
            MEDIA)      SELECTED+=("${MEDIA[@]}") ;;
            BLUETOOTH)  SELECTED+=("${BLUETOOTH[@]}") ;;
            NETWORK)    SELECTED+=("${NETWORK[@]}") ;;
            MISC)       SELECTED+=("${MISC[@]}") ;;
            GAMING)     SELECTED+=("${GAMING[@]}" "${LIBS32[@]}") ;;
            HARDWARE)   SELECTED+=("${HARDWARE[@]}") ;;
            LIBS32)     SELECTED+=("${LIBS32[@]}") ;;
            DEV)        SELECTED+=("${DEV[@]}") ;;
        esac
done

# Filter valid packages
VALID=()
for pkg in "${SELECTED[@]}"; do
    if pacman -Si "$pkg" &>/dev/null; then
        VALID+=("$pkg")
    fi
done

if [[ ${#VALID[@]} -gt 0 ]]; then
    sudo pacman -S --needed --noconfirm "${VALID[@]}" 2>/dev/null || true
else
    echo "  No packages selected."
fi

echo "[01] Core packages installed."
