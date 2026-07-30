#!/bin/bash
# Apply NVIDIA GPU tweaks at boot

# Set power limit to 160W (safe undervolt, minimal perf loss)
/usr/bin/nvidia-smi -pl 160

# Memory overclock +1000 MHz (safe for GDDR6X on RTX 4070)
/usr/bin/nvidia-smi -lmc 1000
