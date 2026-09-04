-- Startup_Apps.lua - User startup commands

hl.on("hyprland.start", function()
    hl.exec_cmd("sleep 1 && hyprpm reload -n")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/PortalHyprland.sh")

    -- qpwgraph (PipeWire routing patchbay)
    hl.exec_cmd("pgrep -x qpwgraph 2>/dev/null || qpwgraph")

    -- Wallpaper watcher: auto-sync lock screen blur + SDDM bg on wallpaper change
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/WatchWallpaper.sh &")
end)

