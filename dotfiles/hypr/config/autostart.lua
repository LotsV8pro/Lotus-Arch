--      _____ __             __ 
--     / ___// /_____ ______/ /_
--    \__ \/ __/ __ `/ ___/ __/
--   ___/ / /_/ /_/ / /  / /_  
--  /____/\__/\__,_/_/   \__/  
--                           

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Awwww daemon not needed under Hyprland
-- inir.service and waybar.service are started by graphical-session.target
-- under uwsm/wayland-session managers. Plain Hyprland (SDDM .desktop) does
-- not activate that target, so start them explicitly (idempotent no-op if
-- already active).
hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user start inir.service")
    hl.exec_cmd("systemctl --user start waybar.service")

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("$HOME/.local/bin/polkit_start.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("fcitx5 -d")
    -- Wallpaper sync via systemd timer
    hl.exec_cmd("systemctl --user start we-wallpaper-sync.path")
end)