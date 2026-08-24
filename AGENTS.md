# AGENTS.md

AI assistant instructions for this dotfiles repository. For stack overview, quick start, and scripts — see **[README.md](./README.md)**.

This repo bootstraps a fresh Arch Linux install into a Hyprland/Wayland tiling desktop (TokyoNight Night theme) plus a daily-driver dev-tools layer, via a single `install.sh` and GNU Stow.

---

## Design Philosophy

1. **One script**: `install.sh` is the single entry point — `install`, `stow`, `validate`, `uninstall`. No per-tool install scripts.
2. **Modular**: each Stow package is self-contained. Files symlink into `$HOME` via `stow -t "$HOME"`.
3. **Back up before replace, never silently delete**: a conflicting file at a stow target gets moved into a timestamped `~/.dotfiles-backup-<timestamp>/` before the real stow runs. Why: a bare-metal first boot has no prior git history (or Time Machine) to fall back on the way an established personal machine does — silently deleting a conflict here has no undo. This is a deliberate divergence from the sibling macOS dotfiles repo, which deletes conflicts with no backup.
4. **Minimal**: no abstractions beyond what the tools need.

---

## Directory Structure

```
arch-linux-dotfiles/
├── install.sh  AGENTS.md  CLAUDE.md  README.md
├── packages/            → official.txt, aur.txt, devtools.txt (pacman/AUR package lists)
├── theme/                → colors, typography, spacing, theme (sourced in place, not stowed)
├── zsh/                  → ~/.zshrc, ~/.zshenv, ~/.zprofile
├── git/                  → ~/.gitconfig, ~/.config/git/ignore
├── starship/             → ~/.config/starship.toml
├── mise/                 → ~/.config/mise/config.toml
├── ghostty/              → ~/.config/ghostty/
├── hyprland/             → ~/.config/hypr/
├── waybar/               → ~/.config/waybar/
├── fuzzel/               → ~/.config/fuzzel/
├── mako/                 → ~/.config/mako/
├── hyprlock/             → ~/.config/hyprlock/
├── hypridle/             → ~/.config/hypridle/
├── hyprpaper/            → ~/.config/hyprpaper/
├── superfile/            → ~/.config/superfile/
├── nvim/                 → ~/.config/nvim/
├── btop/                 → ~/.config/btop/
├── claude/               → ~/.claude/settings.json
├── opencode/             → ~/.config/opencode/
├── codex/                → ~/.codex/config.toml
├── herdr/                → ~/.config/herdr/config.toml
├── scripts/              → ~/.local/bin/{screenshot,clipboard-picker,wallpaper-set}
└── system/etc/greetd/    → /etc/greetd/config.toml (deployed by install.sh, never stowed)
```

---

## Glossary

Three senses of "package" in this repo:

- **Stow package** — a top-level directory here (e.g. `hyprland/`, `zsh/`) that Stow symlinks into `$HOME`.
- **pacman package** — an official Arch package (`core`/`extra`), listed in `packages/official.txt` or `packages/devtools.txt`.
- **AUR package** — a community package built from source via `paru`, listed in `packages/aur.txt`.

---

## Contributor Rules

- Every Stow package's internal path mirrors its intended `$HOME` target exactly (e.g. `waybar/.config/waybar/config.jsonc` → `~/.config/waybar/config.jsonc`). No missing leading dot, no typo'd `.config`.
- **`system/etc/` files are never stowed — only `install.sh` writes into `/etc`** (via `deploy_system_files`, an explicit `sudo install -D`).
- New scripts under `scripts/.local/bin/` must be `chmod +x` before committing — Stow preserves permissions as-is, so a non-executable symlinked script silently fails.
- Adding a package: add it to the relevant Stow package directory + `STOW_PACKAGES` in `install.sh`, or to the matching `packages/*.txt` file (`official.txt`, `aur.txt`, `devtools.txt`).
- Theme colors are hand-authored per tool from the hex values in `theme/colors` (most config languages here can't `source` a shell file). If the palette ever changes, update every hand-authored config — Waybar, Fuzzel, Mako, hyprlock, Hyprland `decoration.conf` — in the same change. Ghostty, Neovim, Superfile, and herdr instead use a built-in/named TokyoNight preset — never hand-author colors when a preset already exists.

---

## Known Gaps

Spot-check these on the real box; none of them block a first run:

- **Wallpaper**: no image is bundled. `hyprpaper` shows a blank background until you run `wallpaper-set <path>` once.
- **Dark-only v1**: no light theme variant.
- **No hypridle "dim" stage**: needs `brightnessctl`, a laptop-only tool not in scope here.
- **herdr install source unverified**: `install_devtools_vendor()` curls `https://herdr.dev/install.sh` as herdr's official installer — this was not 100% confirmed against upstream. Spot-check before trusting it blindly.
- **No Bluetooth/NetworkManager GUI tray applet**: CLI-only (`nmcli`, `bluetoothctl`) until one is added.
- **Font family names**: `env.conf`/Waybar/Fuzzel assume `inter-font` resolves to `Inter` and `ttf-fantasque-nerd` resolves to `FantasqueSansM Nerd Font Mono` in `fc-list` — only confirmable on real hardware.
- **Bibata cursor directory name**: `env.conf` assumes `Bibata-Modern-Ice` under `/usr/share/icons` — the AUR `bibata-cursor-theme-bin` package's actual installed directory name is only confirmable on real hardware.
- **Ghostty install path**: `install_ghostty()` tries the official `pacman` package first, falls back to AUR via `paru` — which path actually fires depends on mirror sync state on the real install date.
- **`spf` binary name**: `binds.conf` (`SUPER+E`) and `install.sh`'s validate step assume superfile's installed binary is named `spf`, not `superfile` — confirm on first run.
- **Codex/Claude Code configs start fresh**: the ported `codex/.codex/config.toml` and `claude/.claude/settings.json` intentionally drop the source macOS repo's machine-specific state (per-project trust levels, hook hashes, an absolute-path `SessionStart` hook script that doesn't exist here) — both tools will re-prompt/re-onboard on first use, which is expected.

---

## Commit & Branch Convention

- Conventional Commits: `type(scope): summary`.
- Branch names: at most three words, hyphen-separated, no slashes or type prefixes.

This is a deliberate difference from the sibling `~/Developer/dotfiles` repo's emoji-commit style — not an inconsistency to fix there.
