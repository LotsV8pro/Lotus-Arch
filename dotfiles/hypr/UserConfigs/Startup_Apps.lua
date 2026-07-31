-- Startup_Apps.lua - User startup commands

-- os.execute(os.getenv("HOME") .. "/.config/hypr/auto_link_obs.sh &")
hl.on("hyprland.start", function()
    hl.exec_cmd("pkill -f '/auto_link_obs.sh' 2>/dev/null; " .. os.getenv("HOME") .. "/.config/hypr/auto_link_obs.sh &")
    hl.exec_cmd("sleep 1 && hyprpm reload -n")
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/fix-portal.sh")

    -- Auto-start apps
    hl.exec_cmd("pkill -x asm-gui 2>/dev/null; /usr/bin/asm-gui --systray &")
end)

