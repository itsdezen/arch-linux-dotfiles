# arch-linux-dotfiles

Bootstraps a fresh Arch Linux install into a Hyprland/Wayland tiling desktop — keyboard-first, TokyoNight Night themed — plus a daily-driver dev-tools layer, via GNU Stow and a single `install.sh`.

## Stack

| Layer | Tool |
|---|---|
| Compositor | Hyprland (Wayland) |
| Bar | Waybar |
| Launcher | Fuzzel |
| Notifications | Mako |
| Lock / idle / wallpaper | hyprlock / hypridle / hyprpaper |
| Display manager | greetd + tuigreet |
| Terminal | Ghostty |
| Shell / prompt | Zsh (zinit) + Starship |
| File manager | Superfile |
| Editor | Neovim (LazyVim) |
| Dotfile management | GNU Stow |
| Package management | pacman + paru (AUR) |

**Theme**: TokyoNight Night, unified across every themed tool. Hex values live in `theme/colors` — see [AGENTS.md](./AGENTS.md) for how each tool consumes them.

**Dev-tools layer**: mise, GitHub CLI, lazygit, Docker, jq/yq, direnv, shellcheck, herdr, Claude Code, Codex CLI, OpenCode — so the box works as a full daily-driver dev environment, not just a desktop.

## Quick start

**Fresh machine, no git yet** (installs git, clones to `~/Developer/dotfiles`, runs install):

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/itsdezen/arch-linux-dotfiles/main/install.sh) bootstrap
```

**Already cloned:**

```sh
git clone https://github.com/itsdezen/arch-linux-dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh
```

Requires a fresh Arch Linux install (`/etc/arch-release` present) and a non-root user with sudo access. `install.sh` installs packages, bootstraps `paru`, stows every config, deploys `/etc/greetd/config.toml`, enables services, and sets Zsh as your default shell.

Other entry points:

```sh
./install.sh bootstrap  # fresh machine: install git, clone to ~/Developer/dotfiles, then install
./install.sh stow       # re-stow configs, sync mise runtimes + nvim plugins (e.g. after editing a package)
./install.sh validate   # check binaries/services, print a PASS/WARN summary
./install.sh uninstall  # remove all stow symlinks (asks for confirmation)
```

First boot has no wallpaper bundled — set one with:

```sh
wallpaper-set ~/Pictures/your-wallpaper.jpg
```

## Stow packages

Each top-level directory is a Stow package; `install.sh` stows all of them except `theme/` (sourced in place, not symlinked). See [AGENTS.md](./AGENTS.md) Directory Structure for the full package → target mapping.

## Scripts

| Script | Purpose |
|---|---|
| `screenshot {full\|region} [--copy]` | grim + slurp, optional clipboard copy |
| `clipboard-picker` | cliphist history via a Fuzzel dmenu |
| `wallpaper-set <path>` | sets and live-reloads the hyprpaper wallpaper |

## Contributing

See [AGENTS.md](./AGENTS.md) for design philosophy, contributor rules, and known gaps.
