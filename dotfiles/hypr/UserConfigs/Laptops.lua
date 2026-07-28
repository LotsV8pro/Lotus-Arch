-- Laptops.lua - Laptop-specific configurations (User overrides)
-- Converted from UserConfigs/Laptops.conf

local mainMod = "SUPER"
local scripts_dir = os.getenv("HOME") .. "/.config/hypr/scripts"
local user_configs_dir = os.getenv("HOME") .. "/.config/hypr/UserConfigs"

-- Below are useful when you are connecting your laptop in external display
-- Suggest you edit below for your laptop display
-- From WIKI This is to disable laptop monitor when lid is closed.
-- consult https://wiki.hyprland.org/hyprland-wiki/pages/Configuring/Binds/#switches

-- WARNING! Using this method has some caveats!! USE THIS PART WITH SOME CAUTION!
-- CONS of doing this, is that you need to set up your wallpaper (SUPER W) and choose wallpaper.
-- CAVEATS! Sometimes the Main Laptop Monitor DOES NOT have display that it needs to re-connect your external monitor
-- One work around is to ensure that before shutting down laptop, MAKE SURE your laptop lid is OPEN!!
-- Make sure to comment (put # on the both the bindl = , switch ......) above
-- NOTE: Display for laptop are being generated into LaptopDisplay.conf
-- This part is to be use if you do not want your main laptop monitor to wake up during say wallpaper change etc

-- For laptop-lid action (to erase the last entry)
-- hl.exec("echo 'monitor = eDP-1, preferred, auto, 1' > " .. user_configs_dir .. "/LaptopDisplay.conf")
