#!/bin/bash
# Apply NVIDIA GPU tweaks at boot (mirrors MSI Afterburner Preset 1)

# Power limit 216W (108% of 200W default = max)
/usr/bin/nvidia-smi -pl 216

# Memory clock +1500 MHz over 10501 MHz max (lock absolute)
/usr/bin/nvidia-smi -lmc 12001

# Core clock: replicate VF curve ceiling (3255 MHz max)
/usr/bin/nvidia-smi -lgc 3255
