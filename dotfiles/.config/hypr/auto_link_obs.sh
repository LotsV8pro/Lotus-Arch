#!/bin/bash

# Espera 5 segundos iniciales para que el sistema y el audio carguen del todo
sleep 5

while true; do
    if pw-link -i | grep -q "obs_virtual_sink"; then
        pw-link "Arctis_Game:monitor_FL" "obs_virtual_sink:playback_FL" 2>/dev/null
        pw-link "Arctis_Game:monitor_FR" "obs_virtual_sink:playback_FR" 2>/dev/null

        pw-link "Arctis_Media:monitor_FL" "obs_virtual_sink:playback_FL" 2>/dev/null                                  
        pw-link "Arctis_Media:monitor_FR" "obs_virtual_sink:playback_FR" 2>/dev/null
    fi
    sleep 3 
done
