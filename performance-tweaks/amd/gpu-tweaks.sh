#!/bin/bash
# AMD GPU tweaks — force max performance level (amdgpu)
# Optional: enable ppfeaturemask (50-amdgpu.conf) for OC via CoreCtrl/Mesa

GPU_DIR=$(ls -d /sys/class/drm/card*/device 2>/dev/null | head -1)
[ -n "$GPU_DIR" ] || exit 0

# Force highest DPM performance level (high = max clocks)
if [ -w "$GPU_DIR/power_dpm_force_performance_level" ]; then
    echo high > "$GPU_DIR/power_dpm_force_performance_level" 2>/dev/null || true
fi

# Prefer the 3D fullscreen workload profile when exposed
if [ -w "$GPU_DIR/power_dpm_workload_type" ]; then
    echo "3d_full_screen" > "$GPU_DIR/power_dpm_workload_type" 2>/dev/null || true
fi
