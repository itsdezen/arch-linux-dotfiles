local mainMod = "SUPER"
-- ALT, not SUPER: keyd remaps SUPER+K -> Ctrl+Shift+K at the evdev level
-- (system/etc/keyd/default.conf) for Ghostty clear-screen, below Hyprland's
-- SUPER grab, so Hyprland would never see a plain SUPER+K here.
local navMod = "ALT"

-- Apps
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd("fuzzel"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd("spf"))
-- SHIFT+V, not V: keyd remaps SUPER+V -> Ctrl+Shift+V at the evdev level
-- (system/etc/keyd/default.conf) for Ghostty paste, below Hyprland's SUPER
-- grab, so Hyprland would never see a plain SUPER+V here.
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("clipboard-picker"))

-- Window management
hl.bind(mainMod .. " + W",             hl.dsp.window.close())
hl.bind(mainMod .. " + Q",             hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q",     hl.dsp.exit())
hl.bind(mainMod .. " + F",             hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))

-- Focus (vim-style)
hl.bind(navMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(navMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(navMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(navMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move window (vim-style)
hl.bind(navMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(navMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(navMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(navMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Workspaces: SUPER+[1-9] switch, SUPER+SHIFT+[1-9] move window
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Screenshot / lock
hl.bind("Print",                   hl.dsp.exec_cmd("screenshot full"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("screenshot region --copy"))
hl.bind(mainMod .. " + ESCAPE",    hl.dsp.exec_cmd("hyprlock"))

-- Brightness (media keys; brightnessctl needs the "video" group — see
-- enable_services in install.sh)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Mouse (move/resize floating windows)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
