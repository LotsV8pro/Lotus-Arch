#!/bin/bash
# Phase 13: Lotus Tune (optional app)
# Downloads the latest Linux x86_64 release from github.com/LotsV8pro/lotus-tune
# and installs it under ~/.local. It is an add-on, not part of the base desktop:
# skip it with --lotus-tune=no, or start it at login with LOTUS_TUNE_AUTOSTART=yes.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

answer="${LOTUS_TUNE:-ask}"
if [[ "$answer" == "ask" ]]; then
    if [[ -n "${LOTUS_UNATTENDED:-}" ]]; then
        answer="no"
    else
        read -p "  Install Lotus Tune (latest release)? [Y/n]: " reply
        case "$reply" in
            n|N|no|NO) answer="no" ;;
            *) answer="yes" ;;
        esac
    fi
fi

if [[ "$answer" != "yes" ]]; then
    echo "[13] Lotus Tune skipped."
    exit 0
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
    echo -e "${YELLOW}[!]${NC} Lotus Tune only publishes an x86_64 Linux build. Skipping."
    exit 0
fi

echo "[13] Installing Lotus Tune from GitHub releases..."

tmp="$(mktemp -d /tmp/lotus-tune.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

api="https://api.github.com/repos/LotsV8pro/lotus-tune/releases/latest"
if ! curl -fsSL --retry 3 "$api" -o "$tmp/release.json"; then
    echo -e "${YELLOW}[!]${NC} GitHub is unreachable. Skipping Lotus Tune."
    exit 0
fi

info="$(python3 - "$tmp/release.json" <<'PY'
import json, sys
release = json.load(open(sys.argv[1]))
for asset in release.get("assets", []):
    if asset["name"].endswith("linux-x86_64.tar.gz"):
        print(release.get("tag_name", "unknown"),
              asset["browser_download_url"],
              asset.get("digest", ""))
        break
PY
)" || info=""

if [[ -z "$info" ]]; then
    echo -e "${YELLOW}[!]${NC} This release has no Linux x86_64 tarball. Skipping."
    exit 0
fi

read -r tag url digest <<< "$info"
echo "  → release $tag"

if ! curl -fL --retry 3 --progress-bar -o "$tmp/lotus-tune.tar.gz" "$url"; then
    echo -e "${YELLOW}[!]${NC} Download failed. Skipping Lotus Tune."
    exit 0
fi

if [[ "$digest" == sha256:* ]]; then
    echo "${digest#sha256:}  $tmp/lotus-tune.tar.gz" | sha256sum -c - >/dev/null
    echo "  → checksum OK"
fi

tar -xzf "$tmp/lotus-tune.tar.gz" -C "$tmp"
root="$(find "$tmp" -maxdepth 1 -type d -name 'lotus-tune-*' | head -1)"
if [[ -z "$root" || ! -x "$root/bin/lotus-tune" ]]; then
    echo -e "${YELLOW}[!]${NC} Unexpected tarball layout. Skipping Lotus Tune."
    exit 0
fi

bin="$HOME/.local/bin"
apps="$HOME/.local/share/applications"
icons="$HOME/.local/share/icons/hicolor/scalable/apps"
meta="$HOME/.local/share/metainfo"
doc="$HOME/.local/share/doc/lotus-tune"
state="$HOME/.local/share/lotus-tune"
install -d "$bin" "$apps" "$icons" "$meta" "$doc" "$state"

install -m755 "$root/bin/lotus-tune" "$bin/lotus-tune"
for helper in ytm_api.py ytm_login.py; do
    [[ -f "$root/bin/$helper" ]] && install -m755 "$root/bin/$helper" "$bin/$helper"
done
[[ -f "$root/share/icons/hicolor/scalable/apps/lotus-tune.svg" ]] && \
    install -m644 "$root/share/icons/hicolor/scalable/apps/lotus-tune.svg" "$icons/lotus-tune.svg"
if [[ -f "$root/share/applications/lotus-tune.desktop" ]]; then
    sed "s|^Exec=lotus-tune|Exec=$bin/lotus-tune|" \
        "$root/share/applications/lotus-tune.desktop" > "$apps/lotus-tune.desktop"
fi
[[ -f "$root/share/metainfo/lotus-tune.metainfo.xml" ]] && \
    install -m644 "$root/share/metainfo/lotus-tune.metainfo.xml" "$meta/lotus-tune.metainfo.xml"
[[ -f "$root/share/doc/lotus-tune/README.md" ]] && \
    install -m644 "$root/share/doc/lotus-tune/README.md" "$doc/README.md"

printf '%s\n' "$tag" > "$state/version"

if [[ "${LOTUS_TUNE_AUTOSTART:-no}" == "yes" ]] && command -v systemctl >/dev/null 2>&1; then
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/lotus-tune.service" <<'EOF'
[Unit]
Description=Lotus Tune Music Player
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/lotus-tune
Restart=on-failure
WorkingDirectory=%h
Environment="QT_QPA_PLATFORM=wayland"
Environment="QT_QPA_PLATFORMTHEME=qt6ct"

[Install]
WantedBy=graphical-session.target
EOF
    systemctl --user daemon-reload || true
    systemctl --user enable lotus-tune.service || true
    echo "  → autostart enabled"
fi

command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$apps" >/dev/null 2>&1 || true

echo -e "${GREEN}[✓]${NC} Lotus Tune $tag installed: $bin/lotus-tune"
echo "  Run it from the app launcher or with: lotus-tune"
