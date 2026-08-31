#!/bin/bash
# ██╗      ██████╗ ████████╗██╗   ██╗███████╗
# ██║     ██╔═══██╗╚══██╔══╝██║   ██║██╔════╝
# ██║     ██║   ██║   ██║   ██║   ██║███████╗
# ██║     ██║   ██║   ██║   ██║   ██║╚════██║
# ███████╗╚██████╔╝   ██║   ╚██████╔╝███████║
# ╚══════╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝
#
# Lotus-Arch - Desktop Installer
# Works on any GPU (NVIDIA / AMD / Intel) and any CPU.
# Hyprland (Lua config) and/or Niri + iNiR shell — your choice.
#
# From minimal Arch to full Lotus-Arch desktop in one script.
#
# Usage:
#   git clone https://github.com/LotsV8pro/Lotus-Arch.git
#   cd Lotus-Arch
#   chmod +x install.sh
#   ./install.sh

set -euo pipefail

export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ── CLI presets (unattended) ─────────────────────────────────────────────────
#   ./install.sh --preset minimal   lean Hyprland-only setup, no prompts
#   ./install.sh --preset full      everything on, both sessions, no prompts
#   Optional overrides:
#     --session hypr|niri|both      (default: minimal→hypr, full→both)
#     --audio arctis|basic          (default: full→arctis, minimal→basic)
#     --streaming yes|no            (default: full→yes,  minimal→no)
PRESET=""
for arg in "$@"; do
    case "$arg" in
        --preset=*)    PRESET="${arg#*=}" ;;
        --preset)      PRESET="full" ;;
        --minimal)     PRESET="minimal" ;;
        --session=*)   export LOTUS_SESSION="${arg#*=}" ;;
        --audio=*)     export LOTUS_AUDIO="${arg#*=}" ;;
        --streaming=*) export LOTUS_STREAMING="${arg#*=}" ;;
        -h|--help)
            sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
    esac
done
if [[ -n "$PRESET" ]]; then
    case "$PRESET" in
        minimal)
            export LOTUS_UNATTENDED="minimal"
            export LOTUS_SESSION="${LOTUS_SESSION:-hypr}"
            export LOTUS_AUDIO="${LOTUS_AUDIO:-basic}"
            export LOTUS_STREAMING="${LOTUS_STREAMING:-no}" ;;
        full)
            export LOTUS_UNATTENDED="full"
            export LOTUS_SESSION="${LOTUS_SESSION:-both}"
            export LOTUS_AUDIO="${LOTUS_AUDIO:-arctis}"
            export LOTUS_STREAMING="${LOTUS_STREAMING:-yes}" ;;
        *) echo "Unknown preset: $PRESET (use minimal|full)"; exit 1 ;;
    esac
fi

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
    echo -e "${CYAN}  Arch Linux | Hyprland / Niri + iNiR | Any GPU${NC}"
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
        return 0
    fi

    # makepkg needs base-devel + git to build yay from the AUR.
    if ! command -v makepkg &>/dev/null || ! command -v git &>/dev/null; then
        print_info "Installing base-devel + git (required to build yay)..."
        sudo pacman -S --needed --noconfirm base-devel git
    fi

    print_info "Installing yay (AUR helper)..."
    local build_dir
    build_dir="$(mktemp -d /tmp/yay-build.XXXXXX)"

    # Ensure the script dir is writable by the user so the final cd works.
    if ! git clone https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin" 2>&1; then
        print_error "Failed to clone yay-bin"
        rm -rf "$build_dir"
        exit 1
    fi

    # makepkg refuses to run as root; we already enforce a non-root user.
    (cd "$build_dir/yay-bin" && makepkg -si --noconfirm) || {
        print_error "yay build/install failed"
        rm -rf "$build_dir"
        exit 1
    }

    rm -rf "$build_dir"
    cd "$SCRIPT_DIR"
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
    if [[ -n "${LOTUS_UNATTENDED:-}" ]]; then
        echo ""
        echo -e "${CYAN}Unattended preset: ${LOTUS_UNATTENDED} (session: ${LOTUS_SESSION}, audio: ${LOTUS_AUDIO:-arctis}, streaming: ${LOTUS_STREAMING:-yes})${NC}"
    fi
    echo ""
    echo "  You will be asked about each component:"
    echo ""
    echo "  ◈ Session choice (first question below):"
    echo "    Hyprland, Niri + iNiR shell, or Both"
    echo ""
    echo "  ◈ Phase 1 — Core (choose what you want)"
    echo "    Waybar, Rofi, Kitty, Thunar"
    echo "    PipeWire, SDDM, fonts, dev tools"
    echo "    Gaming (Steam, Lutris, MangoHud, Gamescope)"
    echo "    Media, Bluetooth, Network, and more"
    echo "    → Hyprland and/or Niri packages per your session choice"
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
    echo "              → selectable profile: NVIDIA+Intel or AMD (each tweak optional)"
    echo "  ◈ Phase 11 — Optional extras [y/N each]"
    echo "              → extra look presets, GPU tuning pack,"
    echo "                GT Racing wallpapers, movie-tui"
    echo "  ◈ Phase 12 — iNiR shell setup (only if Niri chosen; optional)"
    echo ""
    echo "  Then dotfiles deployed with auto-backup."
    echo "  The Lotus preset is always included; extra presets are optional."
    echo ""
    echo -e "${YELLOW}  ⚠  Reboot required after installation.${NC}"
    echo -e "${YELLOW}  ⚠  Your existing configs will be backed up.${NC}"
    echo ""
    if [[ -z "${LOTUS_UNATTENDED:-}" ]]; then
        read -p "Continue? [y/N]: " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi

    # ── Session choice ──
    # iNiR is OPTIONAL: pick Hyprland only if you don't want it.
    if [[ -n "${LOTUS_UNATTENDED:-}" ]]; then
        export LOTUS_SESSION="${LOTUS_SESSION:-hypr}"
    else
        echo ""
        echo -e "${CYAN}Choose your desktop session:${NC}"
        echo ""
        echo "  1) Hyprland            — tiling compositor, Lua config, waybar"
        echo "  2) Niri + iNiR shell   — scrollable tiling + full Quickshell desktop"
        echo "                           (iNiR is OPTIONAL — skip by choosing 1 or 3)"
        echo "  3) Both                — install both sessions, pick at the SDDM login"
        echo ""
        read -p "Session [1/2/3] (default: 1): " sess
        case "$sess" in
            2) export LOTUS_SESSION="niri" ;;
            3) export LOTUS_SESSION="both" ;;
            *) export LOTUS_SESSION="hypr" ;;
        esac
    fi
    echo -e "  ${GREEN}→ Session: ${LOTUS_SESSION}${NC}"

    # ── Hardware pack choices (drive Phase 2/6/9 gating) ──
    if [[ -z "${LOTUS_UNATTENDED:-}" ]]; then
        echo ""
        echo -e "${CYAN}Hardware packs (applied to BOTH sessions):${NC}"
        read -p "  Arctis Nova 5 audio pipeline (Sonar EQ, virtual surround)? [Y/n]: " a_ans
        [[ "$a_ans" =~ ^[Nn] ]] && export LOTUS_AUDIO="basic" || export LOTUS_AUDIO="arctis"
        read -p "  OBS streaming pack (OBS config, virtual mic, audio router)? [y/N]: " s_ans
        [[ "$s_ans" =~ ^[Yy] ]] && export LOTUS_STREAMING="yes" || export LOTUS_STREAMING="no"
    fi
    export LOTUS_AUDIO="${LOTUS_AUDIO:-arctis}"
    export LOTUS_STREAMING="${LOTUS_STREAMING:-yes}"
    echo -e "  ${GREEN}→ Audio: ${LOTUS_AUDIO} · Streaming: ${LOTUS_STREAMING}${NC}"

    # ── Graphics card selection ──
    # Controls which drivers install (Phase 3) and which overclock profile
    # Phase 10 offers. Auto-detects when possible; the overclock config itself
    # is still a separate opt-in inside Phase 10.
    if command -v lspci &>/dev/null && lspci -nn 2>/dev/null | grep -qiE 'vga.*nvidia|3d.*nvidia'; then
        DETECTED_GPU="nvidia"
    elif command -v lspci &>/dev/null && lspci -nn 2>/dev/null | grep -qiE 'vga.*amd|3d.*amd|vga.*advanced micro'; then
        DETECTED_GPU="amd"
    else
        DETECTED_GPU="intel"
    fi
    if [[ -z "${LOTUS_UNATTENDED:-}" ]]; then
        echo ""
        echo -e "${CYAN}Graphics card (selects which GPU drivers are installed):${NC}"
        echo "  1) NVIDIA   (nvidia-open-dkms + settings)"
        echo "  2) AMD      (amdgpu/mesa)"
        echo "  3) Intel    (integrated only)"
        read -p "  Graphics [1/2/3] (default: ${DETECTED_GPU}): " gpu_ans
        case "$gpu_ans" in
            2|amd|AMD) export LOTUS_GPU="amd" ;;
            3|intel|Intel) export LOTUS_GPU="intel" ;;
            1|nvidia|NVIDIA) export LOTUS_GPU="nvidia" ;;
            *) export LOTUS_GPU="$DETECTED_GPU" ;;
        esac
    else
        export LOTUS_GPU="${LOTUS_GPU:-$DETECTED_GPU}"
    fi
    echo -e "  ${GREEN}→ Graphics card: ${LOTUS_GPU}${NC}"

    enable_multilib
    install_yay

    run_phase 0 "00-system-setup.sh" "System Preparation"
    run_phase 1 "01-packages.sh"    "Core Packages"
    run_phase 2 "02-aur.sh"         "AUR Packages"
    run_phase 3 "03-nvidia.sh"      "GPU Drivers"
    run_phase 4 "04-services.sh"    "Enable Services"
    run_phase 5 "05-zsh.sh"         "ZSH Shell"
    run_phase 6 "06-dotfiles.sh"    "Deploy Dotfiles"

    # Phase 7 is optional — runs right after the dotfiles it patches
    run_phase 7 "07-plugins.sh"     "Hyprland Plugins (HyprGlass)"
    run_phase 8 "08-cleanup.sh"     "Final Cleanup"
    run_phase 9 "09-user-apps.sh"   "Restore User Apps & Themes"

    # Phase 10 is optional — run after dotfiles deploy
    print_phase "PHASE 10: Performance Optimization"
    echo "  Optional system tweaks for gaming: GPU OC, CPU tuning, sysctl, NVMe, GRUB."
    echo ""
    run_phase 10 "10-performance.sh" "Performance Tweaks"
    run_phase 11 "11-optional-extras.sh" "Optional Extras (presets / GPU / wallpapers)"
    if [[ "$LOTUS_SESSION" == "niri" || "$LOTUS_SESSION" == "both" ]]; then
        run_phase 12 "12-niri-inir.sh" "Niri + iNiR Shell (optional session)"
    fi

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}Reboot and pick your session (Hyprland / Niri) at SDDM.${NC}"
    echo -e "  ${CYAN}If you applied performance tweaks, a reboot is required.${NC}"
    echo -e "  ${CYAN}Log: $LOG_FILE${NC}"
    echo ""
}

main "$@"
