-- Hyprland Lua Configuration
-- Migrated from hyprland.conf
-- https://wiki.hypr.land/Configuring/Start/

-- Set up Lua path to find modules in configs and UserConfigs directories
local hypr_dir = os.getenv("HOME") .. "/.config/hypr"
package.path = hypr_dir .. "/?.lua;" .. hypr_dir .. "/?/init.lua;" .. package.path

-- Initial boot script
hl.on("hyprland.start", function()
  hl.exec_cmd("$HOME/.config/hypr/initial-boot.sh")
end)

-- Load modular configuration files
-- These files have been converted to Lua format
local configs_dir = hypr_dir .. "/configs"
local user_configs_dir = hypr_dir .. "/UserConfigs"

-- Require the configuration modules
require("configs.Keybinds")
require("configs.Startup_Apps")
require("configs.ENVariables")
require("configs.Laptops")
require("configs.WindowRules")
require("configs.SystemSettings")

-- User configurations (overrides)
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

-- nwg-displays configurations (already in Lua format)
require("monitors")
require("workspaces")
