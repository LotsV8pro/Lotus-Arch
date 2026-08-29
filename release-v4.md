# Lotus Arch — Release Notes

## v4.5 — Random wallpaper fix + general release notes

### Random wallpaper no longer "does nothing"

- The iNiR wallpaper selector's **random** button (`SUPER + W`) used to pick blindly from the folder model, which also contains sub-folders. When it landed on a folder it would just navigate into it, so the wallpaper never changed — appearing to do nothing.
- The random pick now draws **only from actual wallpaper files** (sub-folders are excluded) and only applies when a valid file is chosen.
- Fix is delivered in the vendored `dotfiles/quickshell/inir/services/Wallpapers.qml`, so fresh installs get it automatically via the Phase 12 overlay.

### Docs read as a general project view

- README and release notes rewritten so they state the project's features for anyone installing it, instead of assuming a single owner — hardware defaults, package lists and the portable-path behavior are described without personal framing.

## v4.4 — Graphics-card-selective install

- The installer now asks for your **graphics card** (NVIDIA / AMD / Intel, auto-detected when possible). NVIDIA drivers install only when NVIDIA is selected; AMD gets `vulkan-radeon`; Intel stays integrated-only.
- The choice flows through the whole install: Phase 1's graphics package set and Phase 3 both follow it, and Phase 10 defaults its hardware profile to the same card.
- The GPU **overclock/OC config** remains a separate opt-in (Phase 10) — independent of which drivers install.

## v4.2 — Auto-refresh updates, repo cleanup, installer reproduces the reference install

### Auto-refresh update counter

- The pill bar's update badge now refreshes **instantly** after any package transaction completes.
- `Updates.qml` watches `/var/log/pacman.log` (polls mtime) and re-runs `checkupdates` a few seconds after the log changes — whether you updated from the pill, a terminal, pamac, or the AUR helper.
- No more waiting up to the periodic interval for the counter to drop to zero.

### Installer reproduces the reference install

- **Quickshell is overlaid, never wholesale-replaced.** `install-scripts/06-dotfiles.sh` no longer wipes `~/.config/quickshell/` (which would delete upstream iNiR's modules); it now copies `config.json`, generic `modules/`, `services/` and the `inir/` overlay on top of the upstream install, leaving everything else intact.
- **Quickshell overlays relocated** under `dotfiles/quickshell/inir/` (mirroring the live `~/.config/quickshell/inir/` path) so the pill bar, bar, waffle and service tweaks land in exactly the right place. `install-scripts/12-niri-inir.sh` deploys the whole `inir/` subtree.
- **NVIDIA tweaks on both sessions confirmed**: the driver env (`LIBVA_DRIVER_NAME`, `__GLX_VENDOR_LIBRARY_NAME`, `NVD_BACKEND`, `GBM_BACKEND`, shader cache) is present in both the Hyprland Lua config **and** the Niri `config.d/40-environment.kdl`; Phase 10 GPU/CPU tweaks are compositor-agnostic systemd services that apply to either session.

### Repo cleanup

- Removed stale `release-v2.md` and `release-v3.md` (superseded).
- Removed `optional/gpu/gwe/gwe.db` (binary hardware-profile settings db).
- README: removed the outdated "Security / history rewrite / deleted v1 releases" paragraph and the CI secret-scan note — no longer relevant to the current docs. Kept the CI workflow itself (it still protects the repo).
- Kept the same visual/typographic style throughout.

### Pill bar system update indicator (from v4.1)

- **Download icon badge** in pill rest mode when updates are available.
- **Hover row icon**: full-size download icon with a count badge; click launches `arch-update` (or configured `apps.update`).
- **Soul bead tracking** on the update icon.
- Click triggers `Updates.refresh()` before launching.

### Font fixes (from v4.1)

- `FiraCode Nerd Font` `iconFont`, `JetBrainsMono NF` typo fix, `Open Sans` → `Noto Sans`, `Zen Kaku Gothic New` installed, `Segoe UI` → `Noto Sans`.

### App corrections (from v4.1)

- `firefox` → `zen-browser`, `/usr/bin/code` → `/usr/bin/nvim`, wallpaper path fixed to `GT-cars/Porsche/`.

### Notes

- Requires [iNiR](https://github.com/snowarch/iNiR) upstream quickshell shell.
- `arch-update` (AUR) is installed by the pill click; `yay -S arch-update` if missing.
- `checkupdates` (from `pacman-contrib`) must be available for the counter to work.
