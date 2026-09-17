from colorthief import ColorThief
import json
import os
import re
import sys

_QUICKSHELL_PALETTE = os.path.expanduser(
    "~/.local/state/quickshell/user/generated/colors.json")
_HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")


def _palette_primary():
    try:
        with open(_QUICKSHELL_PALETTE) as f:
            data = json.load(f)
        for key in ("primary", "primary_fixed", "tertiary"):
            value = data.get(key)
            if isinstance(value, str) and _HEX_RE.match(value):
                return value.lower()
    except Exception:
        pass
    return None


primary = _palette_primary()
if primary:
    print(primary)
    sys.exit(0)

colors = ColorThief(sys.argv[1]).get_palette(color_count=5)
brightest = max(colors, key=lambda c: sum(v * v for v in c))

print("#%02x%02x%02x" % brightest)