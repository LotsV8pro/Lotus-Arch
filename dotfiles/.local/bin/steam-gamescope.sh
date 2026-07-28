#!/bin/bash
# Gamescope + Gamemode wrapper for Steam games
# Apply as global Steam launch option:
#   gamemoderun gamescope --rt --force-grab-cursor -w 2560 -h 1440 -r 165 -f -- taskset -c 0-11 %command% -nogui -skip-prereqs

exec gamemoderun gamescope \
    --rt \
    --force-grab-cursor \
    -w 2560 \
    -h 1440 \
    -r 165 \
    -f \
    -- taskset -c 0-11 "$@" -nogui -skip-prereqs
