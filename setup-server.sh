#!/bin/bash

################################################################################
#
# Set up my preferred shell environment on a Debian/Ubuntu server.
#
# This script is for servers, not workstations.
#
# Sets up familiar config, settings, CLI tools and aliases that make sense for a
# headless box, so that it's not a chore to manage it.
#
# To run:
#
#   ./setup-server.sh
#   ./setup-server.sh --with-zsh  # also installs zsh and starship prompt
#
################################################################################

set -euo pipefail

# Resolve the repo from this script's own location rather than hardcoding a
# path. Servers don't necessarily clone to ~/code/benschem.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Usage: $(basename "$0") [--with-zsh]"
  echo
  echo "  --with-zsh   also install zsh, its plugins and the starship prompt"
}

# Loop over every argument and reject anything unrecognised. Matching only on
# \$1 would make a typo - --with-zhs - silently indistinguishable from passing
# no flag at all, so the script would look like it succeeded while quietly
# skipping the thing you asked for.
WITH_ZSH=0
for arg in "$@"; do
  case "$arg" in
    --with-zsh) WITH_ZSH=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
  esac
done

# Confirm the repo really is next to this script before symlinking a home
# directory at it.
#
# Keep in sync with the copy in setup.sh.
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
# Keep in sync with the copy in setup.sh.
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

command -v apt-get >/dev/null || {
  echo "This script is for Debian/Ubuntu. On macOS use setup.sh."
  exit 1
}

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/bin"

# --- Packages ----------------------------------------------------------------

echo "Installing packages..."

sudo apt-get update -qq
sudo apt-get install -y -qq \
  bat \
  ca-certificates \
  curl \
  fd-find \
  git \
  git-delta \
  htop \
  jq \
  ncdu \
  ripgrep \
  tmux \
  tree \
  unzip \
  vim \
  wget

# Rename batcat to bat and fdfind to fd to fix them on debian
[[ -x /usr/bin/batcat ]] && ln -sfn /usr/bin/batcat "$HOME/.local/bin/bat"
[[ -x /usr/bin/fdfind ]] && ln -sfn /usr/bin/fdfind "$HOME/.local/bin/fd"

# --- Locale ------------------------------------------------------------------

# .zshrc on my other machines exports LANG=en_AU.UTF-8, and ssh forwards it.
# Set the same locale on this machine too so every ssh command doesn't warn.
if ! locale -a 2>/dev/null | grep -qi "en_AU.utf8"; then
  echo "Generating en_AU.UTF-8 locale..."
  sudo sed -i 's/^# *en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/' /etc/locale.gen
  sudo locale-gen
fi

# --- Terminal ----------------------------------------------------------------

# ssh forwards your local $TERM, but the terminfo entry describing that terminal
# lives on the workstation. Ghostty, Kitty and WezTerm all ship their own rather
# than waiting for ncurses to carry them, so a stock Debian box has never heard
# of them. With no capabilities to look up, zsh's line editor can't work out how
# to move the cursor or erase a line, and the prompt garbles - doubled letters,
# phantom spaces, backspace leaving debris.
#
# Only the machine that has the entry can hand it over, and this script runs on
# the server, so all it can do is print the command to run from the other end.
if command -v infocmp >/dev/null && [[ -n "${TERM:-}" && "$TERM" != "dumb" ]]; then
  if ! infocmp "$TERM" >/dev/null 2>&1; then
    echo
    echo "NOTE: no terminfo entry here for TERM=$TERM, so the prompt will misbehave."
    echo "From the workstation you ssh in from, run:"
    echo
    echo "  infocmp -x $TERM | ssh $(hostname) tic -x -"
    echo
    echo "(swap $(hostname) for whatever Host name your ~/.ssh/config uses.)"
    echo "-x carries the terminal's extended capabilities; tic compiles the entry"
    echo "into ~/.terminfo here, so it needs no sudo."
  fi
fi

# --- Portable config ---------------------------------------------------------

echo "Symlinking config..."

link "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
link "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
link "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"

# Caps the Docker build cache. Belongs here rather than only on workstations:
# the prune timer below is installed on servers too, and the cap is the other
# half of the same mechanism - a size ceiling plus a periodic sweep. Harmless
# on a box without Docker, since nothing reads it.
link "$DOTFILES_DIR/buildkitd.toml" "$HOME/.config/buildkit/buildkitd.toml"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# --- Scheduled jobs ------------------------------------------------------------

# Symlink my own scripts onto PATH. Globbed so a new script in bin/ is picked up
# without editing this file. Scripts that don't apply to this machine are
# expected to no-op themselves rather than be filtered here (prune-ane-cache.sh,
# for instance, exits immediately on anything that isn't macOS).
for script in "$DOTFILES_DIR"/bin/*.sh; do
  [[ -e "$script" ]] || continue
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Link every unit and enable every timer, so adding job number two is a matter
# of dropping two files in systemd/ and re-running this. Each job's script is
# responsible for no-opping when it has nothing to do (the buildx prune, for
# instance, exits quietly when there's no Docker daemon), which keeps this loop
# from needing to know anything about individual jobs.
if command -v systemctl >/dev/null; then
  systemd_user_dir="$HOME/.config/systemd/user"

  for unit in "$DOTFILES_DIR"/systemd/*.service "$DOTFILES_DIR"/systemd/*.timer; do
    [[ -e "$unit" ]] || continue   # no nullglob, so an empty dir yields the pattern itself
    link "$unit" "$systemd_user_dir/$(basename "$unit")"
  done

  systemctl --user daemon-reload

  for timer in "$DOTFILES_DIR"/systemd/*.timer; do
    [[ -e "$timer" ]] || continue
    systemctl --user enable --now "$(basename "$timer")"
    echo "  enabled $(basename "$timer")"
  done

  # User timers only fire while the user has a session, unless lingering is on.
  # On a headless box you are usually logged out, so without this they simply
  # never run - and nothing warns you about it.
  if ! loginctl show-user "$USER" --property=Linger 2>/dev/null | grep -q "Linger=yes"; then
    echo "Enabling linger so timers run while you're logged out..."
    sudo loginctl enable-linger "$USER"
  fi

  echo "Scheduled jobs active (systemctl --user list-timers)"
fi

# --- Git ---------------------------------------------------------------------

# The committed .gitconfig is portable - vim as the editor, delta as the pager
# (installed above), and excludesfile relative to ~ - so it symlinks here just
# like on a workstation. The GUI-only settings live in .gitconfig.workstation,
# which only setup.sh wires in, so nothing here reaches for VS Code.
link "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# Identity is per-machine and never committed. Seed it, then leave it alone -
# a server may well want a different address, or none at all.
if [[ ! -e "$HOME/.gitconfig.local" ]]; then
  cp "$DOTFILES_DIR/.gitconfig.local.example" "$HOME/.gitconfig.local"
  echo "Created ~/.gitconfig.local - check the name and email"
fi

# --- zsh and starship --------------------------------------------------------

if [[ "$WITH_ZSH" -eq 1 ]]; then
  echo "Installing zsh and starship..."
  sudo apt-get install -y -qq zsh

  # .zshrc sources these unconditionally, so without them every shell opens with
  # errors. They're plain git clones, no package needed. Keep in sync with the
  # list in setup.sh.
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

  # Also unconditional in .zshrc, so it has to exist before the shell is usable.
  if ! command -v starship >/dev/null; then
    curl -fsSL https://starship.rs/install.sh \
      | sh -s -- --yes --bin-dir "$HOME/.local/bin"
  fi

  link "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
  link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

  # Zsh offered, not forced.
  # `ssh host command` keeps working regardless of this setting.
  if [[ "$SHELL" != *zsh ]]; then
    echo
    echo "To make zsh the login shell:  chsh -s \"\$(command -v zsh)\""
    echo "Verify it works with a plain \`zsh\` first - a broken login shell is"
    echo "much easier to fix before it's the default."
  fi
else
  echo "Skipping zsh (pass --with-zsh to install it)"
  echo "  Loading aliases in bash: echo '[ -f ~/.aliases ] && . ~/.aliases' >> ~/.bashrc"
  echo "  Note that aliases calling zsh functions (gbl, gca, mkcd, please)"
  echo "  won't work in bash - those are defined in zsh/functions/."
fi

# --- Done --------------------------------------------------------------------

echo
echo "Server setup complete."

if [[ "$skipped_count" -gt 0 ]]; then
  echo "$skipped_count file(s) skipped - existing config was left untouched."
  echo "Move or delete those, then re-run this script to pick them up."
fi

# ~/.local/bin holds the bat/fd symlinks and starship. .zshrc puts it on PATH,
# but bash only gets it from Debian's stock ~/.profile, which adds the directory
# only if it already existed at login. On a fresh box we just created it, so
# nothing there resolves until the next login. Say so rather than let it look
# like the symlinks failed.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    echo
    echo "NOTE: ~/.local/bin is not on your PATH in this shell, so bat, fd and"
    echo "starship won't be found yet. Log out and back in to pick it up, or for"
    echo "this shell only:  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

echo
echo "Deliberately not installed: Homebrew, VS Code settings, launchd jobs,"
echo "Ruby/rbenv/nvm tooling, and the Claude Code config. Those are"
echo "workstation concerns - see setup.sh."
