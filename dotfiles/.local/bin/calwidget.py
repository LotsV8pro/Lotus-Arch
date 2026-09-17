#!/usr/bin/env python3
"""Backend de datos para el dashboard de calendario (sin quickshell).

Fuentes:
  - Agenda: ~/.config/inir-birthdays/*.ics (via manifest.json), igual que
    reachin waybar-agenda.py. Externo: los 3 calendarios de Google.
  - Todo: ~/.config/calwidget/todo.json
  - Notas: ~/.config/calwidget/notes.txt

Comandos (args en argv):
  agenda [days]        -> proximos eventos en JSON (lista)
  agenda-text [days]   -> texto plano para rofi/notify
  day YYYY-MM-DD       -> eventos de ese dia (JSON)
  month YYYY-MM        -> eventos del mes (JSON, para los dots del calendario)
  todo                 -> todo.json (JSON)
  todo-add <texto>     -> agrega, marca done
  todo-toggle <idx>
  todo-del <idx>
  notes                -> notas (texto)
  notes-set <texto>    -> escribe notas
"""

import json
import os
import re
import sys
from datetime import date, datetime, timedelta

OUTDIR = os.path.expanduser("~/.config/inir-birthdays")
MANIFEST = os.path.join(OUTDIR, "manifest.json")
TODO_FILE = os.path.expanduser("~/.config/calwidget/todo.json")
NOTES_FILE = os.path.expanduser("~/.config/calwidget/notes.txt")

VEVENT_RE = re.compile(r"BEGIN:VEVENT(.*?)END:VEVENT", re.S)
FIELD_RE = re.compile(r"^([A-Z0-9;\-=]+):(.+)$", re.M)


def parse_dt(value: str):
    v = value.split(";")[-1].strip()
    try:
        if "T" in v:
            return datetime.strptime(v, "%Y%m%dT%H%M%S")
        return datetime.strptime(v, "%Y%m%d")
    except ValueError:
        return None


def load_calendars():
    """Devuelve {color, name, events:[{title, start, end, allDay}]} por fuente."""
    try:
        with open(MANIFEST, encoding="utf-8") as fh:
            sources = json.load(fh)
    except (OSError, ValueError):
        return []
    result = []
    for src in sources:
        path = os.path.expanduser(src["path"])
        events = []
        try:
            with open(path, encoding="utf-8", errors="replace") as fh:
                ics = fh.read()
        except OSError:
            continue
        for blk in VEVENT_RE.findall(ics):
            fields = {}
            for line in blk.splitlines():
                m = FIELD_RE.match(line)
                if m:
                    key = m.group(1).split(";")[0]
                    fields[key] = m.group(2)
            summary = fields.get("SUMMARY", "")
            if not summary:
                continue
            start = parse_dt(fields.get("DTSTART", ""))
            if not start:
                continue
            has_t = "T" in fields.get("DTSTART", "")
            rrule = fields.get("RRULE", "")
            if "FREQ=YEARLY" in rrule and start.year < date.today().year:
                end = parse_dt(fields.get("DTEND", "")) or start
                dur = end - start
                this_year = date.today().year
                for y in (this_year - 1, this_year, this_year + 1):
                    try:
                        occ = start.replace(year=y)
                    except ValueError:
                        continue
                    events.append(
                        {
                            "title": summary,
                            "start": occ,
                            "end": occ + dur,
                            "allDay": True,
                        }
                    )
            else:
                events.append(
                    {
                        "title": summary,
                        "start": start,
                        "end": parse_dt(fields.get("DTEND", "")) or start,
                        "allDay": not has_t,
                    }
                )
        events.sort(key=lambda e: e["start"])
        result.append({"name": src["name"], "color": src.get("color", "#FFFFFF"), "events": events})
    return result


def serialize(ev, color, src):
    return {
        "title": ev["title"],
        "start": ev["start"].strftime("%Y-%m-%dT%H:%M"),
        "date": ev["start"].strftime("%Y-%m-%d"),
        "allDay": ev["allDay"],
        "color": color,
        "source": src,
    }


def all_events():
    out = []
    for cal in load_calendars():
        for ev in cal["events"]:
            out.append(serialize(ev, cal["color"], cal["name"]))
    out.sort(key=lambda e: e["start"])
    return out


def cmd_agenda(days):
    try:
        horizon = int(days)
    except (TypeError, ValueError):
        horizon = 14
    today = date.today()
    window_end = today + timedelta(days=horizon)
    out = [
        e for e in all_events()
        if date.fromisoformat(e["date"]) <= window_end
        and date.fromisoformat(e["date"]) >= today
    ]
    print(json.dumps(out, ensure_ascii=False))


def cmd_agenda_text(days):
    try:
        horizon = int(days)
    except (TypeError, ValueError):
        horizon = 14
    lines = []
    today = date.today()
    window_end = today + timedelta(days=horizon)
    for e in all_events():
        d = date.fromisoformat(e["date"])
        if d < today or d > window_end:
            continue
        label = e["title"]
        lines.append(f"{e['date']}  {label}")
    print("\n".join(lines[:40]))


def cmd_day(day_str):
    out = [e for e in all_events() if e["date"] == day_str]
    out.sort(key=lambda e: e["start"])
    print(json.dumps(out, ensure_ascii=False))


def cmd_month(month_str):
    out = [e for e in all_events() if e["date"].startswith(month_str)]
    print(json.dumps(out, ensure_ascii=False))


def cmd_grid(month_str):
    """Retícula del mes para rofi (columns=7): `Lun Mar Mié Jue Vie Sáb Dom`
    seguido por filas de días espaciados. Días con evento llevan * y el día de
    hoy un + como sufijo. Devuelve las celdas (rofi las coloca column-wise)."""
    try:
        y, m = map(int, month_str.split("-"))
    except ValueError:
        y, m = date.today().year, date.today().month
    first = date(y, m, 1)
    import calendar as _cal
    dim = _cal.monthrange(y, m)[1]
    days_with = set()
    try:
        for e in all_events():
            if e["date"].startswith(f"{y:04d}-{m:02d}"):
                days_with.add(int(e["date"][8:10]))
    except Exception:
        pass
    today = date.today()
    wd = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
    cells = list(wd)
    for d in range(first.isoweekday() - 1):
        cells.append("·"*3)
    for d in range(1, dim + 1):
        s = f"{d:02d}"
        if today.year == y and today.month == m and today.day == d:
            s += "+"
        elif d in days_with:
            s += "*"
        else:
            s += " "
        cells.append(s)
    print("\n".join(cells))


def _load_todo():
    try:
        with open(TODO_FILE, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return []


def _save_todo(items):
    with open(TODO_FILE, "w", encoding="utf-8") as fh:
        json.dump(items, fh, ensure_ascii=False, indent=2)


def cmd_todo():
    print(json.dumps(_load_todo(), ensure_ascii=False))


def cmd_todo_add(text):
    items = _load_todo()
    items.append({"content": text, "done": False})
    _save_todo(items)
    print("ok")


def cmd_todo_toggle(idx):
    items = _load_todo()
    if 0 <= idx < len(items):
        items[idx]["done"] = not items[idx]["done"]
        _save_todo(items)
    print("ok")


def cmd_todo_del(idx):
    items = _load_todo()
    if 0 <= idx < len(items):
        items.pop(idx)
        _save_todo(items)
    print("ok")


def cmd_notes():
    try:
        with open(NOTES_FILE, encoding="utf-8") as fh:
            print(fh.read(), end="")
    except OSError:
        print("")


def cmd_notes_set(text):
    if not sys.stdin.isatty():
        text = sys.stdin.read()
    with open(NOTES_FILE, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("ok")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "agenda"
    arg = sys.argv[2] if len(sys.argv) > 2 else None
    HANDLERS = {
        "agenda": lambda: cmd_agenda(arg),
        "agenda-text": lambda: cmd_agenda_text(arg),
        "day": lambda: cmd_day(arg or date.today().isoformat()),
        "month": lambda: cmd_month(arg or date.today().strftime("%Y-%m")),
        "grid": lambda: cmd_grid(arg or date.today().strftime("%Y-%m")),
        "todo": cmd_todo,
        "todo-add": lambda: cmd_todo_add(arg or ""),
        "todo-toggle": lambda: cmd_todo_toggle(int(arg) if arg and arg.isdigit() else 0),
        "todo-del": lambda: cmd_todo_del(int(arg) if arg and arg.isdigit() else 0),
        "notes": cmd_notes,
        "notes-set": lambda: cmd_notes_set(arg or ""),
    }
    HANDLERS.get(cmd, cmd_agenda)()