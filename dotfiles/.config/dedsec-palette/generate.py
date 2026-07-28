#!/usr/bin/env python3
"""D̷E̷D̷S̷E̷C̷ Color Generator — Maximum harmonious palette from color theory."""

import random

def hsl_to_hex(h, s, l):
    """Convert HSL (0-360, 0-100, 0-100) to hex."""
    h = h % 360
    s = max(0, min(100, s)) / 100
    l = max(0, min(100, l)) / 100

    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = l - c / 2

    if h < 60: r, g, b = c, x, 0
    elif h < 120: r, g, b = x, c, 0
    elif h < 180: r, g, b = 0, c, x
    elif h < 240: r, g, b = 0, x, c
    elif h < 300: r, g, b = x, 0, c
    else: r, g, b = c, 0, x

    r = int((r + m) * 255)
    g = int((g + m) * 255)
    b = int((b + m) * 255)
    return f"#{r:02X}{g:02X}{b:02X}"


def mid_hue(h1, h2):
    """Average of two hues, handling wraparound."""
    if abs(h1 - h2) > 180:
        return ((h1 + h2 + 360) // 2) % 360
    return (h1 + h2) // 2


def generate_palette():
    """Generate a 36-color harmonious palette from a single base hue."""
    base = random.randint(0, 359)

    # ── Derived hues ───────────────────────────────────────────
    comp     = (base + 180) % 360
    tri1     = (base + 120) % 360
    tri2     = (base + 240) % 360
    split1   = (base + 150) % 360
    split2   = (base + 210) % 360
    ano1     = (base + 30) % 360
    ano2     = (base - 30 + 360) % 360
    ano3     = (base + 60) % 360
    ano4     = (base - 60 + 360) % 360

    # Fixed hue targets for accent families (always same positions)
    red_h    = (comp + 340) % 360   # ~0° red
    orange_h = (red_h + 30) % 360   # ~30° orange
    yellow_h = (orange_h + 30) % 360
    green_h  = (tri1 + 20) % 360
    cyan_h   = split1
    blue_h   = (tri2 - 10 + 360) % 360
    indigo_h = (tri2 + 20) % 360
    pink_h   = mid_hue(base, red_h)
    mag_h    = (base + 300) % 360
    violet_h = (base + 270) % 360

    p = {}

    # ── Primary group ──────────────────────────────────────────
    p["primary"]       = hsl_to_hex(base, 80, 65)
    p["primary_dim"]   = hsl_to_hex(base, 60, 45)
    p["primary_dark"]  = hsl_to_hex(base, 50, 25)
    p["primary_light"] = hsl_to_hex(base, 70, 80)

    # ── Backgrounds ────────────────────────────────────────────
    p["bg"]            = hsl_to_hex(base, 30, 5)
    p["bg_alt"]        = hsl_to_hex(base, 35, 10)
    p["bg_light"]      = hsl_to_hex(base, 25, 15)

    # ── Foregrounds ────────────────────────────────────────────
    p["fg"]            = hsl_to_hex(base, 45, 85)
    p["fg_dim"]        = hsl_to_hex(base, 30, 50)

    # ── Borders ────────────────────────────────────────────────
    p["border"]        = hsl_to_hex(base, 40, 25)
    p["border_light"]  = hsl_to_hex(base, 35, 35)

    # ── Warm accents ───────────────────────────────────────────
    p["red"]           = hsl_to_hex(red_h, 85, 60)
    p["orange"]        = hsl_to_hex(orange_h, 85, 60)
    p["yellow"]        = hsl_to_hex(yellow_h, 90, 60)
    p["coral"]         = hsl_to_hex(mid_hue(red_h, orange_h), 80, 65)
    p["amber"]         = hsl_to_hex(mid_hue(orange_h, yellow_h), 85, 55)
    p["peach"]         = hsl_to_hex(mid_hue(red_h, base), 65, 75)
    p["rose"]          = hsl_to_hex((red_h + 340) % 360, 75, 65)

    # ── Cool accents ───────────────────────────────────────────
    p["green"]         = hsl_to_hex(green_h, 75, 55)
    p["teal"]          = hsl_to_hex(mid_hue(green_h, cyan_h), 75, 50)
    p["cyan"]          = hsl_to_hex(cyan_h, 75, 55)
    p["sky"]           = hsl_to_hex(mid_hue(cyan_h, blue_h), 70, 60)
    p["blue"]          = hsl_to_hex(blue_h, 70, 60)
    p["indigo"]        = hsl_to_hex(indigo_h, 65, 50)
    p["mint"]          = hsl_to_hex(mid_hue(green_h, ano1), 60, 70)

    # ── Purple accents ─────────────────────────────────────────
    p["magenta"]       = hsl_to_hex(mag_h, 80, 60)
    p["lavender"]      = hsl_to_hex(mid_hue(base, tri2), 55, 75)
    p["violet"]        = hsl_to_hex(violet_h, 70, 55)
    p["fuchsia"]       = hsl_to_hex(mid_hue(mag_h, comp), 75, 60)
    p["plum"]          = hsl_to_hex(mid_hue(mag_h, base), 50, 50)

    # ── Neons ──────────────────────────────────────────────────
    p["neon_green"]    = hsl_to_hex(green_h, 95, 55)
    p["neon_cyan"]     = hsl_to_hex(cyan_h, 95, 55)
    p["neon_pink"]     = hsl_to_hex(pink_h, 90, 60)
    p["neon_yellow"]   = hsl_to_hex(yellow_h, 95, 55)

    # ── Muted tones ────────────────────────────────────────────
    p["gray"]          = hsl_to_hex(base, 8, 50)
    p["slate"]         = hsl_to_hex(base, 15, 40)
    p["stone"]         = hsl_to_hex((base + 40) % 360, 12, 45)
    p["ash"]           = hsl_to_hex(base, 5, 30)

    return p


# All keys in display order
ALL_KEYS = [
    # Primary
    "primary", "primary_dim", "primary_dark", "primary_light",
    # Backgrounds
    "bg", "bg_alt", "bg_light",
    # Foregrounds
    "fg", "fg_dim",
    # Borders
    "border", "border_light",
    # Warm
    "red", "orange", "yellow", "coral", "amber", "peach", "rose",
    # Cool
    "green", "teal", "cyan", "sky", "blue", "indigo", "mint",
    # Purple
    "magenta", "lavender", "violet", "fuchsia", "plum",
    # Neon
    "neon_green", "neon_cyan", "neon_pink", "neon_yellow",
    # Muted
    "gray", "slate", "stone", "ash",
]


def format_palette(palette, name="Randomized"):
    lines = [f"# D̷E̷D̷S̷E̷C̷ Palette — {name}"]
    for key in ALL_KEYS:
        lines.append(f"{key}={palette[key]}")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    print(format_palette(generate_palette()))
