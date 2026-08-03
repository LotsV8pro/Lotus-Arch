#!/usr/bin/env bash
# Restart xdg-desktop-portal services after login so the
# screen-share / window picker works (fixes missing picker in games).
#
# The portal (esp. xdg-desktop-portal-hyprland) can segfault on logout and
# then hit systemd's start-limit, which keeps it dead after re-login. This
# clears that limit before restarting, then checks the OBS PipeWire capture
# health and restarts OBS if its screencast session is dead.

set -euo pipefail

PORTAL=xdg-desktop-portal.service
PORTAL_HL=xdg-desktop-portal-hyprland.service
OBS_FIX=$HOME/.config/hypr/scripts/restart_obs_capture.py

sleep 3

# Clear the restart counter so a previous crash loop can't block recovery.
systemctl --user reset-failed "$PORTAL_HL" "$PORTAL" 2>/dev/null || true

systemctl --user restart "$PORTAL_HL" 2>/dev/null || true

# Wait for the Hyprland backend to be up before bouncing the main portal.
for _ in {1..10}; do
  systemctl --user is-active "$PORTAL_HL" >/dev/null 2>&1 && break
  sleep 0.5
done

systemctl --user restart "$PORTAL" 2>/dev/null || true

for _ in {1..10}; do
  systemctl --user is-active "$PORTAL" >/dev/null 2>&1 && break
  sleep 0.5
done

if systemctl --user is-active "$PORTAL" >/dev/null 2>&1; then
  echo "xdg-desktop-portal restarted OK"
else
  echo "WARNING: xdg-desktop-portal did not come back up" >&2
fi

# Recreating the PipeWire source cannot revive a dead screencast session, so
# the checker only reports health; restart OBS when the capture is dead.
if pgrep -x obs >/dev/null 2>&1 && [ -x "$OBS_FIX" ]; then
  sleep 2
  set +e
  python3 "$OBS_FIX"
  rc=$?
  set -e
  case $rc in
    0|1|5)
      # healthy, OBS not up yet, or refused while streaming/recording
      ;;
    *)
      # 2,3,4 -> dead capture / plugin missing / source missing: restart OBS once
      echo "OBS capture unhealthy (exit $rc); restarting OBS" >&2
      pkill -x obs 2>/dev/null || true
      for _ in {1..20}; do
        pgrep -x obs >/dev/null 2>&1 || break
        sleep 0.5
      done
      nohup obs >/dev/null 2>&1 &
      disown
      ;;
  esac
fi
