#!/usr/bin/env bash
# LOTUS Sound Effects Generator
# Creates terminal-style beep sounds using ffmpeg

SOUND_DIR="$HOME/.config/lotus-sounds"

mkdir -p "$SOUND_DIR"

# Notification beep — short digital chirp
ffmpeg -y -f lavfi -i "sine=frequency=1200:duration=0.08" \
  -af "volume=0.3,afade=t=out:st=0.05:d=0.03" \
  "$SOUND_DIR/notification.mp3" 2>/dev/null

# Alert — dual tone
ffmpeg -y -f lavfi -i "sine=frequency=800:duration=0.1" \
  -f lavfi -i "sine=frequency=1600:duration=0.1" \
  -filter_complex "[0][1]amix=inputs=2:duration=shortest,volume=0.4,afade=t=out:st=0.07:d=0.03" \
  "$SOUND_DIR/alert.mp3" 2>/dev/null

# Lock — descending tone
ffmpeg -y -f lavfi -i "sine=frequency=1000:duration=0.15" \
  -af "vibrato=f=20:d=0.5,volume=0.3,afade=t=out:st=0.1:d=0.05" \
  "$SOUND_DIR/lock.mp3" 2>/dev/null

# Error — low buzz
ffmpeg -y -f lavfi -i "sine=frequency=200:duration=0.2" \
  -af "volume=0.4,afade=t=out:st=0.15:d=0.05" \
  "$SOUND_DIR/error.mp3" 2>/dev/null

# Success — ascending chirp
ffmpeg -y -f lavfi -i "sine=frequency=600:duration=0.05" \
  -f lavfi -i "sine=frequency=1200:duration=0.05" \
  -f lavfi -i "sine=frequency=1800:duration=0.05" \
  -filter_complex "[0][1][2]concat=n=3:v=0:a=1,volume=0.3,afade=t=out:st=0.12:d=0.03" \
  "$SOUND_DIR/success.mp3" 2>/dev/null

# Keypress — tiny click
ffmpeg -y -f lavfi -i "anoisesrc=d=0.02:c=white:a=0.1" \
  -af "highpass=f=2000,volume=0.2" \
  "$SOUND_DIR/keypress.mp3" 2>/dev/null

echo "Lotus sounds generated in $SOUND_DIR"
ls -la "$SOUND_DIR"
