#!/usr/bin/env bash
# Close window — tries QS first (for confirm dialog), falls back to the
# active compositor (niri or Hyprland).
#
# Race condition protection:
# 1. We capture the focused window ID/address immediately (before spawn latency can shift focus).
# 2. If IPC fails/times out, we close the *captured* window by ID — not whatever is
#    focused at fallback time.
# 3. Because both paths target the same window by ID, an accidental double-close is a
#    harmless no-op instead of killing a random window.

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
launcher_path="$script_dir/inir"

# Detect the active compositor (mirrors scripts/inir detect_compositor_service).
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    compositor="hyprland"
elif [[ -n "${NIRI_SOCKET:-}" ]]; then
    compositor="niri"
elif command -v hyprctl >/dev/null 2>&1 && hyprctl activewindow >/dev/null 2>&1; then
    compositor="hyprland"
elif command -v niri >/dev/null 2>&1 && niri msg focused-window >/dev/null 2>&1; then
    compositor="niri"
else
    compositor=""
fi

# Capture focused window immediately — this is the window the user intended to close.
focused_id=""
focused_app_id=""
if [[ "$compositor" = "niri" ]]; then
    focused_window_json=$(niri msg -j focused-window 2>/dev/null)
    focused_id=$(printf '%s' "$focused_window_json" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    focused_app_id=$(printf '%s' "$focused_window_json" | grep -o '"app_id":"[^"]*"' | sed 's/"app_id":"\([^"]*\)"/\1/')
elif [[ "$compositor" = "hyprland" ]]; then
    # Hyprland: focused window address + class are what we need to close later.
    focused_window_json=$(hyprctl activewindow -j 2>/dev/null)
    focused_address=$(printf '%s' "$focused_window_json" | grep -oE '"address"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')
    focused_app_id=$(printf '%s' "$focused_window_json" | grep -oE '"class"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')
    # Hyprland ids its windows by address; empty address means no window focused.
    focused_app_id="${focused_app_id:-}"
fi

close_focused() {
    if [ "${focused_app_id,,}" = "spotify" ]; then
        # Keep Spotify running but hide its window from current workspace.
        if [[ "$compositor" = "niri" && -n "$focused_id" ]]; then
            niri msg action move-window-to-workspace --window-id "$focused_id" --focus false 99 >/dev/null 2>&1
            return 0
        elif [[ "$compositor" = "hyprland" && -n "$focused_address" ]]; then
            hyprctl eval "hl.dispatch(hl.dsp.window.move({workspace = 99, follow = false, window = 'address:$focused_address'}))" >/dev/null 2>&1
            return 0
        fi
    fi

    if [[ "$compositor" = "niri" ]]; then
        if [ -n "$focused_id" ]; then
            niri msg action close-window --id "$focused_id"
        else
            niri msg action close-window
        fi
    elif [[ "$compositor" = "hyprland" ]]; then
        if [ -n "$focused_address" ]; then
            hyprctl eval "hl.dispatch(hl.dsp.window.close({window = 'address:$focused_address'}))"
        else
            hyprctl eval 'hl.dispatch(hl.dsp.window.close())'
        fi
    fi
}

# If QS is not running, close directly using the captured ID.
if ! pgrep -x qs >/dev/null 2>&1 && ! pgrep -x quickshell >/dev/null 2>&1; then
    close_focused
    exit 0
fi

# QS is running — pass the snapshot through IPC so confirmation and fast-close
# use the same window that was focused when the keybind fired.
if [[ "$compositor" = "niri" && -n "$focused_id" ]]; then
    ipc_args=(closeConfirm triggerWindow "$focused_id" "$focused_app_id")
elif [[ "$compositor" = "hyprland" && -n "$focused_address" ]]; then
    # For Hyprland, pass the captured address straight to QS so CloseConfirm
    # closes exactly what the user intended (QS's activeToplevel can be stale).
    ipc_args=(closeConfirm triggerAddress "$focused_address" "$focused_app_id")
else
    ipc_args=(closeConfirm trigger)
fi
if timeout 1 "$launcher_path" "${ipc_args[@]}" 2>/dev/null; then
    exit 0
fi

# Fallback — IPC failed or timed out. Close the originally captured window.
close_focused