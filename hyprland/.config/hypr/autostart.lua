-- Autostart — bar, notifications, wallpaper, idle daemon, polkit agent,
-- and clipboard-history watchers (cliphist backs scripts/clipboard-picker).
-- No direct exec-once equivalent in the Lua API — hl.exec_cmd() inside the
-- hyprland.start event is the documented replacement.
hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
