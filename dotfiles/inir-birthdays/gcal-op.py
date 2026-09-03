#!/usr/bin/env python3
"""Create / update / delete Google objects using the existing gcalcli OAuth
token. Called by inir (EventsDialog) through Process.

Non-birthday events are managed as normal events in the primary Google
Calendar. Events with category "birthday" are instead written to a Google
Contact's birthday field (People API), which is what populates Google's built-in
"Cumpleaños" calendar; the id used for these is the contact resourceName prefixed
with "people/".

Usage:
  gcal-op.py create <json>
  gcal-op.py update <google-event-id> <json>
  gcal-op.py delete <google-event-id>

JSON keys: summary, description, dateTime ("YYYY-MM-DDTHH:MM:SS" local),
recurrence ("none|daily|weekly|monthly|yearly"), category.

Prints one JSON result line to stdout:
  {"ok": true, "id": "..."}   or   {"ok": false, "error": "..."}
"""

import json
import os
import pickle
import sys

from google.auth.transport.requests import Request
from googleapiclient.discovery import build

OAUTH_FILE = os.path.expanduser("~/.local/share/gcalcli/oauth")


def _detect_timezone():
    """Resolve the local IANA timezone for calendar events.

    Priority: $INIR_TZ (per-user override) > the system's configured zone
    (readlink of /etc/localtime) > $TZ > UTC.
    """
    tz = os.environ.get("INIR_TZ")
    if tz:
        return tz
    try:
        zone = os.readlink("/etc/localtime").split("/zoneinfo/", 1)[1]
        return zone
    except Exception:
        pass
    return os.environ.get("TZ") or "UTC"


TIMEZONE = _detect_timezone()

FREQ = {
    "none": None,
    "daily": "DAILY",
    "weekly": "WEEKLY",
    "monthly": "MONTHLY",
    "yearly": "YEARLY",
}


def out(obj):
    print(json.dumps(obj, ensure_ascii=False))
    sys.stdout.flush()


def load_creds():
    with open(OAUTH_FILE, "rb") as fh:
        creds = pickle.load(fh)
    if creds.expired:
        creds.refresh(Request())
    return creds


def people_service(creds):
    """People API client; the token must hold the contacts scope."""
    from googleapiclient.discovery import build
    return build("people", "v1", credentials=creds)


def _month_day(dt):
    if not dt or len(dt) < 10:
        import datetime
        now = datetime.datetime.now()
        return now.month, now.day
    m = int(dt[5:7])
    d = int(dt[8:10])
    return m, d


def find_contact(people, name):
    """Return the resourceName of a contact whose display name matches, else None."""
    if not name:
        return None
    try:
        res = (people.people().searchContacts(
            query=name, readMask="names", pageSize=10).execute())
    except Exception:
        return None
    for person in res.get("results", []):
        p = person.get("person", {})
        for n in p.get("names", []):
            if "-".join(n.get("displayName", "").split()).lower() == name.lower():
                return p.get("resourceName")
    return None


def search_contacts(people, query, max_results=10):
    """Search contacts by name and return a list of
    {id, name, birthday, phone} (id is the people resource name)."""
    results = []
    if not query:
        return results
    try:
        res = (people.people().searchContacts(
            query=query, readMask="names,birthdays,phoneNumbers",
            pageSize=max_results).execute())
    except Exception:
        return results
    for person in res.get("results", []):
        p = person.get("person", {})
        name = (p.get("names") or [{}])[0].get("displayName", "")
        bd = (p.get("birthdays") or [{}])[0].get("date") if p.get("birthdays") else None
        bd_str = f"{bd['month']:02d}/{bd['day']:02d}" if bd else ""
        phones = p.get("phoneNumbers") or []
        phone = phones[0].get("value", "") if phones else ""
        results.append({
            "id": p.get("resourceName", ""),
            "name": name,
            "birthday": bd_str,
            "phone": phone
        })
    return results


def set_birthday(people, resource_name, month, day):
    # updateContact requires the current etag of the contact.
    person = people.people().get(
        resourceName=resource_name,
        personFields="birthdays,names",
    ).execute()
    body = {
        "etag": person.get("etag"),
        "birthdays": [{"date": {"month": month, "day": day}}],
    }
    people.people().updateContact(
        resourceName=resource_name,
        updatePersonFields="birthdays",
        body=body,
    ).execute()


def clear_birthday(people, resource_name):
    person = people.people().get(
        resourceName=resource_name,
        personFields="birthdays,names",
    ).execute()
    body = {
        "etag": person.get("etag"),
        "birthdays": [],
    }
    people.people().updateContact(
        resourceName=resource_name,
        updatePersonFields="birthdays",
        body=body,
    ).execute()


def create_contact_with_birthday(people, name, month, day):
    """Create a contact holding just the name and birthday; return resourceName."""
    person = {
        "names": [{"givenName": name}],
        "birthdays": [{"date": {"month": month, "day": day}}],
    }
    created = (people.people().createContact(body=person).execute())
    return created.get("resourceName")


def build_body(data):
    dt = data.get("dateTime") or ""
    all_day = bool(data.get("allDay"))
    summary = (data.get("summary") or "").strip()
    desc = (data.get("description") or "").strip()
    cat = data.get("category") or "general"
    prio = data.get("priority") or "normal"

    if all_day:
        start_str = dt[:10]
        y, m, d = int(start_str[:4]), int(start_str[5:7]), int(start_str[8:10])
        import datetime
        end = datetime.date(y, m, d) + datetime.timedelta(days=1)
        start = {"date": start_str}
        end = {"date": end.isoformat()}
    else:
        if not dt:
            import datetime
            dt = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        y, mo, da, hh, mi = (int(dt[0:4]), int(dt[5:7]), int(dt[8:10]),
                             int(dt[11:13]), int(dt[14:16]))
        import datetime
        start_dt = datetime.datetime(y, mo, da, hh, mi)
        end_dt = start_dt + datetime.timedelta(hours=1)
        start = {"dateTime": start_dt.isoformat(), "timeZone": TIMEZONE}
        end = {"dateTime": end_dt.isoformat(), "timeZone": TIMEZONE}

    body = {
        "summary": summary,
        "description": desc,
        "start": start,
        "end": end,
    }
    if summary == "":
        body.pop("summary", None)

    freq = FREQ.get(data.get("recurrence") or "none")
    if freq:
        body["recurrence"] = [f"RRULE:FREQ={freq}"]

    # Keep the inir category visible on the Google side too.
    if cat and cat != "general" and "#" not in desc:
        desc = (desc + f"\n[inir:{cat}]").strip()
    # Link the inir priority to the Google event as metadata.
    if prio and prio != "normal" and "[inir:priority:" not in desc:
        desc = (desc + f"\n[inir:priority:{prio}]").strip()
    if desc:
        body["description"] = desc

    # Reminder: sync the inir reminder to Google Calendar. reminderMinutes == 0
    # disables reminders entirely; otherwise use an explicit override (per-event).
    rem_min = data.get("reminderMinutes")
    try:
        rem_min = int(rem_min) if rem_min is not None else None
    except (TypeError, ValueError):
        rem_min = None
    if rem_min == 0:
        body["reminders"] = {"useDefault": False, "overrides": []}
    elif rem_min is not None and rem_min > 0:
        body["reminders"] = {
            "useDefault": False,
            "overrides": [{"method": "popup", "minutes": rem_min}],
        }

    return body


def main():
    args = sys.argv[1:]
    if not args:
        out({"ok": False, "error": "no args"})
        return 1

    op = args[0]
    try:
        creds = load_creds()

        # search <query>  — list matching Google Contacts (for the picker)
        if op == "search":
            query = args[1] if len(args) > 1 else ""
            people = people_service(creds)
            results = search_contacts(people, query)
            out({"ok": True, "results": results})
            return 0

        # A birthday op is detected by its id (people/<resource>) on delete, or
        # by the category flag in the JSON payload on create/update.
        is_birthday = False
        if op == "delete":
            is_birthday = len(args) > 1 and str(args[1]).startswith("people/")
        else:
            is_birthday = bool(args[-1]) and json.loads(args[-1]).get("category") == "birthday"

        if is_birthday:
            return run_birthday(op, creds, args)

        svc = build("calendar", "v3", credentials=creds)

        if op == "create":
            data = json.loads(args[1])
            body = build_body(data)
            ev = svc.events().insert(calendarId="primary", body=body).execute()
            out({"ok": True, "id": ev.get("id"), "htmlLink": ev.get("htmlLink")})

        elif op == "update":
            gid = args[1]
            data = json.loads(args[2])
            body = build_body(data)
            svc.events().update(calendarId="primary", eventId=gid,
                                body=body).execute()
            out({"ok": True, "id": gid})

        elif op == "delete":
            gid = args[1]
            svc.events().delete(calendarId="primary", eventId=gid).execute()
            out({"ok": True, "id": gid})

        else:
            out({"ok": False, "error": f"unknown op: {op}"})
            return 1
    except Exception as exc:  # noqa: BLE001 - report any failure to the UI
        out({"ok": False, "error": f"{type(exc).__name__}: {exc}"})
        return 1
    return 0


def run_birthday(op, creds, args):
    """Create/update/delete a Google Contact's birthday (drives the built-in
    'Cumpleaños' calendar). The id for an existing mirrored birthday is the
    contact resourceName prefixed with 'people/'."""
    people = people_service(creds)
    try:
        if op == "create":
            data = json.loads(args[1])
            name = (data.get("summary") or "").strip()
            month, day = _month_day(data.get("dateTime") or "")
            # If a specific contact ID was provided (from the picker), use it directly.
            contact_id = (data.get("contactId") or "").strip()
            if contact_id:
                resource = contact_id
                set_birthday(people, resource, month, day)
            else:
                resource = find_contact(people, name)
                if resource is None:
                    resource = create_contact_with_birthday(people, name, month, day)
                else:
                    set_birthday(people, resource, month, day)
            out({"ok": True, "id": resource})
            return 0

        if op == "update":
            gid = args[1]
            data = json.loads(args[2])
            if not gid.startswith("people/"):
                out({"ok": False, "error": f"not a contact id: {gid}"})
                return 1
            month, day = _month_day(data.get("dateTime") or "")
            set_birthday(people, gid, month, day)
            out({"ok": True, "id": gid})
            return 0

        if op == "delete":
            gid = args[1]
            if not gid.startswith("people/"):
                out({"ok": False, "error": f"not a contact id: {gid}"})
                return 1
            clear_birthday(people, gid)
            out({"ok": True, "id": gid})
            return 0

        out({"ok": False, "error": f"unknown op: {op}"})
        return 1
    except Exception as exc:  # noqa: BLE001
        out({"ok": False, "error": f"{type(exc).__name__}: {exc}"})
        return 1


if __name__ == "__main__":
    sys.exit(main())