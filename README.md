<p align="center">
  <img src="https://img.shields.io/badge/Arch_Linux-141218?style=for-the-badge&logo=arch-linux&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Hyprland-141218?style=for-the-badge&logo=hyprland&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/NVIDIA_RTX_4070-141218?style=for-the-badge&logo=nvidia&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Lua_Config-141218?style=for-the-badge&logo=lua&logoColor=C4A8E2"/>
</p>

<h1 align="center">◈ LOTUS ARCH ◈</h1>

<p align="center">
  <b>Arch Linux + Hyprland (Lua-only) — Purple Lotus Desktop Environment</b><br>
  <sub>Purple glassmorphism. NVIDIA optimized. Preset-ready.</sub>
</p>

<p align="center">
  <a href="#-overview">Overview</a> •
  <a href="#-screenshots">Screenshots</a> •
  <a href="#-keybindings">Keybindings</a> •
  <a href="#-install">Install</a> •
  <a href="#-structure">Structure</a> •
  <a href="#-themes">Themes</a>
</p>

---

## ◈ Overview

Lotus Arch is a complete **Arch Linux desktop environment** built on Hyprland with a pure Lua configuration — no legacy `.conf` files. It features a cohesive **purple glassmorphism** aesthetic across all applications, NVIDIA RTX 4070 optimization, and a built-in preset system for saving/loading entire desktop themes.

### ✦ Features

| | |
|---|---|
| **Pure Lua** | 100% Hyprland Lua config — all settings, keybinds, animations, window rules |
| **Purple Lotus Theme** | Monochrome purple palette across Hyprland, Waybar, Rofi, Kitty, Ghostty |
| **HyprGlass** | Apple-style liquid glass effect with per-window control |
| **Preset System** | Save/load/delete full desktop themes with `SUPER + CTRL + P` |
| **Palette Editor** | Visual color picker with `SUPER + P` — change every color instantly |
| **NVIDIA Optimized** | RTX 4070 tuned — open-dkms drivers, Wayland-native GPU acceleration |
| **Gaming Ready** | Steam, Lutris, MangoHud, Gamemode, Gamescope, VRR support |
| **Controller Support** | Xbox / ROG Raikiri — launch apps and Steam Big Picture |
| **Wallpaper Browser** | Folder-based browser with `SUPER + W` — 22 wallpaper collections |
| **50+ Waybar Themes** | Pill style, floating, glass, monochrome — all Lotus-colored |

---

## ◈ Ecosystem

Lotus Arch is part of a **unified desktop ecosystem** with matching themes for all major apps:

| App | Theme | Repo |
|---|---|---|
| **Discord** (Vencord) | Lotus Purple | [lotus-discord](https://github.com/LotsV8pro/lotus-discord) |
| **Spotify** (Spicetify) | Lotus Purple | [lotus-spotify](https://github.com/LotsV8pro/lotus-spotify) |
| **Waybar** | Lotus Pill / Lotus Purple | — *(included)* |
| **Rofi** | Lotus Purple | — *(included)* |
| **Kitty / Ghostty** | Lotus Terminal | — *(included)* |
| **GTK / Thunar** | Lotus Purple Pill | — *(included)* |

---

## ◈ Keybindings

| Keybind | Action |
|---------|--------|
| `SUPER + Return` | Terminal (Ghostty) |
| `SUPER + E` | File Manager (Thunar) |
| `SUPER + W` | Wallpaper Select |
| `SUPER + P` | Palette Color Editor |
| `SUPER + CTRL + P` | Preset Manager |
| `SUPER + SHIFT + E` | Exit Menu |
| `SUPER + SHIFT + K` | Searchable Keybinds |
| `SUPER + M` | Power Menu |
| `SUPER + V` | Clipboard Manager |
| `SUPER + T` | Quick Settings |
| `SUPER + F` | Fullscreen |
| `SUPER + G` | Toggle Floating |
| `SUPER + Q` | Kill Active |
| `SUPER + J / K` | Cycle Windows |
| `SUPER + Arrows` | Move Focus |
| `SUPER + 1-5` | Switch Workspace |
| `SUPER + SHIFT + 1-5` | Move to Workspace |

---

## ◈ Install

### Fresh Arch Install

```bash
curl -sL https://raw.githubusercontent.com/LotsV8pro/Lotus-Arch/main/auto-install.sh | bash
```

### Existing Arch Install

```bash
git clone https://github.com/LotsV8pro/Lotus-Arch.git
cd Lotus-Arch
chmod +x install.sh
./install.sh
```

### What gets installed

The installer runs **10 phases** automatically:

```
Phase 0:  System Preparation   — multilib, keyring, mirrors
Phase 1:  Core Packages        — Hyprland, Waybar, Rofi, Kitty, PipeWire, SDDM
Phase 2:  AUR Packages         — Ghostty, swaync, wlogout, wallust, hyprpicker
Phase 3:  NVIDIA Drivers       — open-dkms stack (RTX 4070 optimized)
Phase 4:  Enable Services      — SDDM, PipeWire, Bluetooth, NetworkManager
Phase 5:  ZSH Shell            — Oh-My-ZSH + powerlevel10k + plugins
Phase 6:  Deploy Dotfiles      — All configs (backup originals first)
Phase 7:  Hyprland Plugins     — HyprGlass liquid glass plugin
Phase 8:  Final Cleanup        — Cache cleanup, directory setup
Phase 9:  Restore User Apps    — Your current packages + Spicetify + Discord themes
```

> **Phase 9** detects your currently installed packages (pacman, AUR, Flatpak) and saves them to `packages/` before restoring them on any fresh install — so you never lose your app setup.

### Requirements

- **OS:** Arch Linux
- **Compositor:** Hyprland 0.55+
- **GPU:** NVIDIA (optimized for RTX 4070) or Intel
- **Terminal:** Ghostty (default) or Kitty
- **Depends on:** Waybar, Rofi, swaync, wlogout, swww, nwg-displays

---

## ◈ Structure

```
.config/hypr/
├── hyprland.lua                # Main entry point (requires all modules)
├── configs/                    # Base configuration
│   ├── Keybinds.lua            # Default keybinds
│   ├── Startup_Apps.lua        # Autostart applications
│   ├── ENVariables.lua         # Environment variables
│   ├── WindowRules.lua         # Window & layer rules
│   ├── SystemSettings.lua      # System-level settings
│   └── Laptops.lua             # Laptop-specific config
├── UserConfigs/                # User overrides (survive updates)
│   ├── UserDecorations.lua     # Theme colors, borders, shadows, blur
│   ├── UserAnimations.lua      # Animation curves & speeds
│   ├── UserKeybinds.lua        # Custom keybinds
│   ├── UserSettings.lua        # Personal settings
│   ├── 01-UserDefaults.lua     # Default variables (editor, terminal, files)
│   ├── HyprGlass.lua           # Per-window glass effect config
│   ├── WindowRules.lua         # Custom window rules
│   ├── Laptops.lua             # Laptop overrides
│   └── LaptopDisplay.lua       # Display-specific overrides
├── scripts/                    # Utility scripts
├── UserScripts/                # User scripts
├── animations/                 # Animation presets
├── wallpaper_effects/          # Wallpaper effects
├── wallust/                    # Wallust color templates
├── Monitor_Profiles/           # Saved monitor layouts
└── monitors.conf               # nwg-displays output
```

---

## ◈ Themes

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `#C4A8E2` | <img src="https://placehold.co/16x16/C4A8E2/C4A8E2" width="16"/> | Primary accent, active borders, buttons |
| `#8C7AA6` | <img src="https://placehold.co/16x16/8C7AA6/8C7AA6" width="16"/> | Dim accent, inactive states, indicators |
| `#383048` | <img src="https://placehold.co/16x16/383048/383048" width="16"/> | Dark accent, borders, disabled elements |
| `#D8D0E8` | <img src="https://placehold.co/16x16/D8D0E8/D8D0E8" width="16"/> | Light accent, text, active highlights |
| `#141218` | <img src="https://placehold.co/16x16/141218/141218" width="16"/> | Base background |
| `#1C1A22` | <img src="https://placehold.co/16x16/1C1A22/1C1A22" width="16"/> | Elevated background, cards, sidebar |
| `#282430` | <img src="https://placehold.co/16x16/282430/282430" width="16"/> | Light background, hover states |
| `#887898` | <img src="https://placehold.co/16x16/887898/887898" width="16"/> | Dim text, secondary content |

### Presets

Lotus Arch includes a **Preset Manager** (`SUPER + CTRL + P`) that can save and load full desktop themes. Each preset captures:

- Colors (all 39 palette tokens)
- Waybar style and layout
- Hyprland decorations (borders, shadows, blur)
- Terminal colors (Kitty / Ghostty)
- Rofi theme
- GTK overrides

Built-in presets: `Monochrome`, `Shrek`, `White Monochrome`, `Yellowstone`.

---

## ◈ Packages

The repo captures your current package state at install time:

| Source | Count |
|--------|-------|
| Official (pacman) | 146 |
| AUR (yay) | 16 |
| Flatpak | 2 |

Lists are stored in `packages/{pacman,aur,flatpak}.txt` and restored automatically on fresh installs.

---

## ◈ Gallery

<p align="center">
  <sub>— screenshots coming —</sub>
</p>

---

<p align="center">
  <a href="https://github.com/LotsV8pro/lotus-discord"><img src="https://img.shields.io/badge/Lotus_Discord-141218?style=flat-square&logo=discord&logoColor=C4A8E2"/></a>
  <a href="https://github.com/LotsV8pro/lotus-spotify"><img src="https://img.shields.io/badge/Lotus_Spotify-141218?style=flat-square&logo=spotify&logoColor=C4A8E2"/></a>
  <a href="https://github.com/LotsV8pro/Lotus-Arch"><img src="https://img.shields.io/badge/Lotus_Arch-141218?style=flat-square&logo=arch-linux&logoColor=C4A8E2"/></a>
</p>

<p align="center">
  <sub>MIT License — <a href="https://github.com/LotsV8pro">@LotsV8pro</a></sub>
</p>
