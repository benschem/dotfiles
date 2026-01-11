#!/bin/sh
set -eu

# ------------------------------------------------------------------------------
# Set up a human user (sysadmin) on a linux server with all the fun tools
# ------------------------------------------------------------------------------

# Refuse to run as root
if [ "$(id -u)" -eq 0 ]; then
  echo "This script must not be run as root"
  exit 1
fi

# Refuse to run without sudo
if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to install packages"
  exit 1
fi

# Detect OS
. /etc/os-release
echo "Detected OS: $PRETTY_NAME"

if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
  sudo apt update
  sudo apt install -y git curl zsh vim bat ripgrep tree
elif [ "$ID" = "fedora" ]; then
  sudo dnf update -y
  sudo dnf install -y git curl zsh vim-enhanced bat ripgrep tree
else
  echo "Unsupported OS: $ID"
  exit 1
fi

# Set zsh as login shell for current user
if command -v zsh >/dev/null 2>&1; then
  chsh -s "$(command -v zsh)" "$USER"
else
  echo "zsh installation failed"
  exit 1
fi

# Paths
DOTFILES_DIR="$HOME/dotfiles"
ZSH_CONFIG_DIR="$HOME/.config/zsh"

# Ensure config dirs exist
mkdir -p "$HOME/.config"
mkdir -p "$ZSH_CONFIG_DIR"

# Clone or update dotfiles from sysadmin branch
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone --branch sysadmin https://github.com/benschem/dotfiles.git "$DOTFILES_DIR"
else
  git -C "$DOTFILES_DIR" fetch origin sysadmin
  git -C "$DOTFILES_DIR" checkout sysadmin || git -C "$DOTFILES_DIR" switch sysadmin
  git -C "$DOTFILES_DIR" pull
fi

# Remove .gitconfig from the cloned dotfiles repo if it exists
if [ -f "$DOTFILES_DIR/.gitconfig" ]; then
  rm -f "$DOTFILES_DIR/.gitconfig"
  echo "Removed .gitconfig from dotfiles (server-safe)"
fi

# Symlink dotfiles
ln -sf "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
ln -sf "$DOTFILES_DIR/.vimrc"   "$HOME/.vimrc"
ln -sf "$DOTFILES_DIR/.zshrc"   "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# Install Starship
if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install zsh plugins
[ -d "$ZSH_CONFIG_DIR/zsh-defer" ] || \
  git clone https://github.com/romkatv/zsh-defer.git "$ZSH_CONFIG_DIR/zsh-defer"

[ -d "$ZSH_CONFIG_DIR/zsh-syntax-highlighting" ] || \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CONFIG_DIR/zsh-syntax-highlighting"

[ -d "$ZSH_CONFIG_DIR/zsh-history-substring-search" ] || \
  git clone https://github.com/zsh-users/zsh-history-substring-search.git "$ZSH_CONFIG_DIR/zsh-history-substring-search"

echo "Setup complete (restart shell with 'exec zsh' to activate zsh)"
