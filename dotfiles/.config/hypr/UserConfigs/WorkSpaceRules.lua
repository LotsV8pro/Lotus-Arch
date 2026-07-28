-- WorkSpaceRules.lua - Workspace rules (User overrides)
-- Converted from UserConfigs/WorkSpaceRules.conf

-- NOTE: THIS IS NOT BEING SOURCED by hyprland
-- It is only here as a guide if you want to do it manually
-- The file you should edit is ~/.config/hypr/workspaces.conf
-- Since that is the work space rules being sourced by hyprland
-- use nwg-displays to handle your workspace rules.

-- You can set workspace rules to achieve workspace-specific behaviors. 
-- For instance, you can define a workspace where all windows are drawn without borders or gaps.

-- https://wiki.hyprland.org/Configuring/Workspace-Rules/

-- Assigning workspace to a certain monitor. Below are just examples
-- hl.workspace_rule({ workspace = 1, monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = 2, monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = 3, monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = 4, monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = 5, monitor = "DP-2" })
-- hl.workspace_rule({ workspace = 6, monitor = "DP-2" })
-- hl.workspace_rule({ workspace = 7, monitor = "DP-2" })
-- hl.workspace_rule({ workspace = 8, monitor = "DP-2" })

-- example rules (from wiki)
-- hl.workspace_rule({ workspace = 3, rounding = false, decorate = false })
-- hl.workspace_rule({ workspace = "name:coding", rounding = false, decorate = false, gapsin = 0, gapsout = 0, border = false, monitor = "DP-1" })
-- hl.workspace_rule({ workspace = 8, bordersize = 8 })
-- hl.workspace_rule({ workspace = "name:Hello", monitor = "DP-1", default = true })
-- hl.workspace_rule({ workspace = "name:gaming", monitor = "desc:Chimei Innolux Corporation 0x150C", default = true })
-- hl.workspace_rule({ workspace = 5, on_created_empty = "[float] firefox" })
-- hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "foot" })
