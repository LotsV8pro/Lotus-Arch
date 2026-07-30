<p align="center">
  <img src="https://img.shields.io/badge/Arch_Linux-141218?style=for-the-badge&logo=arch-linux&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Hyprland-141218?style=for-the-badge&logo=hyprland&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/NVIDIA_RTX_4070-141218?style=for-the-badge&logo=nvidia&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Lua_Config-141218?style=for-the-badge&logo=lua&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Purple_Lotus-141218?style=for-the-badge&logo=codeforces&logoColor=C4A8E2"/>
</p>

<h1 align="center">◈ LOTUS ARCH ◈</h1>

<p align="center">
  <b>Arch Linux + Hyprland (Lua-only) — Purple Lotus Desktop Environment</b><br>
  <sub>Purple glassmorphism · NVIDIA optimized · Arctis Nova 5 audio · Preset-ready</sub>
</p>

<p align="center">
  <a href="#-overview">Overview</a> •
  <a href="#-screenshots">Screenshots</a> •
  <a href="#-audio-pipeline">Audio</a> •
  <a href="#-keybindings">Keybindings</a> •
  <a href="#-install">Install</a> •
  <a href="#-structure">Structure</a> •
  <a href="#-themes">Themes</a> •
  <a href="#-ecosystem">Ecosystem</a>
</p>

---

## ◈ Overview

Lotus Arch is a complete **Arch Linux desktop environment** built on Hyprland with a pure Lua configuration — no legacy `.conf` files. It features a cohesive **purple glassmorphism** aesthetic, NVIDIA RTX 4070 optimization, a full **Arctis Nova 5 audio pipeline**, and a built-in preset system for saving/loading entire desktop themes.

### ✦ Features

| | |
|---|---|
| **Pure Lua** | 100% Hyprland Lua config — all settings, keybinds, animations, window rules |
| **Purple Lotus Theme** | Monochrome purple palette across Hyprland, Waybar, Rofi, Kitty, Ghostty |
| **HyprGlass** | Apple-style liquid glass effect with per-window control |
| **Preset System** | Save/load/delete full desktop themes with `SUPER + CTRL + P` |
| **Palette Editor** | Visual color picker with `SUPER + P` — change every color instantly |
| **NVIDIA Optimized** | RTX 4070 tuned — open-dkms drivers, Wayland-native GPU acceleration |
| **Performance Tweaks** | Optional GPU undervolt/OC, fan curve, CPU governor, sysctl, NVMe tuning |
| **Gaming Ready** | Steam, Lutris, MangoHud, Gamemode, Gamescope, VRR support |
| **Controller Support** | Xbox / ROG Raikiri — launch apps and Steam Big Picture |
| **Wallpaper Browser** | Folder-based browser with `SUPER + W` — 22 wallpaper collections |
| **50+ Waybar Themes** | Pill style, floating, glass, monochrome — all Lotus-colored |
| **OBS Studio Pipeline** | Virtual mic, virtual sink, auto-routing from Arctis headset |
| **Arctis Nova 5** | Sonar EQ profiles, 7.1 virtual surround, 3-channel routing |

---

## ◈ Audio Pipeline

Lotus Arch includes a complete **streaming/gaming audio pipeline** designed around the SteelSeries Arctis Nova 5 headset and OBS Studio.

### Audio Devices

| Device | Type | Purpose |
|---|---|---|
| **Arctis_Game** | Sink | Game audio (routed automatically to OBS) |
| **Arctis_Chat** | Sink | Chat/voice audio |
| **Arctis_Media** | Sink | Browser/media audio (routed automatically to OBS) |
| **OBS Virtual Sink** | Sink | Desktop audio capture for OBS |
| **OBS Virtual Mic** | Source | Microphone from OBS (VST-processed) back to system |

### Systemd Services

| Service | Function |
|---|---|
| `virtual-mic.service` | Permanent loopback from OBS virtual sink to virtual mic |
| `auto-link-obs.service` | Auto-connects Arctis_Game + Arctis_Media monitor outputs to OBS virtual sink |
| `arctis-manager.service` | Arctis Sound Manager daemon (Sonar EQ, spatial audio) |
| `arctis-gui.service` | Arctis system tray for quick switching |
| `arctis-video-router.service` | Routes browser/media apps to Arctis_Media automatically |

### Sonar EQ Profiles

Six per-application filter-chain profiles under `~/.config/pipewire/filter-chain.conf.d/`:

| Profile | Target |
|---|---|
| `sonar-game-eq.conf` | Arctis_Game sink |
| `sonar-chat-eq.conf` | Arctis_Chat sink |
| `sonar-media-eq.conf` | Arctis_Media sink |
| `sonar-micro-eq.conf` | Microphone EQ (OBS virtual mic) |
| `sonar-output-eq.conf` | Master output EQ |
| `sink-virtual-surround-7.1-hesuvi.conf` | HeSuVi binaural surround (HRIR convolution) |

### OBS Virtual Microphone

The `virtual-mic` script creates a permanent `pw-loopback` from the OBS virtual sink to the OBS virtual source, so any audio played through the virtual sink (including VST-processed mic from OBS) appears as a system microphone. This enables **discord calls with OBS voice processing**.

---

## ◈ Keybindings

| Keybind | Action |
|---|---|
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

The installer runs **10 phases** interactively:

```
Phase 0:  System Preparation   — multilib, keyring, mirrors
Phase 1:  Core Packages        — 20 interactive categories (DE, gaming, dev, etc.)
Phase 2:  AUR Packages         — 16 interactive per-package prompts
Phase 3:  NVIDIA Drivers       — open-dkms stack (RTX 4070 optimized)
Phase 4:  Enable Services      — SDDM, PipeWire, Bluetooth, NetworkManager
Phase 5:  ZSH Shell            — Oh-My-ZSH + powerlevel10k + plugins
Phase 6:  Deploy Dotfiles      — All configs (backup originals first)
Phase 7:  Hyprland Plugins     — HyprGlass liquid glass plugin
Phase 8:  Final Cleanup        — Cache cleanup, directory setup
Phase 9:  Restore User Apps    — Per-app prompts (Discord, Steam, Spotify, OBS…)
                                + Audio services (virtual mic, loop hole, Arctis)
                                + Spicetify Lotus theme + Discord Lotus theme
Phase 10: Performance Tweaks   — Optional: GPU undervolt/OC, fan curve, CPU governor,
                                sysctl tuning, NVMe read-ahead, GRUB C-state limits
```

### Performance Tweaks (Phase 10)

Phase 10 is optional and asks about each tweak individually. Applied tweaks persist across reboots:

| Tweak | What it does |
|---|---|
| **GPU power limit** | Caps RTX 4070 at 160W — loses ~2% perf but runs cooler and more stable |
| **GPU core OC** | +130 MHz core offset (via Coolbits) — safe, stable on 4070 |
| **GPU mem OC** | +1000 MHz on GDDR6X — free bandwidth, typical headroom is +1500 |
| **GPU fan curve** | Dynamic 30-100% based on temperature, keeps card under 65°C |
| **CPU governor** | Sets `performance` governor and `min_perf_pct=50` at boot |
| **CPU C-states** | Limits deep sleep (C6+) via GRUB — reduces wakeup latency micro-stutters |
| **sysctl** | `swappiness=5`, lower dirty ratios, autogroup off, NUMA balancing off |
| **NVMe read-ahead** | 512 KB (up from 128 KB) — improves game asset loading |
| **Coolbits** | Enables NVIDIA OC/fan control in X config |

### Requirements

- **OS:** Arch Linux
- **Compositor:** Hyprland 0.55+
- **GPU:** NVIDIA (optimized for RTX 4070) or Intel
- **Audio:** PipeWire + WirePlumber (Arctis Nova 5 recommended)
- **Terminal:** Ghostty (default) or Kitty
- **Depends on:** Waybar, Rofi, swaync, wlogout, swww, nwg-displays

---

## ◈ Structure

```
.config/
├── hypr/                      # Main Hyprland Lua config
│   ├── hyprland.lua           # Entry point (requires all modules)
│   ├── configs/               # Base configuration modules
│   ├── UserConfigs/           # User overrides (survive updates)
│   ├── scripts/               # Utility scripts
│   ├── UserScripts/           # User scripts
│   ├── animations/            # Animation presets
│   ├── wallpaper_effects/     # Wallpaper effects
│   ├── wallust/               # Wallust color templates
│   ├── Monitor_Profiles/      # Saved monitor layouts
│   ├── auto_link_obs.sh       # Loop hole — routes Arctis to OBS
│   └── monitors.conf          # nwg-displays output
├── pipewire/
│   └── filter-chain.conf.d/   # Sonar EQ profiles + 7.1 virtual surround
├── systemd/user/              # Audio service units
│   ├── virtual-mic.service
│   ├── auto-link-obs.service
│   ├── arctis-manager.service
│   ├── arctis-gui.service
│   └── arctis-video-router.service
└── spicetify/Themes/Lotus/    # Spicetify Lotus theme
.local/
├── bin/
│   ├── virtual-mic            # OBS virtual mic loopback
│   ├── steam-gamescope.sh     # Steam Gamescope wrapper
│   └── limit-steam-shader.sh  # Steam shader cache limiter
└── share/pipewire/hrir_hesuvi/  # HeSuVi HRIR convolution file
```

---

## ◈ Themes

### Color Palette

| Token | Hex | Usage |
|---|---|---|
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

## ◈ Packages

The repo captures your current package state at install time:

| Source | Count |
|---|---|
| Official (pacman) | 146 |
| AUR (yay) | 16 |
| Flatpak | 2 |

Lists are stored in `packages/{pacman,aur,flatpak}.txt` and restored on fresh installs with **per-app granularity** — no unwanted bulk installs.

---

<p align="center">
  <a href="https://github.com/LotsV8pro/lotus-discord"><img src="https://img.shields.io/badge/Lotus_Discord-141218?style=flat-square&logo=discord&logoColor=C4A8E2"/></a>
  <a href="https://github.com/LotsV8pro/lotus-spotify"><img src="https://img.shields.io/badge/Lotus_Spotify-141218?style=flat-square&logo=spotify&logoColor=C4A8E2"/></a>
  <a href="https://github.com/LotsV8pro/Lotus-Arch"><img src="https://img.shields.io/badge/Lotus_Arch-141218?style=flat-square&logo=arch-linux&logoColor=C4A8E2"/></a>
</p>

<p align="center">
  <sub>MIT License — <a href="https://github.com/LotsV8pro">@LotsV8pro</a></sub>
</p>
