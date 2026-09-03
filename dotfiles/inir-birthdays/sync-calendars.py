#!/usr/bin/env python3
"""Syncs every Google Calendar + the Contacts Birthdays calendar to local ICS
files that inir's CalendarSync reads via file:// URLs. Uses the CalDAV
endpoint with the existing gcalcli OAuth token. Never leaves a broken file:
on failure the previous good copy is kept."""

import json
import os
import pickle
import re
import sys
import tempfile
import time
import urllib.parse

import requests
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

OUTDIR = os.path.expanduser("~/.config/inir-birthdays")
OAUTH_FILE = os.path.expanduser("~/.local/share/gcalcli/oauth")
MANIFEST = os.path.join(OUTDIR, "manifest.json")

CONTACTS_ID = "#contacts@group.v.calendar.google.com"
CONTACTS_TITLE = "Cumpleaños (Contactos)"
SELF_UID_RE = re.compile(
    r"BEGIN:VEVENT.*?UID:[^\n]*BIRTHDAY_self@google\.com[^\n]*.*?END:VEVENT",
    re.S,
)

LOCAL_EVENTS_FILE = os.path.expanduser(
    "~/.local/state/quickshell/user/events.json"
)


def load_google_synced_ids():
    """Return the set of googleEventIds that exist as local inir events.

    Those events were created from the agenda and mirrors exist in Google;
    strip their VEVENTs from the downloaded ICS so they don't appear twice.
    """
    try:
        with open(LOCAL_EVENTS_FILE, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError):
        return set()
    gids = {
        ev.get("googleEventId")
        for ev in (data.get("events") or [])
        if ev.get("googleEventId")
    }
    return {g for g in gids if g}


def birthday_uid_suffixes(creds, gids):
    """Return the contact source-ids appearing in "Cumpleaños" ICS UIDs.

    A local event pushed to Google as a contact birthday has googleEventId
    people/<resource>. The Google "Cumpleaños" calendar VEVENT for that contact
    uses UID '<year>_BIRTHDAY_<sourceid>@google.com' where <sourceid> is the
    People API birthday metadata source id. Those external VEVENTs must be
    stripped too, otherwise a locally-created birthday shows twice (local +
    external). We derive <sourceid> from each local people/<resource> contact.
    """
    if not gids:
        return set()
    people = build("people", "v1", credentials=creds)
    suffixes = set()
    for gid in gids:
        if not str(gid).startswith("people/"):
            continue
        try:
            person = people.people().get(
                resourceName=gid, personFields="birthdays"
            ).execute()
        except Exception:
            continue
        for bd in person.get("birthdays") or []:
            src = (bd.get("metadata") or {}).get("source") or {}
            sid = src.get("id")
            if sid:
                suffixes.add(sid)
    return suffixes


def strip_vevents_by_uid(ics, gids, birthday_suffixes=None):
    """Remove VEVENT components whose UID matches any google event id.

    Google's CalDAV export uses `UID:<id>@google.com`, so match that prefix.
    birthday_suffixes additionally removes 'Cumpleaños' birthdays by their
    contact source id (UID '..._BIRTHDAY_<sourceid>@google.com').
    """
    if not gids and not birthday_suffixes:
        return ics
    needed = {g for g in gids}
    suffixes = birthday_suffixes or set()
    parts = re.split(r"(?=BEGIN:VEVENT)", ics)
    kept = []
    for part in parts:
        if not part.startswith("BEGIN:VEVENT"):
            kept.append(part)
            continue
        uid_match = re.search(r"UID:([^\r\n;]+)", part)
        if uid_match:
            uid = uid_match.group(1).strip()
            base = uid.split("@", 1)[0]
            if uid in needed or base in needed:
                continue
            if suffixes and any(base.endswith(f"_BIRTHDAY_{s}") for s in suffixes):
                continue
        kept.append(part)
    return "".join(kept)

PRESET_COLORS = [
    "#4285F4", "#EA4335", "#34A853", "#FBBC05", "#FF6D01", "#46BDC6",
    "#7986CB", "#E67C73", "#F6BF26", "#33B679", "#8E24AA", "#D81B60",
]


def load_creds():
    with open(OAUTH_FILE, "rb") as fh:
        creds = pickle.load(fh)
    if creds.expired:
        creds.refresh(Request())
    return creds


def caldav_events(creds, cal_id):
    cid = urllib.parse.quote(cal_id, safe="")
    url = f"https://apidata.googleusercontent.com/caldav/v2/{cid}/events"
    last_err = None
    for attempt in range(3):
        try:
            req = requests.get(
                url,
                headers={"Authorization": f"Bearer {creds.token}"},
                timeout=(10, 30),
            )
        except requests.RequestException as exc:
            last_err = exc
            time.sleep(2 * (attempt + 1))
            continue
        if req.status_code != 200 or "BEGIN:VCALENDAR" not in req.text:
            return None
        return req.text
    print(f"error: {last_err}")
    return None


def slugify(title):
    s = re.sub(r"[^A-Za-z0-9]+", "-", title).strip("-").lower()
    return s[:24] or "cal"


def write_atomic(path, text):
    os.makedirs(OUTDIR, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", dir=OUTDIR, delete=False, encoding="utf-8"
    ) as tmp:
        tmp.write(text)
        tmp_path = tmp.name
    os.replace(tmp_path, path)


def reconcile_removed_birthdays(creds):
    """Drop local birthday events whose Google mirror (People API contact
    birthday) no longer exists.

    Local events pushed to Google as a contact birthday carry
    googleEventId "people/<resource>". If that contact's birthday was cleared
    (deleted from Google), the mirror is gone, so the stale local copy must be
    removed too - otherwise it lingers forever in events.json.
    """
    try:
        with open(LOCAL_EVENTS_FILE, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError):
        return
    events = data.get("events") or []
    pending = [
        ev for ev in events
        if (ev.get("googleEventId") or "").startswith("people/")
    ]
    if not pending:
        return
    people = build("people", "v1", credentials=creds)
    removed = 0
    for ev in pending:
        rid = ev["googleEventId"]
        try:
            person = people.people().get(
                resourceName=rid, personFields="birthdays"
            ).execute()
        except Exception:
            # Resource gone entirely - treat as removed.
            person = {}
        if person.get("birthdays"):
            continue
        events = [e for e in events if e.get("googleEventId") != rid]
        removed += 1
        print(f"reconcile: removed local event id={ev.get('id')} ({rid})")
    if removed:
        data["events"] = events
        write_atomic(LOCAL_EVENTS_FILE, json.dumps(data, indent=2, ensure_ascii=False))
        print(f"reconcile: {removed} stale local birthday(s) removed")


def main():
    creds = load_creds()
    reconcile_removed_birthdays(creds)
    svc = build("calendar", "v3", credentials=creds)
    items = svc.calendarList().list(maxResults=250).execute().get("items", [])

    calendars = [(cal.get("summary") or cal["id"], cal["id"]) for cal in items]
    if not any(cid == CONTACTS_ID for _, cid in calendars):
        calendars.append((CONTACTS_TITLE, CONTACTS_ID))

    manifest = []
    synced_ids = load_google_synced_ids()
    birthday_suffixes = birthday_uid_suffixes(creds, synced_ids)
    for i, (title, cid) in enumerate(calendars):
        ics = caldav_events(creds, cid)
        if ics is None:
            print(f"skip {title}: fetch failed")
            continue
        if cid == CONTACTS_ID:
            ics = SELF_UID_RE.sub("", ics)
        ics = strip_vevents_by_uid(ics, synced_ids, birthday_suffixes)
        path = os.path.join(OUTDIR, f"{i:02d}-{slugify(title)}.ics")
        write_atomic(path, ics)
        manifest.append({
            "name": title,
            "path": path,
            "color": PRESET_COLORS[len(manifest) % len(PRESET_COLORS)],
        })
        print(f"ok {title} ({len(ics)} bytes) -> {os.path.basename(path)}")

    write_atomic(MANIFEST, json.dumps(manifest, indent=2, ensure_ascii=False))
    print(f"manifest: {len(manifest)} calendars")


if __name__ == "__main__":
    sys.exit(main())