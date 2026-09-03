#!/bin/bash
# Lotus-Arch Google Calendar sync (events + contact birthdays) setup.
#
# Sets up the "inir-birthdays" sync stack for YOUR Google account:
#   - copies the sync scripts into ~/.config/inir-birthdays/
#   - walks you through creating your own OAuth token (gcalcli)
#   - adds the People/Contacts scope for birthday contact writes
#   - installs + enables the periodic sync timer (every 5 min)
#
# Nothing personal is shipped in this repo: you supply your own Google Cloud
# OAuth client, and the token is stored only under ~/.local/share/gcalcli/.
#
#   bash tools/install-calendar.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info(){ echo -e "${CYAN}[calendar]${NC} $*"; }
ok(){ echo -e "${GREEN}[✓]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }

CONF_DIR="$HOME/.config/inir-birthdays"
OAUTH="$HOME/.local/share/gcalcli/oauth"

echo "════════════════════════════════════════════════"
echo "  Lotus-Arch · Google Calendar + Birthdays setup"
echo "════════════════════════════════════════════════"

# ── 1. Python + gcalcli + libs ──────────────────────────────────────────────
if ! command -v python3 >/dev/null; then
    echo "python3 is required. Install it with: sudo pacman -S python python-pip"
    exit 1
fi

DEPS_MSG="Install the Python tooling with:
  python -m pip install --user gcalcli google-api-python-client google-auth-oauthlib requests
Ensure the dir holding gcalcli is on your PATH (often ~/.local/bin)."

if ! command -v gcalcli >/dev/null; then
    warn "gcalcli not found."
    echo -e "$DEPS_MSG"
    exit 1
fi
ok "gcalcli found: $(command -v gcalcli)"

python3 - <<'PY' || { warn "missing Python libs. $DEPS_MSG"; exit 1; }
import googleapiclient, google_auth_oauthlib, requests   # noqa
import zoneinfo                                          # noqa
PY
ok "Python dependencies found."

# ── 2. OAuth token ──────────────────────────────────────────────────────────
if [[ -f "$OAUTH" ]]; then
    ok "OAuth token found at $OAUTH"
    echo "  If you are starting fresh, or you only have the calendar scope:"
else
    warn "No OAuth token yet at $OAUTH"
fi

echo ""
echo "──────────────────────────────────────────────────"
echo "  STEP A — Create your own Google Cloud OAuth app"
echo "──────────────────────────────────────────────────"
echo "  1) Go to  https://console.cloud.google.com/apis/credentials"
echo "  2) Create (or pick) a project."
echo "  3) Enable these APIs for the project:"
echo "       • Google Calendar API"
echo "       • People API"
echo "  4) 'Create credentials' → 'OAuth client ID' → type 'Desktop app'."
echo "  5) Copy the Client ID and Client Secret."
echo ""
echo "  You can paste them below, or run gcalcli yourself later."
echo "  (They are used only to mint your own token; never committed.)"
echo ""

read -r -p "Client ID [leave empty to skip]: " CLIENT_ID
read -r -p "Client Secret [leave empty to skip]: " CLIENT_SECRET

if [[ -n "$CLIENT_ID" && -n "$CLIENT_SECRET" ]]; then
    ok "Minting calendar-scope token with gcalcli ..."
    gcalcli --client-id "$CLIENT_ID" --client-secret "$CLIENT_SECRET" \
        --save-token "$OAUTH" list 1>/dev/null \
        || warn "gcalcli auth did not complete. Mint the token manually."
fi

if [[ ! -f "$OAUTH" ]]; then
    echo ""
    echo "──────────────────────────────────────────────────"
    echo "  STEP B — Mint the token manually (alternative)"
    echo "──────────────────────────────────────────────────"
    echo "  Run:"
    echo "    gcalcli --client-id '<CLIENT_ID>' --client-secret '<CLIENT_SECRET>'"
    echo "           --save-token '$OAUTH' list"
    echo "  (Approve in the browser that opens.)"
    echo ""
    read -r -p "Press Enter when the token exists at $OAUTH ..." _
fi

[[ -f "$OAUTH" ]] || { echo "No token yet. Install the calendar/contacts scope below."; }

# ── 3. Add the People/Contacts scope (needed for birthdays) ─────────────────
echo ""
echo "──────────────────────────────────────────────────"
echo "  STEP C — Birthday scope (People/Contacts API)"
echo "──────────────────────────────────────────────────"
echo "  Calendar sync works with the calendar scope alone, but writing"
echo "  birthdays to Google Contacts needs the 'contacts' scope too."
echo "  The repo ships people-auth.py to add it to your token:"
echo ""
cp "$REPO/dotfiles/inir-birthdays/people-auth.py" "$HOME/people-auth.py" 2>/dev/null || true
echo "    python3 ~/people-auth.py"
echo ""
read -r -p "Press Enter once you have run people-auth.py (or to skip) ..." _

# ── 4. Install sync stack into ~/.config/inir-birthdays ─────────────────────
mkdir -p "$CONF_DIR"
for f in gcal-op.py sync-calendars.py people-auth.py; do
    [[ -f "$REPO/dotfiles/inir-birthdays/$f" ]] && {
        cp "$REPO/dotfiles/inir-birthdays/$f" "$CONF_DIR/$f"
        chmod +x "$CONF_DIR/$f"
    }
done
ok "sync scripts installed in $CONF_DIR"

# ── 5. Install + enable the periodic sync (every 5 min) ─────────────────────
mkdir -p "$HOME/.config/systemd/user"
cp "$REPO/dotfiles/systemd/user/inir-birthdays.service" \
   "$HOME/.config/systemd/user/inir-birthdays.service"
cp "$REPO/dotfiles/systemd/user/inir-birthdays.timer" \
   "$HOME/.config/systemd/user/inir-birthdays.timer"
systemctl --user daemon-reload || true
systemctl --user enable inir-birthdays.timer 2>/dev/null || true
systemctl --user start  inir-birthdays.timer 2>/dev/null || true
ok "inir-birthdays.timer enabled (syncs every 5 min)"

# ── 6. First manual sync + hint to restart the shell ────────────────────────
echo ""
echo "Run a first sync now? [y/N] "
read -r -n1 ans; echo
if [[ "${ans,,}" == "y" ]]; then
    systemctl --user start inir-birthdays.service || \
        python3 "$CONF_DIR/sync-calendars.py"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  Done. Restart the iNiR shell to load the calendar:"
echo "    systemctl --user restart inir.service"
echo ""
echo "  The manifest + ICS files appear in $CONF_DIR."
echo "════════════════════════════════════════════════"
