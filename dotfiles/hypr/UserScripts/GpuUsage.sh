#!/usr/bin/env bash
# GPU usage for waybar custom module
gpu=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
if [ -n "$gpu" ]; then
    IFS=', ' read -r usage vram_used vram_total temp <<< "$gpu"
    echo "{\"text\": \"󰢮 ${usage}%\", \"tooltip\": \"GPU: ${usage}% | VRAM: ${vram_used}/${vram_total}MB | Temp: ${temp}°C\"}"
else
    echo "{\"text\": \"󰢮 N/A\", \"tooltip\": \"GPU not available\"}"
fi
