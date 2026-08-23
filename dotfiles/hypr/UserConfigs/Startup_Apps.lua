-- Startup_Apps.lua - User startup commands

-- os.execute(os.getenv("HOME") .. "/.config/hypr/auto_link_obs.sh &")
hl.on("hyprland.start", function()
    hl.exec_cmd("pkill -f '/auto_link_obs.sh' 2>/dev/null; " .. os.getenv("HOME") .. "/.config/hypr/auto_link_obs.sh &")
    hl.exec_cmd("sleep 1 && hyprpm reload -n")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/PortalHyprland.sh")

    -- OBS audio routing (PipeWire links; a reload breaks them)
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/ObsAudioLinks.sh")

    -- qpwgraph (Arctis routing patchbay)
    hl.exec_cmd("pgrep -x qpwgraph 2>/dev/null || qpwgraph")

    -- Wallpaper watcher: auto-sync lock screen blur + SDDM bg on wallpaper change
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/WatchWallpaper.sh &")

    -- Auto-start apps
    hl.exec_cmd("pkill -x asm-gui 2>/dev/null; sleep 3 && /usr/bin/asm-gui")
end)

