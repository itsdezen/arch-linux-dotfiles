-- Session environment for a clean Wayland stack under Hyprland.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- fcitx5 input method (Unikey/Telex for Vietnamese, keyboard-us for English —
-- see fcitx5/.config/fcitx5/). Native Wayland GTK4/Qt6 clients pick fcitx5 up
-- over the text-input-v3 protocol without these, but XWayland and older
-- GTK3/Qt5 apps still need the classic immodule bridge env vars.
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- bibata-cursor-theme-bin (AUR). Exact installed directory name under
-- /usr/share/icons is only verifiable on real hardware — spot-check with
-- `find /usr/share/icons -maxdepth 1 -iname 'Bibata*'` on first boot and
-- correct this value if it differs. See AGENTS.md Known Gaps.
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
