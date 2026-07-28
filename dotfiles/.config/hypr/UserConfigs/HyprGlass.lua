-- HyprGlass.lua - Liquid Glass effect for Waybar
-- Converted from UserConfigs/HyprGlass.conf
-- Install: sudo hyprpm add https://github.com/hyprnux/hyprglass && sudo hyprpm enable hyprglass
-- Then reload: hyprctl reload

hl.config({
    plugin = {
        hyprglass = {
            default_theme = "dark",
            default_preset = "clear",
            
            -- Configuration for "apple" preset
            blur_strength = 2.2,
            blur_iterations = 3,
            refraction_strength = 0.55,
            chromatic_aberration = 0.3,
            fresnel_strength = 0.5,
            specular_strength = 0.75,
            edge_thickness = 0.05,
            lens_distortion = 0.3,
            
            -- Dark mode settings
            dark = {
                brightness = 0.82,
                contrast = 0.90,
                saturation = 0.80,
                vibrancy = 0.15,
                adaptive_dim = 0.4,
            },
            
            -- Light mode settings
            light = {
                brightness = 1.12,
                contrast = 0.92,
                saturation = 0.85,
                vibrancy = 0.12,
                adaptive_boost = 0.4,
            },
            
            layers = {
                enabled = 1,
                namespaces = "waybar",
                preset = "subtle",
                namespace_mask_thresholds = {
                    waybar = 0.05,
                },
            },
        },
    },
})
