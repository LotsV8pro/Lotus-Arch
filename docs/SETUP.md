# First-Time Setup Guide

This guide walks you through reproducing Lotus Arch from scratch with **your own** personal data. The repo ships everything *generic* — desktop configs, icons, themes, wallpaper browser, calendar/agenda shell — but **any personal identity lives only on your machine** (OAuth tokens, `events.json`, wallpaper choices, etc.). Nothing of yours is committed to the repo.

## 1. Install

Follow [docs/INSTALLATION.md](INSTALLATION.md) end-to-end:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/LotsV8pro/Lotus-Arch/main/install.sh)
```

- Pick **Hyprland**, **Niri + iNiR**, or **both** at the session prompt.
- Choose the **OBS streaming pack** (optional) if you want the virtual-mic + EasyEffects mic chain; it's what the audio stack builds on. There is **no vendor-specific audio gating** — the base audio stack (PipeWire + WirePlumber + EasyEffects) works with any sound card or headset.
- Select your GPU during install so the right drivers (Phase 3) and performance profile (Phase 10) are applied.

## 2. Verify the desktop

After installing both sessions, log out and choose your session from SDDM (or log into one and switch later):

- **Hyprland** — Lua-based tiling config, `mod + Q` to close, `SUPER + W` opens the wallpaper browser.
- **Niri + iNiR** — scrollable tiling with the full Quickshell desktop (agenda/calendar, notification center, control panel).

Switch sessions anytime from the lock screen to confirm both are wired up.

## 3. Make the audio & streaming stack yours

The EasyEffects configs ship pointing at the **system default** input/output. Open EasyEffects and set your **own** microphone and speakers in the GUI so the EQ/denoise chain targets your hardware:

```sh
systemctl --user status easyeffects.service   # confirm the effects chain runs headless
systemctl --user status virtual-mic.service   # (OBS pack only) loopback sink → virtual mic
```

See [docs/AUDIO.md](AUDIO.md) for the full audio architecture.

## 4. Set up Google Calendar & birthdays with YOUR data (iNiR session)

The calendar is **opt-in** and **per-machine**. The repo can't ship your Google identity, so mint your own token once (~5 minutes):

1. Create your own OAuth client + token — see the **"Create your own OAuth"** section of [docs/CALENDAR.md](CALENDAR.md).
2. Add your personal agenda/birthdays:
   - Add agenda events in the shell (they sync to Google in real time).
   - Link contacts via the **contact picker** (writes birthdays to the Google Contact's birthday field via the People API).
   - Type `Birthday` events directly, or import them — the shell stores them in `~/.local/state/quickshell/user/events.json` (this file is **yours only**, never committed).
3. Run the guided installer and restart the shell:
   ```sh
   bash tools/install-calendar.sh
   systemctl --user restart inir.service
   ```

> **Birthdays always show:** yearly/`Birthday` events are matched by **month + day** (not the stored year), so a birthday appears on the right day every year even if the birth year field varies. See the *Birthday & yearly-event matching* section in [docs/CALENDAR.md](CALENDAR.md). Birthdays are also shown on the **wallpaper browser date / panel** regardless of the calendar app.

## 5. Make the visual identity yours

- **Wallpapers** — press `SUPER + W` in Hyprland to open the browser and set your own. The iNiR session gives each screen its own wallpaper from your folder (multi-monitor random).
- **Presets** — the built-in **lotus-palette** preset system saves/loads entire themes; tweak colors and save your own under a new name. See [docs/THEMES.md](THEMES.md).

## 6. Optional extras

- **GPU tuning pack** (Phase 10 / `optional/`) — overclock/undervolt fan curves, governor, sysctl. Example values ship RTX 4070-tuned; the base desktop needs nothing 4070-specific.
- **Spicetify / Discord Lotus themes** (Phase 9) — apply the matching Lotus look to Spotify and Discord.

## Keeping your data out of the repo

If you fork this repo or contribute back, remember: the repo must stay **generic**. The pieces below are personal and should never be committed:

| Personal (never commit) | Where it lives |
|---|---|
| Google OAuth token | `~/.local/share/gcalcli/oauth` |
| Your calendar/birthday events | `~/.local/state/quickshell/user/events.json`, generated `.ics` files |
| Your email / Names / contact data | Google account only |
| Machine-specific audio device names / autoload bindings | EasyEffects autoload dirs (point at your hardware) |

A CI security scan (`tools/scan-secrets.sh`) blocks pushes containing `/home/`, tokens, keys, or browser databases — run it before pushing:

```sh
bash tools/scan-secrets.sh .
```

## Related docs

- [docs/CALENDAR.md](CALENDAR.md) — Google Calendar & birthdays sync (OAuth setup, yearly-event matching)
- [docs/AUDIO.md](AUDIO.md) — EasyEffects audio stack & OBS streaming
- [docs/INSTALLATION.md](INSTALLATION.md) — full install, phases, performance
- [docs/STRUCTURE.md](STRUCTURE.md) — config tree layout
- [docs/THEMES.md](THEMES.md) — palette & preset system
