-- Workspace rules
-- DP-2 (primary): workspaces 1-5
-- HDMI-A-1 (secondary): workspaces 6-10

for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", persistent = true, default = (i == 1) })
end

for i = 6, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", persistent = true, default = (i == 6) })
end
