-- Hyprland Lua Configuration
-- Main entry point — loads all config modules

local hypr_dir = os.getenv("HOME") .. "/.config/hypr"
package.path = hypr_dir .. "/?.lua;" .. hypr_dir .. "/?/init.lua;" .. package.path

-- Initial boot script
hl.on("hyprland.start", function()
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/initial-boot.sh")
end)

-- Default configs
require("configs.Keybinds")
require("configs.ENVariables")
require("configs.Laptops")
require("configs.WindowRules")
require("configs.SystemSettings")
require("configs.Startup_Apps")

-- User overrides
require("UserConfigs.UserDecorations")
require("UserConfigs.UserAnimations")
require("UserConfigs.UserKeybinds")
require("UserConfigs.UserSettings")
require("UserConfigs.01-UserDefaults")
require("UserConfigs.HyprGlass")
require("UserConfigs.WindowRules")
require("UserConfigs.Laptops")
require("UserConfigs.LaptopDisplay")
require("UserConfigs.ENVariables")
require("UserConfigs.Startup_Apps")
require("UserConfigs.WorkSpaceRules")

-- nwg-displays
require("monitors")
require("workspaces")
