# Niri + iNiR session (optional)

Pick `Niri` at install (or choose Both) to get the scrollable-tiling [Niri](https://github.com/YaLTeu/niri) compositor driven by the [iNiR](https://github.com/snowarch/iNiR) Quickshell shell, overview, app drawer, clipboard manager, screenshot/OCR region tools, lock screen, media & wallpaper browser. Lotus-Arch ships a modular KDL config (`dotfiles/niri/config.d/`) with iNiR keybinds, plus the user config overlay in `dotfiles/inir/`. Phase 12 clones upstream iNiR, applies the Lotus configs on top and wires the systemd session unit.

The niri monitor configuration is portable by default; this machine's exact dual-monitor layout lives in the optional `dotfiles/niri/monitor.lotus.kdl` overlay that activates only when the same outputs are detected (see the [Portable note](INSTALLATION.md#requirements)).

## Window memory

Niri reopens every app on the workspace and monitor where it was last closed. A small daemon does the work: `~/.local/bin/niri-window-memory` listens to `niri msg --json event-stream`, records the placement of each window by `app_id`, and moves a new window back when the same app opens again. It runs as the `niri-window-memory.service` user unit, which the install enables with the graphical session.

Niri's own `open-on-workspace` cannot do this here: it resolves a workspace by name, and this config names the workspaces `1`..`5`, which niri reads as an index on the focused output instead of a name.

Placements live in `~/.config/niri/window-memory.json`. Delete an app's entry there to make it open wherever niri decides again. Dialogs and floating windows are not remembered, and Steam and the portal dialogs are on the ignore list; both lists are in the `settings` block of that file.

## Animated wallpapers & color dots

The Lotus iNiR wallpaper selector (`SUPER + W`, the Skew browser) filters your library by predominant color. With this release the color dots now also cover animated wallpapers (video + GIF), a representative video frame is sampled (via ffmpeg, so the black fade-in frame is skipped) and classified into the same 11 color families (Red … Pink, Brown, Black, White). Live previews are on by default for gifs/videos; press `Escape` or use the toggle button to turn them off, and the choice is remembered.

## Wallpaper Engine auto-sync (optional, opt-in via Phase 12)

The installer wires a systemd watch unit (`we-wallpaper-sync.path`) that watches your Wallpaper Engine workshop cache and keeps a `~/Pictures/Wallpapers/all` folder in sync automatically:

- Adding a wallpaper in Wallpaper Engine copies its video(s) into `all/`.
- Unsubscribing removes the matching files again (a manifest tracks what came from WE, so your own files are never touched).
- Tiny `preview.gif` stubs and 0-byte placeholder files are ignored.

Your personal Wallpaper Engine library is never bundled into the repo, only the sync infrastructure ships, so a fresh install builds its own library from whichever wallpapers you're subscribed to. The helper lives at `~/.local/bin/we-wallpaper-sync.py` and can be run manually anytime.

See also [CALENDAR.md](CALENDAR.md) for the optional Google Calendar / birthdays sync that ships with the iNiR shell.
