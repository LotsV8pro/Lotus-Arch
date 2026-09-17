#!/usr/bin/env python3
import sys, os, subprocess, pathlib

THUMB_DIR = os.path.expanduser("~/.cache/wallpapers/thumbs")
THUMB_W, THUMB_H = 480, 300

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".avif", ".bmp", ".tiff"}
VIDEO_EXTS = {".mp4", ".mkv", ".webm", ".mov", ".m4v"}
ANIM_EXTS = {".gif"}

def thumb_path(src):
    h = pathlib.Path(src).stem
    return os.path.join(THUMB_DIR, h + ".png")

def make_thumb(src):
    os.makedirs(THUMB_DIR, exist_ok=True)
    dst = thumb_path(src)
    if os.path.exists(dst) and os.path.getsize(dst) > 0:
        return dst
    ext = pathlib.Path(src).suffix.lower()
    geom = f"{THUMB_W}x{THUMB_H}^"
    tmp = dst + ".tmp.png"
    try:
        if ext in IMAGE_EXTS or ext in ANIM_EXTS:
            subprocess.run(
                ["magick", src, "-resize", geom, "-gravity", "center",
                 "-extent", f"{THUMB_W}x{THUMB_H}", tmp],
                capture_output=True, timeout=30)
        elif ext in VIDEO_EXTS:
            subprocess.run(
                ["ffmpeg", "-y", "-loglevel", "error", "-i", src,
                 "-vf", f"thumbnail,scale={THUMB_W}:{THUMB_H}:force_original_aspect_ratio=increase,crop={THUMB_W}:{THUMB_H}",
                 "-frames:v", "1", tmp],
                capture_output=True, timeout=30)
        else:
            return src
        if os.path.exists(tmp) and os.path.getsize(tmp) > 0:
            os.replace(tmp, dst)
            return dst
    except Exception:
        pass
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)
    return src

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "all":
        wd = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/Pictures/Wallpapers/all")
        exts = IMAGE_EXTS | VIDEO_EXTS | ANIM_EXTS
        files = [os.path.join(root, fn)
                 for root, _, fns in os.walk(wd)
                 for fn in fns if pathlib.Path(fn).suffix.lower() in exts]
        done = 0
        for f in files:
            if os.path.exists(thumb_path(f)):
                continue
            make_thumb(f)
            done += 1
            if done % 20 == 0:
                print(f"thumbs {done}/{len(files)}", file=sys.stderr, flush=True)
        print(f"DONE total={len(files)} nuevo={done}", file=sys.stderr)
    else:
        print(make_thumb(sys.argv[1]))