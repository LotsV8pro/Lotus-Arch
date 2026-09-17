-- ─────────────────────────────────────────────────────────────────────────────
-- keybinding.lua — Hyprland keybinds (Lua) translated from Niri
-- Source: ~/.config/niri/config.d/70-binds.kdl
--
-- "Mod" = SUPER (Super on bare metal).
-- iNiR binds route through the `inir` launcher which talks to Quickshell
-- via IPC. Niri-native actions are translated to the closest Hyprland
-- dispatcher. Actions that have no Hyprland equivalent are skipped (commented).
-- ─────────────────────────────────────────────────────────────────────────────

local mainMod = "SUPER"

-- ═══════════════════════════════════════════════════════════════════════════
-- Session & compositor
-- ═══════════════════════════════════════════════════════════════════════════

-- Niri's built-in overview → inir overview toggle (works in both compositors).
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("inir overview toggle"))

-- Quit compositor (delayed so uwsm doesn't tear down the session instantly).
hl.bind(mainMod .. " + SHIFT + E", function() hl.dispatch(hl.dsp.exec_cmd("sleep 0.1 && hyprctl dispatch exit")) end)

-- Mod+Escape → toggle-keyboard-shortcuts-inhibit — SKIP (no Hyprland equivalent).

-- Power off all monitors; any input wakes them (DPMS via timer).
hl.bind(mainMod .. " + SHIFT + O", function()
    hl.timer(function() hl.dispatch(hl.dsp.dpms({ action = "disable" })) end, { timeout = 500, type = "oneshot" })
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- iNiR shell overlays & tools
-- ═══════════════════════════════════════════════════════════════════════════

-- Crosshair overlay toggle.
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("inir overlay toggle"))

-- iNiR app launcher / overview.
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("inir overview open"))

-- Clipboard history overlay.
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("inir clipboard toggle"))

-- Lock screen / re-focus lock surface (allow when locked).
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("inir lock activate"), { locked = true })
hl.bind(mainMod .. " + CTRL + SHIFT + L", hl.dsp.exec_cmd("inir lock focus"), { locked = true })

-- Region selector: screenshot / OCR / Google Lens search.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("inir region menu"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("inir region ocr"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("inir region search"))
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("inir region menu"))

-- Wallpaper picker, settings, cheatsheet, session/power dialog.
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("inir wallpaperSelector toggle"))
hl.bind(mainMod .. " + COMMA", hl.dsp.exec_cmd("inir settings"))
hl.bind(mainMod .. " + SLASH", hl.dsp.exec_cmd("inir cheatsheet toggle"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("inir session toggle"))

-- ═══════════════════════════════════════════════════════════════════════════
-- App launchers
-- ═══════════════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("inir terminal"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("inir terminal"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("inir browser"))

-- ═══════════════════════════════════════════════════════════════════════════
-- Window management
-- ═══════════════════════════════════════════════════════════════════════════

-- Close window (iNiR's close with confirmation dialog).
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("inir close-window"))

-- Maximize window (fills screen width, keeps gaps/bar).
hl.bind(mainMod .. " + SPACE", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- Fullscreen (app goes borderless edge-to-edge).
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Toggle floating / tiling.
hl.bind(mainMod .. " + A", hl.dsp.window.float({ action = "toggle" }))

-- Mod+Shift+V → switch-focus-between-floating-and-tiling — SKIP (no Hyprland equivalent).

-- Mod+R → switch-preset-column-width — SKIP (no column concept in Hyprland).

-- Screen recording — region select with audio.
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("inir region recordWithSound"))

-- Mod+Ctrl+R → reset-window-height — SKIP.

-- Center the focused window on screen.
hl.bind(mainMod .. " + C", hl.dsp.window.center())

-- ═══════════════════════════════════════════════════════════════════════════
-- Width/height adjustment (±10%)
-- ═══════════════════════════════════════════════════════════════════════════
-- Niri's set-column-width/set-window-height become relative resizes.
-- hl.dsp.window.resize requires BOTH x and y; compute ±10% of the window.

local function resizeStep(dx, dy)
    return function ()
        local w = hl.get_active_window()
        if not w then return end
        local x = dx ~= 0 and math.floor(w.size.x * dx) or 40 * dx
        local y = dy ~= 0 and math.floor(w.size.y * dy) or 40 * dy
        hl.dispatch(hl.dsp.window.resize({ x = x, y = y, relative = true }))
    end
end

hl.bind(mainMod .. " + MINUS",        resizeStep(-0.1, 0))
hl.bind(mainMod .. " + EQUAL",        resizeStep(0.1, 0))
hl.bind(mainMod .. " + SHIFT + MINUS", resizeStep(0, -0.1))
hl.bind(mainMod .. " + SHIFT + EQUAL", resizeStep(0, 0.1))

-- ═══════════════════════════════════════════════════════════════════════════
-- Consume/expel (Niri column stacking)
-- ═══════════════════════════════════════════════════════════════════════════
-- Mod+BracketLeft / Mod+BracketRight — SKIP (no column stacking in Hyprland).

-- ═══════════════════════════════════════════════════════════════════════════
-- Focus navigation (arrows + Vim keys)
-- ═══════════════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + LEFT",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + UP",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + DOWN",  hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))

-- Mod+Home / Mod+End — SKIP (focus-column-first/last, no column concept).

-- ═══════════════════════════════════════════════════════════════════════════
-- Move windows (arrows + Vim keys)
-- ═══════════════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + SHIFT + LEFT",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + UP",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + DOWN",  hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

-- Mod+Ctrl+Home / Mod+Ctrl+End — SKIP (move-column-to-first/last).

-- ═══════════════════════════════════════════════════════════════════════════
-- Multi-monitor
-- ═══════════════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + CTRL + LEFT",  hl.dsp.focus({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + RIGHT", hl.dsp.focus({ monitor = "r" }))
hl.bind(mainMod .. " + CTRL + UP",    hl.dsp.focus({ monitor = "u" }))
hl.bind(mainMod .. " + CTRL + DOWN",  hl.dsp.focus({ monitor = "d" }))
hl.bind(mainMod .. " + CTRL + SHIFT + LEFT",  hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + SHIFT + RIGHT", hl.dsp.window.move({ monitor = "r" }))

-- Up/down monitor moves — SKIP (Hyprland has no reliable up/down monitor moves).

-- ═══════════════════════════════════════════════════════════════════════════
-- Workspaces
-- ═══════════════════════════════════════════════════════════════════════════

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + PAGE_DOWN", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + PAGE_UP",   hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CTRL + PAGE_DOWN", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + PAGE_UP",   hl.dsp.window.move({ workspace = "r-1" }))

-- ═══════════════════════════════════════════════════════════════════════════
-- Mouse wheel (workspace navigation)
-- ═══════════════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }), { mouse = true })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "r-1" }), { mouse = true })
hl.bind(mainMod .. " + CTRL + mouse_down", hl.dsp.window.move({ workspace = "r+1" }), { mouse = true })
hl.bind(mainMod .. " + CTRL + mouse_up",   hl.dsp.window.move({ workspace = "r-1" }), { mouse = true })

-- Move/resize windows with mainMod + LMB/RMB and dragging (niri-style drag)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Mod+WheelScrollLeft/Right — SKIP (column navigation, no column concept).

-- ═══════════════════════════════════════════════════════════════════════════
-- Screenshots (grim)
-- ═══════════════════════════════════════════════════════════════════════════

-- Full screenshot of all outputs.
hl.bind("PRINT", hl.dsp.exec_cmd("grim \"$HOME/Pictures/$(date +%s).png\""))

-- Screenshot of the currently focused output.
hl.bind("CTRL + PRINT", hl.dsp.exec_cmd("grim -o \"$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')\" \"$HOME/Pictures/$(date +%s).png\""))

-- Alt+Print → screenshot-window — SKIP (window screenshot is complex).

-- ═══════════════════════════════════════════════════════════════════════════
-- Hardware keys → iNiR IPC (with OSD feedback)
-- ═══════════════════════════════════════════════════════════════════════════

-- Volume.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("inir audio volumeUp"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("inir audio volumeDown"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("inir audio mute"),       { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("inir audio micMute"),    { locked = true, repeating = true })

-- Brightness.
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("inir brightness increment"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("inir brightness decrement"), { locked = true, repeating = true })

-- Media playback (MPRIS — works with any player: Spotify, Firefox, mpv…).
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("inir mpris playPause"), { locked = true, repeating = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("inir mpris playPause"), { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("inir mpris next"),      { locked = true, repeating = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("inir mpris previous"),  { locked = true, repeating = true })

-- ═══════════════════════════════════════════════════════════════════════════
-- Additional media keybinds (when no media keys are available)
-- ═══════════════════════════════════════════════════════════════════════════

hl.bind("CTRL + " .. mainMod .. " + SPACE", hl.dsp.exec_cmd("inir mpris playPause"))
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("inir mpris next"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("inir mpris previous"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("inir audio mute"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("inir mpris playPause"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("inir mpris next"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("inir mpris previous"))

-- ═══════════════════════════════════════════════════════════════════════════
-- Sidebars / Dashboard
-- ═══════════════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("inir sidebarRight toggle"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("inir sidebarLeft toggle"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("inir dashboard open"))

-- ═══════════════════════════════════════════════════════════════════════════
-- Alt+Tab (recent windows)
-- ═══════════════════════════════════════════════════════════════════════════

hl.bind("ALT + TAB", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

hl.bind("ALT + SHIFT + TAB", function()
    hl.dispatch(hl.dsp.window.cycle_prev())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)