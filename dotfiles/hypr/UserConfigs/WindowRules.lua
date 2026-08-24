-- WindowRules.lua - User window rules and layer rules
-- Converted from UserConfigs/WindowRules.conf

-- This file is used to add or overwrite window rules 
-- This file will not be modified during dotfiles updates

-- Default workspaces (DP-2: 1-5, HDMI-A-1: 6-10)
hl.window_rule({ match = { class = "^(asm-gui)$" }, workspace = "special:silent" })
hl.window_rule({ match = { class = "^(discord)$" }, workspace = "6" })
hl.window_rule({ match = { class = "^(com\\.obsproject\\.Studio)$" }, workspace = "7" })
hl.window_rule({ match = { title = "^(Arctis Sound Manager)$" }, workspace = "7" })
hl.window_rule({ match = { class = "^(org\\.rncbc\\.qpwgraph)$" }, workspace = "7" })
hl.window_rule({ match = { class = "^(zen|zen-alpha)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^([Ss]team)$" }, workspace = "1" })
-- Games on 1 (main monitor) - detected by Steam appid class, no gamescope wrapper
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(gamescope)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(Wuthering Waves|WutheringWaves|Wuthering_Waves|Client-Win64-Shipping|helldivers2|Helldivers2|Warframe|Soulframe)$" }, workspace = "1" })
-- Baldur's Gate 3 (Proton) - always on workspace 1 (main monitor)
hl.window_rule({ match = { class = "^(steam_proton)$" }, workspace = "1" })
-- WS3: Terminal/dev
hl.window_rule({ match = { class = "^(kitty)$" }, workspace = "3" })
-- WS4: Files
hl.window_rule({ match = { class = "^([Tt]hunar)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(xarchiver)$" }, workspace = "4" })
-- WS10: Media/audio
hl.window_rule({ match = { class = "^([Ss]potify)$" }, workspace = "10" })
hl.window_rule({ match = { class = "^(mpv)$" }, workspace = "10" })
hl.window_rule({ match = { class = "^(swappy)$" }, workspace = "10" })
-- WS5: Hardware/gear settings
hl.window_rule({ match = { class = "^(openrgb|org.openrgb.OpenRGB|Vial|vial|org.freedesktop.Piper|com.leinardi.gwe)$" }, workspace = "5" })
-- WS6: IM
hl.window_rule({ match = { class = "^(vesktop)$" }, workspace = "6" })
-- WS8: Game tools
hl.window_rule({ match = { class = "^(net.lutris.Lutris|protontricks|winetricks)$" }, workspace = "8" })
-- WS9: System monitors
hl.window_rule({ match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|nvidia-settings)$" }, workspace = "9" })
-- WS9: nvtop/btop launched as `kitty --title nvtop/btop` (class is kitty)
hl.window_rule({ match = { title = "^(nvtop|btop)$" }, workspace = "9" })

-- Fullscreen games: disable blur, shadows, dim for max FPS
hl.window_rule({ match = { fullscreen = true }, no_blur = true, no_shadow = true, dim_around = false, no_anim = true })

-- Game-specific: disable compositing effects
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, no_blur = true, no_shadow = true, dim_around = false, no_anim = true })
hl.window_rule({ match = { class = "^(gamescope)$" }, no_blur = true, no_shadow = true, dim_around = false, no_anim = true })
hl.window_rule({ match = { class = "^(steam_proton)$" }, no_blur = true, no_shadow = true, dim_around = false, no_anim = true })
hl.window_rule({ match = { class = "^(Wuthering Waves|WutheringWaves|Wuthering_Waves|Client-Win64-Shipping)$" }, no_blur = true, no_shadow = true, dim_around = false, no_anim = true })
hl.window_rule({ match = { class = "^(helldivers2|Helldivers2)$" }, no_blur = true, no_shadow = true, dim_around = false, no_anim = true })
hl.window_rule({ match = { class = "^(Warframe)$" }, no_blur = true, no_shadow = true, dim_around = false, no_anim = true })

-- Waybar layer rule for HyprGlass
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, ignore_alpha = 0.05 })

-- Wlogout power menu: backdrop handled by HyprGlass layer effect
-- (hg.layer("logout_dialog") in HyprGlass.lua) — no native blur here.

-- Spotify — enable Hyprglass glass effect (see through the background)
hl.window_rule({
    name = "Spotify-Hyprglass",
    match = { class = "^(Spotify)$" },
    opacity = "0.85 0.85",
    tag = "+hyprglass_enabled",
})
