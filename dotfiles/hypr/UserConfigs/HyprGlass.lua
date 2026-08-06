if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        enabled = true,
        default_theme = "dark",
        default_preset = "glass",            -- Changed from "clear" to "liquid" or "glass"
        tint_color = 0x00000000,

        blur_strength = 0.3,                 -- Increased blur (was 2.2)
        blur_iterations = 3,                 -- Extra blur pass (was 3)
        refraction_strength = 0.55,          -- Stronger edge warping (was 0.55)
        chromatic_aberration = 0.3,          -- Stronger RGB color splitting (was 0.3)
        fresnel_strength = 0.5,              -- Stronger edge highlight reflection (was 0.5)
        specular_strength = 0.75,
        edge_thickness = 0.05,               -- Thickens refraction borders (was 0.05)
        lens_distortion = 0.3,              -- Stronger center fisheye/bend effect (was 0.3)

        dark = {
            brightness = 1,
            contrast = 0.90,
            saturation = 0.80,
            vibrancy = 0.15,
            adaptive_dim = 0.0,
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

    hg.preset("glass", {
        blur_strength = 0.,                 -- Increased blur (was 2.2)
        blur_iterations = 0,                 -- Extra blur pass (was 3)
        refraction_strength = 1,          -- Stronger edge warping (was 0.55)
        chromatic_aberration = 0.6,          -- Stronger RGB color splitting (was 0.3)
        fresnel_strength = 0.6,              -- Stronger edge highlight reflection (was 0.5)
        specular_strength = 0.75,
        edge_thickness = 0.08,               -- Thickens refraction borders (was 0.05)
        lens_distortion = 0.5,              -- Stronger center fisheye/bend effect (was 0.3)
    })

    hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })

    -- Wlogout power menu: full-surface glass instead of native blur.
    -- mask_threshold 0 so the glass applies across the transparent layer.
    hg.layer("logout_dialog", { preset = "glass", mask_threshold = 0 })
end
