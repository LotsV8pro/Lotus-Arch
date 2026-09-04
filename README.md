<p align="center">
  <img src="https://img.shields.io/badge/Arch_Linux-141218?style=for-the-badge&logo=arch-linux&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Hyprland-141218?style=for-the-badge&logo=hyprland&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Niri_%2B_iNiR-141218?style=for-the-badge&logo=niri&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Any_GPU-141218?style=for-the-badge&logo=nvidia&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Lua_Config-141218?style=for-the-badge&logo=lua&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Purple_Lotus-141218?style=for-the-badge&logo=codeforces&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/github/v/release/LotsV8pro/Lotus-Arch?style=for-the-badge&color=141218"/>
</p>

<h1 align="center">◈ LOTUS ARCH ◈</h1>

<p align="center">
  <b>Arch Linux — Hyprland and/or Niri + iNiR — Purple Lotus Desktop Environment</b><br>
  <sub>Purple glassmorphism · works on any GPU · EasyEffects audio · Preset-ready</sub>
</p>

## ✦ Overview

Lotus Arch is a complete **Arch Linux desktop environment** with a choice of two sessions — pick at install time, or install **both** and switch from the SDDM login screen:

- **Hyprland** — tiling compositor with a pure Lua configuration (no legacy `.conf` files), waybar, rofi.
- **Niri + iNiR** *(optional)* — scrollable-tiling compositor paired with the [iNiR](https://github.com/snowarch/iNiR) Quickshell shell.

Both share the same foundation: cohesive **purple glassmorphism**, works with **any graphics card** (NVIDIA / AMD / Intel), a built-in **preset system** to save/load entire desktop themes, and a system-wide **EasyEffects** audio pipeline.

| | |
|---|---|
| **Two Sessions** | Hyprland (Lua config) and/or Niri + iNiR — your choice |
| **Purple Lotus Theme** | Monochrome purple palette across the shell, Waybar, Rofi, Kitty |
| **HyprGlass** | Apple-style liquid glass effect with per-window control (Hyprland) |
| **Preset Manager** | Save/load/delete full desktop themes with `SUPER + CTRL + P` |
| **Palette Editor** | Visual color picker with `SUPER + P` — change every color instantly |
| **Any GPU** | Works on **NVIDIA / AMD / Intel** — open-dkms drivers (NVIDIA), Vulkan/radv |
| **Gaming Ready** | Steam, Lutris, MangoHud, Gamemode, Gamescope, VRR support |
| **Wallpaper Browser** | Folder-based browser with `SUPER + W`, per-color dots, WE auto-sync |
| **50+ Waybar Themes** | Pill style, floating, glass, monochrome — all Lotus-colored |
| **Audio** | EasyEffects EQ/effects chain, optional OBS streaming pipeline |

## ✦ Install

**Fresh Arch install:**

```bash
curl -sL https://raw.githubusercontent.com/LotsV8pro/Lotus-Arch/main/auto-install.sh | bash
```

**Existing Arch install:**

```bash
git clone https://github.com/LotsV8pro/Lotus-Arch.git
cd Lotus-Arch && chmod +x install.sh && ./install.sh
```

`./install.sh --preset minimal` (lean Hyprland) or `--preset full` (everything) skip the prompts.
It runs **13 phases** and asks for your session (Hyprland / Niri / Both), GPU, and audio pack.
Works on any hardware: configs are portable and detect your monitors automatically.

> Full details — 13 phases, performance tweaks, requirements — are in [docs/INSTALLATION.md](docs/INSTALLATION.md).

## ✦ Getting Started (new to tiling?)

A tiling desktop places windows automatically and is controlled almost entirely from the **keyboard** — there's no minimize button, that's the point. Give it a couple of days and it gets much faster than any Start menu.

- **SUPER / Win (Hyprland)** or **Mod (Niri)** is your menu key — almost every shortcut starts with it.
- Open your terminal with `SUPER + Return` (**Hyprland**) or `MOD + T` (**Niri**).
- Launch apps: Rofi with `SUPER` (**Hyprland**) or the iNiR overview with `MOD + D` (**Niri**).
- Switch windows: `SUPER + J / K` or the board / app grid.
- Re-color the whole desktop live with the **palette editor** (`SUPER + P`) and **preset manager** (`SUPER + CTRL + P`).

All configs are plain text under `~/.config/` and the installer backs up originals (`~/.config/dotfiles-backup/`), so nothing is ever risky to change.

## ✦ Keybindings

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

## ✦ Documentation

| Guide | Contents |
|---|---|
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Install commands, 13 phases, performance tweaks, requirements |
| [docs/SETUP.md](docs/SETUP.md) | First-time setup — make the desktop & audio & calendar yours |
| [docs/AUDIO.md](docs/AUDIO.md) | EasyEffects audio stack, services, OBS virtual mic |
| [docs/STRUCTURE.md](docs/STRUCTURE.md) | Config tree layout |
| [docs/THEMES.md](docs/THEMES.md) | Color palette & preset system |
| [docs/NIRI-INIR.md](docs/NIRI-INIR.md) | Niri/iNiR session, animated wallpapers, WE sync |
| [docs/CALENDAR.md](docs/CALENDAR.md) | Google Calendar & birthdays sync (optional, own OAuth) |
| [docs/TOOLS.md](docs/TOOLS.md) | Helper scripts (`tools/`) |
| [docs/PACKAGES.md](docs/PACKAGES.md) | Package lists |
| [docs/releases/INDEX.md](docs/releases/INDEX.md) | Release notes |

## ✦ Ecosystem

Lotus Arch is part of a **unified desktop ecosystem** with matching themes:

| App | Theme | Repo |
|---|---|---|
| **Discord** (Vencord) | Lotus Purple | [lotus-discord](https://github.com/LotsV8pro/lotus-discord) |
| **Spotify** (Spicetify) | Lotus Purple | [lotus-spotify](https://github.com/LotsV8pro/lotus-spotify) |
| **EasyEffects mic chain** | deepfilternet→rnnoise→speex→EQ→comp→limit | [lotus-mic-chain](https://github.com/LotsV8pro/lotus-mic-chain) |
| **Audio router** (PipeWire) | Lotus Purple | [pc-audio-volume-controller](https://github.com/LotsV8pro/pc-audio-volume-controller) |
| **Waybar / Rofi / Kitty / GTK** | Lotus Purple | — *(included)* |

---

<p align="center">
  <a href="https://github.com/LotsV8pro/lotus-discord"><img src="https://img.shields.io/badge/Lotus_Discord-141218?style=flat-square&logo=discord&logoColor=C4A8E2"/></a>
  <a href="https://github.com/LotsV8pro/lotus-spotify"><img src="https://img.shields.io/badge/Lotus_Spotify-141218?style=flat-square&logo=spotify&logoColor=C4A8E2"/></a>
  <a href="https://github.com/LotsV8pro/Lotus-Arch"><img src="https://img.shields.io/badge/Lotus_Arch-141218?style=flat-square&logo=arch-linux&logoColor=C4A8E2"/></a>
</p>

<p align="center">
  <sub>MIT License — <a href="https://github.com/LotsV8pro">@LotsV8pro</a></sub>
</p>
