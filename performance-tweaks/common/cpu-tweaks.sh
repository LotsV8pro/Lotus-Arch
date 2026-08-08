#!/bin/bash
# CPU performance tweaks (Intel + AMD compatible)

# Intel pstate: keep min perf at 50% to reduce ramp-up latency (intel_pstate only)
if [ -d /sys/devices/system/cpu/intel_pstate ]; then
    echo 50 > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
fi

# AMD pstate (when active): prefer the performance energy profile
if [ -d /sys/devices/system/cpu/amd_pstate ]; then
    for pref in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        [ -w "$pref" ] && echo performance > "$pref" 2>/dev/null
    done
fi

# Make sure energy perf is performance (works on both pstate and acpi-cpufreq)
cpupower set -e performance 2>/dev/null || true
