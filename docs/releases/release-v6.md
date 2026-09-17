# Lotus Arch — Release Notes

## v6.0 — Full system re-sync, optional wallpapers & reference hardware docs

This release re-syncs the repo with the _current_ desktop (every config that
was touched since v5.2), makes wallpapers and hardware tuning explicit
**optional** choices, trims the stock wallpaper set to the color-filter
packs, and documents the reference machine's exact specs.

### What's in

- **Full system re-sync.** Dotfiles, scripts (`.local/bin`, now 57 portable
  scripts — home paths referenced via `$HOME`), shell overlays, and top-level
  configs all reflect the machine as it is today.
- **iNiR/Quickshell overlay rebuilt.** `dotfiles/quickshell/inir/` now ships
  only the **70 source files that actually differ from upstream**
  [snowarch/inir](https://github.com/snowarch/inir) (63 modified + 7 Lotus-new,
  incl. the CalendarSyncGuide and WaybarEditor settings pages) instead of a
  121 MB mirror. Wallpapers, assets and runtime data stay out of the repo.
  Phase 12 still clones upstream and applies this overlay on top.
- **Starter wallpapers are now optional.** A separate install prompt seeds the
  stock set — **3 per color of the filter** (the 11 named color families of the
  wallpaper selector) plus `Default/2b2.jpg`. **Declining leaves your existing
  `~/Pictures/wallpapers` exactly as-is** — your current wallpaper is never
  touched.
- **Reference hardware documented.** New [HARDWARE.md](HARDWARE.md) and an
  updated INSTALLATION Phase-10 section describe the reference build (Intel +
  NVIDIA **RTX 4070**) with its real out-of-the-box OC values — **216 W power
  limit, GPU lock 3255 MHz, memory lock 12001 MHz, +150 core offset**, Coolbits
  `28`, dynamic fan curve, `performance` governor. Every tweak stays an
  individual opt-in; the base desktop needs nothing 4070-specific.
- **GPU-agnostic, monitors-portable** — unchanged from v5: portable `@HOME@`
  sentinel, auto-detected monitors, optional `.lotus.*` layout overlays.
- **Vencord ignored.** Dist/settings/ExtensionCache were excluded from the
  repo; only the Lotus CSS theme ships (Discord theming lives in the separate
  lotus-discord ecosystem repo).
- **README rewritten** for v6.0 — optional GPU tuning + optional wallpapers now
  front and center, plus the full docs table.

### Notes

- **Hyprland session may have rough edges.** It is the session that has been
  **touched least** during this re-sync (Niri + iNiR is the daily driver).
  The config re-sync touched `hyprland.lua`, `monitors.lua`, `hypridle.conf`
  and `hyprlock.conf`, and the new `dotfiles/hypr/config/*.lua` split was
  migrated from the old `configs/` modules. If you hit issues: `hyprctl`
  config reload first, and check `~/.config/hypr/` for leftover `.conf` files.
- **Wallpaper color packs were trimmed from 4 to **3 per color** (Dracula stays a
  single dark set). If you previously installed the 4th image of any pack,
  simply keep using it — your local copy is untouched.
- **The old `GT Racing` car pack (82 MB) is gone** — the wallpaper library is
  now the stock 3-per-color set + `Default/2b2.jpg`; your personal library
  (including Wallpaper Engine contents) lives in `~/Pictures/Wallpapers/all`
  and is never bundled into the repo.
- The wallpaper seed no longer copies the full `wallpapers/` tree; it seeds the
  `Default/` image plus each color pack.
- `LOTUS_WALLPAPERS=no` (or declining the prompt) makes Phase 6 skip wallpaper
  seeding entirely.
- Re-synced files (`inir.service` et al.) were re-ported to `%h`/`$HOME`;
  `tools/scan-secrets.sh` is clean over the whole tree.