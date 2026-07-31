#!/bin/bash
# Phase 10: Performance optimization tweaks (optional)
# GPU undervolt, OC, fan curve, CPU tuning, sysctl, NVMe, GRUB cstates

set -euo pipefail

PERF_DIR="$SCRIPT_DIR/performance-tweaks"

echo "[10] Performance Optimization Tweaks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Apply system tweaks for gaming performance:"
echo "    • GPU: 160W power limit, +150 MHz core OC, +1500 MHz mem OC"
echo "    • GPU: Dynamic fan curve (30%-100% based on temp)"
echo "    • CPU: Performance governor, min perf 50%, C-state limit"
echo "    • RAM: Lower swappiness, reduced write caching"
echo "    • NVMe: 512KB read-ahead"
echo "    • NVIDIA: Coolbits for full OC control"
echo ""

echo -n "  Apply performance tweaks? [y/N]: "
read -r perf_ans
if [[ ! "$perf_ans" =~ ^[Yy] ]]; then
    echo "  Skipping performance tweaks."
    exit 0
fi

echo ""

apply_gpu_power() {
    echo -n "    GPU power limit (160W) + memory OC (+1000 MHz)? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 755 "$PERF_DIR/gpu-tweaks.sh" /usr/local/bin/gpu-tweaks.sh
        sudo install -m 644 "$PERF_DIR/systemd/gpu-tweaks.service" /etc/systemd/system/gpu-tweaks.service
        sudo systemctl enable gpu-tweaks.service 2>/dev/null || true
        echo "      ✓ GPU power limit + memory OC enabled"
    else
        echo "      Skipped."
    fi
}

apply_gpu_core() {
    echo -n "    GPU core OC (+130 MHz) + dynamic fan curve? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 755 "$PERF_DIR/gpu-fan-curve.sh" /usr/local/bin/gpu-fan-curve.sh
        sudo install -m 644 "$PERF_DIR/systemd/gpu-fan-curve.service" /etc/systemd/system/gpu-fan-curve.service
        sudo systemctl enable gpu-fan-curve.service 2>/dev/null || true
        echo "      ✓ GPU core OC + fan curve enabled"
    else
        echo "      Skipped."
    fi
}

apply_cpu() {
    echo -n "    CPU performance governor + min perf 50%? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 755 "$PERF_DIR/cpu-tweaks.sh" /usr/local/bin/cpu-tweaks.sh
        sudo install -m 644 "$PERF_DIR/systemd/cpu-tweaks.service" /etc/systemd/system/cpu-tweaks.service
        sudo install -m 644 "$PERF_DIR/systemd/performance-governor.service" /etc/systemd/system/performance-governor.service
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
        echo 50 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct > /dev/null 2>&1 || true

        echo "      ✓ CPU tweaks enabled"
    else
        echo "      Skipped."
    fi
}

apply_sysctl() {
    echo -n "    RAM/IO sysctl tweaks (swappiness=5, dirty ratios, etc.)? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 644 "$PERF_DIR/99-performance.conf" /etc/sysctl.d/99-performance.conf
        sudo sysctl --system 2>/dev/null || true
        echo "      ✓ sysctl tweaks applied"
    else
        echo "      Skipped."
    fi
}

apply_nvidia_coolbits() {
    echo -n "    NVIDIA X config (Coolbits for OC/fan control)? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo mkdir -p /etc/X11/xorg.conf.d
        sudo install -m 644 "$PERF_DIR/10-nvidia.conf" /etc/X11/xorg.conf.d/10-nvidia.conf
        echo "      ✓ Coolbits enabled (reboot required)"
    else
        echo "      Skipped."
    fi
}

apply_nvme() {
    echo -n "    NVMe read-ahead (512KB for faster loading)? [Y/n]: "
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
        sudo install -m 644 "$PERF_DIR/99-nvme-performance.rules" /etc/udev/rules.d/99-nvme-performance.rules
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
        if sudo bash "$PERF_DIR/grub-cmdline.sh"; then
            echo "      ✓ GRUB updated (reboot required)"
        else
            echo "      ✗ Failed to update GRUB"
        fi
    else
        echo "      Skipped."
    fi
}

echo ""
echo "  ── Individual tweaks ──"
apply_gpu_power
apply_gpu_core
apply_cpu
apply_sysctl
apply_nvidia_coolbits
apply_nvme
apply_grub

echo ""
echo "[10] Performance tweaks applied."
echo "  ⚠  Reboot required for GRUB params, Coolbits, and some sysctls."
