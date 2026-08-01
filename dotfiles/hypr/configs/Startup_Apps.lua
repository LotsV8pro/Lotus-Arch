-- Startup_Apps.lua - Commands and Apps to be executed at launch

local scripts_dir = os.getenv("HOME") .. "/.config/hypr/scripts"
local user_scripts_dir = os.getenv("HOME") .. "/.config/hypr/UserScripts"

-- Wallpaper stuff
hl.exec_cmd("swww-daemon --format xrgb")

-- Startup & Environment
hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

hl.exec_cmd(scripts_dir .. "/Dropterminal.sh kitty")
hl.exec_cmd("pkill -x hyprpolkitagent 2>/dev/null; " .. scripts_dir .. "/Polkit.sh")
hl.exec_cmd("nm-applet --indicator")
hl.exec_cmd("swaync")
hl.exec_cmd("pgrep -x waybar || waybar")
hl.exec_cmd("pkill -x qs 2>/dev/null; qs -c overview &")
hl.exec_cmd("pkill -x hypridle 2>/dev/null; hypridle &")
hl.exec_cmd(scripts_dir .. "/Hyprsunset.sh init")

-- Clipboard manager (kill old watchers first to prevent accumulation on reload)
hl.exec_cmd("pkill -x wl-paste 2>/dev/null; wl-paste --type text --watch cliphist store &")
hl.exec_cmd("wl-paste --type image --watch cliphist store &")

-- Rainbow borders (disabled by default)
-- hl.exec_cmd(user_scripts_dir .. "/RainbowBorders.sh")

-- Additional startup apps
hl.exec_cmd("blueman-applet")
hl.exec_cmd(scripts_dir .. "/KeybindsLayoutInit.sh")
-- hl.exec_cmd(scripts_dir .. "/XboxGuideButton.sh")  -- script no longer exists
