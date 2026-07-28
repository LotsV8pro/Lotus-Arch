-- Startup_Apps.lua - User startup commands
-- Converted from UserConfigs/Startup_Apps.conf

-- Commands and Apps to be executed at launch
hl.exec("sleep 3 && asm-gui")
hl.exec(os.getenv("HOME") .. "/.config/hypr/auto_link_obs.sh")
