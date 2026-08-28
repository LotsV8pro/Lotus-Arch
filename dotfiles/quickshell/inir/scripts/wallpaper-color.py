#!/usr/bin/env python3
"""Predominant-color analysis for the iniR wallpaper selector (named colors).

Reads one wallpaper path per line from stdin, and for each prints:
    <path>\t{"hue": <0-9|99|100>, "sat": <0-1>, "lit": <0-1>, "share": <0-1>}

where hue is:  0-9  one of the 10 named colors (9 = Brown)
              100  White (light monochrome wallpapers)
               99  Black (dark monochrome wallpapers)

Rules (per-pixel HSV sampling):

1. A pixel counts as "colored" when its saturation >= SAT_MONO (a low floor,
   so pale pastels still count as their colour) and value >= VAL_MIN.
   Grayscale/black/white pixels have ~0 saturation and are not "colored".

2. Colored pixels are binned into 36 fine hue buckets (10 deg) then grouped:
     Red   0-20 and 350-360 (pure red + deep crimson, never leaks into Pink)
     Orange 20-50, Yellow 50-60 (pure, narrow)
     Green 60-160 (starts early, so yellow-green / lime walls are never Yellow)
     Cyan 160-210, Blue 210-270, Violet 270-290,
     Pink 290-350 (light purple + rose/magenta)

3. Decide the dot:
   a. "Monochrome" = a wallpaper that basically has no colour (colored_share
      < MONO_MIN). Split it by mean brightness: White (100) if light, else
      Black (99). This keeps Black, White reserved for true black/white/gray.
   b. Otherwise it is a colour wallpaper: name its dominant colour (multi-
      colour walls still get their leading colour, so they are not dumped
      into Black/White). A low DOM_MIN keeps pastel and multi-tone walls
      labelled; a wall that is mostly neutral with a tiny color accent has a
      low colored_share and falls under (a) instead.
   c. If the dominant colour is a WARM hue (Red/Orange/Yellow) but its mean
      saturation*value intensity is below BROWN_INT, it reads as brown, tan,
      beige or earth-tone (gruvbox/coffee etc.) rather than that colour: it
      is labelled Brown (9). Saturated reds/oranges/yellows keep their hue.
"""
import sys, subprocess, colorsys, json, os

SAT_MONO = 0.10  # per-pixel saturation floor: below this a pixel is grayscale
VAL_MIN = 0.16  # per-pixel brightness floor (excludes near-black)
MONO_MIN = 0.12  # if this share of ALL pixels is colored -> color wallpaper, else monochrome
WHITE_LIT = 0.62  # a monochrome image is White if mean brightness >= this, else Black
DOM_MIN = 0.08  # dominant color share of ALL pixels needed to name that color
BROWN_INT = 0.20  # warm dominant below this mean(sat*value) intensity reads as brown/tan
WARM_GROUPS = {0, 1, 2}  # Red, Orange, Yellow — low-intensity -> Brown
RES = 48  # sampling resolution (48x48 = 2304 pixels)
NBUCKETS = 36  # 36 fine hue families of 10 degrees each (finer boundary control)

# fine bucket (0..35, 10 deg each) -> named color group (0..8)
#   0 Red, 1 Orange, 2 Yellow, 3 Green, 4 Cyan, 5 Blue, 6 Violet, 7 Purple, 8 Pink
# Yellow is a single 50-60 bucket and green starts at 60 so yellow-green / lime
# walls always go to Green, never Yellow. Light purple (290-310) merges into
# Pink, which is 290-350 (rose/magenta/lilac), and Red wraps 0-20 and 350-360
# so deep crimson near 360° never leaks into Pink.
GROUP_MAP = [
    0, 0,             # 0-20   red (pure)      [+ wrap from 350-360 below]
    1, 1, 1,          # 20-50  orange (incl. amber)
    2,                # 50-60  yellow (pure, narrow)
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3,  # 60-160 green (incl. yellow-green)
    4, 4, 4, 4, 4,    # 160-210 cyan
    5, 5, 5, 5, 5, 5, # 210-270 blue
    6, 6,             # 270-290 violet
    8, 8, 8, 8, 8, 8, # 290-350 pink (light purple + rose/magenta)
    0,                # 350-360 deep red (wraps into Red)
]
NGROUPS = 10
HUE_BROWN = 9
HUE_WHITE = 100
HUE_BLACK = 99


VIDEO_EXTS = {".mp4", ".webm", ".mkv", ".avi", ".mov"}


def _pixels(path):
    """Downsample an image (or a representative frame of a video) to raw RGB.

    Videos are decoded with ffmpeg using the `thumbnail` filter, which picks the
    scene frame closest to the video's overall average. This avoids frame 0,
    which for most wallpaper loops is a black fade-in and would misclassify the
    whole video as Black.
    """
    if os.path.splitext(path)[1].lower() in VIDEO_EXTS:
        proc = subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", path,
             "-vf", f"thumbnail=n=200,scale={RES}:{RES}",
             "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
            capture_output=True)
        return proc.stdout
    proc = subprocess.run(
        ["convert", path, "-resize", f"{RES}x{RES}!", "-depth", "8", "rgb:-"],
        capture_output=True)
    return proc.stdout


def classify(path):
    try:
        data = _pixels(path)
        n = len(data) // 3
        if n == 0:
            return None
        # group -> [count, sum_s, sum_v, sum_sv]; also mean brightness
        grp = {}
        lit = 0.0
        for i in range(n):
            h, s, v = colorsys.rgb_to_hsv(
                data[i * 3] / 255.0, data[i * 3 + 1] / 255.0, data[i * 3 + 2] / 255.0)
            lit += v
            if s < SAT_MONO or v < VAL_MIN:
                continue  # grayscale / near-black pixel: no colour
            g = GROUP_MAP[int(h * NBUCKETS) % NBUCKETS]
            if g not in grp:
                grp[g] = [0, 0.0, 0.0, 0.0]
            grp[g][0] += 1
            grp[g][1] += s
            grp[g][2] += v
            grp[g][3] += s * v
        lit = lit / n
        colored = sum(v[0] for v in grp.values())
        colored_share = colored / float(n)

        # "Monochrome" = a wallpaper that basically has no colour (grayscale /
        # black / white). Split it by brightness: White (light) vs Black (dark).
        if colored_share < MONO_MIN:
            return {"hue": HUE_WHITE if lit >= WHITE_LIT else HUE_BLACK,
                    "sat": 0.0, "lit": round(lit, 3), "share": round(colored_share, 3)}

        # Colour wallpaper: name its dominant colour. Multi-colour wallpapers
        # (whose coloured pixels are split across hues) still get their leading
        # colour here rather than being dumped into Black. A low DOM_MIN keeps
        # pastel and multi-tone walls labelled, while a tiny accent on a mostly
        # neutral background stays monochrome above because coloured_share is
        # low. When the dominant colour is warm (Red/Orange/Yellow) but muddy
        # (low mean sat*value) it reads as tan/brown/earth-tone -> Brown.
        if grp:
            ranked = sorted(grp.items(), key=lambda kv: kv[1][0], reverse=True)
            (g, (cnt, ss, sv, ssv)) = ranked[0]
            s1 = cnt / float(n)
            if s1 >= DOM_MIN:
                intensity = (ssv / cnt) if cnt else 0.0
                if g in WARM_GROUPS and intensity < BROWN_INT:
                    g = HUE_BROWN
                return {"hue": int(g), "sat": round(min(ss / cnt, 1.0), 2),
                        "lit": round(sv / cnt, 3), "share": round(s1, 3)}

        return {"hue": HUE_WHITE if lit >= WHITE_LIT else HUE_BLACK,
                "sat": 0.0, "lit": round(lit, 3), "share": round(colored_share, 3)}
    except Exception:
        return None


def main():
    paths = sys.argv[1:] if len(sys.argv) > 1 else [l.strip() for l in sys.stdin if l.strip()]
    for path in paths:
        res = classify(path)
        if res is None:
            print(path + "\tERR")
        else:
            print(path + "\t" + json.dumps(res, separators=(",", ":")))


if __name__ == "__main__":
    main()
