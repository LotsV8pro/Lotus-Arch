#!/usr/bin/env bash
# monitor-backlight.sh: sample brightness subsystem state continuously for debugging
LOG=/tmp/opencode/backlight_monitor.log
: > "$LOG"
echo "=== monitor started $(date +%T.%3N) ===" >> "$LOG"
echo "=== config snapshot ===" >> "$LOG"
echo "ddcci.delay=$(cat /sys/module/ddcci/parameters/delay 2>/dev/null)" >> "$LOG"
echo "waybar pid=$(pgrep -x waybar | tr '\n' ' ')" >> "$LOG"
echo "sync-daemon=$(systemctl --user is-active sync-backlight.service)" >> "$LOG"
echo "=== initial ===" >> "$LOG"
echo "d2=$(cat /sys/class/backlight/ddcci2/brightness) a2=$(cat /sys/class/backlight/ddcci2/actual_brightness) d4=$(cat /sys/class/backlight/ddcci4/brightness) a4=$(cat /sys/class/backlight/ddcci4/actual_brightness)" >> "$LOG"
while true; do
  s="-"
  w="-"
  [ -f /dev/shm/brightness_target ] && s="$(cat /dev/shm/brightness_target)"
  [ -e /dev/shm/brightness_writer ] && w="y"
  d2="$(cat /sys/class/backlight/ddcci2/brightness)"
  a2="$(cat /sys/class/backlight/ddcci2/actual_brightness)"
  d4="$(cat /sys/class/backlight/ddcci4/brightness)"
  a4="$(cat /sys/class/backlight/ddcci4/actual_brightness)"
  printf '%s T=%s W=%s d2=%s a2=%s d4=%s a4=%s\n' "$(date +%H:%M:%S.%3N)" "$s" "$w" "$d2" "$a2" "$d4" "$a4" >> "$LOG"
  sleep 0.1
done