#!/usr/bin/env python3
"""Próximos eventos de Google Calendar (ICS sincronizados a
~/.config/inir-birthdays/*.ics) como módulo custom de waybar.

Emite JSON: {"text": "...", "tooltip": "..."}. Reutiliza el sync
inir-birthdays.service para que los ICS estén frescos.
"""

import json
import os
import re
import sys
from datetime import date, datetime, timedelta

OUTDIR = os.path.expanduser("~/.config/inir-birthdays")
MANIFEST = os.path.join(OUTDIR, "manifest.json")

VEVENT_RE = re.compile(
    r"BEGIN:VEVENT(.*?)END:VEVENT", re.S
)
FIELD_RE = re.compile(r"^([A-Z0-9;=\-]+):(.+)$", re.M)


def parse_date(value: str) -> date | None:
    v = value.split(";")[-1]
    v = v.strip()
    try:
        if "T" in v:
            return datetime.strptime(v.split("T")[0], "%Y%m%d").date()
        return datetime.strptime(v, "%Y%m%d").date()
    except ValueError:
        return None


def yearly_occurrence(start: date, target: date) -> date | None:
    """Próxima ocurrencia de un evento anual para el año objetivo."""
    try:
        return start.replace(year=target.year)
    except ValueError:
        return None


def load_events(horizon: int) -> list[dict]:
    try:
        with open(MANIFEST, encoding="utf-8") as fh:
            sources = json.load(fh)
    except (OSError, ValueError):
        return []

    today = date.today()
    window_end = today + timedelta(days=horizon)
    events = []

    for src in sources:
        path = os.path.expanduser(src["path"])
        color = src.get("color", "#FFFFFF")
        try:
            with open(path, encoding="utf-8", errors="replace") as fh:
                ics = fh.read()
        except OSError:
            continue

        for block in VEVENT_RE.findall(ics):
            raw = dict(
                (m.group(1), m.group(2))
                for m in FIELD_RE.finditer(block)
            )
            summary = ""
            start = None
            for key, val in raw.items():
                base = key.split(";")[0]
                if base == "SUMMARY" and not summary:
                    summary = val.strip()
                elif base == "DTSTART" and start is None:
                    # p.ej. DTSTART;VALUE=DATE / DTSTART;TZID=Europe/Madrid
                    start = parse_date(val.split(";")[-1])
            if not start or not summary:
                continue
            if "RRULE" in raw:
                # Evento recurrente (p.ej. anual): próxima ocurrencia >= hoy
                cand = yearly_occurrence(start, today)
                if cand is None or cand < today:
                    cand = yearly_occurrence(start, today.replace(year=today.year + 1))
                start = cand
            elif start < today:
                # Evento puntual ya pasado
                continue
            if not start:
                continue
            if start > window_end:
                continue
            events.append(
                {
                    "date": start,
                    "title": summary,
                    "color": color,
                    "source": src.get("name", ""),
                }
            )

    events.sort(key=lambda e: e["date"])
    return events


def main() -> int:
    today = date.today()
    notify = "--notify" in sys.argv
    horizon = 30 if notify else int(os.environ.get("AGENDA_HORIZON", "3"))
    events = load_events(horizon)

    lines = []
    for e in events:
        if e["date"] == today:
            head = "Hoy"
        else:
            head = e["date"].strftime("%a %d %b")
        lines.append(
            f"<span color='{e['color']}'>●</span> {head} · {e['title']}"
        )
    tooltip = "\n".join(lines) if lines else "Sin eventos próximos"

    if notify:
        _notify(tooltip)
        return 0

    today_events = [e for e in events if e["date"] == today]
    text = f"📅 {len(today_events)}" if today_events else "📅"
    print(json.dumps({"text": text, "tooltip": tooltip}))
    return 0


def _notify(tooltip: str) -> None:
    """Muestra la agenda completa como notificación del sistema."""
    import re
    import subprocess

    clean = re.sub(r"<span[^>]*>|</span>", "", tooltip).replace("●●", "●")
    subprocess.run(
        ["notify-send", "-a", "Agenda", "-t", "10000", "Próximos eventos", clean],
        check=False,
    )


if __name__ == "__main__":
    sys.exit(main())