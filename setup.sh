#!/bin/bash

DOTFILES_DIR="$HOME/code/benschem/dotfiles"

# For starship, zsh, yarn, etc
mkdir -p "$HOME/.config"

# Symlink ssh config incl server aliases
touch "$HOME/.ssh/config"
touch "$DOTFILES_DIR/.ssh/config"
ln -sf "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"

# Symlink VS Code user configuration, such as settings, keybindings, and profiles.
mkdir -p "$HOME/Library/Application\ Support/Code/User"
ln -sf "$DOTFILES_DIR/settings.json" "$HOME/Library/Application\ Support/Code/User/settings.json"

# Symlink personal shell command aliases
ln -sf "$DOTFILES_DIR/.aliases" "$HOME/.aliases"

# Symlink personal .gitconfig
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# Symlink personal .gitignore
ln -sf "$DOTFILES_DIR/.gitignore" "$HOME/.gitignore"

# Symlink rspec config
ln -sf "$DOTFILES_DIR/.rspec" "$HOME/.rspec"

# Symlink vim config
ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"

# Symlink zsh config
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Symlink starship config
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

echo "Dotfiles symlinked!"
