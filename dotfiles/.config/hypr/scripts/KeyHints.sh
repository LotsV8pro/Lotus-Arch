#!/usr/bin/env bash

if pidof rofi > /dev/null; then
  pkill rofi
fi

if pidof yad > /dev/null; then
  pkill yad
fi

GDK_BACKEND=wayland yad \
    --center \
    --title="Keybinds" \
    --no-buttons --no-markup \
    --list \
    --column=Key: \
    --column=Description: \
    --width=900 \
    --timeout-indicator=bottom \
"ESC" "close this panel" \
" = SUPER KEY" "" \
"" "" \
"LAUNCHERS" "" \
"SUPER Return" "Open terminal (kitty)" \
"SUPER SHIFT Return" "Dropdown terminal" \
"SUPER D" "App launcher (rofi)" \
"SUPER E" "File manager (Thunar)" \
"SUPER B" "Open browser" \
"SUPER S" "Web search (rofi)" \
"SUPER ALT E" "Emoji picker (rofi)" \
"SUPER ALT C" "Calculator (rofi)" \
"SUPER CTRL S" "Window switcher (rofi)" \
"" "" \
"WALLPAPER" "" \
"SUPER W" "Wallpaper picker (with folders)" \
"SUPER SHIFT W" "Wallpaper effects" \
"CTRL ALT W" "Random wallpaper" \
"" "" \
"THEMING" "" \
"SUPER P" "Palette color editor" \
"SUPER CTRL P" "Preset manager (save/load)" \
"SUPER CTRL B" "Waybar style selector" \
"SUPER ALT B" "Waybar layout selector" \
"SUPER CTRL ALT B" "Toggle waybar on/off" \
"SUPER CTRL R" "Rofi theme selector" \
"SUPER CTRL SHIFT R" "Rofi theme selector v2" \
"SUPER SHIFT A" "Animations menu" \
"SUPER N" "Night light toggle (Hyprsunset)" \
"" "" \
"WINDOW" "" \
"SUPER Q" "Close active window" \
"SUPER SHIFT Q" "Kill active process" \
"SUPER F" "Fullscreen" \
"SUPER CTRL F" "Maximize (fake fullscreen)" \
"SUPER SPACE" "Toggle float" \
"SUPER ALT SPACE" "Float all windows" \
"SUPER ALT O" "Toggle blur" \
"SUPER CTRL O" "Toggle opaque" \
"SUPER ALT L" "Toggle Dwindle/Master layout" \
"SUPER SHIFT G" "Game mode (animations off)" \
"" "" \
"LAYOUT" "" \
"SUPER I" "Add master window" \
"SUPER CTRL D" "Remove master window" \
"SUPER CTRL Return" "Swap with master" \
"SUPER SHIFT I" "Toggle split" \
"" "" \
"WINDOW MOVE" "" \
"SUPER SHIFT Arrows" "Resize window" \
"SUPER CTRL Arrows" "Move window" \
"SUPER ALT Arrows" "Swap window" \
"SUPER Arrows" "Focus window" \
"" "" \
"GROUPS" "" \
"SUPER G" "Toggle group" \
"SUPER Tab" "Group next" \
"SUPER SHIFT Tab" "Group previous" \
"SUPER CTRL Tab" "Change active in group" \
"SUPER CTRL K/L/H" "Move into/out of group" \
"" "" \
"WORKSPACES" "" \
"SUPER 1-0" "Switch to workspace 1-10" \
"SUPER SHIFT 1-0" "Move window to workspace" \
"SUPER CTRL 1-0" "Move silently to workspace" \
"SUPER Tab" "Next workspace" \
"SUPER SHIFT Tab" "Previous workspace" \
"SUPER U" "Toggle special workspace" \
"SUPER SHIFT U" "Move to special workspace" \
"SUPER , / ." "Previous / Next workspace" \
"SUPER CTRL F9-F12" "Move workspace to monitor" \
"" "" \
"SCREENSHOT" "" \
"SUPER Print" "Screenshot now" \
"SUPER SHIFT Print" "Screenshot area" \
"SUPER CTRL Print" "Screenshot in 5s" \
"SUPER CTRL SHIFT Print" "Screenshot in 10s" \
"ALT Print" "Screenshot active window" \
"SUPER SHIFT S" "Screenshot to swappy" \
"" "" \
"MEDIA" "" \
"Volume Up/Down" "Volume control" \
"ALT + Volume" "Precise volume" \
"Mute key" "Toggle mute" \
"Mic mute" "Toggle mic mute" \
"Media keys" "Play/Pause/Next/Prev" \
"SUPER SHIFT M" "Online music (rofi)" \
"" "" \
"SYSTEM" "" \
"CTRL ALT L" "Lock screen" \
"CTRL ALT P" "Power menu (wlogout)" \
"CTRL ALT Del" "Exit Hyprland" \
"SUPER T" "Reload Hyprland config" \
"SUPER ALT R" "Refresh waybar + swaync" \
"SUPER SHIFT N" "Notification panel" \
"SUPER SHIFT E" "Quick settings menu" \
"SUPER SHIFT O" "Change ZSH theme" \
"SUPER SHIFT K" "Search all keybinds" \
"SUPER H" "This cheat sheet" \
"" "" \
"MOUSE" "" \
"SUPER + Left Click" "Move window" \
"SUPER + Right Click" "Resize window" \
"SUPER + Scroll" "Switch workspace" \
"SUPER ALT + Scroll" "Zoom in/out"
