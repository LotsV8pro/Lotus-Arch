-- Keybinds.lua - Default Keybinds
-- Converted from configs/Keybinds.conf

local mainMod = "SUPER"
local scripts_dir = os.getenv("HOME") .. "/.config/hypr/scripts"
local user_configs_dir = os.getenv("HOME") .. "/.config/hypr/UserConfigs"
local user_scripts_dir = os.getenv("HOME") .. "/.config/hypr/UserScripts"

-- STANDARD
-- App launcher
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"))

-- Open default browser
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("xdg-open 'https://'"))

-- Desktop overview
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(scripts_dir .. "/OverviewToggle.sh"))

-- Open terminal
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("$term"))

-- Open file manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("$files"))

-- FEATURES / EXTRAS
-- Reload Hyprland config (also restores OBS PipeWire capture, which a reload breaks)
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(scripts_dir .. "/ReloadConfig.sh"))

-- Help / cheat sheet
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(scripts_dir .. "/KeyHints.sh"))

-- Refresh bar and menus
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(scripts_dir .. "/Refresh.sh"))

-- Emoji menu
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd(scripts_dir .. "/RofiEmoji.sh"))

-- Web search
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(scripts_dir .. "/RofiSearch.sh"))

-- Window switcher
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("rofi -show window"))

-- Toggle blur
hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd(scripts_dir .. "/ChangeBlur.sh"))

-- Toggle game mode
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(scripts_dir .. "/GameMode.sh"))

-- Toggle master/dwindle layout
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(scripts_dir .. "/ChangeLayout.sh"))

-- Clipboard manager
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd(scripts_dir .. "/ClipManager.sh"))

-- Rofi theme selector
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(scripts_dir .. "/RofiThemeSelector.sh"))

-- Rofi theme selector (modified)
hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("pkill rofi || true && " .. scripts_dir .. "/RofiThemeSelector-modified.sh"))

-- Fullscreen
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Maximize window
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }))

-- Float current window
hl.bind(mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))

-- Float all windows on the active workspace
-- (classic `workspaceopt allfloat` has no Lua-API equivalent; script emulates it)
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd(scripts_dir .. "/FloatAll.sh"))

-- DropDown terminal
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(scripts_dir .. "/Dropterminal.sh $term"))

-- Desktop zooming or magnifier
hl.bind(mainMod .. " + ALT + mouse_down", hl.dsp.exec_cmd("hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')\""))
hl.bind(mainMod .. " + ALT + mouse_up", hl.dsp.exec_cmd("hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')\""))

-- Waybar / Bar related
hl.bind(mainMod .. " + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(scripts_dir .. "/WaybarStyles.sh"))
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(scripts_dir .. "/WaybarLayout.sh"))

-- Night light toggle (Hyprsunset)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(scripts_dir .. "/Hyprsunset.sh toggle"))

-- FEATURES / EXTRAS (UserScripts)
-- Online music
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(user_scripts_dir .. "/RofiBeats.sh"))

-- Select wallpaper
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(user_scripts_dir .. "/WallpaperSelect.sh"))

-- Wallpaper effects
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(user_scripts_dir .. "/WallpaperEffects.sh"))

-- Quick Settings menu
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(scripts_dir .. "/Quick_Settings.sh"), { description = "Quick Settings" })

-- Random wallpaper
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(user_scripts_dir .. "/WallpaperRandom.sh"))

-- Toggle active window opacity
hl.bind(mainMod .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))

-- Search keybinds
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scripts_dir .. "/KeyBinds.sh"))

-- Animations menu
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scripts_dir .. "/Animations.sh"))

-- Change oh-my-zsh theme
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(user_scripts_dir .. "/ZshChangeTheme.sh"))

-- Switch keyboard layout globally (DISABLED - conflicts with games eating Shift/Alt)
-- hl.bind("ALT_L + SHIFT_L", hl.dsp.exec_cmd(scripts_dir .. "/KeyboardLayout.sh switch"), { release = true })

-- Switch keyboard layout per-window (DISABLED - conflicts with games eating Shift/Alt)
-- hl.bind("SHIFT_L + ALT_L", hl.dsp.exec_cmd(scripts_dir .. "/Tak0-Per-Window-Switch.sh"), { release = true })

-- Calculator
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(user_scripts_dir .. "/RofiCalc.sh"))

-- Move current workspaces to monitors (left right up or down)
hl.bind(mainMod .. " + CTRL + F9", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + F10", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(mainMod .. " + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mainMod .. " + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" }))

-- SYSTEM
-- Exit Hyprland
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())

-- Close active window
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

-- Terminate active process
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(scripts_dir .. "/KillActiveProcess.sh"))

-- Lock screen
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(scripts_dir .. "/LockScreen.sh"))

-- Power menu
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(scripts_dir .. "/Wlogout.sh"))

-- Notification panel
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

-- Quick settings menu
-- Quick settings moved to UserKeybinds.lua

-- Master Layout
hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"))
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"))
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"))

-- Dwindle Layout
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- Works on either layout (Master or Dwindle)
hl.bind(mainMod .. " + M", hl.dsp.layout("splitratio", 0.3))

-- Layout aware keybinds initialization
hl.dsp.exec_cmd(scripts_dir .. "/ChangeLayout.sh init")

-- Cycle windows; if floating bring to top
hl.bind("ALT + Tab", hl.dsp.window.cycle_next({}))
hl.bind("ALT + Tab", hl.dsp.window.bring_to_top())

-- Special Keys / Hot Keys
-- Volume controls
hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd(scripts_dir .. "/Volume.sh --inc"), { locked = true, repeating = true })
hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd(scripts_dir .. "/Volume.sh --dec"), { locked = true, repeating = true })
hl.bind("ALT + xf86audioraisevolume", hl.dsp.exec_cmd(scripts_dir .. "/Volume.sh --inc-precise"), { locked = true, repeating = true })
hl.bind("ALT + xf86audiolowervolume", hl.dsp.exec_cmd(scripts_dir .. "/Volume.sh --dec-precise"), { locked = true, repeating = true })
hl.bind("xf86AudioMicMute", hl.dsp.exec_cmd(scripts_dir .. "/Volume.sh --toggle-mic"), { locked = true })
hl.bind("xf86audiomute", hl.dsp.exec_cmd(scripts_dir .. "/Volume.sh --toggle"), { locked = true })
hl.bind("xf86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("xf86Rfkill", hl.dsp.exec_cmd(scripts_dir .. "/AirplaneMode.sh"), { locked = true })

-- Media controls using keyboards
hl.bind("xf86AudioPause", hl.dsp.exec_cmd(scripts_dir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("xf86AudioPlay", hl.dsp.exec_cmd(scripts_dir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("xf86AudioNext", hl.dsp.exec_cmd(scripts_dir .. "/MediaCtrl.sh --nxt"), { locked = true })
hl.bind("xf86AudioPrev", hl.dsp.exec_cmd(scripts_dir .. "/MediaCtrl.sh --prv"), { locked = true })
hl.bind("xf86audiostop", hl.dsp.exec_cmd(scripts_dir .. "/MediaCtrl.sh --stop"), { locked = true })

-- Screenshot keybindings
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --now"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --area"))
hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --in5"))
hl.bind(mainMod .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --in10"))
hl.bind("ALT + Print", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --active"))

-- Screenshot with swappy
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --swappy"))

-- Resize windows
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

-- Move windows
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "down" }))

-- Swap windows
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.swap({ direction = "down" }))

-- Group
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())

-- Navigate within a group
-- NOTE: SUPER+Tab / SUPER+SHIFT+Tab are used for workspace switching below;
--       group cycling lives on CTRL+Tab combos to avoid double-bound keys
hl.bind(mainMod .. " + CTRL + SHIFT + Tab", hl.dsp.group.next())
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.group.prev())

-- Move window into/out of group
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ into_group = "left" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ into_group = "right" }))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ out_of_group = true }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Workspaces related
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special())

-- Switch workspaces with mainMod + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + code:" .. (9 + i), hl.dsp.focus({ workspace = tostring(i) }))
end

-- Move active window and follow to workspace mainMod + SHIFT [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + SHIFT + code:" .. (9 + i), hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Move to previous/next workspace with brackets
hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "e+1" }))

-- Move active window to a workspace silently mainMod + CTRL [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + CTRL + code:" .. (9 + i), hl.dsp.window.move({ workspace = tostring(i), follow = false }))
end

-- Move silently to previous/next workspace with brackets
hl.bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = "e-1", follow = false }))
hl.bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "e+1", follow = false }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "m-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
