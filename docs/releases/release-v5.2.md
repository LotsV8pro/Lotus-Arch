# Lotus Arch — Release Notes

## v5.2 — Arctis removal, birthday sync overhaul & history purge

This release removes the Arctis Sound Manager integration, overhauls how
birthdays are handled (they now live in **Google Contacts**, not local
events), fixes a calendar-sync bug, and purges personal data from the git
history.

### What's in

- **Arctis Sound Manager dropped.** Removed from the install and config;
  audio control is handled by **EasyEffects + PipeWire only**, which were
  already in place.
- **Birthdays now come from Google Contacts.** New birthdays created in the
  shell's event dialog write to a **Google Contact's birthday field** (People
  API) instead of a local event. Google's built-in "Cumpleaños" calendar then
  feeds the shell through the sync pipeline — no local event duplication, and
  the contact's real name is shown.
- **Named birthdays.** `"<Name> Birthday"` titles and an optional Google
  Contacts picker (with phone disambiguation) instead of a bare "Birthday".
- **Sync fix.** `sync-calendars.py` no longer strips valid contact-birthday
  events — a VEVENT-boundary regex regression was fixed so every contact's
  birthday survives the dedup pass.
- **External sync config shipped.** `config.json` now enables `externalSync`
  with the three calendar sources wired to the shell's agenda.
- **Personal-data purge.** Rewrote history to remove machine-specific home
  paths (replaced with a portable `@HOME@` sentinel), plus the OBS WebSocket
  password, TMDB API key, and Spotify autologin credential files. `scan-secrets.sh`
  still catches `/home/lots` if it ever re-appears.

### Notes

- The git history is intentionally rewritten for this release (force-push).
  On a fresh clone, the repo no longer contains any personal paths or
  credential placeholders — configs use `@HOME@`, expanded to your home at
  install time.
- Birthdays require the People API scope in your own OAuth token; the sync
  setup is unchanged from v5.1.