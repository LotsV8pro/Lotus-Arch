-- HyprGlass.lua - Liquid Glass effect for Waybar
-- Requires: hyprpm add https://github.com/hyprnux/hyprglass && hyprpm enable hyprglass
-- If version mismatch: sudo rm -rf /var/cache/hyprpm/lots/HyprGlass && hyprpm add https://github.com/hyprnux/hyprglass && hyprpm enable hyprglass

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        default_theme = "dark",
        default_preset = "clear",
        tint_color = 0x8899aa22,

        blur_strength = 2.2,
        blur_iterations = 3,
        refraction_strength = 0.55,
        chromatic_aberration = 0.3,
        fresnel_strength = 0.5,
        specular_strength = 0.75,
        edge_thickness = 0.05,
        lens_distortion = 0.3,

        dark = {
            brightness = 0.82,
            contrast = 0.90,
            saturation = 0.80,
            vibrancy = 0.15,
            adaptive_dim = 0.4,
        },

        light = {
            brightness = 1.12,
            contrast = 0.92,
            saturation = 0.85,
            vibrancy = 0.12,
            adaptive_boost = 0.4,
        },

        layers = { enabled = true },
    })

    hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })
end
