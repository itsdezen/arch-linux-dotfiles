-- Auto-detect and enable every connected monitor at its preferred mode.
-- Replace with explicit fields (output/mode/position/scale) once the real
-- hardware's output names are known (`hyprctl monitors`).
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
