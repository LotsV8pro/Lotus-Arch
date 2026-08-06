-- Startup_Apps.lua - User startup commands

-- os.execute(os.getenv("HOME") .. "/.config/hypr/auto_link_obs.sh &")
hl.on("hyprland.start", function()
    hl.exec_cmd("pkill -f '/auto_link_obs.sh' 2>/dev/null; " .. os.getenv("HOME") .. "/.config/hypr/auto_link_obs.sh &")
    hl.exec_cmd("sleep 1 && hyprpm reload -n && hyprctl reload")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/PortalHyprland.sh")

    -- Auto-start apps
    hl.exec_cmd("pkill -x asm-gui 2>/dev/null; sleep 3 && /usr/bin/asm-gui")
end)

