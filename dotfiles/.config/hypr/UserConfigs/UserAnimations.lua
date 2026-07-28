-- UserAnimations.lua - User animation settings
-- Converted from UserConfigs/UserAnimations.conf

-- Animation curves
hl.curve("dedsec", { type = "bezier", points = { {0.22, 0.61}, {0.36, 1.0} } })
hl.curve("dedsec-fast", { type = "bezier", points = { {0.15, 0.8}, {0.3, 1.0} } })
hl.curve("dedsec-spring", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- Animation settings
hl.config({
    animations = {
        enabled = true,
    },
})

-- Windows: slide with smooth ease
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "dedsec", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "dedsec-fast", style = "slide" })

-- Borders: gentle pulse
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "dedsec" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "dedsec" })

-- Fade: soft and smooth
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "dedsec" })

-- Workspaces: fluid slide
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "dedsec", style = "slide" })

-- Special workspace
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "dedsec", style = "slidevert" })
