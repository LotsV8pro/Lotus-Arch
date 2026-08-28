#!/usr/bin/env python3
"""Auto-sync Wallpaper Engine workshop videos into the wallpaper selector's
`all/` folder. Adds newly-downloaded videos and removes ones whose source
workshop item was unsubscribed (deleted from the Steam cache).

- Only REAL video wallpapers (.mp4/.webm/.mkv/.avi/.mov) are synced; tiny
  low-res preview.gif thumbnails are ignored.
- A manifest maps each target filename -> source path so files not sourced
  from Wallpaper Engine are never deleted.
"""
import json
import os
import shutil
import sys
from pathlib import Path

HOME = Path.home()
WE_DIR = Path(os.environ.get("WE_SYNC_WE_DIR",
                             HOME / ".local/share/Steam/steamapps/workshop/content/431960"))
DEST_DIR = Path(os.environ.get("WE_SYNC_DEST", HOME / "Pictures/Wallpapers/all"))
STATE_DIR = Path(os.environ.get("WE_SYNC_STATE", HOME / ".local/state/we-wallpaper-sync"))
MANIFEST = STATE_DIR / "manifest.json"

VIDEO_EXTS = {".mp4", ".webm", ".mkv", ".avi", ".mov"}
SKIP_NAMES = {"preview.gif", "preview.png", "preview.jpg", "thumbnail.gif",
              "thumbnail.png", "thumbnail.jpg"}


def log(msg: str) -> None:
    print(f"[we-sync] {msg}")


def load_manifest() -> dict:
    if MANIFEST.exists():
        try:
            return json.loads(MANIFEST.read_text())
        except Exception:
            return {}
    return {}


def unique_name(dest: Path, base: str) -> str:
    """Return a non-colliding filename in dest."""
    if not (dest / base).exists():
        return base
    stem, ext = os.path.splitext(base)
    i = 1
    while (dest / f"{stem}-{i}{ext}").exists():
        i += 1
    return f"{stem}-{i}{ext}"


def discover_sources() -> list:
    if not WE_DIR.is_dir():
        return []
    out = []
    for p in sorted(WE_DIR.rglob("*")):
        if not p.is_file():
            continue
        if p.suffix.lower() not in VIDEO_EXTS:
            continue
        if p.name.lower() in SKIP_NAMES:
            continue
        if p.stat().st_size == 0:
            continue  # broken/empty placeholder (e.g. Wallpaper Engine "video.webm")
        out.append(p)
    return out


def main() -> None:
    if not WE_DIR.is_dir():
        log(f"WE cache not found: {WE_DIR}")
        return 0

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    DEST_DIR.mkdir(parents=True, exist_ok=True)

    manifest = load_manifest()
    sources = discover_sources()
    source_set = {str(s) for s in sources}

    new_manifest = {}
    added = 0

    for src in sources:
        base = src.name
        tgt = base
        target = DEST_DIR / tgt
        if target.exists():
            # Target basename already present. If no other source claims this name
            # yet, treat the existing file as already synced from this source
            # (covers seeding from the previously-copied videos).
            if tgt not in new_manifest:
                new_manifest[tgt] = str(src)
                continue
            # Claimed by a different source -> disambiguate with a numeric suffix.
            tgt = unique_name(DEST_DIR, base)
            target = DEST_DIR / tgt
        if not target.exists():
            shutil.copy2(src, target)
            added += 1
        new_manifest[tgt] = str(src)

    removed = 0
    for tgt, src_path in manifest.items():
        if src_path not in source_set:
            target = DEST_DIR / tgt
            if target.exists():
                try:
                    target.unlink()
                    removed += 1
                except OSError:
                    pass
        else:
            new_manifest[tgt] = src_path

    MANIFEST.write_text(json.dumps(new_manifest, indent=2, sort_keys=True))

    log(f"WE videos synced: +{added} added, -{removed} removed ({len(sources)} sources).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
