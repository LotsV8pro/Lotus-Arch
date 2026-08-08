# Lotus Arch v2.0.0 — Portable, Replicable System

Full overhaul so the repo can be cloned and installed on **any Arch machine** (any username, NVIDIA *or* AMD, optional peripherals), plus all detected issues patched.

## 🔧 Installer fixes

- **`install.sh`**: `SCRIPT_DIR` is now **exported** — Phases 9 and 10 were silently broken in child shells and used the wrong repo path.
- Missing packages added: **wallust** (AUR, referenced by the configs but never installed) and **kitty** (the configs default to `$term = kitty`). `awww` was already listed. **ghostty** was mistakenly added then removed — it is **not** installed on the live system.
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
- `wireplumber/wireplumber.conf.d/50-lotus-audio.conf` — no audio device suspension (fixes crackle/latency).
- `lotus-sounds/` — Lotus theme sound effects (`generate.sh` + mp3s).

## 🔐 Privacy hardening (follow-up)

- **`spotify/prefs`: purged `connect.mdns_devices`** — the file leaked your LAN IP (`192.168.x.x`), **public IP** and Chromecast hostname/device metadata. Now `"[]"`.
- `arctis-manager.desktop` → `Hidden=true`: `asm-gui` was started twice (autostart **and** `arctis-gui.service`) on the live system; the file that was being backed up on your machine is now correctly disabled in the repo.

> Hardware-specific bits (dual-monitor layout `DP-2`+`HDMI-A-1`, Arctis Nova audio pipeline, peripheral tools) are kept but optional — every prompt can be answered `n` on machines that don't match.

## 🧹 Full security cleanup (this release supersedes v1.x entirely)

The previous v1.0.0–v1.3.3 releases leaked real data. **They have been deleted from GitHub** (not just hidden) and the **git history was rewritten** to scrub them completely, so nothing sensitive remains reachable:

- **`obs-studio/plugin_config/obs-browser/`** (a full Chrome profile: **Cookies**, **Login Data** = saved passwords, History) — removed from all history.
- **`spotify/Users/`** (account id, autologin **encrypted credentials**, local-files tracking, LAN + **public IP** and Chromecast hostname from `connect.mdns_devices`) — removed from all history; prefs purged.
- **OBS WebSocket password** and **TMDB API key** — hardcoded values scrubbed from all history; the OBS script now reads the password from OBS's own config at runtime, and `movie-tui` re-prompts for the API key.
- Old **v1.x tags and releases deleted**; only `v2.0.0` exists (pointing to the rewritten history).

> ⚠️ **If you ever reused the old OBS WebSocket password / TMDB key / Spotify password elsewhere, rotate them.** The released artifacts were drafts after 2026-08-07 23:14 but the repo was public beforehand.

## 🧪 CI + package-list sync

- **`.github/workflows/security-scan.yml`**: gitleaks + `tools/scan-secrets.sh` run on every push/PR and auto-block the repo on a leak.
- **`tools/regenerate-package-lists.sh`** re-exports `packages/*.txt` from the live machine; lists regenerated to match exactly what is installed (kitty over ghostty, `waybar-git` over `waybar`, NTFS/Strace/Clang tooling, etc.). Only the **`linux`** kernel is kept (the booted kernel); the unused `linux-zen` fallback was dropped.
