#!/bin/bash
# Phase 10: Performance optimization tweaks (optional, hardware-profile based)
# Pick your hardware profile and apply only the tweaks you want.
#   NVIDIA + Intel  → RTX 4070 tuned (power/OC via nvidia-smi, Coolbits, fan curve, pstate)
#   AMD             → amdgpu performance level, hwmon fan curve, pstate EPP, ppfeaturemask

set -euo pipefail

PERF_DIR="$SCRIPT_DIR/performance-tweaks"

echo "[10] Performance Optimization Tweaks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Select your hardware profile — GPU tweaks differ per vendor:"
echo "    [1] NVIDIA + Intel   (RTX 4070 OC/fan curve via nvidia-smi, Coolbits)"
echo "    [2] AMD              (amdgpu perf level, hwmon fan curve, pstate)"
echo ""
echo -n "  Hardware profile [1/2/s=SkiP]: "
read -r profile
case "$profile" in
    s|S|n|N) echo "  Skipping performance tweaks."; exit 0 ;;
    2|amd|AMD) PROFILE="amd" ;;
    *)        PROFILE="intel" ;;
esac

echo "  Using profile: $PROFILE"
echo "  (you can skip every individual tweak with n/N)"
echo ""

apply_gpu_power() {
    if [[ "$PROFILE" == "amd" ]]; then
        echo -n "    AMD GPU max performance level (DPM high)? [Y/n]: "
        read -r ans
        if [[ ! "$ans" =~ ^[Nn] ]]; then
            sudo install -m 755 "$PERF_DIR/amd/gpu-tweaks.sh" /usr/local/bin/gpu-tweaks.sh
            sudo install -m 644 "$PERF_DIR/amd/systemd/gpu-tweaks.service" /etc/systemd/system/gpu-tweaks.service
            sudo systemctl enable gpu-tweaks.service 2>/dev/null || true
            echo "      ✓ AMD GPU performance tweaks enabled"
        else
            echo "      Skipped."
        fi
    else
        echo -n "    GPU power limit (160W) + memory OC (+1500 MHz)? [Y/n]: "
        read -r ans
        if [[ ! "$ans" =~ ^[Nn] ]]; then
            sudo install -m 755 "$PERF_DIR/nvidia/gpu-tweaks.sh" /usr/local/bin/gpu-tweaks.sh
            sudo install -m 644 "$PERF_DIR/nvidia/systemd/gpu-tweaks.service" /etc/systemd/system/gpu-tweaks.service
            sudo systemctl enable gpu-tweaks.service 2>/dev/null || true
            echo "      ✓ GPU power limit + memory OC enabled"
        else
            echo "      Skipped."
        fi
    fi
}

apply_gpu_fan() {
    if [[ "$PROFILE" == "amd" ]]; then
        echo -n "    AMD GPU core OC + dynamic fan curve? [Y/n]: "
    else
        echo -n "    GPU core OC (+150 MHz) + dynamic fan curve? [Y/n]: "
    fi
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 755 "$PERF_DIR/$PROFILE/gpu-fan-curve.sh" /usr/local/bin/gpu-fan-curve.sh
        sudo install -m 644 "$PERF_DIR/$PROFILE/systemd/gpu-fan-curve.service" /etc/systemd/system/gpu-fan-curve.service
        sudo systemctl enable gpu-fan-curve.service 2>/dev/null || true
        echo "      ✓ GPU core OC + fan curve enabled"
    else
        echo "      Skipped."
    fi
}

apply_cpu() {
    echo -n "    CPU performance governor + min perf 50% (Intel pstate / AMD pstate EPP)? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 755 "$PERF_DIR/common/cpu-tweaks.sh" /usr/local/bin/cpu-tweaks.sh
        sudo install -m 644 "$PERF_DIR/common/systemd/cpu-tweaks.service" /etc/systemd/system/cpu-tweaks.service
        sudo install -m 644 "$PERF_DIR/common/systemd/performance-governor.service" /etc/systemd/system/performance-governor.service
        sudo systemctl enable cpu-tweaks.service 2>/dev/null || true
        sudo systemctl enable performance-governor.service 2>/dev/null || true

        # Mask power-profiles-daemon — it overrides the governor
        sudo systemctl stop power-profiles-daemon.service 2>/dev/null || true
        sudo systemctl mask power-profiles-daemon.service 2>/dev/null || true

        # Remove conflicting user-level service
        rm -f "$HOME/.config/systemd/user/performance-governor.service" 2>/dev/null || true
        systemctl --user daemon-reload 2>/dev/null || true

        # Apply immediately
        sudo cpupower frequency-set -g performance 2>/dev/null || true
        if [[ "$PROFILE" == "intel" ]] && [ -d /sys/devices/system/cpu/intel_pstate ]; then
            echo 50 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct > /dev/null 2>&1 || true
        fi

        echo "      ✓ CPU tweaks enabled"
    else
        echo "      Skipped."
    fi
}

apply_sysctl() {
    echo -n "    RAM/IO sysctl tweaks (swappiness=5, dirty ratios, etc.)? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 644 "$PERF_DIR/common/99-performance.conf" /etc/sysctl.d/99-performance.conf
        sudo sysctl --system 2>/dev/null || true
        echo "      ✓ sysctl tweaks applied"
    else
        echo "      Skipped."
    fi
}

apply_gpu_xconf() {
    if [[ "$PROFILE" == "amd" ]]; then
        echo -n "    AMD ppfeaturemask (overclocking via CoreCtrl)? [Y/n]: "
        read -r ans
        if [[ ! "$ans" =~ ^[Nn] ]]; then
            sudo mkdir -p /etc/modprobe.d
            sudo install -m 644 "$PERF_DIR/amd/50-amdgpu.conf" /etc/modprobe.d/50-amdgpu.conf
            echo "      ✓ amdgpu OC enabled (reboot required)"
        else
            echo "      Skipped."
        fi
    else
        echo -n "    NVIDIA X config (Coolbits for OC/fan control)? [Y/n]: "
        read -r ans
        if [[ ! "$ans" =~ ^[Nn] ]]; then
            sudo mkdir -p /etc/X11/xorg.conf.d
            sudo install -m 644 "$PERF_DIR/nvidia/10-nvidia.conf" /etc/X11/xorg.conf.d/10-nvidia.conf
            echo "      ✓ Coolbits enabled (reboot required)"
        else
            echo "      Skipped."
        fi
    fi
}

apply_nvme() {
    echo -n "    NVMe read-ahead (512KB for faster loading)? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 644 "$PERF_DIR/common/99-nvme-performance.rules" /etc/udev/rules.d/99-nvme-performance.rules
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo udevadm trigger 2>/dev/null || true
        echo "      ✓ NVMe read-ahead set to 512KB"
    else
        echo "      Skipped."
    fi
}

apply_grub() {
    echo -n "    GRUB kernel params (CPU C-state limits for lower latency)? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        if sudo bash "$PERF_DIR/common/grub-cmdline.sh" "$PROFILE"; then
            echo "      ✓ GRUB updated (reboot required)"
        else
            echo "      ✗ Failed to update GRUB"
        fi
    else
        echo "      Skipped."
    fi
}

echo ""
echo "  ── Individual tweaks ($PROFILE) ──"
apply_gpu_power
apply_gpu_fan
apply_cpu
apply_sysctl
apply_gpu_xconf
apply_nvme
apply_grub

echo ""
echo "[10] Performance tweaks applied."
echo "  ⚠  Reboot required for GRUB params, Coolbits/ppfeaturemask, and some sysctls."
