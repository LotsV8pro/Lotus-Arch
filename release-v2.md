# Lotus Arch v2.0.0 — Portable, Replicable System

Full overhaul so the repo can be cloned and installed on **any Arch machine** (any username, NVIDIA *or* AMD, optional peripherals), plus all detected issues patched.

## 🔧 Installer fixes

- **`install.sh`**: `SCRIPT_DIR` is now **exported** — Phases 9 and 10 were silently broken in child shells and used the wrong repo path.
- Missing packages added: **ghostty** (official) and **wallust** (AUR, referenced by the configs but never installed). `awww` was already listed.
- Phase 6 deploy now **rewrites every hardcoded `@HOME@` path** to the real `$HOME` at install time — the repo no longer forces you to be user `lots`.
- Deploy **symlinks `swww`/`swww-daemon` → `awww`/`awww-daemon`** automatically (`swww` is deprecated; its successor `awww` is what's installed in 2026).
- Deploy **seeds a starter wallpaper set** (Blobs And Waves + Dracula) into `~/Pictures/wallpapers` and a default `.wallpaper_current` so `initial-boot.sh` (wallust + wallpaper) works out of the box.

## 🎛️ Phase 10 — selectable hardware profiles

Phase 10 now asks for your hardware profile and lets you skip **each** tweak individually:

| Profile | GPU | CPU |
|---|---|---|
| **1) NVIDIA + Intel** | RTX 4070 tuned: 160W power limit, +150 core / +1500 mem OC (`nvidia-smi`), Coolbits X config, dynamic fan curve | `intel_pstate` min perf 50% + performance governor |
| **2) AMD** | amdgpu DPM forced high, hwmon dynamic fan curve, optional `ppfeaturemask` for CoreCtrl OC | `amd_pstate` EPP=performance + performance governor |

Structure reorganized into `performance-tweaks/{common,nvidia,amd}` — common tweaks (sysctl, NVMe, GRUB C-states, pstate CPU) apply to both.

## 🔒 Portability

- PipeWire HeSuVi HRIR path → `${env:HOME}` (PipeWire-native expansion).
- `steam-shader-limit.service` → `%h`; scripts use `$HOME` instead of `@HOME@`.
- Wallpaper presets (Lotus/Pixel/Shrek/monochrome/white) and `PresetManager.sh` use/expand `$HOME`.
- MangoHud, qpwgraph, QtProject, qt5ct/qt6ct, gtk bookmarks, OBS, spicetify: personal paths/history cleared or regenerated at runtime.

## 🧹 Junk removed (personal/machine-specific)

- **OBS browser cache** (`plugin_config/obs-browser/` — a full Chrome profile, ~MBs).
- **Windows OBS scenes/profiles** ("Sin Título" with `C:\` paths).
- Hyprland `v2.3.20` stray file + `.conf-backup-20260728/` snapshot.
- Wallpaper state binaries (`.wallpaper_current`/`.wallpaper_modified`).
- `Startup_Apps.lua.backup*` + `arctis-manager.desktop.backup*`.
- **`spotify/prefs` autologin credentials purged** (security).
- `.gitignore` now ignores backups, wallpaper state, OBS browser cache.

## 🆕 Added

- `limit-steam-shader.sh` + `cpulimit` binary (used by `steam-shader-limit.service`).
- Starter wallpapers: `wallpapers/Blobs And Waves/` + `wallpapers/Dracula/`.

> Hardware-specific bits (dual-monitor layout `DP-2`+`HDMI-A-1`, Arctis Nova audio pipeline, peripheral tools) are kept but optional — every prompt can be answered `n` on machines that don't match.
