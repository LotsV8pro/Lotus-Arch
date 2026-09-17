#!/usr/bin/env python3
"""Dashboard moderno en GTK3 + gtk-layer-shell (reemplazo del de quickshell).

Estética sincronizada con el theme (haku_theme: accent #F9B2D7, fondo
rgba(0,0,0,0.85), bordes 20-24px, Noto Sans Gothic). Overlay layer-shell
anclado arriba, con 3 columnas:

  izquierda:  Agenda (próximos eventos)
  centro:     Calendario mensual + día seleccionado
  derecha:    To-Do y Notas

Integración con el backend (~/.local/bin/calwidget.py) y Google
(gcal-op.py / sync-calendars.py).

Abrir/cerrar: la primera instancia abre; si ya hay una, la cierra (toggle
desde keybind). ESC o el botón ✕ cierran.
"""

import json
import os
import re
import signal
import subprocess
import sys
from datetime import date, datetime
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("GtkLayerShell", "0.1")

from gi.repository import Gdk, GdkPixbuf, Gio, GLib, Gtk, GtkLayerShell, Pango

HOME = Path.home()
PIPE_BIN = HOME / ".local/bin/calwidget.py"
GCAL_OP = HOME / ".config/inir-birthdays/gcal-op.py"
SYNC_CALENDARS = HOME / ".config/inir-birthdays/sync-calendars.py"
THEME_DIR = HOME / ".local/state/haku_theme"
PID_FILE = HOME / ".cache/haku_dash.pid"

ACCENT = "#F9B2D7"
WEEKDAYS = ["LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB", "DOM"]
MONTHS = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
          "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]

CSS = """
* { font-family: "Noto Sans Gothic"; font-size: 14px; }
.dash-bg { background: transparent; }
.card { background: rgba(255,255,255,0.045); border: 1px solid rgba(255,255,255,0.07);
        border-radius: 18px; }
.card-title { color: #e8e8ee; font-weight: bold; font-size: 15px; }
.card-title-acc { color: %(accent)s; font-weight: bold; font-size: 15px; }
.card-sub { color: rgba(255,255,255,0.45); font-size: 12px; }
.text { color: #dedee4; }
.gray { color: rgba(255,255,255,0.5); }
.accent { color: %(accent)s; }
.today { color: %(accent)s; font-weight: bold; }
.hdr-date { color: #f2f2f7; font-weight: bold; font-size: 22px; }
.hdr-sub  { color: rgba(255,255,255,0.55); font-size: 13px; }
.icon-btn { background: rgba(255,255,255,0.07); border-radius: 12px; color: #e8e8ee; }
.icon-btn:hover { background: rgba(255,255,255,0.14); }
.primary { background: %(accent)s; color: #141416; border-radius: 12px; font-weight: bold; }
.primary:hover { background: #ffc3e2; }
.cal-day { color: #e6e6ee; border-radius: 10px; padding: 0; margin: 1px; min-width: 46px; min-height: 40px; }
.cal-day:hover { background: rgba(255,255,255,0.10); }
.cal-day:active { background: rgba(255,255,255,0.16); }
.cal-day-sel { background: rgba(249,178,215,0.22); border: 1px solid %(accent)s; }
.cal-day-today { color: %(accent)s; font-weight: bold; }
.cal-day-sel.cal-day-today { background: %(accent)s; color: #141416; }
.cal-dow { color: rgba(255,255,255,0.4); font-size: 11px; font-weight: bold; }
.nav-btn { background: transparent; color: #d0d0d8; border-radius: 10px; font-size: 18px; }
.nav-btn:hover { background: rgba(255,255,255,0.10); }
.agenda-row { border-radius: 12px; padding: 6px 10px; }
.scroll { background: transparent; }
.view { background: rgba(255,255,255,0.04); border-radius: 14px; }
.view text { color: #e6e6ee; }
.todo-done { color: rgba(255,255,255,0.35); text-decoration: line-through; }
.entry { background: rgba(255,255,255,0.06); border-radius: 12px; color: #e6e6ee; }
.sep { background: rgba(255,255,255,0.07); }
.tag-dot { color: %(accent)s; }
.badge { background: %(accent)s; color: #141416; border-radius: 999px; font-weight: bold; }
.todo-notebook { background: transparent; }
.todo-notebook header { background: transparent; }
.todo-notebook tab { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.6);
                     border-radius: 10px; padding: 4px 14px; margin: 0 3px; font-weight: bold; }
.todo-notebook tab:checked { background: %(accent)s; color: #141416; }
.dlg-scrim { background: rgba(0,0,0,0.55); }
.dlg-card { background: rgba(22,22,26,0.98); border: 1px solid rgba(255,255,255,0.12);
            border-radius: 20px; padding: 20px; }
.dlg-card .entry { border: 1px solid rgba(255,255,255,0.08); }
.dlg-lbl { color: rgba(255,255,255,0.5); font-size: 12px; }
.dlg-title { color: %(accent)s; font-weight: bold; font-size: 17px; }
.dlg-search { background: rgba(249,178,215,0.15); color: %(accent)s; border-radius: 10px;
              font-weight: bold; }
.dlg-search:hover { background: rgba(249,178,215,0.28); }
.small-hint { color: rgba(255,255,255,0.4); font-size: 11px; }
"""


def run(args, input_data=None):
    try:
        p = subprocess.run(
            [str(a) for a in args],
            input=input_data, text=True, capture_output=True, timeout=30)
        return p.stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def backend(args):
    return run([PIPE_BIN, *args])


def backend_json(args):
    try:
        return json.loads(backend(args) or "null")
    except ValueError:
        return None


class Dashboard(Gtk.Window):
    STATE = {"month": 0, "year": 0, "sel": None, "events": [], "todos": []}

    def __init__(self):
        super().__init__(title="Haku Dashboard")
        self.set_position(Gtk.WindowPosition.NONE)
        self.set_decorated(False)
        self.set_type_hint(Gdk.WindowTypeHint.UTILITY)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_resizable(False)
        self.set_size_request(1480, 780)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.set_app_paintable(True)
        self.connect("draw", self._draw_round_bg)

        # Layer-shell: es CLAVE setear el monitor (ninguno es primary en 2 monitores).
        GtkLayerShell.init_for_window(self)
        mon = self._pick_monitor()
        if mon:
            GtkLayerShell.set_monitor(self, mon)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        # Zona exclusiva desactivada (-1): así el panel flota por ENCIMA de las
        # ventanas sin reservar espacio ni reorganizarlas en niri.
        GtkLayerShell.set_exclusive_zone(self, -1)
        # Solo anchor TOP: con LEFT/RIGHT el compositor encogía la ventana a 76x18.
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 24)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)

        t0 = date.today()
        self.STATE["year"], self.STATE["month"] = t0.year, t0.month
        self.STATE["sel"] = t0

        self._build_css()
        self._build_ui()
        self.connect("key-press-event", self._on_key)
        self.show_all()
        self.refresh()

    def _pick_monitor(self):
        """Monitor destino del panel.

        Prioridad:
          1. $HAKU_DASH_MONITOR (índice) si se indica.
          2. Monitor bajo el puntero (el panel aparece donde está el cursor).
          3. El primero disponible.
        """
        d = self.get_screen().get_display()
        n = d.get_n_monitors()
        if n == 0:
            return None
        env = os.environ.get("HAKU_DASH_MONITOR")
        if env:
            try:
                i = int(env)
                if 0 <= i < n:
                    return d.get_monitor(i)
            except (TypeError, ValueError):
                pass
        try:
            mon = d.get_default_seat().get_pointer_monitor()
            if mon:
                return mon
        except Exception:
            pass
        return d.get_monitor(0)

    def _draw_round_bg(self, w, cr):
        """Pinta el fondo ARGB con esquinas verdaderamente redondeadas.

        El CSS border-radius en GTK3 recorta la caja del widget hijo, pero la
        ventana (surface layer-shell) sigue siendo un rectángulo opaco. Aquí se
        pinta un camino redondeado con el fondo del panel y el resto queda
        transparente, para que las esquinas recorten de verdad.
        """
        import math
        w_ = w.get_allocated_width()
        h_ = w.get_allocated_height()
        r = 24.0
        if w_ <= 0 or h_ <= 0:
            return False
        cr.save()
        cr.new_path()
        cr.arc(r, r, r, math.pi, 1.5 * math.pi)
        cr.arc(w_ - r, r, r, 1.5 * math.pi, 2 * math.pi)
        cr.arc(w_ - r, h_ - r, r, 0, 0.5 * math.pi)
        cr.arc(r, h_ - r, r, 0.5 * math.pi, math.pi)
        cr.close_path()
        # rgba(8,8,10,0.92)  (mismo que .dash-bg)
        cr.set_source_rgba(0.031, 0.031, 0.039, 0.92)
        cr.fill()
        # rgba(255,255,255,0.09) — borde 1 px
        cr.new_path()
        cr.arc(r, r, r, math.pi, 1.5 * math.pi)
        cr.arc(w_ - r, r, r, 1.5 * math.pi, 2 * math.pi)
        cr.arc(w_ - r, h_ - r, r, 0, 0.5 * math.pi)
        cr.arc(r, h_ - r, r, 0.5 * math.pi, math.pi)
        cr.close_path()
        cr.set_source_rgba(1.0, 1.0, 1.0, 0.09)
        cr.set_line_width(1.0)
        cr.stroke()
        cr.restore()
        return False

    def _build_css(self):
        accent = ACCENT
        try:
            txt = (THEME_DIR / "colors.css").read_text()
            m = re.search(r"accent_color\s+#([0-9a-fA-F]{6})", txt)
            if m:
                accent = "#" + m.group(1)
        except OSError:
            pass
        self.ACCENT = accent
        self.css = Gtk.CssProvider.new()
        self.css.load_from_data(bytes(CSS % {"accent": accent}, "utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), self.css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def _build_ui(self):
        self.root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.root.get_style_context().add_class("dash-bg")
        self.add(self.root)

        self.overlay = Gtk.Overlay()
        self.overlay.set_hexpand(True)
        self.overlay.set_vexpand(True)
        self.root.pack_start(self.overlay, True, True, 0)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        vbox.set_margin_top(6); vbox.set_margin_bottom(6)
        vbox.set_margin_left(14); vbox.set_margin_right(14)
        self.overlay.add(vbox)

        self._build_header(vbox)

        columns = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        vbox.pack_start(columns, True, True, 0)

        self._build_agenda_col(columns)      # izquierda
        self._build_calendar_col(columns)    # centro
        self._build_notes_col(columns)       # derecha

        self._build_dialog_overlay()

    def _build_dialog_overlay(self):
        """Diálogo de evento como OVERLAY dentro del propio surface.

        Un Gtk.Dialog normal queda oculto a pesar de transient_for: vive en una
        ventana xdg-toplevel separada, y niri lo coloca detrás de la surface
        layer-shell / el juego fullscreen. Embebido aquí NO puede quedar oculto.
        """
        self._dlg_scrim = Gtk.EventBox()
        self._dlg_scrim.get_style_context().add_class("dlg-scrim")
        self._dlg_scrim.set_hexpand(True)
        self._dlg_scrim.set_vexpand(True)
        self._dlg_scrim.set_halign(Gtk.Align.FILL)
        self._dlg_scrim.set_valign(Gtk.Align.FILL)
        self._dlg_scrim.connect("button-press-event", self._close_event_dialog)
        self.overlay.add_overlay(self._dlg_scrim)

        self._dlg_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self._dlg_card.get_style_context().add_class("dlg-card")
        self._dlg_card.set_size_request(460, -1)
        self._dlg_card.set_halign(Gtk.Align.CENTER)
        self._dlg_card.set_valign(Gtk.Align.CENTER)
        self._dlg_scrim.add(self._dlg_card)
        # Los clicks dentro de la tarjeta NO deben cerrar el diálogo.
        self._dlg_card.connect("button-press-event", lambda w, e: True)

        self._dlg_card.set_no_show_all(True)
        self._dlg_scrim.set_no_show_all(True)

    def _card(self, title):
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        card.get_style_context().add_class("card")
        card.set_margin_top(10); card.set_margin_bottom(10)
        card.set_margin_left(10); card.set_margin_right(10)
        lbl = Gtk.Label(label=title)
        lbl.get_style_context().add_class("card-title-acc")
        lbl.set_halign(Gtk.Align.START)
        card.pack_start(lbl, False, False, 0)
        card._title_lbl = lbl
        return card

    def _header_action(self, label, handler, cls="icon-btn"):
        b = Gtk.Button(label=label)
        b.get_style_context().add_class(cls)
        b.set_halign(Gtk.Align.CENTER)
        b.set_valign(Gtk.Align.CENTER)
        b.set_relief(Gtk.ReliefStyle.NONE)
        b.connect("clicked", handler)
        return b

    def _build_header(self, vbox):
        h = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        h.set_margin_top(6); h.set_margin_bottom(6)
        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.hdr_date = Gtk.Label(label="")
        self.hdr_date.get_style_context().add_class("hdr-date")
        self.hdr_date.set_halign(Gtk.Align.START)
        self.hdr_sub = Gtk.Label(label="")
        self.hdr_sub.get_style_context().add_class("hdr-sub")
        self.hdr_sub.set_halign(Gtk.Align.START)
        left.pack_start(self.hdr_date, False, False, 0)
        left.pack_start(self.hdr_sub, False, False, 0)
        h.pack_start(left, False, False, 0)

        h.pack_start(Gtk.Label(label=""), True, True, 0)

        self.sync_btn = self._header_action("⟳", self._do_sync, "primary")
        self.sync_btn.set_label("⟳  Sincronizar")
        h.pack_start(self.sync_btn, False, False, 0)

        new_btn = self._header_action("＋  Evento", self._open_event_dialog, "icon-btn")
        h.pack_start(new_btn, False, False, 0)

        close_btn = self._header_action("✕", self._quit, "icon-btn")
        h.pack_start(close_btn, False, False, 0)

        self.hdr_status = Gtk.Label(label="")
        self.hdr_status.get_style_context().add_class("hdr-sub")
        h.pack_start(self.hdr_status, False, False, 0)

        vbox.pack_start(h, False, False, 0)
        sep = Gtk.Separator()
        sep.get_style_context().add_class("sep")
        vbox.pack_start(sep, False, False, 0)

    def _build_agenda_col(self, columns):
        col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        col.set_size_request(360, -1)
        card = self._card("AGENDA")
        card._title_lbl.get_style_context().add_class("card-title-acc")
        self.agenda_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        sc = Gtk.ScrolledWindow()
        sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sc.get_style_context().add_class("scroll")
        sc.add(self.agenda_box)
        card.pack_start(sc, True, True, 0)
        col.pack_start(card, True, True, 0)
        columns.pack_start(col, False, False, 0)

    def _build_calendar_col(self, columns):
        col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        card = self._card("CALENDARIO")
        self.cal_grid = Gtk.Grid()
        self.cal_grid.set_column_homogeneous(True)
        self.cal_grid.set_row_homogeneous(True)
        self.cal_grid.set_column_spacing(3)
        self.cal_grid.set_row_spacing(3)
        card.pack_start(self.cal_grid, True, True, 0)

        nav = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        prev = self._header_action("‹", self._cal_prev, "nav-btn")
        self.cal_title = Gtk.Label(label="")
        self.cal_title.get_style_context().add_class("card-title")
        nxt = self._header_action("›", self._cal_next, "nav-btn")
        nav.pack_start(prev, False, False, 0)
        nav.pack_start(self.cal_title, True, True, 0)
        nav.pack_start(nxt, False, False, 0)
        card.pack_start(nav, False, False, 0)

        self.day_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.day_box.set_margin_top(6)
        sc = Gtk.ScrolledWindow()
        sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sc.get_style_context().add_class("scroll")
        sc.set_size_request(-1, 150)
        sc.add(self.day_box)
        card.pack_start(sc, True, True, 0)

        col.pack_start(card, True, True, 0)
        columns.pack_start(col, True, True, 0)

    def _build_notes_col(self, columns):
        col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        col.set_size_request(360, -1)

        # To-Do — 2 pestañas: Pendientes / Completados
        todo_card = self._card("TO-DO")
        self.todo_notebook = Gtk.Notebook()
        self.todo_notebook.set_show_border(False)
        self.todo_notebook.set_tab_pos(Gtk.PositionType.TOP)
        self.todo_notebook.get_style_context().add_class("todo-notebook")

        self.todo_pending_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        self.todo_done_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        self.todo_sc = Gtk.ScrolledWindow()
        self.todo_sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.todo_sc.get_style_context().add_class("scroll")
        self.todo_sc.set_size_request(-1, 220)

        pending_sc = Gtk.ScrolledWindow()
        pending_sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        pending_sc.get_style_context().add_class("scroll")
        pending_sc.add(self.todo_pending_box)
        done_sc = Gtk.ScrolledWindow()
        done_sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        done_sc.get_style_context().add_class("scroll")
        done_sc.add(self.todo_done_box)
        self.todo_sc.add(self.todo_notebook)
        self.todo_notebook.append_page(pending_sc, self._lbl("Pendientes", "card-sub"))
        self.todo_notebook.append_page(done_sc, self._lbl("Completados", "card-sub"))
        todo_card.pack_start(self.todo_sc, True, True, 0)

        ent_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.todo_entry = Gtk.Entry()
        self.todo_entry.get_style_context().add_class("entry")
        self.todo_entry.set_placeholder_text("Añadir tarea…")
        self.todo_entry.connect("activate", self._todo_add)
        add_btn = self._header_action("＋", self._todo_add, "icon-btn")
        ent_row.pack_start(self.todo_entry, True, True, 0)
        ent_row.pack_start(add_btn, False, False, 0)
        todo_card.pack_start(ent_row, False, False, 0)
        col.pack_start(todo_card, True, True, 0)

        # Notas
        notes_card = self._card("NOTAS")
        self.notes_view = Gtk.TextView()
        self.notes_view.get_style_context().add_class("view")
        self.notes_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.notes_buf = self.notes_view.get_buffer()
        notes_sc = Gtk.ScrolledWindow()
        notes_sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        notes_sc.get_style_context().add_class("scroll")
        notes_sc.add(self.notes_view)
        notes_card.pack_start(notes_sc, True, True, 0)

        save_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        save_btn = self._header_action("💾 Guardar", self._notes_save, "primary")
        save_row.pack_start(Gtk.Label(label=""), True, True, 0)
        save_row.pack_start(save_btn, False, False, 0)
        notes_card.pack_start(save_row, False, False, 0)
        col.pack_start(notes_card, True, True, 0)

        columns.pack_start(col, False, False, 0)

    # ────────────── tema / maquetación helpers ──────────────
    def _lbl(self, text, cls="text"):
        l = Gtk.Label(label=text)
        l.get_style_context().add_class(cls)
        l.set_halign(Gtk.Align.START)
        return l

    # ────────────── datos ──────────────
    def refresh(self):
        self._set_hdr_date()
        self._render_calendar()
        self._render_agenda()
        self._render_todo()
        self._render_notes()
        self._render_day()

    def _set_hdr_date(self):
        now = datetime.now()
        days = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
        self.hdr_date.set_text(f"{days[now.weekday()]}, {now.day} {MONTHS[now.month-1]}")
        self.hdr_sub.set_text(f"{now.strftime('%H:%M')}  ·  {now.year}")

    # ────────────── agenda ──────────────
    def _render_agenda(self):
        for c in self.agenda_box.get_children():
            c.destroy()
        events = backend_json(["agenda", "21"]) or []
        if not events:
            self.agenda_box.pack_start(self._lbl("Sin eventos próximos", "gray"), False, False, 0)
            self.agenda_box.show_all()
            return
        day_groups = {}
        for e in events:
            day_groups.setdefault(e["date"], []).append(e)
        today = date.today()
        for d, evs in sorted(day_groups.items()):
            ds = date.fromisoformat(d)
            label = "Hoy" if ds == today else (
                "Mañana" if ds == today.__class__(today.year, today.month, today.day + 1) else
                f"{ds.day} {MONTHS[ds.month-1][:3]}")
            lbl = self._lbl(label, "today" if ds == today else "card-sub")
            self.agenda_box.pack_start(lbl, False, False, 0)
            for e in evs:
                t = ""
                if not e.get("allDay"):
                    hh, mm = e.get("start", "")[11:16].split(":")
                    t = f"{int(hh):02}:{mm}"
                time_cls = "card-sub"
                row = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
                title = self._lbl(e["title"], "text")
                meta = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
                dot = self._lbl("●", "tag-dot")
                dot.override_color(Gtk.StateFlags.NORMAL,
                                   _hex(e.get("color") or self.ACCENT))
                src = self._lbl(f"{e['source']}", "card-sub")
                if t:
                    meta.pack_start(self._lbl(t, "accent"), False, False, 0)
                meta.pack_start(dot, False, False, 0)
                meta.pack_start(src, False, False, 0)
                row.pack_start(title, False, False, 0)
                row.pack_start(meta, False, False, 0)
                self.agenda_box.pack_start(row, False, False, 0)
        self.agenda_box.show_all()

    # ────────────── calendario ──────────────
    def _cal_shift(self, months):
        yy, mm = self.STATE["year"], self.STATE["month"]
        mm += months
        while mm > 12: mm -= 12; yy += 1
        while mm < 1: mm += 12; yy -= 1
        self.STATE["year"], self.STATE["month"] = yy, mm
        self._render_calendar()
        self._render_day()

    def _cal_prev(self, *_):
        self._cal_shift(-1)

    def _cal_next(self, *_):
        self._cal_shift(1)

    def _render_calendar(self):
        for c in self.cal_grid.get_children():
            self.cal_grid.remove(c)
        yy, mm = self.STATE["year"], self.STATE["month"]
        self.cal_title.set_text(f"{MONTHS[mm-1]} {yy}")

        for i, d in enumerate(WEEKDAYS):
            l = Gtk.Label(label=d)
            l.get_style_context().add_class("cal-dow")
            self.cal_grid.attach(l, i, 0, 1, 1)

        first = date(yy, mm, 1)
        start_dow = first.weekday()
        import calendar as _cal
        dim = _cal.monthrange(yy, mm)[1]
        events = backend_json(["month", f"{yy}-{mm:02d}"]) or []
        days_with = set(int(e["date"][8:10]) for e in events)

        today = date.today()
        for d in range(1, dim + 1):
            btn = Gtk.Button(label=str(d))
            btn.get_style_context().add_class("cal-day")
            if d in days_with:
                btn.set_label(f"{d}●")
            if date(yy, mm, d) == today:
                btn.get_style_context().add_class("cal-day-today")
            if self.STATE["sel"] and self.STATE["sel"].year == yy and \
               self.STATE["sel"].month == mm and self.STATE["sel"].day == d:
                btn.get_style_context().add_class("cal-day-sel")
            btn.connect("clicked", self._day_clicked, date(yy, mm, d))
            idx = start_dow + d - 1
            self.cal_grid.attach(btn, idx % 7, 1 + idx // 7, 1, 1)

        self.cal_grid.show_all()

    def _day_clicked(self, _btn, d):
        self.STATE["sel"] = d
        self._render_calendar()
        self._render_day()

    def _render_day(self):
        for c in self.day_box.get_children():
            c.destroy()
        if not self.STATE["sel"]:
            return
        sel = self.STATE["sel"]
        events = backend_json(["day", sel.isoformat()]) or []
        head = self._lbl(f"{sel.day} {MONTHS[sel.month-1]} · {sel.year}", "card-title")
        self.day_box.pack_start(head, False, False, 0)

        add_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        add_btn = self._header_action("＋ Añadir evento", lambda *_: self._open_event_dialog(sel), "primary")
        add_btn.set_label("＋  Añadir evento")
        add_row.pack_start(Gtk.Label(label=""), True, True, 0)
        add_row.pack_start(add_btn, False, False, 0)
        self.day_box.pack_start(add_row, False, False, 0)

        self.day_box.pack_start(Gtk.Separator(), False, False, 0)

        if not events:
            self.day_box.pack_start(self._lbl("Sin eventos este día", "gray"), False, False, 0)
        for e in events:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            dot = self._lbl("●", "tag-dot")
            if e.get("color"):
                dot.override_color(Gtk.StateFlags.NORMAL, _hex(e["color"]))
            t = ""
            if not e.get("allDay"):
                t = e.get("start", "")[11:16]
            title = self._lbl(e["title"], "text")
            meta = self._lbl((t + "  " if t else "") + str(e.get("source", "")), "card-sub")
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
            box.pack_start(title, False, False, 0)
            box.pack_start(meta, False, False, 0)
            row.pack_start(dot, False, False, 0)
            row.pack_start(box, True, True, 0)
            self.day_box.pack_start(row, False, False, 0)
        self.day_box.show_all()

    # ────────────── To-Do ──────────────
    def _render_todo(self):
        for c in self.todo_pending_box.get_children():
            c.destroy()
        for c in self.todo_done_box.get_children():
            c.destroy()
        self.STATE["todos"] = backend_json(["todo"]) or []
        if not self.STATE["todos"]:
            self.todo_pending_box.pack_start(self._lbl("Sin tareas", "gray"), False, False, 0)
            self.todo_done_box.pack_start(self._lbl("Sin tareas completadas", "gray"), False, False, 0)
            self.todo_pending_box.show_all()
            self.todo_done_box.show_all()
            return
        for i, t in enumerate(self.STATE["todos"]):
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            check = Gtk.CheckButton()
            check.set_active(bool(t.get("done")))
            check.connect("toggled", self._todo_toggle, i)
            lbl = self._lbl(t["content"], "todo-done" if t.get("done") else "text")
            lbl.connect("button-press-event", lambda w, ev, i=i: _todo_click(w, ev, i, self))
            row.pack_start(check, False, False, 0)
            row.pack_start(lbl, True, True, 0)
            if t.get("done"):
                self.todo_done_box.pack_start(row, False, False, 0)
            else:
                self.todo_pending_box.pack_start(row, False, False, 0)
        self.todo_pending_box.show_all()
        self.todo_done_box.show_all()

    def _todo_toggle(self, check, i):
        backend(["todo-toggle", str(i)])

    def _todo_add(self, *_):
        txt = self.todo_entry.get_text().strip()
        if not txt:
            return
        backend(["todo-add", txt])
        self.todo_entry.set_text("")
        self._render_todo()

    # ────────────── Notas ──────────────
    def _render_notes(self):
        self.notes_buf.set_text(backend(["notes"]) or "")

    def _notes_save(self, *_):
        buf = self.notes_buf
        start, end = buf.get_bounds()
        txt = buf.get_text(start, end, False)
        backend(["notes-set"], input_data=txt)

    # ────────────── Google ──────────────
    def _do_sync(self, *_):
        self.sync_btn.set_sensitive(False)
        self.hdr_status.set_text("Sincronizando…")
        self._spawn([SYNC_CALENDARS], self._after_sync)

    def _after_sync(self, ok, out):
        self.sync_btn.set_sensitive(True)
        if ok:
            self.hdr_status.set_text("✓ Sincronizado " + datetime.now().strftime("%H:%M"))
            self._render_agenda()
            self._render_calendar()
            self._render_day()
        else:
            self.hdr_status.set_text("✗ Error de sincronización")

        def _reset(*_):
            self.hdr_status.set_text("")
        GLib.timeout_add_seconds(4, _reset)

    def _open_event_dialog(self, selected=None):
        for ch in self._dlg_card.get_children():
            self._dlg_card.remove(ch)

        self._dlg_w = {}

        title = Gtk.Label(label="Nuevo evento en Google")
        title.get_style_context().add_class("dlg-title")
        title.set_halign(Gtk.Align.START)
        self._dlg_card.pack_start(title, False, False, 0)

        def row(label, widget):
            r = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            lbl = self._lbl(label, "dlg-lbl")
            lbl.set_size_request(96, -1)
            r.pack_start(lbl, False, False, 0)
            r.pack_start(widget, True, True, 0)
            self._dlg_card.pack_start(r, False, False, 0)
            return r

        t = Gtk.Entry(); t.set_placeholder_text("Título del evento (obligatorio)")
        row("Título", t); self._dlg_w["title"] = t

        d = Gtk.Entry(); d.set_placeholder_text("Descripción (opcional)")
        row("Descripción", d); self._dlg_w["desc"] = d

        sel = selected or self.STATE["sel"] or date.today()
        e_date = Gtk.Entry(); e_date.set_text(sel.isoformat())
        row("Fecha", e_date); self._dlg_w["date"] = e_date

        now = datetime.now()
        e_time = Gtk.Entry(); e_time.set_text(f"{now.hour:02d}:{now.minute:02d}")
        row("Hora", e_time); self._dlg_w["time"] = e_time

        all_day = Gtk.CheckButton(label="Todo el día")
        all_day.set_halign(Gtk.Align.START)
        self._dlg_card.pack_start(all_day, False, False, 0)
        self._dlg_w["allday"] = all_day

        def combo(options):
            c = Gtk.ComboBoxText()
            for label_text, val in options:
                c.append(val, label_text)
            c.set_active(0)
            return c

        categories = [("General", "general"), ("Cumpleaños", "birthday"),
                      ("Reunión", "meeting"), ("Fecha límite", "deadline"),
                      ("Recordatorio", "reminder")]
        e_category = combo(categories)
        e_category.connect("changed", self._on_cat_changed)
        row("Categoría", e_category); self._dlg_w["cat"] = e_category

        # ── Fila Contacto (visible solo en Cumpleaños): búsqueda + picker ──
        contact_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        c_lbl = self._lbl("Contacto", "dlg-lbl")
        c_lbl.set_size_request(96, -1)
        contact_row.pack_start(c_lbl, False, False, 0)

        c_search = Gtk.Entry()
        c_search.set_placeholder_text("Buscar en Google Contacts…")
        contact_row.pack_start(c_search, True, True, 0)
        self._dlg_w["contact_search"] = c_search

        c_btn = Gtk.Button(label="Buscar")
        c_btn.get_style_context().add_class("dlg-search")
        c_btn.connect("clicked", self._on_contact_search)
        contact_row.pack_start(c_btn, False, False, 0)

        c_results = Gtk.ComboBoxText()
        c_results.set_no_show_all(True)
        contact_row.pack_start(c_results, False, False, 0)
        self._dlg_w["contact_results"] = c_results

        c_hint = self._lbl("Si no hay coincidencias, se crea el contacto", "small-hint")
        c_hint.set_no_show_all(True)
        contact_row.pack_start(c_hint, False, False, 0)

        self._dlg_w["contact_row"] = contact_row
        self._dlg_card.pack_start(contact_row, False, False, 0)
        contact_row.no_show_all = contact_row.get_no_show_all()
        contact_row.set_no_show_all(True)

        priorities = [("Normal", "normal"), ("Baja", "low"), ("Alta", "high")]
        e_prio = combo(priorities)
        row("Prioridad", e_prio); self._dlg_w["prio"] = e_prio

        reminders = [("Ninguno", "0"), ("5 min", "5"), ("15 min", "15"),
                     ("1 hora", "60"), ("1 día", "1440")]
        e_rem = combo(reminders)
        e_rem.set_active(1)
        row("Recordatorio", e_rem); self._dlg_w["rem"] = e_rem

        repeats = [("Nunca", "none"), ("Diaria", "daily"), ("Semanal", "weekly"),
                   ("Mensual", "monthly"), ("Anual", "yearly")]
        e_rep = combo(repeats)
        row("Repetir", e_rep); self._dlg_w["rep"] = e_rep

        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        actions.set_halign(Gtk.Align.END)
        cancel = Gtk.Button(label="Cancelar")
        cancel.connect("clicked", self._close_event_dialog)
        create = Gtk.Button(label="Crear")
        create.get_style_context().add_class("primary")
        create.connect("clicked", self._submit_event)
        actions.pack_start(cancel, False, False, 0)
        actions.pack_start(create, False, False, 0)
        self._dlg_card.pack_start(actions, False, False, 0)
        self._dlg_w["create"] = create

        self._set_dlg_visibility()
        self._dlg_scrim.set_no_show_all(False)
        self._dlg_card.set_no_show_all(False)
        self._dlg_scrim.show_all()
        t.grab_focus()

    def _set_dlg_visibility(self):
        cat = self._dlg_w["cat"].get_active_id()
        show_contact = cat == "birthday"
        self._dlg_w["contact_row"].set_no_show_all(not show_contact)
        self._dlg_w["contact_row"].set_visible(show_contact)
        if show_contact and self._dlg_w["contact_row"].get_parent():
            self._dlg_w["contact_row"].get_parent().show_all()

    def _on_cat_changed(self, *_):
        self._set_dlg_visibility()

    def _close_event_dialog(self, *_):
        self._dlg_scrim.hide()

    def _on_contact_search(self, *_):
        q = self._dlg_w["contact_search"].get_text().strip()
        if not q:
            return
        self._dlg_w["contact_results"].remove_all()
        self._dlg_w["contact_hint_lbl"] = None
        self._spawn([GCAL_OP, "search", q], self._after_contact_search)

    def _after_contact_search(self, ok, out):
        combo = self._dlg_w.get("contact_results")
        if not combo:
            return
        combo.remove_all()
        hint = self._dlg_w["contact_row"].get_children()[-1]
        try:
            res = json.loads(out)
        except ValueError:
            res = {}
        results = res.get("results") or []
        for c in results:
            parts = [c["name"]]
            if c.get("phone"):
                parts.append(c["phone"])
            if c.get("birthday"):
                parts.append("🎂 " + c["birthday"])
            combo.append(c["id"], " · ".join(parts))
        hint.set_visible(ok and not results)
        combo.set_visible(bool(results))
        if results:
            combo.set_active(0)

    def _submit_event(self, *_):
        w = self._dlg_w
        t = w["title"].get_text().strip()
        ds = w["date"].get_text().strip()
        ts = w["time"].get_text().strip()
        if not t or not ds:
            return
        try:
            day = date.fromisoformat(ds)
            hh, mm = (ts or "10:00").split(":")
            dt = f"{day.isoformat()}T{int(hh):02d}:{int(mm):02d}:00"
        except ValueError:
            return
        payload = {
            "summary": t,
            "description": w["desc"].get_text().strip(),
            "dateTime": dt,
            "allDay": w["allday"].get_active(),
            "category": w["cat"].get_active_id() or "general",
            "priority": w["prio"].get_active_id() or "normal",
            "reminderMinutes": int((w["rem"].get_active_id() or "0")),
            "recurrence": w["rep"].get_active_id() or "none",
        }
        # Cumpleaños → se escriben en Google Contacts (People API), como en quickshell.
        if payload["category"] == "birthday":
            cr = w.get("contact_results")
            cid = cr.get_active_id() if cr else None
            if cid:
                payload["contactId"] = cid
            payload["name"] = w["contact_search"].get_text().strip() or t
        self._close_event_dialog()
        self.hdr_status.set_text("Creando evento…")
        self._spawn([GCAL_OP, "create", json.dumps(payload)], self._after_create)

    def _after_create(self, ok, out):
        try:
            res = json.loads(out)
        except ValueError:
            res = {}
        if ok and res.get("ok"):
            self.hdr_status.set_text("✓ Evento creado")
            self.sync_btn.set_sensitive(True)
            self._do_sync()
        else:
            self.hdr_status.set_text("✗ No se pudo crear el evento")
        def _reset(*_):
            self.hdr_status.set_text("")
        GLib.timeout_add_seconds(4, _reset)

    # ────────────── utilidades ──────────────
    def _spawn(self, args, callback):
        def _done(p, cond):
            try:
                res = p.communicate(None)
                # res = (bool, BGytes stdout, bytes/stderr)
                bin_out = res[1]
                if bin_out is None:
                    out = ""
                else:
                    try:
                        out = bin_out.get_data().decode("utf-8", "replace")
                    except AttributeError:
                        out = GLib.Bytes.new(bin_out).get_data().decode("utf-8", "replace")
                GLib.idle_add(callback, p.get_exit_status() == 0, out)
            except Exception as ex:
                GLib.idle_add(callback, False, str(ex))
            return False
        flags = Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_MERGE
        try:
            p = Gio.Subprocess.new([str(a) for a in args], flags)
            p.wait_async(None, _done)
        except GLib.Error:
            callback(False, "")

    def _on_key(self, _w, ev):
        if ev.keyval == 0xFF1B:  # Escape
            self._quit()
            return True
        return False

    def _quit(self, *_):
        self._save_pid(False)
        Gtk.main_quit()

    def _save_pid(self, on=True):
        try:
            if on:
                PID_FILE.write_text(str(os.getpid()))
            else:
                PID_FILE.unlink()
        except OSError:
            pass


def _hex(color):
    c = color.lstrip("#")
    try:
        r = int(c[0:2], 16) / 255
        g = int(c[2:4], 16) / 255
        b = int(c[4:6], 16) / 255
        return Gdk.RGBA(r, g, b, 1.0)
    except (ValueError, IndexError):
        return Gdk.RGBA(0.9, 0.7, 0.84, 1.0)


def _todo_click(w, ev, i, dash):
    if ev.button == 3:  # botón derecho -> borrar
        backend(["todo-del", str(i)])
        dash._render_todo()
        return True
    return False


def _is_our_pid(pid):
    """True si el PID es una instancia viva de haku_dash.py (para el toggle)."""
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as fh:
            cmdline = fh.read().decode("utf-8", "replace")
        return "haku_dash" in cmdline
    except OSError:
        return False


def main():
    # Toggle: si ya hay una instancia viva de haku_dash.py, ciérrala y sal.
    # Si el pidfile contiene un PID ajeno o muerto, ignóralo (y límpialo).
    try:
        pid = int(PID_FILE.read_text().strip())
    except (OSError, ValueError):
        pid = None
    if pid and _is_our_pid(pid):
        os.kill(pid, signal.SIGTERM)
        try:
            PID_FILE.unlink()
        except OSError:
            pass
        return
    if pid:
        try:
            PID_FILE.unlink()
        except OSError:
            pass
    dash = Dashboard()
    dash._save_pid(True)
    Gtk.main()


if __name__ == "__main__":
    main()