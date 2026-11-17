#!/bin/bash
# Phase 2: AUR packages — grouped categories (one prompt per group)
#
# Groups marked [core] are always installed (the theme/system depends on them).
# The OBS capture group follows the streaming choice made at install start
# (LOTUS_STREAMING=yes|no).

set -euo pipefail

echo "[02] Installing AUR packages..."

SESSION="${LOTUS_SESSION:-hypr}"
STREAMING="${LOTUS_STREAMING:-yes}"

# ── Grouped AUR packages ─────────────────────────────────────────────────────
# name:desc
AUR_GROUPS=(
    "BROWSING:Browsing & Dev (Zen Browser, GitHub CLI)"
    "CHAT:Chat (Discord)"
    "MEDIA:Media & Audio tools (Spotify, cava, noise suppression)"
    "DESKTOP:Desktop extras (Wallpaper Engine, OpenRGB, DeepCool Digital)"
)

# [core] groups — no prompt, always selected
CORE_PACKAGES=(
    zram-generator
    wallust
    gtk-engine-murrine
    ttf-victor-mono
    quickshell
)

GROUP_PACKAGES=(
    "BROWSING:zen-browser-bin github-cli"
    "CHAT:discord"
    "MEDIA:spotify cava noise-suppression-for-voice"
    "DESKTOP:linux-wallpaperengine-bin openrgb deepcool-digital-linux-git"
)

SELECTED=("${CORE_PACKAGES[@]}")

for entry in "${AUR_GROUPS[@]}"; do
    name="${entry%%:*}"
    desc="${entry#*:}"

    if [[ "${LOTUS_UNATTENDED:-}" == "full" ]]; then
        echo "  Install $desc? [auto: yes]"
    elif [[ "${LOTUS_UNATTENDED:-}" == "minimal" ]]; then
        echo "  [skip] $desc — minimal preset"
        continue
    else
        echo -e -n "\n  Install $desc? [Y/n]: "
        read -r ans
        [[ "$ans" =~ ^[Nn] ]] && continue
    fi

    for g in "${GROUP_PACKAGES[@]}"; do
        [[ "${g%%:*}" == "$name" ]] && SELECTED+=(${g#*:})
    done
done

# OBS PipeWire audio capture — part of the streaming pack
if [[ "$STREAMING" == "yes" && "${LOTUS_UNATTENDED:-}" != "minimal" ]]; then
    SELECTED+=(obs-pipewire-audio-capture-git)
fi

VALID=()
for pkg in "${SELECTED[@]}"; do
    if yay -Si "$pkg" &>/dev/null 2>&1; then
        VALID+=("$pkg")
    fi
done

if [[ ${#VALID[@]} -gt 0 ]]; then
    yay -S --needed --noconfirm "${VALID[@]}" 2>/dev/null || true
else
    echo "  No AUR packages selected."
fi

echo "[02] AUR packages installed."
