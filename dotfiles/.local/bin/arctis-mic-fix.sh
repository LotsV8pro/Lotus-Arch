#!/usr/bin/env bash
set -euo pipefail

# Busca la tarjeta SteelSeries Arctis Nova 5 (USBID 1038:2232)
for card_dir in /proc/asound/card*; do
  usbid="$(cat "$card_dir/usbid" 2>/dev/null || true)"
  if [[ "$usbid" == "1038:2232" ]]; then
    card="${card_dir##*/}"; card="${card#card}"
    amixer -s -c "$card" sset 'Headset' 100% >/dev/null 2>&1 \
      && echo "MIC Gain Arctis fijado a 100% (card $card)" \
      || echo "ERROR: no se pudo ajustar 'Headset' en card $card"
    exit 0
  fi
done
echo "Arctis Nova 5 no detectado"
exit 0