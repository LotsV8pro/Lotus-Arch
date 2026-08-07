#!/usr/bin/env bash
# Wire Arctis Game/Media monitor -> OBS virtual sink.
# Runs in the background and keeps the links connected across reboots/restarts.

LINKS=(
  "Arctis_Game:monitor_FL|obs_virtual_sink:playback_FL"
  "Arctis_Game:monitor_FR|obs_virtual_sink:playback_FR"
  "Arctis_Media:monitor_FL|obs_virtual_sink:playback_FL"
  "Arctis_Media:monitor_FR|obs_virtual_sink:playback_FR"
)

while true; do
  for link in "${LINKS[@]}"; do
    out="${link%%|*}"
    in="${link##*|}"
    if ! pw-link -l 2>/dev/null | grep -A1 "^${out}$" | grep -q "${in}"; then
      pw-link "${out}" "${in}" 2>/dev/null
    fi
  done
  sleep 3
done
