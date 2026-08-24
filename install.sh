#!/usr/bin/env bash
set -euo pipefail

# Refuse immediately outside a real Arch Linux install — this repo is
# authored on macOS and must never attempt to touch pacman/systemctl there.
if [[ ! -f /etc/arch-release ]]; then
  printf '\033[0;31m✗\033[0m install.sh: /etc/arch-release not found — this only runs on Arch Linux.\n' >&2
  exit 1
fi

# ── colors / output helpers ─────────────────────────────────────────────────
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; BL='\033[0;34m'; P='\033[0;35m'; D='\033[2m'; B='\033[1m'; NC='\033[0m'
ok()       { printf "  ${G}✓${NC} %s\n" "$*"; }
skip()     { printf "  ${D}◎${NC} %s\n" "$*"; }
run()      { printf "  ${D}→${NC} %s\n" "$*"; }
warn()     { printf "  ${Y}!${NC} %s\n" "$*"; }
item_new() { printf "      ${G}+${NC} %s\n" "$*"; }
item_upd() { printf "      ${Y}↑${NC} %s\n" "$*"; }
item_rm()  { printf "      ${R}-${NC} %s\n" "$*"; }
abort() {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null
  SPIN_PID=""
  printf "\r\033[2K  ${R}✗${NC} %s\n" "$*" >&2
  exit 1
}
section() {
  _section_t=$SECONDS
  printf "\n${P}${B}➤ %s${NC}\n" "$*"
}
section_end() {
  [[ -n "$_section_t" ]] && printf "  ${D}%ds${NC}\n" "$(( SECONDS - _section_t ))"
}

# ── spinner ──────────────────────────────────────────────────────────────────

SPIN_PID=""
SUDO_KEEPALIVE_PID=""
_section_t=""
[[ -t 1 ]] && _TTY=true || _TTY=false
cleanup() {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null
  [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
}
trap cleanup EXIT

spin() {
  if ! $_TTY; then run "$1"; return; fi
  local msg="$1" i=0 frames='|/-\'
  printf "  ${BL}|${NC} %s" "$msg"
  ( while true; do
      printf "\r  ${BL}%s${NC} %s" "${frames:$i:1}" "$msg"
      i=$(( (i+1) % 4 )); sleep 0.05
    done ) &
  SPIN_PID=$!
  disown "$SPIN_PID"
}

spin_ok() {
  if ! $_TTY; then ok "$*"; return; fi
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null
  SPIN_PID=""
  printf "\r\033[2K  ${G}✓${NC} %s\n" "$*"
}

spin_warn() {
  if ! $_TTY; then warn "$*"; return; fi
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null
  SPIN_PID=""
  printf "\r\033[2K  ${Y}!${NC} %s\n" "$*"
}

spin_skip() {
  if ! $_TTY; then skip "$*"; return; fi
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null
  SPIN_PID=""
  printf "\r\033[2K  ${D}◎${NC} %s\n" "$*"
}

# ── paths / package sets ─────────────────────────────────────────────────────

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REPO="https://github.com/itsdezen/arch-linux-dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

STOW_PACKAGES=(zsh git starship mise ghostty hyprland waybar fuzzel mako hyprlock hypridle hyprpaper superfile nvim btop claude opencode codex herdr fcitx5 scripts)
# theme/ is deliberately excluded from STOW_PACKAGES — it's sourced in place
# from $DOTFILES_DIR/theme/theme by scripts, not symlinked into $HOME.

# packages whose target dir mixes static config with app-generated state
# (claude projects/sessions, herdr logs/sockets, opencode cache) — always
# stowed file-by-file so runtime-generated files never land in the repo.
NO_FOLD_PACKAGES=(claude herdr opencode codex)

# ── small utils ──────────────────────────────────────────────────────────────

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

is_no_fold() {
  local pkg="$1" p
  for p in "${NO_FOLD_PACKAGES[@]}"; do
    [[ "$p" == "$pkg" ]] && return 0
  done
  return 1
}

read_pkg_list() {
  local file="$1"
  local line
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(trim "$line")"
    [[ -n "$line" ]] && printf '%s\n' "$line"
  done < "$file"
}

# ── guards ───────────────────────────────────────────────────────────────────

require_not_root() {
  [[ "$EUID" -ne 0 ]] || abort "do not run as root — this script uses sudo where needed"
}

# ── packages ─────────────────────────────────────────────────────────────────

install_pacman_list() {
  local file="$1" label="$2"
  [[ -f "$file" ]] || abort "package list not found: $file"
  local pkgs=()
  while IFS= read -r pkg; do pkgs+=("$pkg"); done < <(read_pkg_list "$file")
  [[ ${#pkgs[@]} -gt 0 ]] || { skip "$label — nothing to install"; return; }
  spin "Installing $label (${#pkgs[@]} packages)"
  if sudo pacman -S --needed --noconfirm "${pkgs[@]}" >/dev/null 2>&1; then
    spin_ok "$label installed"
  else
    spin_warn "$label — some packages failed, check manually"
  fi
}

install_aur_list() {
  local file="$1" label="$2"
  [[ -f "$file" ]] || abort "package list not found: $file"
  command -v paru &>/dev/null || abort "paru not found — bootstrap_paru should have run first"
  local pkgs=()
  while IFS= read -r pkg; do pkgs+=("$pkg"); done < <(read_pkg_list "$file")
  [[ ${#pkgs[@]} -gt 0 ]] || { skip "$label — nothing to install"; return; }
  spin "Installing $label (${#pkgs[@]} packages)"
  if paru -S --needed --noconfirm --skipreview "${pkgs[@]}" >/dev/null 2>&1; then
    spin_ok "$label installed"
  else
    spin_warn "$label — some packages failed, check manually"
  fi
}

install_ghostty() {
  section "Ghostty"
  # Newly official as of ~April 2026 — try pacman first, fall back to the
  # AUR build via paru if the local mirror hasn't synced it yet. Which path
  # actually fires is only knowable on the real install date (Known Gap).
  if pacman -Qi ghostty &>/dev/null; then
    skip "ghostty (already installed)"
  elif sudo pacman -S --needed --noconfirm ghostty >/dev/null 2>&1; then
    ok "ghostty installed (official repo)"
  else
    warn "ghostty not available in official repos yet — falling back to AUR"
    bootstrap_paru
    if paru -S --needed --noconfirm --skipreview ghostty >/dev/null 2>&1; then
      ok "ghostty installed (AUR)"
    else
      warn "ghostty install failed — install manually later"
    fi
  fi
  section_end
}

bootstrap_paru() {
  if command -v paru &>/dev/null; then
    return
  fi
  section "paru"
  spin "Building paru from AUR"
  local tmp
  tmp="$(mktemp -d)"
  if git clone --quiet https://aur.archlinux.org/paru.git "$tmp/paru" >/dev/null 2>&1 \
    && (cd "$tmp/paru" && makepkg -si --noconfirm) >/dev/null 2>&1; then
    spin_ok "paru installed"
  else
    rm -rf "$tmp"
    abort "paru build failed"
  fi
  rm -rf "$tmp"
  section_end
}

install_devtools_vendor() {
  section "Vendor dev tools (no Arch package)"

  if command -v claude &>/dev/null; then
    skip "claude (already installed)"
  else
    spin "Installing Claude Code"
    if curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1; then
      spin_ok "Claude Code installed"
    else
      spin_warn "Claude Code install failed — non-fatal, install manually later"
    fi
  fi

  if command -v codex &>/dev/null; then
    skip "codex (already installed)"
  else
    spin "Installing Codex CLI"
    # CODEX_NON_INTERACTIVE suppresses the installer's own "Start Codex now?"
    # prompt, which otherwise hangs forever with no real stdin to read from
    # under `curl | bash`.
    if (export CODEX_NON_INTERACTIVE=true; curl -fsSL https://chatgpt.com/codex/install.sh | bash) >/dev/null 2>&1; then
      spin_ok "Codex CLI installed"
    else
      spin_warn "Codex CLI install failed — non-fatal, install manually later"
    fi
  fi

  if command -v herdr &>/dev/null; then
    skip "herdr (already installed)"
  else
    spin "Installing herdr"
    # This URL as the correct upstream for herdr is not 100% verified — see
    # AGENTS.md Known Gaps. Spot-check on the first real run.
    if curl -fsSL https://herdr.dev/install.sh | bash >/dev/null 2>&1; then
      spin_ok "herdr installed"
    else
      spin_warn "herdr install failed — non-fatal, install manually later"
    fi
  fi

  section_end
}

# ── runtimes / plugins ───────────────────────────────────────────────────────

install_runtimes() {
  section "Runtimes"
  if ! command -v mise &>/dev/null; then
    warn "mise not found — skipping runtime install"
    section_end
    return
  fi
  spin "Installing runtimes"
  local out
  if out=$(mise install --yes 2>&1); then
    if echo "$out" | grep -q "all tools are installed"; then
      spin_skip "Runtimes up to date"
    else
      spin_ok "Runtimes installed"
    fi
  else
    spin_warn "mise install failed — check manually"
  fi
  section_end
}

sync_nvim_plugins() {
  section "Neovim plugins"
  if ! command -v nvim &>/dev/null; then
    warn "nvim not found — skipping plugin sync"
    section_end
    return
  fi
  spin "Syncing plugins"
  if nvim --headless "+Lazy! sync" +qa &>/dev/null; then
    spin_ok "Plugins synced"
  else
    spin_warn "Neovim plugin sync failed — check manually"
  fi
  section_end
}

# ── stow ─────────────────────────────────────────────────────────────────────

stow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES_DIR/$pkg" ]] || { warn "package not found: $pkg"; return; }
  local fold_flag=""
  is_no_fold "$pkg" && fold_flag="--no-folding"
  local conflicts
  # shellcheck disable=SC2086  # $fold_flag intentionally unquoted: word-splits
  # away when empty rather than being passed as a literal empty argument.
  conflicts=$(cd "$DOTFILES_DIR" && stow -n -t "$HOME" -R $fold_flag "$pkg" 2>&1 \
    | perl -ne '
        if (/existing target is not owned by stow: (.+)$/) { print "$1\n" }
        elsif (/existing target is stowed to a different package: (.+?) => /) { print "$1\n" }
        elsif (/cannot stow .* over existing (?:directory )?target (.+?)(?: since\b|$)/) { print "$1\n" }
      ') || true
  while IFS= read -r conflict; do
    [[ -n "$conflict" ]] || continue
    local target="$HOME/$conflict"
    [[ "$target" == "$HOME/"* ]] || continue
    mkdir -p "$BACKUP_DIR/$(dirname "$conflict")"
    mv "$target" "$BACKUP_DIR/$conflict"
  done <<<"$conflicts"
  # shellcheck disable=SC2086
  if (cd "$DOTFILES_DIR" && stow -t "$HOME" -R $fold_flag "$pkg") 2>/dev/null; then
    ok "$pkg"
    while IFS= read -r conflict; do
      [[ -n "$conflict" ]] || continue
      item_upd "backed up ~/$conflict → $BACKUP_DIR/$conflict"
    done <<<"$conflicts"
  else
    warn "$pkg — stow failed"
  fi
}

unstow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES_DIR/$pkg" ]] || return
  local fold_flag=""
  is_no_fold "$pkg" && fold_flag="--no-folding"
  # shellcheck disable=SC2086
  if (cd "$DOTFILES_DIR" && stow -t "$HOME" -D $fold_flag "$pkg") 2>/dev/null; then
    ok "$pkg"
  else
    warn "$pkg unstow failed"
  fi
}

backup_and_stow() {
  section "Dotfiles (stow)"
  command -v stow &>/dev/null || abort "stow not found"
  local pkg
  for pkg in "${STOW_PACKAGES[@]}"; do
    stow_pkg "$pkg"
  done
  if [[ -d "$BACKUP_DIR" ]]; then
    warn "conflicting files backed up to $BACKUP_DIR"
  fi
  section_end
}

# ── system files (never stowed) ─────────────────────────────────────────────

deploy_system_files() {
  section "System files"
  sudo install -D -m 644 "$DOTFILES_DIR/system/etc/greetd/config.toml" /etc/greetd/config.toml
  ok "/etc/greetd/config.toml"
  section_end
}

configure_greetd() {
  section "greetd"
  # Enable only — starting it mid-script (--now) would hijack the current
  # TTY out from under this running install.
  if sudo systemctl enable greetd.service >/dev/null 2>&1; then
    ok "greetd enabled (starts on next boot)"
  else
    warn "failed to enable greetd — enable manually: sudo systemctl enable greetd"
  fi
  section_end
}

enable_services() {
  section "Services"

  if sudo systemctl enable NetworkManager.service >/dev/null 2>&1; then
    ok "NetworkManager enabled"
  else
    warn "failed to enable NetworkManager"
  fi

  if sudo systemctl enable bluetooth.service >/dev/null 2>&1; then
    ok "bluetooth enabled"
  else
    warn "failed to enable bluetooth"
  fi

  if command -v docker &>/dev/null; then
    if sudo systemctl enable docker.service >/dev/null 2>&1; then
      ok "docker enabled"
    else
      warn "failed to enable docker"
    fi
    if groups "$USER" | grep -qw docker; then
      skip "$USER already in docker group"
    elif sudo usermod -aG docker "$USER"; then
      ok "added $USER to docker group (re-login required)"
    else
      warn "failed to add $USER to docker group"
    fi
  fi

  if systemctl --user enable pipewire pipewire-pulse wireplumber >/dev/null 2>&1; then
    ok "pipewire user units enabled"
  else
    warn "failed to enable pipewire user units"
  fi

  if groups "$USER" | grep -qw video; then
    skip "$USER already in video group"
  elif sudo usermod -aG video "$USER"; then
    ok "added $USER to video group (re-login required, needed for brightnessctl)"
  else
    warn "failed to add $USER to video group"
  fi

  section_end
}

set_default_shell() {
  section "Shell"
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    skip "zsh already default shell"
  elif chsh -s "$zsh_path" "$USER"; then
    ok "default shell set to zsh (re-login required)"
  else
    warn "failed to chsh — run manually: chsh -s $zsh_path"
  fi
  section_end
}

# ── validation ───────────────────────────────────────────────────────────────

VALIDATE_PASS=0
VALIDATE_WARN=0

check_bin() {
  if command -v "$1" &>/dev/null; then
    ok "$1 found"
    VALIDATE_PASS=$((VALIDATE_PASS + 1))
  else
    warn "$1 not found"
    VALIDATE_WARN=$((VALIDATE_WARN + 1))
  fi
}

check_service() {
  if systemctl is-enabled "$1" &>/dev/null; then
    ok "$1 enabled"
    VALIDATE_PASS=$((VALIDATE_PASS + 1))
  else
    warn "$1 not enabled"
    VALIDATE_WARN=$((VALIDATE_WARN + 1))
  fi
}

validate_installation() {
  section "Validation"
  VALIDATE_PASS=0
  VALIDATE_WARN=0

  local bin
  # `spf` is superfile's binary name per current upstream — only confirmable
  # on real hardware (Known Gap).
  for bin in Hyprland waybar fuzzel mako hyprlock hypridle hyprpaper spf \
             nvim zsh starship stow tuigreet ghostty git mise gh lazygit \
             docker jq yq direnv shellcheck fd rg btop chromium; do
    check_bin "$bin"
  done

  local svc
  for svc in NetworkManager bluetooth greetd docker; do
    check_service "$svc"
  done

  printf "\n"
  if [[ "$VALIDATE_WARN" -eq 0 ]]; then
    printf "  ${G}${B}PASS${NC} — %d checks passed, 0 warnings\n" "$VALIDATE_PASS"
  else
    printf "  ${Y}${B}WARN${NC} — %d checks passed, %d warnings (see above)\n" "$VALIDATE_PASS" "$VALIDATE_WARN"
  fi
  section_end
}

# ── commands ─────────────────────────────────────────────────────────────────

cmd_install() {
  local _t0=$SECONDS

  section "System"
  skip "$(cat /etc/arch-release 2>/dev/null || echo 'Arch Linux')"
  command -v git &>/dev/null || abort "git missing — install with: sudo pacman -S git"
  command -v curl &>/dev/null || abort "curl missing — install with: sudo pacman -S curl"
  section_end

  section "sudo"
  sudo -v || abort "sudo authentication failed"
  # keep-alive: refresh the sudo timestamp until this script exits
  ( while true; do sudo -n true 2>/dev/null; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
  disown "$SUDO_KEEPALIVE_PID"
  section_end

  section "Official packages"
  install_pacman_list "$DOTFILES_DIR/packages/official.txt" "official packages"
  section_end

  install_ghostty
  bootstrap_paru

  section "AUR packages"
  install_aur_list "$DOTFILES_DIR/packages/aur.txt" "AUR packages"
  section_end

  section "Dev tools"
  install_pacman_list "$DOTFILES_DIR/packages/devtools.txt" "dev tools"
  section_end

  install_devtools_vendor
  backup_and_stow
  install_runtimes
  sync_nvim_plugins
  deploy_system_files
  configure_greetd
  enable_services
  set_default_shell
  validate_installation

  printf "\n  ${G}✓${NC} done  ${D}$(( SECONDS - _t0 ))s total${NC}\n\n"
  warn "Reboot (or re-login) to pick up group membership, default shell, and greetd."
}

cmd_bootstrap() {
  # Remote entry point for a fresh box with no git yet — invoke as:
  #   bash <(curl -fsSL https://raw.githubusercontent.com/itsdezen/arch-linux-dotfiles/main/install.sh) bootstrap
  # curl itself must already be present (it's not universally guaranteed on
  # a bare `base` install either — install with `pacman -S curl` first if
  # the one-liner above fails to even start).
  section "git"
  if command -v git &>/dev/null; then
    skip "git"
  else
    spin "Installing git"
    if sudo pacman -Syu --needed --noconfirm git >/dev/null 2>&1; then
      spin_ok "git installed"
    else
      abort "failed to install git — check your network/mirrors and try again"
    fi
  fi
  section_end

  section "Dotfiles"
  local dest="$HOME/Developer/dotfiles"
  if [[ -d "$dest/.git" ]]; then
    skip "already cloned — $dest"
  else
    mkdir -p "$(dirname "$dest")"
    spin "Cloning dotfiles"
    if git clone --quiet "$DOTFILES_REPO" "$dest" >/dev/null 2>&1; then
      spin_ok "Dotfiles cloned"
    else
      abort "git clone failed — check your network/mirrors and try again"
    fi
  fi
  section_end

  exec "$dest/install.sh" install
}

cmd_stow() {
  backup_and_stow
  install_runtimes
  sync_nvim_plugins
}

cmd_validate() {
  validate_installation
}

cmd_uninstall() {
  printf "${Y}!${NC} Remove all dotfiles symlinks? [y/N] "
  read -r resp
  [[ "$resp" =~ ^[Yy]$ ]] || { ok "aborted"; exit 0; }

  section "Dotfiles"
  command -v stow &>/dev/null || abort "stow not found"
  local pkg
  for pkg in "${STOW_PACKAGES[@]}"; do unstow_pkg "$pkg"; done
  section_end

  printf "\n  ${G}✓${NC} done\n"
  warn "Installed pacman/AUR packages were not removed"
  warn "System files (/etc/greetd/config.toml) were not removed"
}

# ── entrypoint ───────────────────────────────────────────────────────────────

require_not_root

case "${1:-install}" in
  bootstrap) cmd_bootstrap ;;
  install)   cmd_install ;;
  stow)      cmd_stow ;;
  validate)  cmd_validate ;;
  uninstall) cmd_uninstall ;;
  *) printf "usage: %s [bootstrap|install|stow|validate|uninstall]\n" "$0"; exit 1 ;;
esac
