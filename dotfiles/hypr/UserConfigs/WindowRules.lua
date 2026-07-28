-- WindowRules.lua - User window rules and layer rules
-- Converted from UserConfigs/WindowRules.conf

-- This file is used to add or overwrite window rules 
-- This file will not be modified during dotfiles updates

-- Default workspaces (DP-2: 1-5, HDMI-A-1: 6-10)
hl.window_rule({ match = { class = "^(asm-gui)$" }, workspace = "special:silent" })
hl.window_rule({ match = { class = "^(discord)$" }, workspace = "6" })
hl.window_rule({ match = { class = "^(com%.obsproject%.Studio)$" }, workspace = "7" })
hl.window_rule({ match = { title = "^(Arctis Sound Manager)$" }, workspace = "7" })
hl.window_rule({ match = { class = "^(org%.rncbc%.qpwgraph)$" }, workspace = "7" })
hl.window_rule({ match = { class = "^([Ss]team)$" }, workspace = "1" })

-- Waybar layer rule for HyprGlass
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, ignore_alpha = 0.05 })
