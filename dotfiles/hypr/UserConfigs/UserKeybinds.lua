-- UserKeybinds.lua - User custom keybinds
-- Converted from UserConfigs/UserKeybinds.conf

local mainMod = "SUPER"
local scripts_dir = os.getenv("HOME") .. "/.config/hypr/scripts"
local user_scripts_dir = os.getenv("HOME") .. "/.config/hypr/UserScripts"
local user_configs_dir = os.getenv("HOME") .. "/.config/hypr/UserConfigs"

-- IMPORTANT: If you want to remap an existing keybind you MUST unbind it first

-- The bindings are CASE SENSITIVE. We suggest you copy the existing binding here
--  Then change `bindd` to `unbind`

-- E.g. 
-- hl.unbind(mainMod .. " + Return")
-- hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("ghostty"))

-- If you are ADDING a bindd, make sure you include the description 
-- Other the keybind search menu might not show it properly 

-- E.g.
-- hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("APPNAME"), { description = "My z app" })

-- LOTUS Palette Menu
hl.unbind(mainMod .. " + P")
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("bash ~/.config/lotus-palette/palette-menu.sh"), { description = "Palette color editor" })

-- Preset Manager (save/load/delete full desktop presets)
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("bash " .. scripts_dir .. "/PresetManager.sh"), { description = "Preset Manager - Save/Load themes" })

-- For passthrough keyboard into a VM
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"))
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("reset"))


