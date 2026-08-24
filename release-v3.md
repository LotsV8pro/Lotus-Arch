# Lotus Arch — Release Notes

## 🚀 v3.0 — Niri + iNiR session, GRUB sync, GPU pack

### ✦ New: Niri + iNiR session (optional)

- The installer now asks for your **session** up front:
  `1) Hyprland` · `2) Niri + iNiR shell (optional)` · `3) Both`.
  Pick **both** and switch from the SDDM login screen. iNiR is fully optional — choose Hyprland-only to skip it entirely.
- **New Phase 12 (`install-scripts/12-niri-inir.sh`)**: verifies the niri/quickshell packages, clones [iNiR](https://github.com/snowarch/iNiR) from upstream, overlays the Lotus configs on top and wires the systemd session unit.
- **New configs**: modular KDL config for niri (`dotfiles/niri/config.kdl` + `config.d/10…90`, iNiR keybinds routed through the portable `sh -c ~/.local/bin/inir …` launcher form), iNiR user config (`dotfiles/inir/config.json`) and the Lotus Quickshell variant (`dotfiles/quickshell/lotus-shell/`).
- **New user units**: `inir.service`, `steam-shader-limit.service` (50 % CPU cap on Steam shader compilation), plus `arctis-video-router.service` now shipped in the repo.

### ✦ Persona theme removed

- The optional Persona 3 Reload Quickshell theme (PersonaPalette, persona preset, QML overrides) is gone from the repo and the installer — replaced by the cleaner Niri + iNiR option.

### ✦ Optional extras reworked (Phase 11) — compositor-agnostic

All extras work identically on Hyprland **and** Niri:

- **GPU tuning pack**: GWE fan/OC profiles + vkSumi color grading (`optional/gpu/`), with an optional vkBasalt ReShade-shaders clone.
- **GT Racing wallpaper pack**: 83 car wallpapers (~82 MB) under `wallpapers/GT Racing/`, copied into `~/Pictures/wallpapers` only if you opt in.
- **movie-tui config**: ships sanitized (add your own TMDB API key).

### ✦ Desktop updates

- **GRUB theme sync**: new `tools/grub-theme-sync.sh` (+ passwordless sudoers snippet) — wallpaper changes now update the GRUB background and menu colors automatically via hooks in `WallustSwww.sh` / `WatchWallpaper.sh`.
- **Window rules**: gamescope & Steam-Proton windows pinned to workspace 1 (perf rules: no blur/shadow/animation), media moved WS5 → WS10, hardware tools (OpenRGB/Vial/GWE/Piper) moved to WS5.
- **Kitty rewritten**: JetBrains Mono 11 pt, beam cursor with trail, wider margins.
- **Waybar**: new backlight module, updater module relocated left, per-module include dir, refined hover styles.
- **GTK/Qt theming overhaul**: adw-gtk3-dark + WhiteSur icons + Darkly color scheme + MaterialAdw Kvantum; Thunar pill styling via `thunar.css`.
- **Arctis Sonar EQ v3/v4**: 18-band slots, retuned immersion/distance, new HeSuvi media-sink filter chain.
- **btop**: auto-generated `ii-auto` theme (+ caelestia extra).
- **MangoHud / cava / mimeapps / OBS scenes / spicetify** refreshed to match the live system.

### 🔧 Housekeeping

- All hardcoded `@HOME@` paths removed from newly synced configs (secret scanner passes clean).
- Package lists regenerated against the current machine (pacman +257 lines incl. niri stack).
- README updated: dual-session overview, niri keybind table, new structure tree, phase list, credits (Niri/iNiR upstreams).
