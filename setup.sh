#!/bin/bash

################################################################################
#
# Setup my preferred shell environment for development work on MacOS or Linux.
#
# This script is for workstations, not servers. For a headless Debian/Ubuntu
# box use setup-server.sh instead.
#
# It installs CLI tools, symlinks expected config and settings, and registers
# scheduled maintenance jobs.
#
# Safe to re-run. It never overwrites config it didn't create.
#
# To run:
#
#   ./setup.sh                   config and scheduled jobs only, takes seconds
#   ./setup.sh --with-packages   also install everything in the Brewfile
#
################################################################################

set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") [--with-packages] [--force]"
  echo
  echo "  --with-packages   also install everything in the Brewfile (takes minutes)"
  echo "  --force           run even if this machine looks headless"
}

# Loop over every argument and reject anything unrecognised. Matching only on
# \$1 would make a typo - --wtih-packages - silently indistinguishable from
# passing no flag at all, so the script would look like it succeeded while
# quietly skipping the thing you asked for.
WITH_PACKAGES=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --with-packages) WITH_PACKAGES=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
  esac
done

# Refuse to run under Rosetta on Apple Silicon
if [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"Apple"* ]] && [[ "$(uname -m)" == "x86_64" ]]; then
  echo "ERROR: You're running under Rosetta on Apple Silicon."
  echo "Everything will install as x86 instead of native ARM."
  echo "Check Terminal > Get Info > uncheck 'Open using Rosetta', then reopen."
  exit 1
fi

# Refuse to run on what looks like a headless box
if [[ "$(uname)" != "Darwin" ]] && [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && [[ "$FORCE" -eq 0 ]]; then
  echo "ERROR: this machine looks headless - no DISPLAY or WAYLAND_DISPLAY." >&2
  echo "setup.sh is for workstations. On a server run setup-server.sh instead." >&2
  echo "If this really is a desktop, pass --force." >&2
  exit 1
fi

# Resolve the repo from this script's own location rather than hardcoding a
# path, so a clone anywhere works. Same approach as setup-server.sh.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Confirm the repo really is next to this script before symlinking a home
# directory at it.
#
# Keep in sync with the copy in setup-server.sh.
for marker in .aliases .gitconfig .zshrc; do
  if [[ ! -e "$DOTFILES_DIR/$marker" ]]; then
    echo "ERROR: $DOTFILES_DIR does not look like the dotfiles repo ($marker missing)." >&2
    echo "Run this script from inside a clone, not from a copy of the file." >&2
    exit 1
  fi
done

skipped_count=0

skip() {
  echo "SKIPPED $1 - $2"
  skipped_count=$((skipped_count + 1))
}

# Symlink source -> target
# Ignore and report an existing target.
#
# Keep in sync with the copy in setup-server.sh.
link() {
  local source_path="$1"
  local target_path="$2"

  if [[ ! -e "$source_path" ]]; then
    skip "$target_path" "source $source_path does not exist"
    return
  fi

  if [[ -L "$target_path" ]]; then
    local existing_link="$(readlink "$target_path")"
    [[ "$existing_link" == "$source_path" ]] && return
    skip "$target_path" "already a symlink to $existing_link"
    return
  fi

  # Only here so the message is accurate - cmp against a directory would fail
  # below anyway and wrongly call it "a different file".
  if [[ -d "$target_path" ]]; then
    skip "$target_path" "a real directory already exists there"
    return
  fi

  if [[ -e "$target_path" ]] && ! cmp -s "$source_path" "$target_path"; then
    skip "$target_path" "a different file already exists there"
    return
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -sfn "$source_path" "$target_path"
}

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/bin"

# --- Packages -----------------------------------------------------------------

# The Brewfile is the source of truth for what's installed. Refresh it after
# installing something new with:
#
#   brew bundle dump --file="$DOTFILES_DIR/Brewfile" --force --describe
#
# Opt-in because it takes minutes and hits the network, while the rest of this
# script takes seconds. Re-running setup.sh to pick up one new symlink shouldn't
# mean waiting for Homebrew.
if [[ "$WITH_PACKAGES" -eq 1 ]]; then
  # Put the native Homebrew first, exactly as .zshrc does. Both prefixes can
  # exist on an Apple Silicon Mac - /opt/homebrew native, /usr/local under
  # Rosetta - and /usr/local/bin comes earlier on the default PATH, so a bare
  # `brew` here would quietly install x86 builds on an ARM machine. This script
  # doesn't read .zshrc, so it has to make the same choice itself.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if command -v brew >/dev/null; then
    echo "Installing packages from Brewfile..."
    # Don't abort the whole run over one failure. Third-party taps in particular
    # fail routinely - Homebrew now refuses untrusted ones - and that shouldn't
    # stop the config from being symlinked.
    brew bundle --file="$DOTFILES_DIR/Brewfile" || \
      echo "WARNING: brew bundle reported failures - see above"
  else
    echo "SKIPPED packages - Homebrew not installed (see README)"
  fi
else
  echo "Skipping packages (pass --with-packages to install from the Brewfile)"
fi

# --- Config -------------------------------------------------------------------

echo "Symlinking config..."

# Symlink ssh config incl server aliases. ssh refuses to read a config that is
# writable by anyone but the owner, so the permissions matter on both ends.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
mkdir -p "$DOTFILES_DIR/.ssh"
touch "$DOTFILES_DIR/.ssh/config"
chmod 600 "$DOTFILES_DIR/.ssh/config"
link "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"

# Symlink VS Code user configuration, such as settings, keybindings, and
# profiles. The user directory lives in a different place on each OS.
case "$(uname)" in
  Darwin) vscode_user_dir="$HOME/Library/Application Support/Code/User" ;;
  Linux) vscode_user_dir="$HOME/.config/Code/User" ;;
  *) vscode_user_dir="" ;;
esac

if [[ -n "$vscode_user_dir" ]]; then
  link "$DOTFILES_DIR/settings.json" "$vscode_user_dir/settings.json"
fi

# Symlink personal shell command aliases
link "$DOTFILES_DIR/.aliases" "$HOME/.aliases"

# The committed .gitconfig is portable, so it symlinks like anything else.
# Identity and GUI-only settings hang off it via ~/.gitconfig.local.
link "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

if [[ ! -e "$HOME/.gitconfig.local" ]]; then
  cp "$DOTFILES_DIR/.gitconfig.local.example" "$HOME/.gitconfig.local"
  echo "Created ~/.gitconfig.local - check the name and email"
fi

# Pull in the workstation-only settings (VS Code as editor, merge and diff
# tool). This has to be appended here rather than declared in .gitconfig,
# because git resolves a relative include path against ~/ - where the symlink
# lives - not against the real file in this repo, so it could never find it.
# An absolute path works, and is only knowable at setup time.
# Match a real `path =` line, not the phrase - the example file mentions
# .gitconfig.workstation in its own comments, which a loose grep matches.
if ! grep -qE '^[[:space:]]*path[[:space:]]*=.*gitconfig\.workstation' "$HOME/.gitconfig.local"; then
  printf '\n[include]\n  path = %s/.gitconfig.workstation\n' "$DOTFILES_DIR" \
    >> "$HOME/.gitconfig.local"
  echo "Added the workstation include to ~/.gitconfig.local"
fi

# Symlink the global gitignore that .gitconfig's excludesfile points at. Note
# this is .gitignore_global, not this repo's own .gitignore - see Git config in
# the README for why they're separate.
link "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"

# Symlink rspec config
link "$DOTFILES_DIR/.rspec" "$HOME/.rspec"

# Symlink vim config
link "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"

# Symlink zsh config
link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Symlink starship config
link "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# Symlink claude config. These three are named explicitly because ~/.claude
# holds plenty of state I don't want touched (credentials, history, projects).
mkdir -p "$HOME/.claude/skills"
link "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
link "$DOTFILES_DIR/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

# Skills are globbed from *this repo*, not from ~/.claude/skills - which is the
# whole reason it's safe. Vendored and plugin skills install themselves into
# ~/.claude/skills as real directories and are never committed here, so the
# repo is itself the allowlist: globbing it can only ever pick up ones I wrote.
# Trailing slash stripped so the symlink target matches on a re-run.
for skill in "$DOTFILES_DIR"/.claude/skills/*/; do
  [[ -d "$skill" ]] || continue
  link "${skill%/}" "$HOME/.claude/skills/$(basename "$skill")"
done

# Symlink BuildKit config - caps the Docker build cache (see README)
link "$DOTFILES_DIR/buildkitd.toml" "$HOME/.config/buildkit/buildkitd.toml"

# Symlink my own scripts onto PATH. Globbed so a new script in bin/ is picked up
# without editing this file. Scripts that don't apply to this machine are
# expected to no-op themselves rather than be filtered here.
for script in "$DOTFILES_DIR"/bin/*.sh; do
  [[ -e "$script" ]] || continue
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# --- Shell --------------------------------------------------------------------

# .zshrc sources these plugins and runs `starship init` unconditionally, so
# without them every new shell opens with errors and no prompt. Same bootstrap
# as setup-server.sh --with-zsh - keep the two lists in sync.
mkdir -p "$HOME/.config/zsh"
for plugin in \
  "romkatv/zsh-defer" \
  "zsh-users/zsh-syntax-highlighting" \
  "zsh-users/zsh-history-substring-search" \
  "zsh-users/zsh-autosuggestions"
do
  plugin_name="${plugin##*/}"
  plugin_dir="$HOME/.config/zsh/$plugin_name"
  if [[ -d "$plugin_dir" ]]; then
    git -C "$plugin_dir" pull --quiet --ff-only || true
  else
    git clone --quiet --depth 1 "https://github.com/$plugin.git" "$plugin_dir"
    echo "  cloned $plugin_name"
  fi
done

if ! command -v starship >/dev/null; then
  echo "Installing starship..."
  curl -fsSL https://starship.rs/install.sh \
    | sh -s -- --yes --bin-dir "$HOME/.local/bin"
fi

# --- Scheduled jobs -------------------------------------------------------------

# Link every agent and register it with launchd, so adding job number two is a
# matter of dropping a plist in LaunchAgents/ and re-running this. macOS only -
# the Linux equivalents are systemd user timers, wired up by setup-server.sh.
# bootstrap fails if the job is already loaded, which is fine on a re-run.
if [[ "$(uname)" == "Darwin" ]]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  for plist in "$DOTFILES_DIR"/LaunchAgents/*.plist; do
    [[ -e "$plist" ]] || continue   # no nullglob, so an empty dir yields the pattern itself
    plist_name="$(basename "$plist")"
    link "$plist" "$HOME/Library/LaunchAgents/$plist_name"
    launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/$plist_name" 2>/dev/null || true
  done
fi

# --- Done ---------------------------------------------------------------------

echo
echo "Dotfiles symlinked!"

if [[ "$skipped_count" -gt 0 ]]; then
  echo "$skipped_count file(s) skipped - existing config was left untouched."
  echo "Move or delete those, then re-run this script to pick them up."
fi

# ~/.local/bin holds starship and my own scripts. .zshrc puts it on PATH, but
# that only takes effect in a new shell - and if this ran under bash, not at
# all until you start one.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    echo
    echo "NOTE: ~/.local/bin is not on your PATH in this shell, so starship and"
    echo "the bin/ scripts won't be found yet. Start a new shell, or for this"
    echo "one only:  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac
