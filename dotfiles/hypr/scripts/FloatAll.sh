#!/usr/bin/env bash
# Emulates classic `workspaceopt allfloat` (removed in Hyprland's Lua API):
# toggles floating for every window on the active workspace.
# Note: unlike workspaceopt, windows spawned afterwards follow normal rules.

ACTIVE_WS=$(hyprctl activeworkspace -j | jq -r '.id')

hyprctl clients -j | jq -r --argjson WS "$ACTIVE_WS" '.[] | select(.workspace.id == $WS) | .address' |
while read -r addr; do
    hyprctl dispatch "hl.dsp.window.float({ action = \"toggle\", window = \"address:${addr}\" })" >/dev/null 2>&1
done
