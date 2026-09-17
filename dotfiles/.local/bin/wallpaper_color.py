#!/usr/bin/env python3
import sys, os, json, subprocess
from pathlib import Path

INIR_COLOR = os.path.expanduser("~/.config/quickshell/inir/scripts/wallpaper-color.py")
CACHE = os.path.expanduser("~/.cache/wallpaper_colors.json")
WALL_DIR = os.path.expanduser("~/Pictures/Wallpapers/all")

# Nombres de los 10 grupos del coverflow (0-9 + 99=Black + 100=White)
GROUP_NAMES = [
    "Red", "Orange", "Yellow", "Green", "Cyan",
    "Blue", "Violet", "Purple", "Pink", "Brown",
]
HUE_BLACK = 99
HUE_WHITE = 100

SWATCH = {
    "Red":     "#e53935",
    "Orange":  "#f57c00",
    "Yellow":  "#fbc02d",
    "Green":   "#43a047",
    "Cyan":    "#00acc1",
    "Blue":    "#1e88e5",
    "Violet":  "#8e24aa",
    "Purple":  "#7b1fa2",
    "Pink":    "#d81b60",
    "Brown":   "#8d6e63",
    "Black":   "#111111",
    "White":   "#f5f5f5",
}

def name_for(hue):
    if hue == HUE_BLACK: return "Black"
    if hue == HUE_WHITE: return "White"
    if 0 <= hue < 10: return GROUP_NAMES[hue]
    return None

def tone_filter_matches(c, query):
    if not query:
        return True
    sat = c.get("sat", 0.0)
    lit = c.get("lit", 0.0)
    for t in query.split(","):
        t = t.strip()
        if t == "light": return lit >= 0.58
        if t == "mid": return 0.34 < lit < 0.58
        if t == "dark": return lit <= 0.34
        if t == "vivid": return sat >= 0.45
        if t == "muted": return sat < 0.45
    return True

VIDEO_EXTS = {".mp4", ".webm", ".mkv", ".avi", ".mov", ".m4v"}
ANIM_EXTS = {".gif"}
def type_matches(rel, ftype):
    ext = os.path.splitext(rel)[1].lower()
    if ftype == "IMG": return ext not in VIDEO_EXTS and ext not in ANIM_EXTS
    if ftype == "VID": return ext in VIDEO_EXTS
    if ftype == "GIF": return ext in ANIM_EXTS
    return True

def ensure_cache(force=False):
    if not force and os.path.exists(CACHE) and os.path.getsize(CACHE) > 0:
        return
    paths = []
    for root, _, fns in os.walk(WALL_DIR):
        for fn in fns:
            ext = Path(fn).suffix.lower()
            if ext in {".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif", ".mp4", ".webm", ".mkv"}:
                paths.append(os.path.join(root, fn))
    data = {}
    batch = []
    for p in paths:
        batch.append(p)
        if len(batch) >= 200:
            run_batch(batch, data)
            batch = []
    if batch:
        run_batch(batch, data)
    json.dump(data, open(CACHE, "w"))
    print(f"cache generada ({len(data)} archivos)", file=sys.stderr)

def run_batch(batch, data):
    try:
        out = subprocess.run(
            ["python3", INIR_COLOR] + batch,
            capture_output=True, text=True)
        for line in out.stdout.splitlines():
            try:
                path, rest = line.split("\t", 1)
                info = json.loads(rest)
                rel = os.path.relpath(path, WALL_DIR)
                data[rel] = info
            except Exception:
                continue
        json.dump(data, open(CACHE, "w"))
        print(f"procesados {len(data)}...", file=sys.stderr, flush=True)
    except Exception as e:
        print(f"error batch: {e}", file=sys.stderr)

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "cats"
    if cmd == "rebuild":
        ensure_cache(force=True)
        return
    ensure_cache()
    data = json.load(open(CACHE))
    if cmd == "cats":
        seen = set()
        for rel, c in data.items():
            nm = name_for(c.get("hue", -1))
            if nm: seen.add(nm)
        print("\n".join(sorted(seen)))
    elif cmd == "list":
        target = sys.argv[2]
        thumbs = os.path.expanduser("~/.cache/wallpapers/thumbs")
        for rel, c in data.items():
            nm = name_for(c.get("hue", -1))
            if nm != target: continue
            src = os.path.join(WALL_DIR, rel)
            stem = os.path.splitext(os.path.basename(rel))[0]
            thumb = os.path.join(thumbs, stem + ".png")
            icon = thumb if os.path.exists(thumb) else src
            print(f"{rel}\0icon\x1f{icon}")
    elif cmd == "listall":
        thumbs = os.path.expanduser("~/.cache/wallpapers/thumbs")
        for rel, c in data.items():
            src = os.path.join(WALL_DIR, rel)
            stem = os.path.splitext(os.path.basename(rel))[0]
            thumb = os.path.join(thumbs, stem + ".png")
            icon = thumb if os.path.exists(thumb) else src
            print(f"{rel}\0icon\x1f{icon}")
    elif cmd == "name":
        # devolver nombre del color para un hue
        print(name_for(int(sys.argv[2])))

if __name__ == "__main__":
    main()