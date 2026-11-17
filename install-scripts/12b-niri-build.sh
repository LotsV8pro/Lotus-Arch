#!/bin/bash
# Phase 12b: Build and install niri with layer animations (PR #3481).
# Only relevant for the Niri session. The stock Arch `niri` package is too old
# for the Lotus config (custom-shader, ease-in-quad, layer animations).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_FILE="$SCRIPT_DIR/../.lotus-session"
SESSION="${LOTUS_SESSION:-$(cat "$SESSION_FILE" 2>/dev/null || echo hypr)}"

if [[ "$SESSION" != "niri" && "$SESSION" != "both" ]]; then
    echo "[12b] Niri not selected; skipping custom build."
    exit 0
fi

if pacman -Q niri-lotus &>/dev/null; then
    echo "[12b] niri-lotus already installed."
    exit 0
fi

echo "[12b] Building niri with layer animations (this takes a while)..."
if ! command -v cargo &>/dev/null; then
    sudo -n pacman -S --needed --noconfirm rust cargo clang git >/dev/null
fi

BUILD="$(mktemp -d)"
cp -a "$SCRIPT_DIR/../packages/niri-lotus/." "$BUILD/"
chown -R "$(whoami)" "$BUILD"
cd "$BUILD"

if makepkg -si --noconfirm; then
    echo "[12b] niri-lotus installed."
else
    echo "[12b] Custom build failed; installing stock niri as fallback."
    sudo -n pacman -S --needed --noconfirm niri >/dev/null || true
fi
cd "$SCRIPT_DIR"
rm -rf "$BUILD"
