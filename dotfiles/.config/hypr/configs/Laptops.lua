-- Laptops.lua - Laptop-specific configurations
-- Converted from configs/Laptops.conf

local mainMod = "SUPER"
local scripts_dir = os.getenv("HOME") .. "/.config/hypr/scripts"
local user_configs_dir = os.getenv("HOME") .. "/.config/hypr/UserConfigs"

-- Touchpad device configuration
local touchpad_device = "asue1209:00-04f3:319f-touchpad"

-- Keyboard brightness controls
hl.bind("", "xf86KbdBrightnessDown", hl.dsp.exec_cmd(scripts_dir .. "/BrightnessKbd.sh --dec"), { repeat = true })
hl.bind("", "xf86KbdBrightnessUp", hl.dsp.exec_cmd(scripts_dir .. "/BrightnessKbd.sh --inc"), { repeat = true })

-- Monitor brightness controls
hl.bind("", "xf86MonBrightnessDown", hl.dsp.exec_cmd(scripts_dir .. "/Brightness.sh --dec"), { repeat = true })
hl.bind("", "xf86MonBrightnessUp", hl.dsp.exec_cmd(scripts_dir .. "/Brightness.sh --inc"), { repeat = true })

-- Touchpad toggle
hl.bind("", "xf86TouchpadToggle", hl.dsp.exec_cmd(scripts_dir .. "/TouchPad.sh"))

-- Screenshot keybindings using F6 (no PrinSrc button)
hl.bind(mainMod .. " + F6", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --now"))
hl.bind(mainMod .. " + SHIFT + F6", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --area"))
hl.bind(mainMod .. " + CTRL + F6", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --in5"))
hl.bind(mainMod .. " + ALT + F6", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --in10"))
hl.bind("ALT + F6", hl.dsp.exec_cmd(scripts_dir .. "/ScreenShot.sh --active"))

-- Touchpad device settings
hl.device({
    name = touchpad_device,
    enabled = true,
})
