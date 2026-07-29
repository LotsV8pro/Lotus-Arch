# Lotus-Arch

Arch Linux + Hyprland (Lua-only config) — purple Lotus theme with NVIDIA RTX 4070 optimization.

**Pure `.lua` Hyprland config** — no legacy `.conf` files. Requires Hyprland 0.55+.

## What's Inside

- **Hyprland Lua config** — All settings, keybinds, animations, decorations, window rules in `.lua`
- **Purple Lotus theme** — Monochrome purple palette across Hyprland, Waybar, Rofi, Kitty
- **Preset system** — Save/load/delete full desktop themes with `SUPER+CTRL+P`
- **Wallpaper browser** — Folder-based browser with `SUPER+W`
- **Controller support** — Xbox/ROG Raikiri controller for app launch and Steam Big Picture
- **22 wallpaper folders** — Organized by color (blue, purple, red, cyberpunk, minimal, etc.)

## Key Bindings

| Keybind | Action |
|---------|--------|
| `SUPER+Return` | Terminal (Ghostty) |
| `SUPER+E` | File Manager (Thunar) |
| `SUPER+W` | Wallpaper Select |
| `SUPER+P` | Palette Color Editor |
| `SUPER+CTRL+P` | Preset Manager |
| `SUPER+SHIFT+E` | Exit Menu |
| `SUPER+SHIFT+K` | Searchable Keybinds |
| `SUPER+M` | Power Menu |
| `SUPER+V` | Clipboard Manager |
| `SUPER+T` | Quick Settings |
| `SUPER+F` | Fullscreen |
| `SUPER+G` | Toggle Floating |
| `SUPER+Q` | Kill Active |
| `SUPER+J/K` | Cycle Windows |
| `SUPER+Arrows` | Move Focus |
| `SUPER+1-5` | Switch Workspace |
| `SUPER+SHIFT+1-5` | Move to Workspace |

## Install

```bash
# Fresh Arch install
curl -sL https://raw.githubusercontent.com/LotsV8pro/Lotus-Arch/main/auto-install.sh | bash

# Existing Arch install
git clone https://github.com/LotsV8pro/Lotus-Arch.git
cd Lotus-Arch
chmod +x install.sh
./install.sh
```

## Requirements

- Arch Linux
- Hyprland 0.55+
- NVIDIA GPU (optimized for RTX 4070)
- Ghostty terminal
- Waybar, Rofi, swaync, wlogout
- swww (wallpaper daemon)
- nwg-displays (monitor config)

## Structure

```
.config/hypr/
├── hyprland.lua              # Main entry point
├── configs/
│   ├── Keybinds.lua          # Default keybinds
│   ├── Startup_Apps.lua      # Autostart apps
│   ├── ENVariables.lua       # Environment variables
│   ├── WindowRules.lua       # Window rules
│   ├── SystemSettings.lua    # System settings
│   └── Laptops.lua           # Laptop-specific
├── UserConfigs/
│   ├── UserDecorations.lua   # Theme colors/decorations
│   ├── UserAnimations.lua    # Animation settings
│   ├── UserKeybinds.lua      # Custom keybinds
│   ├── UserSettings.lua      # User settings
│   ├── 01-UserDefaults.lua   # Default variables
│   ├── HyprGlass.lua         # Glass blur effects
│   ├── WindowRules.lua       # Custom window rules
│   ├── Laptops.lua           # Laptop overrides
│   └── LaptopDisplay.lua     # Display settings
├── animations/               # Animation presets (.conf → auto-converted)
├── scripts/                  # Utility scripts
├── UserScripts/              # User scripts
└── monitors.conf             # Monitor config (nwg-displays)
```

## License

MIT
