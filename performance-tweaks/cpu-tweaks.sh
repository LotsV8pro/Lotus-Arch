#!/bin/bash
# CPU performance tweaks

# Prevent deep downclocking — keep min perf at 50% to reduce ramp-up latency
echo 50 > /sys/devices/system/cpu/intel_pstate/min_perf_pct

# Make sure energy perf is performance (should already be)
cpupower set -e performance
