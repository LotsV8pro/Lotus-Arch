#!/bin/bash
# Limit ALL fossilize_replay processes to 50% CPU — instant catch
declare -A managed

cleanup_managed() {
    for pid in "${!managed[@]}"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            unset managed[$pid]
        fi
    done
}

while true; do
    cleanup_managed
    for pid in $(pgrep -x fossilize_repla 2>/dev/null); do
        if [[ -z "${managed[$pid]}" ]] || ! kill -0 "${managed[$pid]}" 2>/dev/null; then
            "$HOME/.local/bin/cpulimit" -p "$pid" -l 50 -z 2>/dev/null &
            managed[$pid]=$!
        fi
    done
    sleep 2
done
