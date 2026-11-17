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
