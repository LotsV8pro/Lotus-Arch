#!/usr/bin/env python3
import os, sys, json, time
from pathlib import Path

WALL_DIR = os.path.expanduser(os.environ.get("WALL_DIR", "~/Pictures/Wallpapers/all"))
CACHE = os.path.expanduser("~/.cache/wallpaper_colors.json")
EXTS = (".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif")

from colorthief import ColorThief

def brightness(c):
    return sum(v*v for v in c)

def load_cache():
    if os.path.exists(CACHE):
        try:
            return json.load(open(CACHE))
        except Exception:
            return {}
    return {}

def main():
    cache = load_cache()
    files = []
    for root, _, fnames in os.walk(WALL_DIR):
        for fn in fnames:
            if fn.lower().endswith(EXTS):
                files.append(os.path.join(root, fn))
    changed = 0
    for fp in files:
        rel = os.path.relpath(fp, WALL_DIR)
        if rel not in cache or not os.path.exists(cache[rel].get("path", "")):
            try:
                colors = ColorThief(fp).get_palette(color_count=5)
                b = max(colors, key=brightness)
                cache[rel] = {"path": fp, "hex": "#%02x%02x%02x" % b}
                changed += 1
            except Exception as e:
                cache[rel] = {"path": fp, "hex": None}
                changed += 1
            if changed % 50 == 0:
                json.dump(cache, open(CACHE, "w"))
                print(f"procesados {changed}/{len(files)}", file=sys.stderr)
    json.dump(cache, open(CACHE, "w"))
    print(f"DONE total={len(cache)} nuevo={changed}", file=sys.stderr)

if __name__ == "__main__":
    main()
