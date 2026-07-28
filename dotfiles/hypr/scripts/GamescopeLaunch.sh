#!/usr/bin/env bash
# Gamescope launch wrapper for Steam games
# Usage: Add to Steam launch options:
#   gamescope --rt --force-grab-cursor -w 2560 -h 1440 -r 165 -F fsr -- %command%

RESOLUTION="2560x1440"
REFRESH="165"

gamescope \
    --rt \
    --force-grab-cursor \
    --nested-width 2560 \
    --nested-height 1440 \
    --refresh $REFRESH \
    --fsr-upscaling \
    --adaptive-sync \
    --hdr-enabled \
    -- \
    "$@"
