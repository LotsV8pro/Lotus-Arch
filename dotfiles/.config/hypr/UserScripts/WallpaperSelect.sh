#!/usr/bin/env bash
# This script for selecting wallpapers (SUPER W)

# WALLPAPERS PATH
terminal=kitty
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# swww transition config
FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Check if package bc exists
if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Install package bc first"
  exit 1
fi

# Variables
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ensure focused_monitor is detected
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

# Monitor details
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

# Kill existing wallpaper daemons for video
kill_wallpaper_for_video() {
  swww kill 2>/dev/null
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Kill existing wallpaper daemons for image
kill_wallpaper_for_image() {
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# ── Folder menu ────────────────────────────────────────────────
folder_menu() {
  local folders=()
  while IFS= read -r d; do
    folders+=("$(basename "$d")")
  done < <(find -L "${wallDIR}" -mindepth 1 -maxdepth 1 -type d | sort)

  printf ". all wallpapers\n"
  for f in "${folders[@]}"; do
    local count
    count=$(find -L "${wallDIR}/$f" -type f \( \
      -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
      -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
      -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) 2>/dev/null | wc -l)
    [[ "$count" -gt 0 ]] && printf "%s  (%d)\n" "$f" "$count"
  done
}

# ── Wallpaper menu for a given directory ───────────────────────
RANDOM_PIC_NAME=". random"

menu() {
  local dir="${1:-$wallDIR}"

  mapfile -d '' PICS < <(find -L "${dir}" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
    -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
    -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0)

  [[ ${#PICS[@]} -eq 0 ]] && return

  RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"

  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))
  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 1920x1080 "$cache_gif_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif_image"
    elif [[ "$pic_name" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      cache_preview_image="$HOME/.cache/video_preview/${pic_name}.png"
      if [[ ! -f "$cache_preview_image" ]]; then
        mkdir -p "$HOME/.cache/video_preview"
        ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 "$cache_preview_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_preview_image"
    else
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$pic_path"
    fi
  done
}


modify_startup_config() {
  local selected_file="$1"
  local startup_lua="$HOME/.config/hypr/UserConfigs/Startup_Apps.lua"

  # Check if it's a live wallpaper (video)
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm)$ ]]; then
    # For video wallpapers: comment swww-daemon, enable mpvpaper
    sed -i 's|hl.exec("swww-daemon --format xrgb")|-- hl.exec("swww-daemon --format xrgb")|' "$startup_lua"
    
    # Update or add mpvpaper line
    selected_file="${selected_file/#$HOME/\$HOME}"
    if grep -q 'mpvpaper' "$startup_lua"; then
      sed -i "s|.*mpvpaper.*|hl.exec(\"mpvpaper '*' -o \\\"load-scripts=no no-audio --loop\\\" \\\"$selected_file\\\"\")|" "$startup_lua"
    else
      echo "hl.exec(\"mpvpaper '*' -o \\\"load-scripts=no no-audio --loop\\\" \\\"$selected_file\\\"\")" >> "$startup_lua"
    fi

    echo "Configured for live wallpaper (video)."
  else
    # For image wallpapers: enable swww-daemon, comment mpvpaper
    sed -i 's|-- hl.exec("swww-daemon --format xrgb")|hl.exec("swww-daemon --format xrgb")|' "$startup_lua"
    sed -i 's|hl.exec("mpvpaper.*|-- hl.exec("mpvpaper|' "$startup_lua"

    echo "Configured for static wallpaper (image)."
  fi
}

# Apply Image Wallpaper
apply_image_wallpaper() {
  local image_path="$1"

  kill_wallpaper_for_image

  if ! pgrep -x "swww-daemon" >/dev/null; then
    echo "Starting swww-daemon..."
    swww-daemon --format xrgb &
  fi

  swww img -o "$focused_monitor" "$image_path" $SWWW_PARAMS

  # Run additional scripts (pass the image path to avoid cache race conditions)
  "$SCRIPTSDIR/WallustSwww.sh" "$image_path"
  sleep 2
  "$SCRIPTSDIR/Refresh.sh"
  sleep 1

}

apply_video_wallpaper() {
  local video_path="$1"

  # Check if mpvpaper is installed
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "mpvpaper not found"
    return 1
  fi
  kill_wallpaper_for_video

  # Apply video wallpaper using mpvpaper
  mpvpaper '*' -o "load-scripts=no no-audio --loop" "$video_path" &
}

# Main function
main() {
  while true; do
    # Step 1: Pick a folder
    local folder_choice
    folder_choice=$(folder_menu | rofi -i -show -dmenu -p "  Folder" -config "$rofi_theme" -theme-str "$rofi_override")

    # Escape on folder list = exit entirely
    [[ -z "$folder_choice" ]] && exit 0

    local selected_dir="$wallDIR"
    if [[ "$folder_choice" != ". all wallpapers" ]]; then
      local folder_name
      folder_name=$(echo "$folder_choice" | sed 's/  *([0-9]*)$//')
      selected_dir="$wallDIR/$folder_name"
    fi

    # Step 2: Pick a wallpaper from that folder
    local choice
    choice=$(menu "$selected_dir" | rofi -i -show -dmenu -p "  Wallpaper" -config "$rofi_theme" -theme-str "$rofi_override")
    choice=$(echo "$choice" | xargs)

    # Escape/empty on wallpaper list = go back to folder list
    [[ -z "$choice" ]] && continue

    if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
      choice=$(basename "$RANDOM_PIC")
    fi

    choice_basename=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')

    selected_file=$(find "$wallDIR" -iname "$choice_basename.*" -print -quit)

    if [[ -z "$selected_file" ]]; then
      echo "File not found. Selected choice: $choice"
      exit 1
    fi

    modify_startup_config "$selected_file"

    if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      apply_video_wallpaper "$selected_file"
    else
      apply_image_wallpaper "$selected_file"
    fi

    break
  done
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

main