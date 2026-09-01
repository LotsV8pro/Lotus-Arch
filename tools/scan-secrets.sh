#!/bin/bash
# Scans the repo working tree for common secrets / personal data before
# committing. Exit code 1 if anything suspicious is found.
# Usage: bash tools/scan-secrets.sh [path]

set -euo pipefail

SCAN_ROOT="${1:-.}"

SECRET_PATTERNS=(
    'autologin\.'
    'connect\.mdns_devices=.+"public_ip'
    'OBS_WS_PASSWORD\s*=\s*"'
    '"server_password"\s*:\s*"..+"'
    '"tmdb_api_key"\s*:\s*"..+"'
    'AIza[0-9A-Za-z_-]{30,}'
    'AKIA[0-9A-Z]{16}'
    '-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY'
    'ghp_[0-9A-Za-z]{30,}'
    'github_pat_[0-9A-Za-z_]{20,}'
    'xox[baprs]-[0-9A-Za-z-]{10,}'
    'sk-[0-9A-Za-z]{20,}'
)

RISK_FILES=(
    '*Cookies'
    '*Cookies-journal'
    '*Login Data*'
    '*History'
    '*.sqlite*'
    '*Network Action Predictor*'
    '*Web Data*'
    '*.key'
    '*.pem'
    '*.p12'
    '*.pfx'
)

FAILED=0

echo "── Secret patterns ──"
for pat in "${SECRET_PATTERNS[@]}"; do
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        echo "  [!] $f matches: $pat"
        FAILED=1
    done < <(rg -l "$pat" "$SCAN_ROOT" --hidden -g '!.git' -g '!*.png' -g '!*.jpg' -g '!*.wav' -g '!*.mp3' 2>/dev/null || true)
done

echo "── High-risk files ──"
for pat in "${RISK_FILES[@]}"; do
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        echo "  [!] $f (browser/app database)"
        FAILED=1
    done < <(find "$SCAN_ROOT" -path '*/\.git' -prune -o -name "$pat" -print 2>/dev/null)
done

echo "── Personal paths ──"
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
        *README.md|*06-dotfiles.sh|*tools/scan-secrets.sh|*release-v[0-9]*.md) continue ;;
    esac
    echo "  [!] $f contains @HOME@"
    FAILED=1
done < <(rg -l "@HOME@" "$SCAN_ROOT" --hidden -g '!.git' 2>/dev/null || true)

echo "── Personal symlinks ──"
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    target="$(readlink "$f")"
    if [[ "$target" == /* ]] && [[ "$target" != *"/dotfiles-backup/"* ]]; then
        echo "  [!] $f is an absolute symlink -> $target (machine-specific)"
        FAILED=1
    fi
done < <(find "$SCAN_ROOT" -path '*/\.git' -prune -o -type l -print 2>/dev/null)

if [[ "$FAILED" -eq 0 ]]; then
    echo "  OK — no secrets or personal data found."
else
    echo ""
    echo "  ✗ Review the items above before committing."
fi

exit "$FAILED"
