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
    obs-studio obs-studio-plugin-browser obs-pipewire-audio-capture-git
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
    networkmanager network-manager-applet nm-connection-manager
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

ALL_PACKAGES=("${HYPR[@]}" "${GRAPHICS[@]}" "${BAR[@]}" "${LAUNCHER[@]}" \
    "${TERMINAL[@]}" "${FILEMANAGER[@]}" "${NOTIFY[@]}" "${AUDIO[@]}" \
    "${DM[@]}" "${SCREENSHOT[@]}" "${THEME[@]}" "${FONTS[@]}" \
    "${UTILS[@]}" "${MEDIA[@]}" "${BLUETOOTH[@]}" "${NETWORK[@]}" \
    "${MISC[@]}" "${GAMING[@]}" "${HARDWARE[@]}" "${LAPTOP[@]}" \
    "${LIBS32[@]}" "${DEV[@]}")

# Filter valid packages
VALID=()
for pkg in "${ALL_PACKAGES[@]}"; do
    if pacman -Si "$pkg" &>/dev/null; then
        VALID+=("$pkg")
    fi
done

sudo pacman -S --needed --noconfirm "${VALID[@]}" 2>/dev/null || true

echo "[01] Core packages installed."
