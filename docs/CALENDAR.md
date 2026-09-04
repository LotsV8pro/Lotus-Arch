# Google Calendar & Birthdays Sync (iNiR, optional)

The iNiR shell ships an **agenda + calendar** that can mirror your **Google Calendar** and your **Google Contacts' birthdays** (the built-in "Cumpleaños" calendar):

- Events created/edited in the agenda sync to Google in real time (title, dates, **all-day**, priority, **reminders**).
- A **contact picker** links birthdays to Google Contacts — the contact's phone is shown to disambiguate; birthdays are written to the Google Contact's birthday field (People API).
- Synced events are **not duplicated**: `sync-calendars.py` strips the Google VEVENTs that already exist locally (including birthdays, matched by People-API contact id).

This is a **per-machine, opt-in** feature — **none of this is automatic and nothing of yours ships in the repo**:

| Ships (generic code) | Never in the repo (yours only) |
|---|---|
| `dotfiles/inir-birthdays/*.py` — the 3 sync scripts | your OAuth token (`~/.local/share/gcalcli/oauth`) |
| `dotfiles/quickshell/inir/{services,modules}/*` — the QML calendar overlay | your `events.json` and generated `.ics` files |
| `dotfiles/systemd/user/inir-birthdays.{service,timer}` — 5-min sync timer | your Google account/contact data |
| `tools/install-calendar.sh` — guided setup | — |

## Birthday & yearly-event matching

The iNiR calendar distinguishes **three kinds of events**, and yearly recurrence is handled specially so that **birthdays and annual events always show up on the right day, every year**:

- **Exact-date events** — an event whose date falls on the date being shown.
- **Yearly-recurring events** (`recurrence === "yearly"`) — birthdays. Because the stored birth *year* may differ from the current year (e.g. a contact's birth year), a yearly event is matched by **month + day only**, not by the stored year. For each date the shell keeps at most **one** yearly event (the earliest) to avoid duplicates when both a local birthday and the synced "Cumpleaños" Google event exist for the same person.
- **Upcoming events** — `getUpcomingEvents(days)` finds the *next* occurrence of each yearly event within the lookahead window using the same month+day rule, so a birthday is reported even when its year field is stale.

> **Why young-year birthdays matter:** if a contact's birth year is newer than the current year (or the year field was written differently), matching by *full date* would silently hide the birthday. Matching by **month + day** guarantees the reminder still fires every year regardless of the stored year.

See also [SETUP.md](SETUP.md) for the end-to-end first-time setup with your own personal data.

## Create your own OAuth (one-time)

Because only **you** own your Google data, the repo can't — and won't — contain a ready-made token. Mint your own in ~5 minutes:

1. **Google Cloud Console** → [credentials](https://console.cloud.google.com/apis/credentials):
   - Create/pick a project.
   - Enable the **Google Calendar API** and the **People API**.
   - *Create credentials → OAuth client ID → Desktop app*.
   - Copy the **Client ID** and **Client Secret**.
2. **Mint the token** (calendar scope) — open a browser to approve:
   ```bash
   gcalcli --client-id '<CLIENT_ID>' --client-secret '<CLIENT_SECRET>' \
           --save-token ~/.local/share/gcalcli/oauth list
   ```
3. **Add the contacts scope** (needed to write Contact birthdays):
   ```bash
   python3 ~/.config/inir-birthdays/people-auth.py
   ```
   It re-runs the consent flow with both `calendar` + `contacts` scopes and refreshes the same token.
4. **Run the guided installer** (copies scripts + units, enables the 5-min timer):
   ```bash
   bash tools/install-calendar.sh
   ```
5. **Restart the shell** to load the calendar:
   ```bash
   systemctl --user restart inir.service
   ```

Your timezone is detected automatically (override with `INIR_TZ=...`). The sync timer runs every 5 minutes and only talks to **your** account. Nothing in this stack requires or ships your email, passwords, or tokens.
