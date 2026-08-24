-- Restrained bezier animations — quick and subtle, not bouncy.
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},    {1, 1}    } })

hl.config({
    animations = {
        enabled = true,
    },
})

hl.animation({ leaf = "windows",          enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 3, bezier = "linear" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "layers",           enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 3, bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 3, bezier = "linear" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert" })
