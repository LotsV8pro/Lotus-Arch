# Installation

Detailed installation guide for Lotus Arch.

## Fresh Arch Install

```bash
curl -sL https://raw.githubusercontent.com/LotsV8pro/Lotus-Arch/main/auto-install.sh | bash
```

## Existing Arch Install

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

## What gets installed

The installer first asks for your **session**:

```
  1) Hyprland            — tiling compositor, Lua config, waybar
  2) Niri + iNiR shell   — scrollable tiling + full Quickshell desktop (optional)
  3) Both                — install both, pick at the SDDM login screen
```

A hardware-pack question follows (OBS streaming pack) — it gates which streaming configs and services get deployed, in **both** sessions.

Then it runs **13 phases** interactively:

```
Phase 0:  System Preparation   — multilib, mirrors, system update
Phase 1:  Core Packages        — interactive categories incl. Hyprland / Niri per session choice
Phase 2:  AUR Packages         — grouped prompts (Browsing / Chat / Media / Desktop extras)
Phase 3:  GPU Drivers          — installs only for the graphics card you
                                 selected earlier (NVIDIA: open-dkms stack /
                                 AMD: vulkan-radeon / Intel: integrated)
Phase 4:  Enable Services      — SDDM, PipeWire, Bluetooth, NetworkManager
Phase 5:  ZSH Shell            — Oh-My-ZSH + custom lotus theme + plugins
Phase 6:  Deploy Dotfiles      — All configs (backup originals first)
Phase 7:  Hyprland Plugins     — HyprGlass liquid glass plugin
Phase 8:  Final Cleanup        — Cache cleanup, directory setup
Phase 9:  Restore User Apps    — Per-app prompts (Discord, Steam, Spotify, OBS…)
                                 + Audio services (virtual mic, EasyEffects)
                                 + Spicetify Lotus theme + Discord Lotus theme
Phase 10: Performance Tweaks   — Selectable profile (NVIDIA / AMD). Optional:
                                 GPU OC/fan curve, CPU governor, sysctl, NVMe, GRUB C-states
Phase 11: Optional Extras      — extra presets, GPU tuning pack, GT Racing
                                 wallpapers (~82 MB), movie-tui config
Phase 12: iNiR Shell           — only if Niri was chosen; clones upstream iNiR,
                                 overlays Lotus configs, wires the session
```

### Performance Tweaks (Phase 10)

Phase 10 is **optional and purely additive** — the base desktop works on **any graphics card** without it. It asks about each tweak individually and starts by asking you to pick your **hardware profile** (NVIDIA or AMD, defaulted to the graphics card you selected earlier). Everything here is opt-in, and the **overclock/undervolt numbers below are tuned specifically for an RTX 4070** — running them on a different card is not recommended; skip the OC/undervolt tweaks (or edit the offsets) if you don't have a 4070.

| Profile | GPU tweaks | CPU tweaks |
|---|---|---|
| **NVIDIA** | RTX 4070-tuned example — 160W power limit, +150 core / +1500 mem OC (nvidia-smi), Coolbits X config, dynamic fan curve *(adjust for your model)* | `intel_pstate` min perf 50% + performance governor |
| **AMD** | amdgpu DPM forced to high, hwmon fan curve, optional `ppfeaturemask` for CoreCtrl OC | `amd_pstate` EPP=performance + performance governor |

Applied tweaks persist across reboots. **The OC/undervolt figures are for an RTX 4070** — on any other card keep the non-OC tweaks (fan curve, governor, sysctl) and adjust or skip the power-limit/clock offsets:

| Tweak | What it does |
|---|---|
| **GPU power limit** | RTX 4070 example: caps at 160W — loses ~2% perf, runs cooler and more stable *(adjust per GPU)* |
| **GPU core OC** | RTX 4070 example: +150 MHz core offset (via Coolbits), stable on that card |
| **GPU mem OC** | RTX 4070 example: +1500 MHz on GDDR6X, typical headroom *(edit for your VRAM)* |
| **GPU fan curve** | Dynamic 30-100% based on temperature, keeps card under 65°C |
| **AMD GPU perf** | Forces highest DPM performance level + 3D workload profile |
| **CPU governor** | Sets `performance` governor (Intel pstate + AMD pstate) at boot |
| **CPU C-states** | Limits deep sleep (C6+) via GRUB — reduces wakeup latency micro-stutters |
| **sysctl** | `swappiness=5`, lower dirty ratios, autogroup off, NUMA balancing off |
| **NVMe read-ahead** | 512 KB (up from 128 KB) — improves game asset loading |
| **NVIDIA Coolbits** | Enables NVIDIA OC/fan control in X config |
| **AMD ppfeaturemask** | Optional — enables amdgpu overclocking/undervolt in CoreCtrl |

### Performance Tweaks location

The Phase 10 `performance-tweaks/` layout and its RTX 4070-tuned OC values are stored under [../performance-tweaks](../performance-tweaks).

## Requirements

- **OS:** Arch Linux
- **Compositor:** Hyprland 0.55+ (Lua config) and/or Niri + iNiR (optional session)
- **GPU:** works with **NVIDIA, AMD, or Intel**. You select your graphics card during install (gates which drivers Phase 3 installs). The Phase 10 overclock/undervolt profile ships RTX 4070-tuned example values — the basic desktop needs nothing 4070-specific.
- **Audio:** PipeWire + WirePlumber + EasyEffects (system-wide EQ/effects — works with any sound card)
- **Terminal:** Kitty (the configs default to `$term = kitty`; ghostty configs ship as an optional extra in `dotfiles/ghostty/`)
- **Depends on:** Waybar, Rofi, swaync, wlogout, `awww` (wallpaper daemon — the scripts call `swww`, which is symlinked to `awww` automatically during install since `swww` is deprecated), wallust
- **Niri session only:** quickshell + iNiR ([github.com/snowarch/iNiR](https://github.com/snowarch/iNiR) — installed automatically by Phase 12)

> **Portable:** configs use a `@HOME@` sentinel that the installer rewrites to your real home directory at deploy
> time, ships a starter wallpaper set, and keeps optional bits (OBS streaming pipeline) behind per-app
> prompts — so it works on any hardware and username.
>
> **Any monitors:** the compositor configs ship *portable* by default — niri (`monitor.kdl`) and Hyprland
> (`monitors.lua`) have **no output names hardcoded**, so they auto-detect every display on any machine, and the
> iNiR shell (`config.json`) ships with empty/inert monitor fields. The reference build's precise layout
> (DP-2 @1440p primary + HDMI-A-1 @1080p secondary, custom positions/scales, workspace pinning) lives in
> **optional overlays** — `dotfiles/niri/monitor.lotus.kdl`, `dotfiles/hypr/monitors.lotus.lua`, and
> `dotfiles/inir/config.lotus.json` — that `06-dotfiles.sh` applies automatically **only when both connectors are
> physically present** (detected via `/sys/class/drm`, compositor-independent so it works even mid-install).
> Cloning to a different PC just works — and restoring this machine perfectly is one automatic detection away.

See also [TOOLS.md](TOOLS.md) for the helper scripts shipped in `tools/`.
