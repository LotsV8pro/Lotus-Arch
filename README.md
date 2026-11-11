<p align="center">
  <img src="https://img.shields.io/badge/Arch_Linux-141218?style=for-the-badge&logo=arch-linux&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Hyprland-141218?style=for-the-badge&logo=hyprland&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Niri_%2B_iNiR-141218?style=for-the-badge&logo=niri&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/RTX_4070_%2F_Any_GPU-141218?style=for-the-badge&logo=nvidia&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/badge/Quickshell-141218?style=for-the-badge&logo=qml&logoColor=C4A8E2"/>
  <img src="https://img.shields.io/github/v/release/LotsV8pro/Lotus-Arch?style=for-the-badge&color=141218"/>
</p>

<h1 align="center">Lotus Arch</h1>

An Arch Linux desktop, installed by a script. It offers two sessions and the
same purple theme in both, plus a palette editor and a preset system to switch
between saved looks.

This is a personal desktop, published because the scripts and the configs can be
useful to someone else. It is not a distribution and it is not supported.

## The two sessions

The installer asks which one you want, and you can install both and choose at the
login screen.

**Hyprland**: tiling compositor with a Lua configuration. Waybar, rofi, kitty and
the HyprGlass blur effect. This is the session with fewer hours of use lately,
because development moved to the other one. It works, but expect rough edges.

**Niri + iNiR**: scrollable tiling compositor with the
[iNiR](https://github.com/snowarch/iNiR) shell, which brings the overview, the
calendar, the notification centre and animated wallpapers.

Both share the same foundation:

| Piece | What it does |
|---|---|
| Purple palette | One set of colours for the shell, Waybar, rofi and kitty |
| Palette editor | Change every colour at once, `SUPER + P` |
| Preset manager | Save and load a whole look, `SUPER + CTRL + P` |
| Waybar layouts | `full`, `left`, `minimal`, `neon` and `coredge`, recoloured by the palette |
| EasyEffects | Audio chain for the speakers and for a streaming microphone |
| Wallpaper browser | Folder based, per colour, `SUPER + W` |
| Calendar | Google Calendar and birthdays in the shell, with your own OAuth client |

Anything tied to a specific machine is optional: the RTX 4070 overclock values,
the starter wallpapers and the OBS streaming pipeline are all prompts you can
decline.

## Install

On a fresh Arch install:

```bash
curl -sL https://raw.githubusercontent.com/LotsV8pro/Lotus-Arch/main/auto-install.sh | bash
```

On an existing Arch install:

```bash
git clone https://github.com/LotsV8pro/Lotus-Arch.git
cd Lotus-Arch
chmod +x install.sh
./install.sh
```

`./install.sh --preset minimal` installs a lean Hyprland setup and
`./install.sh --preset full` installs everything, both without the questions.
The rest of the flags are in `./install.sh --help`.

The script runs 13 phases, from the system preparation to the optional extras,
and asks for the session, the GPU, the audio pack and whether to copy the starter
wallpapers. Configs detect the monitors, so a different screen layout is not a
problem.

More detail: [docs/INSTALLATION.md](docs/INSTALLATION.md) for the phases and the
requirements, [docs/HARDWARE.md](docs/HARDWARE.md) for the reference machine and
the optional overclock.

## First steps

A tiling desktop places windows by itself and is driven from the keyboard. There
is no minimize button; that is the design.

- `SUPER` in Hyprland, `Mod` in Niri, starts almost every shortcut.
- Terminal: `SUPER + Return` in Hyprland, `Mod + T` in Niri.
- Applications: rofi with `SUPER` in Hyprland, the iNiR overview with `Mod + D`
  in Niri.
- Move between windows: `SUPER + J` and `SUPER + K`, or the overview.

All configs are plain text under `~/.config/`. The installer copies the previous
ones to `~/.config/dotfiles-backup/` before deploying, so a change can always be
undone.

## Keybindings

### Hyprland

| Key | Action |
|---|---|
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + E` | File manager (Thunar) |
| `SUPER + W` | Wallpaper selector |
| `SUPER + P` | Palette editor |
| `SUPER + CTRL + P` | Preset manager |
| `SUPER + SHIFT + E` | Exit menu |
| `SUPER + SHIFT + K` | Searchable keybinds |
| `SUPER + M` | Power menu |
| `SUPER + V` | Clipboard |
| `SUPER + T` | Quick settings |
| `SUPER + F` | Fullscreen |
| `SUPER + G` | Toggle floating |
| `SUPER + Q` | Close window |
| `SUPER + J / K` | Next / previous window |
| `SUPER + arrows` | Move focus |
| `SUPER + 1-5` | Switch workspace |
| `SUPER + SHIFT + 1-5` | Move window to workspace |

### Niri (iNiR)

| Key | Action |
|---|---|
| `Mod + T` or `Return` | Terminal |
| `Mod + D` | iNiR overview |
| `Mod + V` | Clipboard |
| `Super + G` | Quick overlay |
| `Mod + Comma` | iNiR settings |
| `Mod + /` | Cheatsheet |
| `Mod + Shift + S` | Region screenshot |
| `Mod + Shift + X` | Region OCR |
| `Ctrl + Alt + T` | Wallpaper selector |
| `Mod + Q` | Close window |
| `XF86 Audio` and `XF86 Brightness` | Volume and brightness |

## Documentation

| Guide | Contents |
|---|---|
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Install commands, the 13 phases, requirements |
| [docs/HARDWARE.md](docs/HARDWARE.md) | Reference build (RTX 4070) and optional tuning |
| [docs/SETUP.md](docs/SETUP.md) | First-time setup of the desktop, audio and calendar |
| [docs/AUDIO.md](docs/AUDIO.md) | EasyEffects chain, services, OBS virtual mic |
| [docs/STRUCTURE.md](docs/STRUCTURE.md) | Where each config lives |
| [docs/THEMES.md](docs/THEMES.md) | Palette and preset system |
| [docs/NIRI-INIR.md](docs/NIRI-INIR.md) | Niri and iNiR session, wallpapers |
| [docs/CALENDAR.md](docs/CALENDAR.md) | Google Calendar and birthdays |
| [docs/TOOLS.md](docs/TOOLS.md) | The scripts in `tools/` |
| [docs/PACKAGES.md](docs/PACKAGES.md) | Package lists |
| [docs/releases/INDEX.md](docs/releases/INDEX.md) | Release notes |

## Other repos

| App | Repo |
|---|---|
| Discord (Vencord) | [lotus-discord](https://github.com/LotsV8pro/lotus-discord) |
| Spotify (Spicetify) | [lotus-spotify](https://github.com/LotsV8pro/lotus-spotify) |
| Steam (Millennium) | [lotus-steam](https://github.com/LotsV8pro/lotus-steam) |
| Microphone chain for EasyEffects | [lotus-mic-chain](https://github.com/LotsV8pro/lotus-mic-chain) |
| Laptop microphone preset | [lotus-mic-radio](https://github.com/LotsV8pro/lotus-mic-radio) |
| PipeWire audio router | [pc-audio-volume-controller](https://github.com/LotsV8pro/pc-audio-volume-controller) |
| Music player for YouTube Music | [lotus-tune](https://github.com/LotsV8pro/lotus-tune) |
| Film browser for the terminal | [movie-tui](https://github.com/LotsV8pro/movie-tui) |

Waybar, rofi, kitty and GTK themes ship inside this repo.

## Credits

| Project | Used for |
|---|---|
| [Hyprland](https://hyprland.org) | Tiling compositor, Lua config |
| [Niri](https://github.com/YaLTeu/niri) | Scrollable tiling compositor, optional session |
| [iNiR](https://github.com/snowarch/iNiR) | Quickshell shell, shipped here as an overlay of its modules |
| [Quickshell](https://github.com/outfoxxed/quickshell) | The Qt/QML runtime under iNiR |
| [HyprGlass](https://github.com/hyprnux/hyprglass) | The glass blur effect |
| [kitty-themes](https://github.com/dexpota/kitty-themes) | Terminal colour themes |
| [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh) | ZSH framework |
| [Wallpaper Engine](https://www.wallpaperengine.io) | Animated wallpaper library, optional sync |

The wallpapers are either original artwork or stock material bundled for
convenience; see the starter wallpapers section of
[docs/HARDWARE.md](docs/HARDWARE.md). The rest of the repository is MIT.

<p align="center">
  <a href="https://github.com/LotsV8pro/lotus-discord"><img src="https://img.shields.io/badge/Lotus_Discord-141218?style=flat-square&logo=discord&logoColor=C4A8E2"/></a>
  <a href="https://github.com/LotsV8pro/lotus-spotify"><img src="https://img.shields.io/badge/Lotus_Spotify-141218?style=flat-square&logo=spotify&logoColor=C4A8E2"/></a>
  <a href="https://github.com/LotsV8pro/lotus-steam"><img src="https://img.shields.io/badge/Lotus_Steam-141218?style=flat-square&logo=steam&logoColor=C4A8E2"/></a>
</p>

<p align="center">
  <sub>MIT License, <a href="https://github.com/LotsV8pro">@LotsV8pro</a></sub>
</p>
