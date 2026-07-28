-- UserSettings.lua - User settings
-- Converted from UserConfigs/UserSettings.conf

-- This is where you put your own settings as this will not be touched during update 
-- if the upgrade.sh is used.

-- refer to Hyprland wiki for more info https://wiki.hyprland.org/Configuring/Variables/
-- NOTE: some settings are in ~/.config/hypr/UserConfigs/UserDecorAnimations.conf
--
-- Look on ~/.config/hypr/configs/SystemSettings.conf to know how to modify this

-- Input settings
hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "altgr-intl",
    },
})

-- General settings
hl.config({
    general = {
        allow_tearing = true,
    },
})
