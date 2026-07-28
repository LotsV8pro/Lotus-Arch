-- Startup_Apps.lua - Commands and Apps to be executed at launch
-- Converted from configs/Startup_Apps.conf

local scripts_dir = os.getenv("HOME") .. "/.config/hypr/scripts"
local user_scripts_dir = os.getenv("HOME") .. "/.config/hypr/UserScripts"

-- Wallpaper stuff
hl.exec("swww-daemon --format xrgb")

-- Startup
hl.exec("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
hl.exec("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
hl.exec(scripts_dir .. "/Dropterminal.sh kitty &")
hl.exec(scripts_dir .. "/Polkit.sh")
hl.exec("nm-applet --indicator")
hl.exec("swaync")
hl.exec("waybar")
hl.exec("qs -c overview")
hl.exec("hypridle")
hl.exec(scripts_dir .. "/Hyprsunset.sh init")

-- Clipboard manager
hl.exec("wl-paste --type text --watch cliphist store")
hl.exec("wl-paste --type image --watch cliphist store")

-- Rainbow borders (disabled by default)
-- hl.exec(user_scripts_dir .. "/RainbowBorders.sh")

-- Additional startup apps
hl.exec("blueman-applet")
hl.exec(scripts_dir .. "/KeybindsLayoutInit.sh")
