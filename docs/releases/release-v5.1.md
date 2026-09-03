# Lotus Arch — Release Notes

## v5.1 — Google Calendar & birthdays sync for the iNiR shell

The iNiR agenda and calendar can now mirror your **Google Calendar** and your **Google Contacts' birthdays** — with a full "one step further" contact picker and de-duplicated events. Every calendar feature added so far is included in this release.

### What's in

- **Google Calendar sync.** `sync-calendars.py` pulls your Google events into the shell's agenda and pushes edits back in real time (title, dates, all-day, priority, reminders).
- **Birthdays from Google Contacts.** A **contact picker** in the event dialog links a birthday to the right contact — the contact's phone is shown to disambiguate — and people-auth (People API) writes it back to the contact's birthday field.
- **De-duplicated events.** Synced events aren't duplicated: Google VEVENTs that already exist locally are stripped (birthdays matched by People-API contact id).
- **5-minute auto-sync.** `inir-birthdays.timer` keeps the agenda fresh in the background; `gcal-op.py` is the CLI layer the shell calls for event operations.

### Your data stays yours

This is a **per-machine, opt-in** feature. The repo ships the **generic code only** — timezone is detected automatically (`INIR_TZ` overrides it) and paths use `$HOME`, `%h` and `XDG_CONFIG_HOME`:

| Ships | Never in the repo (yours only) |
|---|---|
| `dotfiles/inir-birthdays/*.py` — 3 sync scripts | your OAuth token (`~/.local/share/gcalcli/oauth`) |
| iNiR QML calendar overlay (`CalendarSync`, `Events`, widgets) | your `events.json` and generated `.ics` files |
| `systemd/user/inir-birthdays.{service,timer}` | your Google account / contact data |
| `tools/install-calendar.sh` — guided setup | — |

**You mint your own OAuth** in ~5 minutes (Google Cloud Console → enable Calendar + People APIs → create a Desktop-app OAuth client → approve with `gcalcli` → add the contacts scope with `people-auth.py`), then `bash tools/install-calendar.sh` and `systemctl --user restart inir.service`. The full tutorial with commands is in the README.

### Notes

- Requires the [Google Calendar API](https://console.cloud.google.com/apis/library/calendar-googleapis.googleapis.com) and [People API](https://console.cloud.google.com/apis/library/people.googleapis.com) enabled in your own Cloud project.
- Nothing runs until you provision the token and enable the timer — safe to clone on any machine.
