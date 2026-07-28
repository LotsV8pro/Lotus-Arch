#!/bin/bash
# ██████╗ ███████╗██╗   ██╗███████╗███╗   ██╗███████╗██████╗
# ██╔══██╗██╔════╝██║   ██║██╔════╝████╗  ██║██╔════╝██╔══██╗
# ██║  ██║█████╗  ██║   ██║█████╗  ██╔██╗ ██║█████╗  ██████╔╝
# ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗
# ██████╔╝███████╗ ╚████╔╝ ███████╗██║ ╚████║███████╗██║  ██║
# ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
#
# Arch DedSec - Hyprland Desktop Installer
# NVIDIA RTX 4070 + i7-13700KF optimized
#
# From minimal Arch to full DedSec desktop in one script.
#
# Usage:
#   git clone https://github.com/LotsV8pro/Arch-DedSec.git
#   cd Arch-DedSec
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

  ██████╗ ███████╗██╗   ██╗███████╗███╗   ██╗███████╗██████╗
  ██╔══██╗██╔════╝██║   ██║██╔════╝████╗  ██║██╔════╝██╔══██╗
  ██║  ██║█████╗  ██║   ██║█████╗  ██╔██╗ ██║█████╗  ██████╔╝
  ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗
  ██████╔╝███████╗ ╚████╔╝ ███████╗██║ ╚████║███████╗██║  ██║
  ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝

EOF
    echo -e "${NC}"
    echo -e "${CYAN}  Arch Linux + Hyprland | Full Desktop Environment${NC}"
    echo -e "${CYAN}  https://github.com/LotsV8pro/Arch-DedSec${NC}"
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

    echo -e "${CYAN}This installer will set up:${NC}"
    echo ""
    echo "  Hyprland + Waybar + Rofi + Kitty terminal"
    echo "  PipeWire audio + SDDM display manager"
    echo "  NVIDIA drivers (open-dkms)"
    echo "  Steam + MangoHud + Gaming tools"
    echo "  ZSH + Oh-My-ZSH"
    echo "  All DedSec purple theme dotfiles"
    echo "  50+ waybar themes, animations, palettes"
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
    run_phase 7 "07-cleanup.sh"     "Final Cleanup"

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}Reboot to start Hyprland via SDDM.${NC}"
    echo -e "  ${CYAN}Log: $LOG_FILE${NC}"
    echo ""
}

main "$@"
