-- Machine-specific monitor layout & persistent workspace rules for the Lotus
-- reference build. OPTIONAL overlay — not the default.
--
-- Reference desktop:
--   - DP-2      2560x1440 @165 Hz   primary (0x0), VRR, 10-bit
--   - HDMI-A-1  1920x1080 @60 Hz    secondary (left at -1920x360)
--   - Persistent workspaces 1-5 on DP-2, 6-10 on HDMI-A-1
--
-- 06-dotfiles.sh activates this ONLY when both output connectors are physically
-- connected (detected via /sys/class/drm), so other PCs keep the portable
-- default (monitors.lua). You can also apply it manually:
--   cp $HOME/.config/hypr/monitors.lotus.lua $HOME/.config/hypr/monitors.lua

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- DP-2 gets 1-5, HDMI-A-1 gets 6-10
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", persistent = true, default = (i == 1) })
end

for i = 6, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", persistent = true, default = (i == 6) })
end

-- Main monitor: DP-2 NSL 1440p 165Hz VRR 10-bit
hl.monitor({ output = "DP-2", mode = "2560x1440@165", position = "0x0", scale = 1, bitdepth = 10, vrr = 2 })
-- Secondary monitor: HDMI-A-1 aligned to bottom, now on the LEFT
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "-1920x360", scale = 1 })
