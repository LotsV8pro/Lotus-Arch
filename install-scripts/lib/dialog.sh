#!/bin/bash
# Dialog helpers for the Lotus installer.
# Uses whiptail when available (Clonezilla-style menu); falls back to plain
# read prompts otherwise. Set LOTUS_PLAIN=1 to force plain mode.

DIALOG_OK=0
DIALOG_CANCEL=1

have_dialog() {
    [[ -z "${LOTUS_PLAIN:-}" ]] && command -v whiptail &>/dev/null
}

# Ensure whiptail is present (best effort, needs sudo/root).
ensure_dialog() {
    if have_dialog; then return 0; fi
    command -v whiptail &>/dev/null && return 0
    if command -v pacman &>/dev/null; then
        if [[ ${EUID} -eq 0 ]]; then
            pacman -S --needed --noconfirm libnewt &>/dev/null || true
        else
            sudo -n pacman -S --needed --noconfirm libnewt &>/dev/null || true
        fi
    fi
    have_dialog
}

# confirm_dialog "title" "text" -> 0 yes, 1 no
confirm_dialog() {
    local title="$1" text="$2"
    if have_dialog; then
        whiptail --title "$title" --yesno "$text" 14 70 3>&1 1>&2 2>&3
        return $?
    fi
    echo "$text"
    read -r -p "  [y/N]: " ans
    [[ "$ans" =~ ^[Yy] ]] && return 0 || return 1
}

# menu_dialog "title" "text" "tag1" "desc1" "tag2" "desc2" ... -> prints chosen tag
menu_dialog() {
    local title="$1" text="$2"; shift 2
    if have_dialog; then
        local -a items=()
        while (($#)); do
            items+=("$1" "$2"); shift 2
        done
        whiptail --title "$title" --menu "$text" 20 78 10 "${items[@]}" 3>&1 1>&2 2>&3
        return $?
    fi
    echo "$text"
    local -a tags=()
    while (($#)); do
        echo "  $1) $2"; tags+=("$1"); shift 2
    done
    read -r -p "  Choice: " choice
    echo "$choice"
}
