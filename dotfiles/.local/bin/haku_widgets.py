#!/usr/bin/env python3
"""Widgets de escritorio estilo quickshell (GTK3 + gtk-layer-shell).

Uso:
  haku_widgets.py upcoming          toggle widget upcoming
  haku_widgets.py media             toggle widget media
  haku_widgets.py edit              editor de widgets (mover/posicionar/mostrar)
  haku_widgets.py desktop           catcher de click derecho -> menú contextual
  haku_widgets.py --all             abre ambos widgets

Cada widget es una surface layer-shell BOTTOM (detrás de ventanas, encima del
wallpaper), libremente posicionable. Posiciones guardadas en
~/.config/haku-widgets.json. Arrastrar por el header mueve el widget; al soltar
se guarda la posición automáticamente. El click derecho del ratón sobre el
escritorio abre un menú contextual con "Editar widgets" y los controles rápidos
de visibilidad. Aparición/desaparición con fade como las ventanas.
"""

import json
import os
import signal
import subprocess
import sys
import threading
import urllib.request
from datetime import date, datetime, timedelta
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("GtkLayerShell", "0.1")

from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, GtkLayerShell, Pango

HOME = Path.home()
PIPE_BIN = HOME / ".local/bin/calwidget.py"
LYRICS = HOME / ".config/quickshell/inir/scripts/lyrics/lyrics.py"
THEME_DIR = HOME / ".local/state/haku_theme"
CFG = HOME / ".config" / "haku-widgets.json"
SELF = HOME / ".local/bin/haku_widgets.py"

ACCENT = "#F9B2D7"
MEDIA_COLOR = "#7DD3FC"
MONTHS = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
          "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
WEEKDAYS = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]


# ─── Config helper ────────────────────────────────────────────────────
_DEFAULTS = {
    "upcoming": {"x": 80, "y": 80, "visible": False},
    "media":    {"x": 440, "y": 80, "visible": False},
}
WIDGET_NAMES = {"upcoming": "Upcoming", "media": "Media"}
WIDGET_SIZE = {"upcoming": (310, 260), "media": (350, 460)}


def _load_cfg():
    try:
        return json.loads(CFG.read_text())
    except (OSError, ValueError):
        return dict(_DEFAULTS)


def _save_cfg(data):
    CFG.parent.mkdir(parents=True, exist_ok=True)
    CFG.write_text(json.dumps(data, indent=2, ensure_ascii=False))


def _pidfile(kind):
    return HOME / f".cache/haku_widget_{kind}.pid"


# ─── Theme / CSS ──────────────────────────────────────────────────────
def _accent():
    try:
        txt = (THEME_DIR / "colors.css").read_text()
        m = __import__("re").search(r"accent_color\s+#([0-9a-fA-F]{6})", txt)
        if m:
            return "#" + m.group(1)
    except OSError:
        pass
    return ACCENT


def run(args, input_data=None):
    try:
        p = subprocess.run([str(a) for a in args], input=input_data,
                           text=True, capture_output=True, timeout=30)
        return p.stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def backend(args):
    return run([PIPE_BIN, *args])


_CSS = """
* { font-family: "%(font)s"; }
window.haku-widget, window.haku-menu { background: transparent; }
.wcard { background: rgba(12,12,15,0.88); border: 1px solid rgba(255,255,255,0.12);
         border-radius: 18px; }
.title { color: %(accent)s; font-weight: bold; font-size: 15px; }
.card-sub { color: rgba(255,255,255,0.5); font-size: 12px; }
.date-hd { color: %(accent)s; font-weight: bold; font-size: 12px; }
.inset { background: rgba(255,255,255,0.06); border-radius: 12px; }
.text { color: #e6e6ee; }
.muted { color: rgba(255,255,255,0.5); }
.primary { background: %(accent)s; color: #141416; border-radius: 10px; font-weight: bold; }
.ctrl { background: rgba(255,255,255,0.07); color: #e6e6ee; border-radius: 10px;
        font-weight: bold; }
.ctrl:hover { background: rgba(255,255,255,0.15); }
.lyr-cur { color: %(accent)s; font-weight: bold; }
.lyr-off { color: rgba(255,255,255,0.45); }
.cover-frame { background: rgba(255,255,255,0.06); border-radius: 14px; }
.drag-header { background: rgba(255,255,255,0.03); }
.drag-header:hover { background: rgba(255,255,255,0.07); }
.menu-item { color: #e6e6ee; }
.menu-item:hover { background: rgba(255,255,255,0.09); }
canvas-frame { background: rgba(255,255,255,0.04); border-radius: 12px; }
.form-label { color: rgba(255,255,255,0.85); font-size: 13px; }
"""


def _css_load():
    font = "Noto Sans Gothic"
    try:
        txt = (THEME_DIR / "fonts.css").read_text()
        m = __import__("re").search(r"font_family\s*[:=]\s*[\"']([^\"']+)", txt)
        if m:
            font = m.group(1)
    except OSError:
        pass
    prov = Gtk.CssProvider()
    prov.load_from_data(bytes(_CSS % {"accent": _accent(), "font": font}, "utf-8"))
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


def _pick_monitor(win):
    d = win.get_screen().get_display()
    n = d.get_n_monitors()
    if n == 0:
        return None
    mon = os.environ.get("HAKU_DASH_MONITOR")
    if mon is not None:
        try:
            i = int(mon)
            if 0 <= i < n:
                return d.get_monitor(i)
        except (TypeError, ValueError):
            pass
    try:
        m = d.get_default_seat().get_pointer_monitor()
        if m:
            return m
    except Exception:
        pass
    return d.get_monitor(0)


def _mon_origin(win):
    mon = _pick_monitor(win)
    if mon:
        g = mon.get_geometry()
        return (g.x, g.y), mon
    return (0, 0), None


def lbl(text, cls, size=14):
    l = Gtk.Label(label=text)
    l.get_style_context().add_class(cls)
    l.set_line_wrap(True)
    l.set_xalign(0)
    l.set_yalign(0)
    l.modify_font(Pango.FontDescription(f"{size}px"))
    return l


def _hex_rgba(h):
    try:
        h = h.lstrip("#")
        return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
    except Exception:
        return (0.976, 0.69, 0.84)


# ─── Animación (fade como apertura de ventana) ──────────────────────────
def _fade(win, target, ms=220, done=None):
    steps = max(8, int(ms / 16))
    start = win.get_opacity()
    i = [0]

    def tick():
        i[0] += 1
        p = min(1.0, i[0] / steps)
        try:
            win.set_opacity(start + (target - start) * p)
        except Exception:
            pass
        if i[0] >= steps:
            if done:
                done()
            return False
        return True

    GLib.timeout_add(16, tick)
    return True


def _fade_in(win, ms=220):
    try:
        win.set_opacity(0.0)
    except Exception:
        pass
    win.show_all()
    win.set_opacity(0.0)
    GLib.timeout_add(32, lambda: _fade(win, 1.0, ms) or False)


def _draw_round_bg(win, cr):
    """Dibuja fondo redondeado como en haku_dash.py."""
    import math
    w_ = win.get_allocated_width()
    h_ = win.get_allocated_height()
    r = 18.0
    if w_ <= 0 or h_ <= 0:
        return False
    cr.save()
    for _ in range(2):
        cr.new_path()
        cr.arc(r, r, r, math.pi, 1.5 * math.pi)
        cr.arc(w_ - r, r, r, 1.5 * math.pi, 2 * math.pi)
        cr.arc(w_ - r, h_ - r, r, 0, 0.5 * math.pi)
        cr.arc(r, h_ - r, r, 0.5 * math.pi, math.pi)
        cr.close_path()
        if _ == 0:
            cr.set_source_rgba(0.047, 0.047, 0.059, 0.88)
            cr.fill()
        else:
            cr.set_source_rgba(1, 1, 1, 0.12)
            cr.set_line_width(1.0)
            cr.stroke()
    cr.restore()
    return False


# ─── Draggable mixin ──────────────────────────────────────────────────
class _Draggable:
    """Mixin: arrastra el header del widget para moverlo. Guarda posición
    al soltar."""

    def _setup_drag(self, header_box, kind):
        self._kind = kind
        self._dragging = False
        self._drag_off = (0, 0)
        self._drag_header = header_box
        header_box.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK)
        header_box.connect("button-press-event", self._on_drag_press)
        header_box.connect("button-release-event", self._on_drag_release)
        header_box.connect("motion-notify-event", self._on_drag_motion)

    def _on_drag_press(self, w, ev):
        if ev.button != 1:
            return False
        self._dragging = True
        rel = (ev.x_root - self._mon_orig[0], ev.y_root - self._mon_orig[1])
        self._drag_off = (rel[0] - self._pos[0], rel[1] - self._pos[1])
        return False

    def _on_drag_release(self, w, ev):
        if not self._dragging:
            return False
        self._dragging = False
        self._save_position()
        return False

    def _on_drag_motion(self, w, ev):
        if not self._dragging:
            return False
        rel = (ev.x_root - self._mon_orig[0], ev.y_root - self._mon_orig[1])
        new_x = int(rel[0] - self._drag_off[0])
        new_y = int(rel[1] - self._drag_off[1])
        mon = _pick_monitor(self)
        if mon:
            mg = mon.get_geometry()
            new_x = max(mg.x, min(mg.x + mg.width - 20, new_x))
            new_y = max(mg.y, min(mg.y + mg.height - 20, new_y))
        self._pos = (new_x, new_y)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, new_y)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.LEFT, new_x)
        return False

    def _save_position(self):
        cfg = _load_cfg()
        cfg.setdefault(self._kind, {})
        cfg[self._kind]["x"] = self._pos[0]
        cfg[self._kind]["y"] = self._pos[1]
        _save_cfg(cfg)


# ─── Layer-shell helper ───────────────────────────────────────────────
def _make_shell(win, kind, x, y, layer=GtkLayerShell.Layer.BOTTOM):
    GtkLayerShell.init_for_window(win)
    mon = _pick_monitor(win)
    if mon:
        GtkLayerShell.set_monitor(win, mon)
    win._mon_orig = (0, 0)
    if mon:
        g = mon.get_geometry()
        win._mon_orig = (g.x, g.y)
    GtkLayerShell.set_layer(win, layer)
    GtkLayerShell.set_exclusive_zone(win, -1)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, y)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.LEFT, x)
    win.set_resizable(False)
    win.set_decorated(False)
    win.set_type_hint(Gdk.WindowTypeHint.UTILITY)
    win.set_skip_taskbar_hint(True)
    win.set_skip_pager_hint(True)
    screen = win.get_screen()
    visual = screen.get_rgba_visual()
    if visual:
        win.set_visual(visual)
    win.get_style_context().add_class("haku-widget")
    if kind != "menu":
        win.set_app_paintable(True)
        win.connect("draw", _draw_round_bg)
    win._pos = (x, y)
    win._kind = kind


def _make_card():
    root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    root.get_style_context().add_class("wcard")
    root.set_margin_top(16); root.set_margin_bottom(16)
    root.set_margin_left(18); root.set_margin_right(18)
    root.set_spacing(10)
    return root


def _make_header(title, kind, win):
    wrap = Gtk.EventBox()
    wrap.get_style_context().add_class("drag-header")
    wrap.set_margin_top(2); wrap.set_margin_bottom(2)
    wrap.set_margin_left(4); wrap.set_margin_right(4)
    hdr = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    wrap.add(hdr)
    lbl_w = Gtk.Label(label=title)
    lbl_w.get_style_context().add_class("title")
    lbl_w.set_halign(Gtk.Align.START)
    lbl_w.set_margin_left(8)
    hdr.pack_start(lbl_w, True, True, 0)
    return wrap


# ═════════════════════ UPCOMING ════════════════════════════════════════
class UpcomingWidget(Gtk.Window, _Draggable):
    def __init__(self, x, y):
        super().__init__(title="Upcoming")
        _make_shell(self, "upcoming", x, y)
        _css_load()
        self.set_size_request(*WIDGET_SIZE["upcoming"])

        root = _make_card()
        self.add(root)
        hdr = _make_header("Upcoming · Próximos eventos", "upcoming", self)
        root.pack_start(hdr, False, False, 0)
        self._setup_drag(hdr, "upcoming")

        self._list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        root.pack_start(self._list, True, True, 0)
        self.connect("key-press-event",
                     lambda w, e: (self._quit(), True) if e.keyval == 0xFF1B else False)
        self.connect("button-press-event", self._dbg_event)
        self.connect("button-release-event", self._dbg_event)
        _fade_in(self)
        self._do_refresh()
        GLib.timeout_add_seconds(120, self._do_refresh)

    def _dbg_event(self, w, ev):
        with open("/tmp/dbg_click.log", "a") as f:
            f.write(f"{self._kind} {ev.type} b={ev.button} x={int(ev.x)} y={int(ev.y)} "
                    f"xr={int(ev.x_root)} yr={int(ev.y_root)} f={self.is_focus()}\n")
        return False

    def _do_refresh(self, *_):
        for c in self._list.get_children():
            self._list.remove(c)
        try:
            evs = json.loads(backend(["agenda", "14"]) or "[]")
        except ValueError:
            evs = []
        today = date.today()
        groups = {}
        for e in evs:
            d = e.get("date", "")[:10]
            try:
                dd = date.fromisoformat(d)
            except ValueError:
                continue
            if dd < today:
                continue
            groups.setdefault(dd.isoformat(), []).append(e)
        if not groups:
            self._list.pack_start(
                lbl("Sin eventos próximos", "muted", 12), False, False, 0)
        for day in sorted(groups):
            h = lbl(self._day_label(day), "date-hd", 12)
            h.set_halign(Gtk.Align.START)
            h.set_margin_left(2)
            self._list.pack_start(h, False, False, 0)
            for e in groups[day]:
                row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
                row.set_margin_left(4)
                row.set_margin_right(4)
                dot = Gtk.Label(label="●")
                dot.override_color(
                    Gtk.StateFlags.NORMAL,
                    Gdk.RGBA(*_hex_rgba(e.get("color") or ACCENT)))
                dot.set_size_request(14, -1)
                dot.set_margin_right(2)
                row.pack_start(dot, False, False, 0)
                col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
                t = lbl(e.get("title", ""), "text", 13)
                t.set_halign(Gtk.Align.START)
                col.pack_start(t, False, False, 0)
                if not e.get("allDay"):
                    tm = lbl(e.get("start", "")[11:16], "card-sub", 11)
                    tm.set_halign(Gtk.Align.START)
                    col.pack_start(tm, False, False, 0)
                src = lbl(e.get("source", ""), "card-sub", 10)
                src.set_halign(Gtk.Align.START)
                col.pack_start(src, False, False, 0)
                row.pack_start(col, True, True, 0)
                self._list.pack_start(row, False, False, 0)
        self._list.show_all()
        return True

    def _day_label(self, iso):
        d = date.fromisoformat(iso)
        today = date.today()
        if d == today:
            return "Hoy · " + iso[5:]
        if d == today + timedelta(days=1):
            return "Mañana · " + iso[5:]
        return f"{WEEKDAYS[d.weekday()]}, {d.day} {MONTHS[d.month-1]}"

    def _quit(self):
        cfg = _load_cfg()
        cfg.setdefault("upcoming", {})["visible"] = False
        _save_cfg(cfg)
        _fade(self, 0.0, 180, done=lambda: (self.hide(), Gtk.main_quit()))
        return True


# ═════════════════════ MEDIA ═══════════════════════════════════════════
class MediaWidget(Gtk.Window, _Draggable):
    def __init__(self, x, y):
        super().__init__(title="Media")
        _make_shell(self, "media", x, y)
        _css_load()
        self.set_size_request(*WIDGET_SIZE["media"])

        self._lyrics, self._lyr_lines, self._cur_line = [], [], -1
        self._last_meta = ""

        root = _make_card()
        self.add(root)
        hdr = _make_header("Media", "media", self)
        root.pack_start(hdr, False, False, 0)
        self._setup_drag(hdr, "media")

        body = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        cf = Gtk.Box()
        cf.get_style_context().add_class("cover-frame")
        cf.set_size_request(96, 96)
        self._cover = Gtk.Image()
        cf.pack_start(self._cover, True, True, 0)
        body.pack_start(cf, False, False, 0)
        info = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        info.set_margin_top(2)
        self._title = lbl("—", "text", 14)
        self._artist = lbl("—", "muted", 12)
        self._album = lbl("", "card-sub", 11)
        self._posbar = Gtk.ProgressBar()
        self._posbar.set_size_request(-1, 5)
        for w in (self._title, self._artist, self._album, self._posbar):
            w.set_halign(Gtk.Align.START)
            info.pack_start(w, False, False, 0)
        body.pack_start(info, True, True, 0)
        body.set_margin_top(4)
        root.pack_start(body, False, False, 0)

        ctr = Gtk.Box(spacing=6)
        for sym, cb in [("⏮", self._prev), ("▶", self._toggle_play),
                        ("⏭", self._next), ("⏹", self._stop)]:
            b = Gtk.Button(label=sym)
            b.get_style_context().add_class("ctrl")
            b.set_size_request(40, 30)
            b.connect("clicked", cb)
            ctr.pack_start(b, False, False, 0)
        ctr.set_halign(Gtk.Align.CENTER)
        ctr.set_margin_top(2); ctr.set_margin_bottom(2)
        root.pack_start(ctr, False, False, 0)

        sep = Gtk.Separator()
        sep.override_color(Gtk.StateFlags.NORMAL, Gdk.RGBA(1, 1, 1, 0.08))
        root.pack_start(sep, False, False, 0)

        self._lyr_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        sw = Gtk.ScrolledWindow()
        sw.add(self._lyr_box)
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        root.pack_start(sw, True, True, 0)

        self.connect("key-press-event",
                     lambda w, e: (self._quit(), True) if e.keyval == 0xFF1B else False)
        _fade_in(self)
        self._refresh()
        GLib.timeout_add_seconds(1, self._refresh)

    @staticmethod
    def _cmd(args):
        try:
            return subprocess.run(
                ["playerctl", *args], capture_output=True,
                text=True, timeout=3).stdout.strip()
        except (OSError, subprocess.TimeoutExpired):
            return ""

    def _refresh(self, *_):
        title = self._cmd(["metadata", "xesam:title"])
        artist = self._cmd(["metadata", "xesam:artist"])
        album = self._cmd(["metadata", "xesam:album"])
        art = self._cmd(["metadata", "mpris:artUrl"])
        try:
            playing = self._cmd(["status"]) == "Playing"
        except Exception:
            playing = False
        try:
            pos = float(self._cmd(["position"]) or 0) / 1e6
        except ValueError:
            pos = 0.0
        try:
            length = float(self._cmd(["metadata", "mpris:length"]) or 0) / 1e6
        except ValueError:
            length = 0.0
        meta = f"{title}\x01{artist}\x01{album}"
        self._title.set_text(title or "—")
        self._artist.set_text(artist or "—")
        self._album.set_text(album or "")
        if length:
            self._posbar.set_fraction(max(0, min(1, pos / length)))
        if art:
            self._load_cover(art)
        if meta != self._last_meta:
            self._last_meta = meta
            self._load_lyrics(title or "", artist or "", album or "", length)
        if self._lyrics:
            self._update_current(pos)
        return True

    def _toggle_play(self, *_):
        self._cmd(["play-pause"])

    def _prev(self, *_):
        self._cmd(["previous"])

    def _next(self, *_):
        self._cmd(["next"])

    def _stop(self, *_):
        self._cmd(["stop"])

    def _load_cover(self, url):
        def _dl():
            try:
                if url.startswith("file://"):
                    data = Path(url.replace("file://", "")).read_bytes()
                else:
                    with urllib.request.urlopen(url, timeout=6) as r:
                        data = r.read()
                loader = GdkPixbuf.PixbufLoader.new()
                loader.write(data)
                loader.close()
                pb = loader.get_pixbuf()
                if pb and (pb.get_width() > 120 or pb.get_height() > 120):
                    pb = pb.scale_simple(88, 88, GdkPixbuf.InterpType.BILINEAR)
                GLib.idle_add(self._set_cover, pb)
            except Exception:
                GLib.idle_add(self._cover.clear)
        threading.Thread(target=_dl, daemon=True).start()

    def _set_cover(self, pb):
        if pb:
            self._cover.set_from_pixbuf(pb)

    def _load_lyrics(self, title, artist, album, length):
        def _fetch():
            try:
                out = subprocess.run(
                    [str(LYRICS), title, artist, album,
                     str(int(length)) if length else ""],
                    capture_output=True, text=True, timeout=20).stdout
                data = json.loads(out) if out else {}
            except (OSError, subprocess.TimeoutExpired, ValueError):
                data = {}
            GLib.idle_add(self._apply_lyrics, data)
        threading.Thread(target=_fetch, daemon=True).start()

    def _apply_lyrics(self, data):
        for c in self._lyr_box.get_children():
            self._lyr_box.remove(c)
        self._lyrics = data.get("lines", []) if data.get("status") == "ok" else []
        self._cur_line = -1
        self._lyr_lines = []
        if not self._lyrics:
            w = lbl("Sin letra disponible", "muted", 12)
            w.set_halign(Gtk.Align.START)
            w.set_margin_left(6); w.set_margin_right(6)
            self._lyr_box.pack_start(w, False, False, 0)
        else:
            for line in self._lyrics:
                w = lbl(line.get("text") or "···", "lyr-off", 12)
                w.set_halign(Gtk.Align.START)
                w.set_margin_left(6); w.set_margin_right(6)
                self._lyr_box.pack_start(w, False, False, 0)
            self._lyr_lines = self._lyr_box.get_children()
        self._lyr_box.show_all()

    def _update_current(self, pos):
        idx = -1
        for i, l in enumerate(self._lyrics):
            if (l.get("time") or l.get("t") or 0) <= pos:
                idx = i
            else:
                break
        if idx == self._cur_line:
            return
        self._cur_line = idx
        for j, w in enumerate(self._lyr_lines):
            ctx = w.get_style_context()
            ctx.remove_class("lyr-cur")
            ctx.remove_class("lyr-off")
            if j == idx:
                ctx.add_class("lyr-cur")
                sw = w.get_parent()
                if isinstance(sw, Gtk.ScrolledWindow):
                    vadj = sw.get_vadjustment()
                    if vadj:
                        vadj.set_value(max(0, j * 24 - vadj.get_page_size() / 2))
            else:
                ctx.add_class("lyr-off")

    def _quit(self):
        cfg = _load_cfg()
        cfg.setdefault("media", {})["visible"] = False
        _save_cfg(cfg)
        _fade(self, 0.0, 180, done=lambda: (self.hide(), Gtk.main_quit()))
        return True


# ═════════════════════ PROCESO / CICLO DE VIDA ═════════════════════════
def _kill_widget(kind):
    pid = _pidfile(kind)
    if not pid.exists():
        return
    try:
        os.kill(int(pid.read_text()), signal.SIGTERM)
    except (OSError, ValueError):
        pass
    try:
        pid.unlink()
    except OSError:
        pass


def _spawn_widget(kind):
    cfg = _load_cfg()
    pos = cfg.get(kind, {})
    x, y = int(pos.get("x", 80)), int(pos.get("y", 80))
    env = dict(os.environ)
    env["HAKU_DASH_MONITOR"] = env.get("HAKU_DASH_MONITOR", "0")
    subprocess.Popen([sys.executable, str(SELF), "show", kind, str(x), str(y)],
                     env=env, start_new_session=True,
                     stdout=open(f"/tmp/haku_widget_{kind}.log", "a"),
                     stderr=subprocess.STDOUT)
    cfg.setdefault(kind, {})["visible"] = True
    _save_cfg(cfg)


def _toggle(kind):
    """Si está abierto lo cierra, si no lo abre."""
    if _pidfile(kind).exists():
        _kill_widget(kind)
        cfg = _load_cfg()
        cfg.setdefault(kind, {})["visible"] = False
        _save_cfg(cfg)
        return False
    _spawn_widget(kind)
    return True


# ═════════════════════ EDITOR ═════════════════════════════════════════
class _PreviewCanvas(Gtk.DrawingArea):
    """Mini-mapa del monitor con los widgets arrastrables."""

    def __init__(self, mon_w, mon_h):
        super().__init__()
        self.mon_w, self.mon_h = mon_w, mon_h
        self._boxes = {}
        self._visible = {}
        self._spins = {}
        self._dragging = None
        self.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK |
            Gdk.EventMask.BUTTON1_MOTION_MASK)
        self.connect("draw", self._draw)
        self.connect("button-press-event", self._on_press)
        self.connect("button-release-event", self._on_release)
        self.connect("motion-notify-event", self._on_motion)

    def scale(self):
        return min(1.0, 720.0 / self.mon_w, 420.0 / self.mon_h) if self.mon_w else 0

    def _cfg_pix(self, kind):
        cfg = _load_cfg()
        pos = cfg.get(kind, {})
        w, h = WIDGET_SIZE[kind]
        return int(pos.get("x", 80)), int(pos.get("y", 80)), w, h

    def _resize(self, *_):
        s = self.scale()
        self.set_size_request(int(self.mon_w * s), int(self.mon_h * s))
        return True

    def _draw(self, wgt, cr):
        s = self.scale()
        W = self.mon_w * s
        H = self.mon_h * s
        cr.set_source_rgba(0.06, 0.06, 0.08, 1.0)
        cr.rectangle(2, 2, W - 4, H - 4)
        cr.fill()
        cr.set_source_rgba(0.35, 0.35, 0.42, 0.9)
        cr.set_line_width(1.0)
        cr.rectangle(2, 2, W - 4, H - 4)
        cr.stroke()
        for kind in ("upcoming", "media"):
            x, y, w, h = self._boxes.get(kind, self._cfg_pix(kind))
            if kind == "upcoming":
                col = (*_hex_rgba(ACCENT), 0.85 if self._visible.get(kind) else 0.25)
            else:
                col = (*_hex_rgba(MEDIA_COLOR), 0.85 if self._visible.get(kind) else 0.25)
            cr.set_source_rgba(*col)
            radius = 9 * s
            self._rounded_rect(cr, x * s, y * s, w * s, h * s, radius)
            cr.fill()
            lay = self.create_pango_layout(WIDGET_NAMES[kind])
            lay.set_font_description(Pango.FontDescription("Sans 11"))
            cr.set_source_rgba(0.06, 0.06, 0.08, 1.0)
            cr.move_to(x * s + 8, y * s + 6)
            cr.show_layout(lay)
            cr.rectangle(x * s, y * s, w * s, h * s)
            cr.stroke()
        return True

    @staticmethod
    def _rounded_rect(cr, x, y, w, h, r):
        cr.move_to(x + r, y)
        cr.arc(x + w - r, y + r, r, -0.5 * 3.14159, 0)
        cr.arc(x + w - r, y + h - r, r, 0, 0.5 * 3.14159)
        cr.arc(x + r, y + h - r, r, 0.5 * 3.14159, 3.14159)
        cr.arc(x + r, y + r, r, 3.14159, 1.5 * 3.14159)
        cr.close_path()

    def _hit(self, px, py):
        s = self.scale()
        for kind in ("upcoming", "media"):
            x, y, w, h = self._boxes.get(kind, self._cfg_pix(kind))
            if x * s <= px <= (x + w) * s and y * s <= py <= (y + h) * s:
                return kind
        return None

    def _on_press(self, w, ev):
        if ev.button == 1:
            self._dragging = self._hit(ev.x, ev.y)
            if self._dragging:
                self._drag_off = (ev.x - self._boxes[self._dragging][0] * self.scale(),
                                  ev.y - self._boxes[self._dragging][1] * self.scale())
                return True
        return False

    def _on_release(self, w, ev):
        self._dragging = None
        return True

    def _on_motion(self, w, ev):
        if not self._dragging:
            return False
        s = self.scale()
        kind = self._dragging
        x, y, bw, bh = self._boxes.get(kind, self._cfg_pix(kind))
        nx = int((ev.x - self._drag_off[0]) / s)
        ny = int((ev.y - self._drag_off[1]) / s)
        nx = max(0, min(self.mon_w - bw, nx))
        ny = max(0, min(self.mon_h - bh, ny))
        self._boxes[kind] = (nx, ny, bw, bh)
        self._sync_spin(kind)
        self.queue_draw()
        return True

    def _sync_spin(self, kind):
        spins = self._spins.get(kind)
        if spins:
            x, y, _, _ = self._boxes.get(kind, (0, 0, 0, 0))
            spins[0].set_value(x)
            spins[1].set_value(y)
            try:
                cfg = _load_cfg()
                cfg.setdefault(kind, {})["x"] = x
                cfg.setdefault(kind, {})["y"] = y
                _save_cfg(cfg)
            except Exception:
                pass


def _open_editor():
    pid = HOME / ".cache/haku_widget_editor.pid"
    if pid.exists():
        try:
            os.kill(int(pid.read_text()), signal.SIGTERM)
        except (OSError, ValueError):
            pass
        pid.unlink(missing_ok=True)
        return
    _css_load()
    cfg = _load_cfg()
    probe = Gtk.Window()
    _, mon = _mon_origin(probe)
    mon_w, mon_h = 1920, 1080
    if mon:
        g = mon.get_geometry()
        mon_w, mon_h = g.width, g.height

    win = Gtk.Window(title="Editar widgets")
    win.set_default_size(760, 460)
    win.set_decorated(True)
    win.set_position(Gtk.WindowPosition.CENTER)
    win.set_type_hint(Gdk.WindowTypeHint.DIALOG)

    vb = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    vb.set_margin_top(16); vb.set_margin_bottom(16)
    vb.set_margin_left(18); vb.set_margin_right(18)
    win.add(vb)

    h = lbl("Editar widgets", "title", 17)
    h.set_margin_bottom(2)
    vb.pack_start(h, False, False, 0)
    hint = lbl("Arrastra los bloques en el mapa o usa los controles. Se aplica al guardar.",
               "card-sub", 12)
    vb.pack_start(hint, False, False, 0)

    frame = Gtk.Box()
    frame.get_style_context().add_class("canvas-frame")
    frame.set_margin_top(6)
    canvas = _PreviewCanvas(mon_w, mon_h)
    canvas.get_style_context().add_class("canvas-frame")
    frame.pack_start(canvas, True, True, 0)
    vb.pack_start(frame, False, False, 0)

    rows = {}
    checks = {}
    for kind, title in [("upcoming", "Upcoming · Eventos"), ("media", "Media Player")]:
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.set_margin_top(6)
        chk = Gtk.CheckButton(label=title)
        chk.set_active(bool(cfg.get(kind, {}).get("visible", False)))
        chk.get_style_context().add_class("form-label")
        checks[kind] = chk
        row.pack_start(chk, False, False, 0)
        ix = Gtk.SpinButton.new_with_range(0, 15000, 10)
        iy = Gtk.SpinButton.new_with_range(0, 8000, 10)
        ix.set_value(int(cfg.get(kind, {}).get("x", 80)))
        iy.set_value(int(cfg.get(kind, {}).get("y", 80)))
        ix.set_size_request(100, -1)
        iy.set_size_request(100, -1)
        row.pack_start(ix, False, False, 0)
        row.pack_start(iy, False, False, 0)
        for d, fn in [("◀", lambda k=kind, dx=-10: _nudge(k, dx, 0)),
                      ("▶", lambda k=kind, dx=10: _nudge(k, dx, 0)),
                      ("▲", lambda k=kind, dy=-10: _nudge(k, 0, dy)),
                      ("▼", lambda k=kind, dy=10: _nudge(k, 0, dy))]:
            b = Gtk.Button(label=d)
            b.get_style_context().add_class("ctrl")
            b.set_size_request(34, 28)
            row.pack_start(b, False, False, 0)
        rows[kind] = (ix, iy)
        canvas._spins[kind] = (ix, iy)
        vb.pack_start(row, False, False, 0)
        canvas._visible[kind] = bool(cfg.get(kind, {}).get("visible", False))

    for kind in ("upcoming", "media"):
        canvas._boxes[kind] = canvas._cfg_pix(kind)

    def _apply(*_):
        cfg_new = _load_cfg()
        for kind in ("upcoming", "media"):
            cfg_new.setdefault(kind, {})
            cfg_new[kind]["visible"] = checks[kind].get_active()
            cfg_new[kind]["x"] = int(rows[kind][0].get_value())
            cfg_new[kind]["y"] = int(rows[kind][1].get_value())
        _save_cfg(cfg_new)
        for kind in ("upcoming", "media"):
            _kill_widget(kind)
        for kind in ("upcoming", "media"):
            if cfg_new[kind]["visible"]:
                _spawn_widget(kind)
        win.destroy()

    def _nudge(kind, dx, dy):
        ix, iy = rows[kind]
        ix.set_value(int(ix.get_value()) + dx)
        iy.set_value(int(iy.get_value()) + dy)
        x, y, _, _ = canvas._boxes.get(kind, (0, 0, 0, 0))
        x = max(0, min(mon_w - WIDGET_SIZE[kind][0], x + dx))
        y = max(0, min(mon_h - WIDGET_SIZE[kind][1], y + dy))
        canvas._boxes[kind] = (x, y, WIDGET_SIZE[kind][0], WIDGET_SIZE[kind][1])
        canvas.queue_draw()

    for kind, (ix, iy) in rows.items():
        ix.connect("value-changed", lambda s, k=kind: (_set_draft(k),
                                                       canvas.queue_draw()))
        iy.connect("value-changed", lambda s, k=kind: (_set_draft(k),
                                                       canvas.queue_draw()))

    def _set_draft(kind):
        ix, iy = rows[kind]
        x, y, w, h = canvas._boxes.get(kind, (0, 0, 0, 0))
        target_x = min(max(int(ix.get_value()), 0), mon_w - w)
        target_y = min(max(int(iy.get_value()), 0), mon_h - h)
        canvas._boxes[kind] = (target_x, target_y, w, h)

    chk_up = checks["upcoming"]
    chk_me = checks["media"]
    chk_up.connect("toggled", lambda b, k="upcoming": _set_vis(k, b.get_active()))
    chk_me.connect("toggled", lambda b, k="media": _set_vis(k, b.get_active()))
    for kind in ("upcoming", "media"):
        canvas._visible[kind] = checks[kind].get_active()

    def _set_vis(kind, active):
        canvas._visible[kind] = active
        canvas.queue_draw()

    hb = Gtk.Box(spacing=8)
    hb.set_halign(Gtk.Align.END)
    save = Gtk.Button(label="Aplicar")
    save.get_style_context().add_class("primary")
    save.set_size_request(120, 32)
    cancel = Gtk.Button(label="Cancelar")
    cancel.set_size_request(90, 32)
    hb.pack_start(cancel, False, False, 0)
    hb.pack_start(save, False, False, 0)
    vb.pack_start(hb, False, False, 0)

    save.connect("clicked", _apply)
    cancel.connect("clicked", lambda *_: win.destroy())
    win.connect("destroy",
                lambda *_: (pid.unlink(missing_ok=True), Gtk.main_quit()))
    pid.write_text(str(os.getpid()))
    win.show_all()
    canvas._resize()
    Gtk.main()


# ═════════════════════ MENÚ CONTEXTUAL ═════════════════════════════════
class _DesktopMenu(Gtk.Window):
    """Menú tipo Windows que aparece al click derecho del escritorio."""

    def __init__(self, gx, gy):
        super().__init__(title="haku-menu")
        _make_shell(self, "menu", 0, 0,
                    layer=GtkLayerShell.Layer.TOP)
        self._mon_orig, mon = _mon_origin(self)
        if mon:
            GtkLayerShell.set_monitor(self, mon)
        for e in GtkLayerShell.Edge:
            GtkLayerShell.set_anchor(self, e, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 0)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.LEFT, 0)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU)

        overlay = Gtk.EventBox()
        overlay.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
        overlay.get_style_context().add_class("canvas-frame")
        self.add(overlay)

        fixed = Gtk.Fixed()
        overlay.add(fixed)

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        card.get_style_context().add_class("wcard")
        card.set_margin_top(8); card.set_margin_bottom(8)
        card.set_margin_left(10); card.set_margin_right(10)
        card.set_size_request(230, -1)

        ti = lbl("Escritorio", "title", 15)
        ti.set_halign(Gtk.Align.START)
        card.pack_start(ti, False, False, 0)
        sep = Gtk.Separator()
        sep.override_color(Gtk.StateFlags.NORMAL, Gdk.RGBA(1, 1, 1, 0.08))
        card.pack_start(sep, False, False, 0)

        cfg = _load_cfg()
        for kind in ("upcoming", "media"):
            chk = Gtk.CheckButton(
                label=f"Mostrar {WIDGET_NAMES[kind]}")
            chk.set_active(bool(cfg.get(kind, {}).get("visible", False)))
            chk.get_style_context().add_class("menu-item")
            chk.connect("toggled", self._on_vis_toggle, kind)
            card.pack_start(chk, False, False, 0)

        edit = Gtk.Button(label="✎  Editar widgets (mover · mostrar · posición)")
        edit.get_style_context().add_class("primary")
        edit.set_size_request(-1, 36)
        edit.connect("clicked", lambda *_: self._choose_edit())
        edit.set_margin_top(6)
        card.pack_start(edit, False, False, 0)

        fixed.put(card, int(gx - self._mon_orig[0]), int(gy - self._mon_orig[1]))
        self._card = card
        self._fixed = fixed
        self.connect("key-press-event",
                     lambda w, e: (self._close(), True) if e.keyval == 0xFF1B else False)
        overlay.connect("button-press-event", self._on_outside)
        self._closing = False
        _fade_in(self, 140)
        self.show_all()

    def _on_outside(self, w, ev):
        try:
            ax, ay = ev.x_root - self._mon_orig[0], ev.y_root - self._mon_orig[1]
            cx, cy = self._fixed.child_get(self._card, "x", "y")
            cw, ch = self._card.get_allocation().width, self._card.get_allocation().height
            if cx[0] <= ax <= cx[0] + cw and cy[0] <= ay <= cy[0] + ch:
                return False
        except Exception:
            pass
        self._close()
        return True

    def _on_vis_toggle(self, chk, kind):
        if chk.get_active():
            _spawn_widget(kind)
        else:
            _kill_widget(kind)

    def _choose_edit(self):
        self._close(open_editor=True)

    def _close(self, open_editor=False):
        if self._closing:
            return
        self._closing = True
        if open_editor:
            def _after():
                try:
                    self.destroy()
                except Exception:
                    pass
                Gtk.main_quit()
                subprocess.Popen([sys.executable, str(SELF), "edit"])
            _fade(self, 0.0, 140, done=_after)
        else:
            _fade(self, 0.0, 140, done=lambda: (self.destroy(),
                                                Gtk.main_quit()))


def _run_desktop_menu(gx, gy):
    _css_load()
    pid = HOME / ".cache/haku_widget.menu.pid"
    if pid.exists():
        try:
            os.kill(int(pid.read_text()), signal.SIGTERM)
        except (OSError, ValueError):
            pass
        pid.unlink(missing_ok=True)
        return
    win = _DesktopMenu(gx, gy)
    pid.write_text(str(os.getpid()))
    Gtk.main()
    pid.unlink(missing_ok=True)


# ═════════════════════ CATCHER DE CLICK DERECHO ═════════════════════
class _DesktopCatcher(Gtk.Window):
    """Surface transparente a pantalla completa que captura el click derecho
    sobre el escritorio y abre el menú contextual."""

    def __init__(self):
        super().__init__(title="haku-desktop")
        self.set_app_paintable(True)
        self.connect("draw", lambda w, cr: False)
        GtkLayerShell.init_for_window(self)
        mon = _pick_monitor(self)
        if mon:
            GtkLayerShell.set_monitor(self, mon)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.BACKGROUND)
        GtkLayerShell.set_exclusive_zone(self, -1)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)
        for e in GtkLayerShell.Edge:
            GtkLayerShell.set_anchor(self, e, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 0)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_type_hint(Gdk.WindowTypeHint.DESKTOP)
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK |
                        Gdk.EventMask.BUTTON_RELEASE_MASK)
        self.connect("button-press-event", self._on_press)
        self.connect("button-release-event", self._on_release)
        self._menu_spawning = False
        self.show_all()

    def _on_press(self, w, ev):
        if ev.button == 3 and not self._menu_spawning:
            self._menu_spawning = True
            subprocess.Popen([sys.executable, str(SELF), "menu",
                              str(int(ev.x_root)), str(int(ev.y_root))])
            GLib.timeout_add(250, self._clear_spawn)
            return True
        return False

    def _clear_spawn(self):
        self._menu_spawning = False
        return False

    def _on_release(self, w, ev):
        return True


def _run_desktop_catcher():
    _css_load()
    pid = HOME / ".cache/haku_widget.desktop.pid"
    if pid.exists():
        try:
            os.kill(int(pid.read_text()), signal.SIGTERM)
        except (OSError, ValueError):
            pass
        pid.unlink(missing_ok=True)
        return
    win = _DesktopCatcher()
    pid.write_text(str(os.getpid()))
    Gtk.main()
    pid.unlink(missing_ok=True)


# ═════════════════════ MAIN ═════════════════════════════════════════
def _refresh_visible():
    cfg = _load_cfg()
    for kind in ("upcoming", "media"):
        if cfg.get(kind, {}).get("visible", False) and not _pidfile(kind).exists():
            _spawn_widget(kind)


def _main():
    args = sys.argv[1:]
    if not args:
        _refresh_visible()
        return
    cmd = args[0]
    if cmd == "--all":
        _spawn_widget("upcoming")
        _spawn_widget("media")
        return
    if cmd == "show":
        # Invocado por _spawn_widget: ejecuta el widget directamente.
        kind, x, y = args[1], int(args[2]), int(args[3])
        _css_load()
        pid = _pidfile(kind)
        win = MediaWidget(x, y) if kind == "media" else UpcomingWidget(x, y)
        pid.write_text(str(os.getpid()))
        try:
            Gtk.main()
        finally:
            pid.unlink(missing_ok=True)
        return
    if cmd == "edit":
        _open_editor()
        return
    if cmd == "desktop":
        _run_desktop_catcher()
        return
    if cmd == "menu":
        glib = GLib.MainLoop()
        _run_desktop_menu(int(args[1]), int(args[2]))
        return
    if cmd in ("upcoming", "media"):
        _toggle(cmd)
        return


if __name__ == "__main__":
    _main()