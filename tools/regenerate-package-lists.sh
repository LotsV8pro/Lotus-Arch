#!/bin/bash
# Export the CURRENT machine's installed packages to packages/ so the repo
# always mirrors exactly what is installed. Run on the machine you want to
# replicate, then commit the changes.
#   bash tools/regenerate-package-lists.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGS_DIR="$SCRIPT_DIR/../packages"

mkdir -p "$PKGS_DIR"

# Foreign (AUR) packages — installed via yay/paru, not in official repos.
# Keep them ALL for the pacman exclusion; only drop yay itself + debug
# build from the published aur.txt (build tooling, not a real package).
AUR_LIST="$(yay -Qqm 2>/dev/null | sort)"

# Official packages: everything explicitly installed that isn't AUR.
# (keeps base/base-devel to match the original capture)
pacman -Qqe 2>/dev/null \
    | grep -vFxf <(printf '%s\n' "$AUR_LIST") \
    | sort > "$PKGS_DIR/pacman.txt"

printf '%s\n' "$AUR_LIST" | grep -vE '^yay(-bin)?(-debug)?$' | sed '/^$/d' > "$PKGS_DIR/aur.txt"

# Flatpak apps
flatpak list --app --columns=application 2>/dev/null | sort > "$PKGS_DIR/flatpak.txt"

echo "Regenerated package lists:"
wc -l "$PKGS_DIR/pacman.txt" "$PKGS_DIR/aur.txt" "$PKGS_DIR/flatpak.txt"
echo ""
echo "Review the diff and commit: git diff packages/"
