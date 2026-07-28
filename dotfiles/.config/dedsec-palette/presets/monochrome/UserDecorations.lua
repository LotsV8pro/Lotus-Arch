-- D̷E̷D̷S̷E̷C̷ Decorations

-- General settings
hl.config({
    general = {
        border_size = 2,
        gaps_in = 4,
        gaps_out = 8,
        
        col = {
            active_border = { colors = {"rgba(C8C8C8cc)", "rgba(888888cc)"}, angle = 135 },
            inactive_border = { colors = {"rgba(C8C8C822)", "rgba(88888822)"}, angle = 135 },
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
            range = 10,
            render_power = 3,
            color = "rgba(C8C8C830)",
            color_inactive = "rgba(88888815)",
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
            border_active = "rgba(C8C8C8cc)",
            border_inactive = "rgba(88888833)",
        },
        
        groupbar = {
            col = {
                active = "rgba(C8C8C8cc)",
                inactive = "rgba(88888833)",
            },
            enabled = true,
        },
    },
})
