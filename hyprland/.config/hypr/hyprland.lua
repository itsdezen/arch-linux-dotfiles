-- Hyprland — main entrypoint. Split into focused modules, required in order.
-- (Since Hyprland 0.55, hyprlang/.conf is deprecated in favor of Lua — see
-- AGENTS.md Known Gaps for migration notes and what's still unconfirmed.)
require("env")
require("monitors")
require("autostart")
require("decoration")
require("animations")
require("binds")
require("windowrules")

hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
        },
    },

    gestures = {
        workspace_swipe = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
    },
})
