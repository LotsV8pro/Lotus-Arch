-- Generated monitor layout (owned by resolution-switcher.sh - survives reloads)
pcall(dofile, (os.getenv("HOME") or "") .. "/.config/hypr/modules/monitors-state.lua")

-- Hotplug fallback: any monitor without a rule above comes up at preferred mode
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- DP-2 gets 1-5, HDMI-A-1 gets 6-10
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", persistent = true, default = (i == 1) })
end

for i = 6, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", persistent = true, default = (i == 6) })
end

-- Main monitor: DP-2 NSL 1440p 144Hz VRR 10-bit
hl.monitor({ output = "DP-2", mode = "2560x1440@165", position = "0x0", scale = 1, bitdepth = 10, vrr = 2 })
-- Secondary monitor: HDMI-A-1 aligned to bottom, now on the LEFT
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "-1920x360", scale = 1 })
