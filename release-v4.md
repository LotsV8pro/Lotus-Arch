# Lotus Arch — Release Notes

## v4.1 — Pill bar system update indicator, font fixes, app corrections

### Pill bar: system update indicator

- **Download icon badge** in pill rest mode: a small download glyph appears next to the clock when updates are available, with a colored dot for strongly-advised thresholds.
- **Hover row icon**: a full-size download icon with a count badge appears in the pill's status row. Clicking it launches `arch-update` (or the configured `apps.update` command).
- **Soul bead tracking**: the pill's animated bead now follows the cursor to the update icon on hover.
- **Auto-refresh**: clicking the icon triggers `Updates.refresh()` before launching the update command, so the count stays current.
- New components: `SystemUpdateIndicator.qml` (bar module), service integration with `Updates.qml`.
- Installer overlay: `dotfiles/quickshell/modules/pill/`, `modules/bar/`, `services/Updates.qml` are now deployed by `install-scripts/12-niri-inir.sh`.

### Font fixes

- **FiraCode Nerd Font**: installed and referenced correctly in `config.json` `iconFont`. Fixes nerd-glyph rendering across the shell.
- **JetBrainsMono NF**: fixed name typo (`JetBrains Mono NF` → `JetBrainsMono NF`) in both quickshell and iNiR configs.
- **Open Sans → Noto Sans**: replaced missing `Open Sans` with installed `Noto Sans` for the UI font.
- **Zen Kaku Gothic New**: installed for kanji glyph rendering in the pill bar clock and media controls. Fixes square/tofu glyphs.
- **Segoe UI → Noto Sans**: replaced Windows-only `Segoe UI` / `Segoe UI Variable Display` defaults in waffle background clock and common Config.qml with cross-platform `Noto Sans`.

### App corrections

- **Browser**: replaced `firefox` (not installed) with `zen-browser` across all config references (apps.browser, dock pinnedApps, sidebar quickLaunch).
- **Editor**: replaced `/usr/bin/code` (not installed) with `/usr/bin/nvim` in sidebar quickLaunch.
- **Wallpaper path**: fixed broken path (`GT Racing/` → `GT-cars/Porsche/`) to match actual directory structure.

### Installer updates

- `install-scripts/12-niri-inir.sh` now overlays quickshell module overrides (pill, bar, waffle, common, overview, services) on top of upstream iNiR during install.
- Font config (`quickshell/config.json`) is deployed alongside the iNiR config.

### Cleanup

- Removed unused `import Quickshell.Hyprland` from `WaffleOSD.qml` (you're on Niri, not Hyprland).
- Removed debug print statements from `BarContent.qml` EdgeZoneCell.

### Notes

- Requires [iNiR](https://github.com/snowarch/iNiR) upstream quickshell shell.
- `arch-update` (AUR) is installed by the pill bar click action; install it with `yay -S arch-update` if missing.
- `checkupdates` (from `pacman-contrib`) must be available for the update counter to work.
