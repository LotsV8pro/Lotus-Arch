-- WindowRules.lua - Window Rules and Layer Rules
-- Converted from configs/WindowRules.conf

-- TAGS - add apps under appropriate tag to use the same settings

-- Browser tags
hl.window_rule({ match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(chrome-.+-Default)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Cc]hromium)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(zen-alpha|zen)$" }, tag = "+browser" })

-- Notification tags
hl.window_rule({ match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" }, tag = "+notif" })

-- Settings tags
hl.window_rule({ match = { title = "^(Cheat Sheet)$" }, tag = "+cheat" })
hl.window_rule({ match = { title = "^(ctOS Settings)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(nwg-displays|nwg-look)$" }, tag = "+settings" })

-- Terminal tags
hl.window_rule({ match = { class = "^(Alacritty|kitty|kitty-dropterm)$" }, tag = "+terminal" })

-- Email tags
hl.window_rule({ match = { class = "^([Tt]hunderbird|org.mozilla.Thunderbird)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(eu.betterbird.Betterbird)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(org.gnome.Evolution)$" }, tag = "+email" })

-- Project tags
hl.window_rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(VSCode|code|code-url-handler)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(jetbrains-.+)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(dev.zed.Zed|antigravity)$" }, tag = "+projects" })

-- Screenshare tags
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, tag = "+screenshare" })

-- IM tags
hl.window_rule({ match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(teams-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(im.riot.Riot|Element)$" }, tag = "+im" })

-- Game tags
hl.window_rule({ match = { class = "^(gamescope)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, tag = "+games" })

-- Gamestore tags
hl.window_rule({ match = { class = "^([Ss]team)$" }, tag = "+gamestore" })
hl.window_rule({ match = { title = "^([Ll]utris)$" }, tag = "+gamestore" })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$" }, tag = "+gamestore" })

-- File-manager tags
hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" }, tag = "+file-manager" })
hl.window_rule({ match = { class = "^(app.drey.Warp)$" }, tag = "+file-manager" })

-- Wallpaper tags
hl.window_rule({ match = { class = "^([Ww]aytrogen)$" }, tag = "+wallpaper" })

-- Multimedia tags
hl.window_rule({ match = { class = "^([Aa]udacious)$" }, tag = "+multimedia" })

-- Multimedia-video tags
hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia_video" })

-- Settings tags (additional)
hl.window_rule({ match = { title = "^(ROG Control)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(gnome-disks|wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { title = "(Kvantum Manager)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(qt5ct|qt6ct)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "(xdg-desktop-portal-gtk)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([Rr]ofi)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(btrfs-assistant)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(timeshift-gtk)$" }, tag = "+settings" })

-- Viewer tags
hl.window_rule({ match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(evince)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(eog|org.gnome.Loupe)$" }, tag = "+viewer" })

-- Special override rules
hl.window_rule({ match = { tag = "multimedia_video" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video" }, opacity = "1.0 1.0" })
hl.window_rule({ match = { tag = "multimedia" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia" }, opacity = "1.0 1.0" })

-- POSITION
hl.window_rule({ match = { tag = "cheat" }, center = true })
hl.window_rule({ match = { tag = "settings" }, center = true })
hl.window_rule({ match = { title = "^(ROG Control)$" }, center = true })
hl.window_rule({ match = { title = "^(Keybindings)$" }, center = true })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, center = true })

-- Window rule to avoid idle for fullscreen apps
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

-- FLOAT
hl.window_rule({ match = { tag = "cheat" }, float = true })
hl.window_rule({ match = { tag = "wallpaper" }, float = true, center = true })
hl.window_rule({ match = { tag = "settings" }, float = true, center = true })
hl.window_rule({ match = { tag = "viewer" }, float = true, center = true })
hl.window_rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)" }, float = true })
hl.window_rule({ match = { class = "(org.gnome.Calculator|qalculate-gtk)" }, float = true })
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, float = true })

-- Popups and dialogue
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })
hl.window_rule({ match = { class = "(codium|codium-url-handler|VSCodium)" }, float = true })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$" }, float = true })
hl.window_rule({ match = { class = "^([Ss]team)$" }, float = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true, size = { "monitor_w*0.7", "monitor_h*0.6" }, center = true })
hl.window_rule({ match = { title = "^(Save As)$" }, float = true, size = { "monitor_w*0.7", "monitor_h*0.6" }, center = true })
hl.window_rule({ match = { initial_title = "(Open Files)" }, float = true, size = { "monitor_w*0.7", "monitor_h*0.6" } })
hl.window_rule({ match = { title = "^(SDDM Background)$" }, float = true, center = true, size = { "monitor_w*0.16", "monitor_h*0.12" } })
hl.window_rule({ match = { class = "^(yad)$" }, float = true, center = true, size = { "monitor_w*0.2", "monitor_h*0.2" } })
hl.window_rule({ match = { class = "^(hyprland-donate-screen)$" }, float = true, center = true })

-- OPACITY
hl.window_rule({ match = { tag = "browser" }, opacity = "0.99 0.8" })
hl.window_rule({ match = { tag = "projects" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "im" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "multimedia" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "file-manager" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "terminal" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { tag = "settings" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "viewer" }, opacity = "0.82 0.75" })
hl.window_rule({ match = { tag = "wallpaper" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { class = "^(deluge)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { class = "^(seahorse)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "0.95 0.75" })

-- SIZE
hl.window_rule({ match = { tag = "cheat" }, size = { "monitor_w*0.65", "monitor_h*0.9" } })
hl.window_rule({ match = { tag = "wallpaper" }, size = { "monitor_w*0.7", "monitor_h*0.7" } })
hl.window_rule({ match = { tag = "settings" }, size = { "monitor_w*0.7", "monitor_h*0.7" } })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, size = { "monitor_w*0.6", "monitor_h*0.7" } })

-- BLUR & FULLSCREEN
hl.window_rule({ match = { tag = "games" }, no_blur = true, fullscreen = false })
hl.window_rule({ match = { tag = "games" }, fullscreen = false })

-- No initial focus for JetBrains and wind
hl.window_rule({ match = { class = "^(jetbrains-*)" }, no_initial_focus = true })
hl.window_rule({ match = { title = "^(wind.*)$" }, no_initial_focus = true })

-- LAYER RULES
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, ignore_alpha = 0.5 })

-- Named rules for special cases
hl.window_rule({
    name = "Whatsapp-zapzap",
    match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
    size = { "monitor_w*0.6", "monitor_h*0.7" },
    center = true,
})

hl.window_rule({
    name = "Picture-in-Picture",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    move = "72% 7%",
    opacity = "0.95 0.75",
    pin = true,
    keep_aspect_ratio = true,
    size = { "monitor_w*0.3", "monitor_h*0.3" },
})

-- Thunar copy progress dialog
hl.window_rule({
    name = "Thunar-Progress-bar",
    match = { class = "^(thunar)$", title = "^(File Operation Progress)$" },
    float = true,
    center = true,
    size = { "monitor_w*0.26", "monitor_h*0.18" },
})
-- Force opacity on Discord / Vesktop so Hyprglass can process it
hl.window_rule({
    name = "Discord-Hyprglass",
    match = { class = "^(discord|vesktop|WebCord|VencordDesktop)$" },
    opacity = "0.75 0.75",
    tag = "+hyprglass_enabled",
})
