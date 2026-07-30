#!/bin/bash
# ██╗      ██████╗ ████████╗██╗   ██╗███████╗
# ██║     ██╔═══██╗╚══██╔══╝██║   ██║██╔════╝
# ██║     ██║   ██║   ██║   ██║   ██║███████╗
# ██║     ██║   ██║   ██║   ██║   ██║╚════██║
# ███████╗╚██████╔╝   ██║   ╚██████╔╝███████║
# ╚══════╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝
#
# Lotus-Arch - Hyprland Desktop Installer
# NVIDIA RTX 4070 + i7-13700KF optimized
# Lua-only Hyprland config (HyprGlass plugin ready)
#
# From minimal Arch to full Lotus-Arch desktop in one script.
#
# Usage:
#   git clone https://github.com/LotsV8pro/Lotus-Arch.git
#   cd Lotus-Arch
#   chmod +x install.sh
#   ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${MAGENTA}"
    cat << "EOF"

  ██╗      ██████╗ ████████╗██╗   ██╗███████╗
  ██║     ██╔═══██╗╚══██╔══╝██║   ██║██╔════╝
  ██║     ██║   ██║   ██║   ██║   ██║███████╗
  ██║     ██║   ██║   ██║   ██║   ██║╚════██║
  ███████╗╚██████╔╝   ██║   ╚██████╔╝███████║
  ╚══════╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝

EOF
    echo -e "${NC}"
    echo -e "${CYAN}  Arch Linux + Hyprland | Lua Config | NVIDIA Ready${NC}"
    echo -e "${CYAN}  https://github.com/LotsV8pro/Lotus-Arch${NC}"
    echo ""
}

print_status()   { echo -e "${GREEN}[✓]${NC} $1"; }
print_warn()     { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()    { echo -e "${RED}[✗]${NC} $1"; }
print_info()     { echo -e "${BLUE}[i]${NC} $1"; }
print_phase()    { echo -e "\n${MAGENTA}═══════════════════════════════════════════${NC}"; echo -e "${MAGENTA}  $1${NC}"; echo -e "${MAGENTA}═══════════════════════════════════════════${NC}\n"; }

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this as root!"
        echo "  Run as a regular user with sudo privileges."
        exit 1
    fi
}

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        print_error "This script is for Arch Linux only!"
        exit 1
    fi
}

check_network() {
    if ! ping -c 1 archlinux.org &>/dev/null; then
        print_error "No internet connection!"
        exit 1
    fi
    print_status "Internet connection OK"
}

enable_multilib() {
    print_info "Enabling multilib..."
    if ! grep -q "^\[multilib\]" /etc/pacman.conf 2>/dev/null; then
        sudo sed -i '/^#\[multilib\]/,+2 s/^#//' /etc/pacman.conf
        sudo pacman -Sy
    fi
    print_status "Multilib enabled"
}

install_yay() {
    if command -v yay &>/dev/null; then
        print_status "yay already installed"
    else
        print_info "Installing yay (AUR helper)..."
        cd /tmp
        git clone https://aur.archlinux.org/yay-bin.git
        cd yay-bin
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
    fi
}

run_phase() {
    local num="$1"
    local script="$2"
    local desc="$3"

    print_phase "PHASE $num: $desc"

    if [[ -f "$SCRIPT_DIR/install-scripts/$script" ]]; then
        bash "$SCRIPT_DIR/install-scripts/$script"
        print_status "Phase $num complete"
    else
        print_error "Script not found: $script"
        exit 1
    fi
}

main() {
    print_banner
    check_root
    check_arch
    check_network

    echo -e "${CYAN}Lotus Arch Installer — Interactive Selection${NC}"
    echo ""
    echo "  You will be asked about each component:"
    echo ""
    echo "  ◈ Phase 1 — Core (choose what you want)"
    echo "    Hyprland, Waybar, Rofi, Kitty, Thunar"
    echo "    PipeWire, SDDM, fonts, dev tools"
    echo "    Gaming (Steam, Lutris, MangoHud, Gamescope)"
    echo "    Media, Bluetooth, Network, and more"
    echo ""
    echo "  ◈ Phase 2 — AUR apps (each prompted)"
    echo "    Discord, Spotify, Zen Browser, GitHub CLI"
    echo "    Wallpaper Engine, cava, OpenRGB, etc."
    echo ""
    echo "  ◈ Phase 3 — NVIDIA drivers [Y/n]"
    echo "  ◈ Phase 5 — ZSH + Oh-My-ZSH [Y/n]"
    echo "  ◈ Phase 7 — HyprGlass plugin [Y/n]"
    echo "  ◈ Phase 9 — Restore saved user packages [Y/n]"
    echo "  ◈ Phase 10 — Performance tweaks (GPU/CPU/RAM/NVMe) [Y/n]"
    echo ""
    echo "  Then dotfiles deployed with auto-backup."
    echo ""
    echo -e "${YELLOW}  ⚠  Reboot required after installation.${NC}"
    echo -e "${YELLOW}  ⚠  Your existing configs will be backed up.${NC}"
    echo ""
    read -p "Continue? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi

    enable_multilib
    install_yay

    run_phase 0 "00-system-setup.sh" "System Preparation"
    run_phase 1 "01-packages.sh"    "Core Packages"
    run_phase 2 "02-aur.sh"         "AUR Packages"
    run_phase 3 "03-nvidia.sh"      "NVIDIA Drivers"
    run_phase 4 "04-services.sh"    "Enable Services"
    run_phase 5 "05-zsh.sh"         "ZSH Shell"
    run_phase 6 "06-dotfiles.sh"    "Deploy Dotfiles"
    run_phase 7 "08-plugins.sh"     "Hyprland Plugins (HyprGlass)"
    run_phase 8 "07-cleanup.sh"     "Final Cleanup"
    run_phase 9 "09-user-apps.sh"   "Restore User Apps & Themes"

    # Phase 10 is optional — run after dotfiles deploy
    print_phase "PHASE 10: Performance Optimization"
    echo "  Optional system tweaks for gaming: GPU OC, CPU tuning, sysctl, NVMe, GRUB."
    echo ""
    run_phase 10 "10-performance.sh" "Performance Tweaks"

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}Reboot to start Hyprland via SDDM.${NC}"
    echo -e "  ${CYAN}If you applied performance tweaks, a reboot is required.${NC}"
    echo -e "  ${CYAN}Log: $LOG_FILE${NC}"
    echo ""
}

main "$@"
