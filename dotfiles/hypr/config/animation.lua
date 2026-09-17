--      ___          _                 __  _           
--     /   |  ____  (_)___ ___  ____ _/ /_(_)___  ____ 
--    / /| | / __ \/ / __ `__ \/ __ `/ __/ / __ \/ __ \
--   / ___ |/ / / / / / / / / / /_/ / /_/ / /_/ / / / /
--  /_/  |_/_/ /_/_/_/ /_/ /_/\__,_/\__/_/\____/_/ /_/ 
--                                                   
-- Animations for Hyprland 0.56 Lua API
-- speed is in deciseconds (1 = 100ms)

--------------------------
------- ANIMATIONS -------
--------------------------
hl.curve("myBezier", { type = "bezier", points = { {0.02, 1.0}, {0.3, 1.05} } })
hl.curve("easeInOut", { type = "bezier", points = { {0.65, 0}, {0.35, 1} } })
hl.curve("smoothzz", { type = "bezier", points = { {0.2, 0.9}, {0.2, 1} } })

-- Window
hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "myBezier", style = "gnomed" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "myBezier", style = "gnomed" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "myBezier", style = "gnomed" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "myBezier" })

-- Layer
hl.animation({ leaf = "layers", enabled = true, speed = 8, bezier = "myBezier" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 8, bezier = "myBezier" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 8, bezier = "myBezier" })

-- Fade effects
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fadePopups", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 6, bezier = "default" })

-- DPMS & BORDER
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 20, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "default" })

-- Workspaces
hl.animation({ leaf = "workspaces", enabled = true, speed = 8, bezier = "smoothzz", style = "slidevert" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 8, bezier = "smoothzz", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 8, bezier = "smoothzz", style = "slidevert" })

-- Special workspace
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "smoothzz", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 6, bezier = "smoothzz", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 8, bezier = "smoothzz", style = "slidevert" })

-- Others
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 6, bezier = "smoothzz" })
hl.animation({ leaf = "monitorAdded", enabled = true, speed = 6, bezier = "smoothzz" })
