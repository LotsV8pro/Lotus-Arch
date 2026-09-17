#!/usr/bin/env bash
# sync-backlight: keep all ddcci backlight devices equal to ddcci4 (primary monitor) brightness
sec=/sys/class/backlight/ddcci4/brightness
prev=""
while true; do
  targets=""
  for d in /sys/class/backlight/ddcci*/brightness; do
    [ "$d" = "$sec" ] && continue
    targets="$targets $d"
  done
  [ -z "$targets" ] && { sleep 2; continue; }
  cur="$(cat "$sec" 2>/dev/null)" || { sleep 2; continue; }
  if [ "$cur" != "$prev" ]; then
    prev="$cur"
    for t in $targets; do
      [ -w "$t" ] && printf '%s' "$cur" > "$t"
    done
  fi
  sleep 1
done