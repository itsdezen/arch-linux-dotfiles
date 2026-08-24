-- Tiled by default. Float only dialogs/pickers/PiP.
--
-- `pin = true` alongside `float = true` for Picture-in-Picture mirrors the
-- old two-rule `windowrulev2 = float, ...` + `windowrulev2 = pin, ...` pair.
-- Whether `pin` is a valid static window_rule field (vs. only a keybind
-- dispatcher, hl.dsp.window.pin()) isn't confirmed in current docs — spot
-- check PiP windows float without staying pinned on top; see AGENTS.md
-- Known Gaps.
hl.window_rule({
    name  = "float-pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
})

local floatClasses = {
    "pavucontrol",
    "nm-connection-editor",
    "blueman-manager",
    "file_progress",
    "confirm",
    "confirmreset",
    "dialog",
    "download",
    "notification",
    "error",
    "splash",
    "polkit-gnome-authentication-agent-1",
    "hyprpolkitagent",
}

for _, class in ipairs(floatClasses) do
    hl.window_rule({
        name  = "float-" .. class,
        match = { class = "^(" .. class .. ")$" },
        float = true,
    })
end
