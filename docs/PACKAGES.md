# Packages

The package lists reflect the reference install and are re-exported from it whenever packages change, so a fresh install mirrors the same set:

| Source | Count |
|---|---|
| Official (pacman) | 158 |
| AUR (yay) | 21 |
| Flatpak | 2 |

Lists are stored in `packages/{pacman,aur,flatpak}.txt` and restored on fresh installs with **per-app granularity** — no unwanted bulk installs. Re-export them after adding/removing packages with `tools/regenerate-package-lists.sh` (see [TOOLS.md](TOOLS.md)).
