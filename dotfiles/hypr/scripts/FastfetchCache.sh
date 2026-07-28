#!/bin/bash
# Generates fastfetch config once per Hyprland session
# Called from .zshrc on first terminal open

CACHE_DIR="/tmp/ssgg-fastfetch"
CONFIG="$CACHE_DIR/config.jsonc"
LOCK="$CACHE_DIR/.lock"

mkdir -p "$CACHE_DIR"

# If config already exists this session, skip generation
if [ -f "$CONFIG" ]; then
    exit 0
fi

FASTFETCH_DIR="$HOME/Pictures/fastfetch"
if [ -d "$FASTFETCH_DIR" ] && [ "$(ls -A "$FASTFETCH_DIR")" ]; then
    RANDOM_IMG=$(find "$FASTFETCH_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | shuf -n 1)
    
    cat <<EOF > "$CONFIG"
{
    "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "kitty",
        "source": "$RANDOM_IMG",
        "width": 20,
        "height": 10,
        "padding": {
            "top": 1,
            "left": 1,
            "right": 2
        }
    },
    "display": {
        "separator": " 󰁔 "
    },
    "modules": [
        { "type": "custom", "format": " [!] DEDSEC_SYS_OVERRIDE [!]" },
        { "type": "custom", "format": "----------------------------------------" },
        { "type": "title", "key": " 󰌽 TARGET", "keyColor": "red" },
        { "type": "os", "key": " 󰍹 KERNEL", "keyColor": "magenta" },
        { "type": "wm", "key": " 󰖲 SYSTEM", "keyColor": "magenta" },
        { "type": "shell", "key": " 󰞷 SHELL", "keyColor": "cyan" },
        { "type": "terminal", "key": " 󰆍 CLIENT", "keyColor": "cyan" },
        { "type": "memory", "key": " 󰍛 MEMORY", "keyColor": "green" },
        { "type": "uptime", "key": " 󱎫 ACTIVE", "keyColor": "green" },
        { "type": "custom", "format": "----------------------------------------" },
        { "type": "colors", "symbol": "circle" }
    ]
}
EOF
else
    cp "$HOME/.config/fastfetch/config-compact.jsonc" "$CONFIG" 2>/dev/null || exit 0
fi
