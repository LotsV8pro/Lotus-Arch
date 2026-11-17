#!/bin/bash
# Phase 14: Lotus extras — Vencord themes, firewall, opencode agent skills
# - Installs Vencord into Discord (or uses Vesktop's bundled one)
# - Drops the lotus-purple and caelestia pastel themes from lotus-discord
# - Enables a minimal nftables firewall (desktop: input drop, loopback + established)
# - Installs the token-optimisation skills used on this machine

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "[14] Lotus extras (Vencord themes, firewall, agent skills)..."

# ── 1. Vencord themes ────────────────────────────────────────────────────────
# Vencord itself (official CLI, pinned release with SHA-256 check).
if ! command -v vencord &>/dev/null && [[ ! -d "$HOME/.config/Vencord" ]]; then
    VENCORD_CLI_URL="https://github.com/Vencord/Installer/releases/download/v1.4.2/VencordInstallerCli-linux"
    VENCORD_SHA="52642c8521a866ad241c10337144a4f513672c54b9c86a8169954785054c815d"
    CLI_TMP="$(mktemp)"
    if curl -fsSL "$VENCORD_CLI_URL" -o "$CLI_TMP" && echo "$VENCORD_SHA  $CLI_TMP" | sha256sum -c - &>/dev/null; then
        chmod +x "$CLI_TMP"
        "$CLI_TMP" --install 2>/dev/null || true
        echo -e "  ${GREEN}[✓]${NC} Vencord installed"
    else
        echo -e "  ${YELLOW}[!]${NC} Vencord download/checksum failed; install from https://vencord.dev"
    fi
    rm -f "$CLI_TMP"
fi

THEMES_DIR="$HOME/.config/Vencord/themes"
mkdir -p "$THEMES_DIR"
for theme in lotus-purple caelestia; do
    url="https://raw.githubusercontent.com/LotsV8pro/lotus-discord/master/themes/${theme}.theme.css"
    if curl -fsSL "$url" -o "$THEMES_DIR/${theme}.theme.css"; then
        echo -e "  ${GREEN}[✓]${NC} theme ${theme}"
    else
        echo -e "  ${YELLOW}[!]${NC} could not fetch ${theme}"
    fi
done

# If Vencord is not installed, tell the user how to get it (it is not in pacman).
if [[ ! -d "$HOME/.config/Vencord" ]]; then
    echo -e "  ${YELLOW}[i]${NC} Vencord not detected. Install it from https://vencord.dev"
    echo -e "      (or use Vesktop, which ships Vencord) and enable the themes under Settings > Vencord > Themes."
fi

# ── 2. Firewall ──────────────────────────────────────────────────────────────
if command -v nft &>/dev/null; then
    if [[ ! -f /etc/nftables.conf ]]; then
        sudo tee /etc/nftables.conf >/dev/null <<'NFT'
table inet firewall {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iif "lo" accept
    ip protocol icmp accept
    ip6 nexthdr icmpv6 accept
    udp dport 68 accept
  }
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    iif "waydroid0" accept
  }
  chain output {
    type filter hook output priority filter; policy accept;
  }
}
NFT
        echo -e "  ${GREEN}[✓]${NC} nftables rules written"
    fi
    sudo systemctl enable --now nftables.service 2>/dev/null || true
fi

# ── 3. Agent skills (token optimisation) ────────────────────────────────────
SKILLS_DIR="$HOME/.config/opencode/skills"
mkdir -p "$SKILLS_DIR"
for dir in "$SCRIPT_DIR"/../dotfiles/opencode/skills/*/; do
    [[ -d "$dir" ]] && cp -r "$dir" "$SKILLS_DIR/" 2>/dev/null || true
done

echo -e "  ${GREEN}[✓]${NC} Lotus extras done."
