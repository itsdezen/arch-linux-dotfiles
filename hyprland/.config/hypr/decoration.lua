-- Visual targets from theme/spacing: rounding=10, border_size=1,
-- gaps_in=8/gaps_out=12, subtle shadow, low blur (size 3, passes 2), high
-- opacity. Hex colors here are hand-authored and must stay in sync with
-- theme/colors (COLOR_ACCENT, COLOR_BORDER) — Hyprland's config language
-- can't source a shell file, so this repo keeps values in sync by hand.

hl.config({
    general = {
        gaps_in = 8,
        gaps_out = 12,
        border_size = 1,
        col = {
            active_border   = "rgba(7aa2f7ff)",
            inactive_border = "rgba(3b4261aa)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 10,

        active_opacity   = 1.0,
        inactive_opacity = 0.95,

        shadow = {
            enabled      = true,
            range        = 24,
            render_power = 4,
            color        = "rgba(1a1b26aa)",
        },

        blur = {
            enabled            = true,
            size               = 3,
            passes             = 2,
            new_optimizations  = true,
            ignore_opacity     = true,
        },
    },

    -- pseudotile was removed as a dwindle master switch in Hyprland 0.55+;
    -- it's now per-window only (windowrule = pseudo, ... / hl.dsp.window.pseudo()).
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },
})
