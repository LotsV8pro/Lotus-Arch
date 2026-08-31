#!/bin/bash

# Auto-bridge EasyEffects master output to the physical Arctis headset PCM.
# Survives EasyEffects / PipeWire restarts by re-linking a few seconds later.

SLEEP=5
OUT="alsa_output.usb-SteelSeries_SteelSeries_Arctis_Nova_5-00.pro-output-0"

sleep "$SLEEP"

while true; do
    if pw-link -i | grep -q "easyeffects_source"; then
        pw-link "easyeffects_source:capture_FL" "$OUT:playback_AUX0" 2>/dev/null
        pw-link "easyeffects_source:capture_FR" "$OUT:playback_AUX1" 2>/dev/null
    fi
    sleep 3
done
