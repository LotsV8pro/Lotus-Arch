<p align="center">
  <img src="https://img.shields.io/badge/Arch_Linux-141218?style=for-the-badge&logo=arch-linux&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Hyprland-141218?style=for-the-badge&logo=hyprland&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Niri_%2B_iNiR-141218?style=for-the-badge&logo=niri&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/NVIDIA_RTX_4070-141218?style=for-the-badge&logo=nvidia&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Lua_Config-141218?style=for-the-badge&logo=lua&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Purple_Lotus-141218?style=for-the-badge&logo=codeforces&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/github/v/release/LotsV8pro/Lotus-Arch?style=for-the-badge&color=141218"/>
</p>

<h1 align="center">◈ LOTUS ARCH ◈</h1>

<p align="center">
  <b>Arch Linux — Hyprland and/or Niri + iNiR — Purple Lotus Desktop Environment</b><br>
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

Lotus Arch is a complete **Arch Linux desktop environment** with a choice of two sessions — pick at install time, or install **both** and switch from the SDDM login screen:

- **Hyprland** — tiling compositor with a pure Lua configuration (no legacy `.conf` files), waybar, rofi.
- **Niri + iNiR** *(optional)* — scrollable-tiling compositor paired with the [iNiR](https://github.com/snowarch/iNiR) Quickshell shell: overview, app drawer, clipboard manager, lock screen, media/wallpaper tools.

Both sessions share the same foundation: cohesive **purple glassmorphism** aesthetic, NVIDIA RTX 4070 optimization, full **Arctis Nova 5 audio pipeline**, and a built-in preset system for saving/loading entire desktop themes.

### ✦ Features

| | |
|---|---|
| **Two Sessions** | Hyprland (Lua config) and/or Niri + iNiR — your choice at install |
| **Purple Lotus Theme** | Monochrome purple palette across the shell, Waybar, Rofi, Kitty |
| **HyprGlass** | Apple-style liquid glass effect with per-window control (Hyprland) |
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

### Hyprland

| Keybind | Action |
|---|---|
| `SUPER + Return` | Terminal (Kitty) |
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

### Niri (iNiR)

| Keybind | Action |
|---|---|
| `Mod + T / Return` | Terminal (via iNiR) |
| `Mod + D` | iNiR Overview |
| `Mod + V` | Clipboard Manager |
| `Super + G` | Quick Overlay |
| `Mod + Comma` | iNiR Settings |
| `Mod + /` | Cheatsheet |
| `Mod + Shift + S` | Region Screenshot |
| `Mod + Shift + X` | Region OCR |
| `Ctrl + Alt + T` | Wallpaper Selector |
| `Mod + Q` | Close Window |
| `XF86 Audio/Brightness` | Volume / Brightness control |

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

**Unattended presets** (skip all prompts):

```bash
./install.sh --preset minimal   # lean Hyprland-only desktop
./install.sh --preset full      # everything on, both sessions
./install.sh --session niri --audio basic --streaming no   # targeted overrides
```

### What gets installed

The installer first asks for your **session**:

```
  1) Hyprland            — tiling compositor, Lua config, waybar
  2) Niri + iNiR shell   — scrollable tiling + full Quickshell desktop (optional)
  3) Both                — install both, pick at the SDDM login screen
```

Two hardware-pack questions follow (Arctis audio pipeline / OBS streaming pack) — they gate which audio configs and services get deployed, in **both** sessions.

Then it runs **13 phases** interactively:

```
Phase 0:  System Preparation   — multilib, mirrors, system update
Phase 1:  Core Packages        — interactive categories incl. Hyprland / Niri per session choice
Phase 2:  AUR Packages         — grouped prompts (Browsing / Chat / Media / Desktop extras)
Phase 3:  NVIDIA Drivers       — open-dkms stack (RTX 4070 optimized)
Phase 4:  Enable Services      — SDDM, PipeWire, Bluetooth, NetworkManager
Phase 5:  ZSH Shell            — Oh-My-ZSH + custom lotus theme + plugins
Phase 6:  Deploy Dotfiles      — All configs (backup originals first)
Phase 12: iNiR Shell           — only if Niri was chosen; clones upstream iNiR,
                                 overlays Lotus configs, wires the session
Phase 11: Optional Extras      — extra presets, GPU tuning pack, GT Racing
                                 wallpapers (~82 MB), movie-tui config
Phase 7:  Hyprland Plugins     — HyprGlass liquid glass plugin
Phase 8:  Final Cleanup        — Cache cleanup, directory setup
Phase 9:  Restore User Apps    — Per-app prompts (Discord, Steam, Spotify, OBS…)
                                 + Audio services (virtual mic, loop hole, Arctis)
                                 + Spicetify Lotus theme + Discord Lotus theme
Phase 10: Performance Tweaks   — Selectable profile (NVIDIA+Intel / AMD). Optional:
                                 GPU OC/fan curve, CPU governor, sysctl, NVMe, GRUB C-states
```

### Performance Tweaks (Phase 10)

Phase 10 is optional, asks about each tweak individually, and starts by asking you to pick your **hardware profile**:

| Profile | GPU tweaks | CPU tweaks |
|---|---|---|
| **NVIDIA + Intel** | RTX 4070 tuned — 160W power limit, +150 core / +1500 mem OC (nvidia-smi), Coolbits X config, dynamic fan curve | `intel_pstate` min perf 50% + performance governor |
| **AMD** | amdgpu DPM forced to high, hwmon fan curve, optional `ppfeaturemask` for CoreCtrl OC | `amd_pstate` EPP=performance + performance governor |

Applied tweaks persist across reboots (GRUB C-states apply to both profiles):

| Tweak | What it does |
|---|---|
| **GPU power limit** | Caps RTX 4070 at 160W — loses ~2% perf but runs cooler and more stable |
| **GPU core OC** | +150 MHz core offset (via Coolbits) — safe, stable on 4070 |
| **GPU mem OC** | +1500 MHz on GDDR6X — free bandwidth, typical headroom is +1500 |
| **GPU fan curve** | Dynamic 30-100% based on temperature, keeps card under 65°C |
| **AMD GPU perf** | Forces highest DPM performance level + 3D workload profile |
| **CPU governor** | Sets `performance` governor (Intel pstate + AMD pstate) at boot |
| **CPU C-states** | Limits deep sleep (C6+) via GRUB — reduces wakeup latency micro-stutters |
| **sysctl** | `swappiness=5`, lower dirty ratios, autogroup off, NUMA balancing off |
| **NVMe read-ahead** | 512 KB (up from 128 KB) — improves game asset loading |
| **NVIDIA Coolbits** | Enables NVIDIA OC/fan control in X config |
| **AMD ppfeaturemask** | Optional — enables amdgpu overclocking/undervolt in CoreCtrl |

### Requirements

- **OS:** Arch Linux
- **Compositor:** Hyprland 0.55+ (Lua config) and/or Niri + iNiR (optional session)
- **GPU:** NVIDIA (optimized for RTX 4070) or AMD / Intel — Phase 10 lets you pick your profile
- **Audio:** PipeWire + WirePlumber (Arctis Nova 5 recommended for the full audio pipeline)
- **Terminal:** Kitty (the configs default to `$term = kitty`; ghostty configs ship as an optional extra in `dotfiles/ghostty/`)
- **Depends on:** Waybar, Rofi, swaync, wlogout, `awww` (wallpaper daemon — the scripts call `swww`, which is symlinked to `awww` automatically during install since `swww` is deprecated), wallust
- **Niri session only:** quickshell + iNiR ([github.com/snowarch/iNiR](https://github.com/snowarch/iNiR) — installed automatically by Phase 12)

> **Portable:** the repo was captured on user `lots` (NVIDIA RTX 4070 + i7-13700KF + dual monitor). The installer
> rewrites every hardcoded `@HOME@` path to your own home at deploy time, ships a starter wallpaper set, and
> the Arctis audio services / OBS pipeline are optional (per-app prompts) — so it works on any hardware/username.

### Tools (`tools/`)

| Script | Purpose |
|---|---|
| `tools/scan-secrets.sh` | Scans the working tree for credentials / personal data (passwords, API keys, browser DBs, `Cookies`, `@HOME@`). Run before committing — exit 1 flags anything suspicious. |
| `tools/deploy-dotfiles.sh` | Quick re-sync: deploys only Phase 6 (dotfiles) with auto-backup, without reinstalling. Replaces existing configs in place (true mirror — safe to re-run anytime). Use after editing configs in the repo. |
| `tools/regenerate-package-lists.sh` | Re-export `packages/*.txt` from the current machine (`pacman -Qqe` + `yay -Qqm` + `flatpak`) so the repo always mirrors exactly what is installed. Run it after adding/removing packages. |

---



## ◈ Structure

```
.config/
├── hypr/                        # Hyprland session — main Lua config
│   ├── hyprland.lua             # Entry point (requires all modules)
│   ├── configs/                 # Base configuration modules
│   ├── UserConfigs/             # User overrides (survive updates)
│   ├── scripts/                 # Utility scripts (palette, wallpaper effects)
│   ├── UserScripts/             # User scripts
│   ├── animations/              # Animation presets
│   ├── wallpaper_effects/       # Wallpaper effects
│   ├── wallust/                 # Wallust color templates
│   ├── Monitor_Profiles/        # Saved monitor layouts
│   ├── auto_link_obs.sh         # Loop hole — routes Arctis to OBS
│   └── monitors.lua             # nwg-displays output
├── niri/                        # Niri session — modular KDL config
│   ├── config.kdl               # Entry point (includes config.d/*)
│   └── config.d/                # 10-input … 90-user-overrides modules
├── inir/                        # iNiR shell user config (AI models, prefs)
├── quickshell/
│   ├── lotus-shell/             # Lotus Quickshell bar/shell variant
│   └── overview/                # Overview plugin bits
├── pipewire/
│   └── filter-chain.conf.d/     # Sonar EQ profiles + 7.1 virtual surround
├── systemd/user/                # Audio & session service units
│   ├── virtual-mic.service
│   ├── auto-link-obs.service
│   ├── arctis-manager.service
│   ├── arctis-gui.service
│   ├── arctis-video-router.service
│   ├── steam-shader-limit.service
│   └── inir.service             # iNiR shell session unit (Niri)
├── lotus-palette/               # Preset engine + palette tools
└── spicetify/Themes/Lotus/      # Spicetify Lotus theme
optional/                        # Opt-in extras (Phase 11) — work on BOTH sessions
├── gpu/                         # GWE fan/OC profiles + vkSumi color grading
└── movie-tui/                   # movie-tui config (add your own TMDB key)
wallpapers/GT Racing/            # GT Racing car wallpaper pack (~82 MB, opt-in copy)
.local/
├── bin/
│   ├── virtual-mic              # OBS virtual mic loopback
│   ├── steam-gamescope.sh       # Steam Gamescope wrapper
│   ├── limit-steam-shader.sh    # Steam shader cache limiter
│   └── cpulimit                 # CPU limiter for shader processes
└── share/pipewire/hrir_hesuvi/  # HeSuVi HRIR convolution file
```

### Performance Tweaks (Phase 10)

```
performance-tweaks/
├── common/                    # Works for every hardware profile
│   ├── 99-performance.conf    # sysctl
│   ├── 99-nvme-performance.rules
│   ├── grub-cmdline.sh        # C-state kernel params (intel/amd)
│   ├── cpu-tweaks.sh          # Intel pstate / AMD pstate EPP
│   └── systemd/               # cpu-tweaks + performance-governor services
├── nvidia/                    # NVIDIA + Intel profile (RTX 4070 tuned)
│   ├── 10-nvidia.conf         # Coolbits X config
│   ├── gpu-tweaks.sh          # 160W power limit + mem OC (nvidia-smi)
│   ├── gpu-fan-curve.sh       # Dynamic fan curve + core OC
│   └── systemd/
└── amd/                       # AMD profile
    ├── 50-amdgpu.conf         # ppfeaturemask (optional OC via CoreCtrl)
    ├── gpu-tweaks.sh          # DPM high + 3D workload profile
    ├── gpu-fan-curve.sh       # hwmon-based dynamic fan curve
    └── systemd/
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
- Terminal colors (Kitty)
- Rofi theme
- GTK overrides
- Shell/bar state (waybar on/off, extra Quickshell shells)

The **Lotus** preset ships by default. The extra presets (`Monochrome`, `Pixel`, `White Monochrome`) are **optional** — choose them during install (Phase 11).

> ℹ️ `Yellowstone.conf` is a legacy leftover and not loadable as a preset.

### Niri + iNiR session (optional)

Pick `Niri` at install (or choose **Both**) to get the scrollable-tiling **[Niri](https://github.com/YaLTeu/niri)** compositor driven by the **[iNiR](https://github.com/snowarch/iNiR)** Quickshell shell — overview, app drawer, clipboard manager, screenshot/OCR region tools, lock screen, media & wallpaper browser. Lotus-Arch ships a modular KDL config (`dotfiles/niri/config.d/`) with iNiR keybinds, plus the user config overlay in `dotfiles/inir/`. Phase 12 clones upstream iNiR, applies the Lotus configs on top and wires the systemd session unit.

---

## ◈ Credits

### JaKooLit — Hyprland base

The Hyprland configuration architecture (configs / UserConfigs / UserScripts layout, script collection, theming pipeline) started as a conversion of **[JaKooLit's Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland)** dots, later rewritten for Hyprland's native Lua config. Huge thanks to [@JaKooLit](https://github.com/JaKooLit) — much of the desktop plumbing traces back to that project.

### Quickshell Overview

`dotfiles/quickshell/overview/` is **[quickshell-overview](https://github.com/Shanu-Kumawat/quickshell-overview)** by **[@Shanu-Kumawat](https://github.com/Shanu-Kumawat)** (GPL-3.0), vendored unmodified apart from user keybind integration. The license notice lives in [dotfiles/quickshell/overview/NOTICE.md](dotfiles/quickshell/overview/NOTICE.md).

### Niri + iNiR

- **[Niri](https://github.com/YaLTeu/niri)** by **[@YaLTeu](https://github.com/YaLTeu)** — the scrollable-tiling compositor (GPL-3.0)
- **[iNiR](https://github.com/snowarch/iNiR)** by **[@snowarch](https://github.com/snowarch)** — the Quickshell desktop shell installed by Phase 12

### Also with thanks

- **[ML4W / Stephan Raabe](https://gitlab.com/stephan-raabe/dotfiles)** — several waybar styles (`ML4W Glass`, `ML4W starter`, …)
- **[end-4](https://github.com/end-4/dots-hyprland)** — the `END-4` animation preset
- **Kiran George ([@SherLock707](https://github.com/SherLock707))** — the dropdown terminal script
- **[@wnkz](https://github.com/wnkz)** — monoglow_z kitty theme
- **Catppuccin, Rosé Pine, Everforest, Nord & DedSec** communities — palette-derived themes and wallpapers throughout `waybar/`, `kitty/` and `wallpapers/`

---

## ◈ Ecosystem

Lotus Arch is part of a **unified desktop ecosystem** with matching themes for all major apps:

| App | Theme | Repo |
|---|---|---|
| **Discord** (Vencord) | Lotus Purple | [lotus-discord](https://github.com/LotsV8pro/lotus-discord) |
| **Spotify** (Spicetify) | Lotus Purple | [lotus-spotify](https://github.com/LotsV8pro/lotus-spotify) |
| **Waybar** | Lotus Pill / Lotus Purple | — *(included)* |
| **Rofi** | Lotus Purple | — *(included)* |
| **Kitty** | Lotus Terminal | — *(included)* |
| **GTK / Thunar** | Lotus Purple Pill | — *(included)* |

---

## ◈ Packages

The repo captures your current package state at install time:

| Source | Count |
|---|---|
| Official (pacman) | 158 |
| AUR (yay) | 21 |
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
