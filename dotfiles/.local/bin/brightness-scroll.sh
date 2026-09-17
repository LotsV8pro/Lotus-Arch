#!/usr/bin/env bash
# brightness-scroll.sh <up|down>: debounced DDC brightness change for waybar scroll.
# Accumulates rapid scroll events into a target value and commits it once the burst settles,
# respecting a minimum gap between DDC writes (the monitor silently drops writes that
# arrive too close together).
set -euo pipefail

step=5
min_gap_ms=600
dev=/sys/class/backlight/ddcci4/brightness
state=/dev/shm/brightness_target
state_lock=/dev/shm/brightness_target.lock
writer_flag=/dev/shm/brightness_writer
last_ddc=/dev/shm/brightness_last_ddc

exec 9> "$state_lock"
flock 9

# Base value: the pending target is the only source of truth for accumulation.
# Fall back to sysfs only on the very first call.
if [ -f "$state" ]; then
  base="$(cat "$state")"
else
  base="$(cat "$dev")"
fi
case "${1:-}" in
  up)   new=$((base + step)) ;;
  down) new=$((base - step)) ;;
  *) exit 1 ;;
esac
if (( new < 0 )); then new=0; fi
if (( new > 100 )); then new=100; fi

printf '%s\n' "$new" > "$state"

# Exactly one writer at a time: the flag is only created under the lock.
if [ ! -e "$writer_flag" ]; then
  touch "$writer_flag"
  (
    # The writer runs detached and must not hold the lock while waiting.
    exec 9>&-
    # Wait until the target stabilizes (no new scrolls within the window).
    t1="$(cat "$state" 2>/dev/null || echo 0)"
    for _ in $(seq 1 50); do
      sleep 0.12
      t2="$(cat "$state" 2>/dev/null || echo 0)"
      [ "$t1" = "$t2" ] && break
      t1="$t2"
    done
    # Enforce a minimum gap since the last DDC write to avoid the monitor
    # silently dropping consecutive writes.
    while :; do
      now="$(date +%s%3N)"
      last="$(cat "$last_ddc" 2>/dev/null || echo 0)"
      [ $(( now - last )) -ge "$min_gap_ms" ] && break
      sleep 0.05
    done
    # Commit atomically: re-acquire the lock so no scroll can update the target
    # while we read the final value and write it to the device.
    exec 9> "$state_lock"
    flock 9
    final="$(cat "$state" 2>/dev/null || echo 0)"
    printf '%s' "$final" > "$dev" 2>/dev/null || true
    date +%s%3N > "$last_ddc"
    rm -f "$writer_flag"
    flock -u 9
    exec 9>&-
  ) &
fi

flock -u 9
exec 9>&-