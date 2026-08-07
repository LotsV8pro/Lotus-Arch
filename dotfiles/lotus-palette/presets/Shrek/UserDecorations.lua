-- LOTUS Decorations

-- General settings
hl.config({
    general = {
        border_size = 2,
        gaps_in = 4,
        gaps_out = 8,
        
        col = {
            active_border = { colors = {"rgba(00FF66cc)", "rgba(00AA44cc)"}, angle = 135 },
            inactive_border = { colors = {"rgba(00FF6622)", "rgba(00AA4422)"}, angle = 135 },
        },
    },
})

-- Decoration settings
hl.config({
    decoration = {
        rounding = 10,
        
        active_opacity = 1.0,
        inactive_opacity = 0.90,
        fullscreen_opacity = 1.0,
        
        dim_inactive = true,
        dim_strength = 0.12,
        dim_special = 0.8,
        
        shadow = {
            enabled = true,
            range = 15,
            render_power = 3,
            color = "rgba(00FF6630)",
            color_inactive = "rgba(00AA4415)",
            offset = "0, 4",
        },
        
        blur = {
            enabled = true,
            size = 10,
            passes = 4,
            new_optimizations = true,
            xray = true,
            ignore_opacity = true,
            special = true,
            popups = true,
            noise = 0.015,
            contrast = 1.1,
            brightness = 0.8,
        },
    },
})

-- Group settings
hl.config({
    group = {
        col = {
            border_active = "rgba(00FF66cc)",
            border_inactive = "rgba(00AA4433)",
        },
        
        groupbar = {
            col = {
                active = "rgba(00FF66cc)",
                inactive = "rgba(00AA4433)",
            },
            enabled = true,
        },
    },
})
