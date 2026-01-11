#!/bin/bash

DOTFILES_DIR="$HOME/code/benschem/dotfiles"

mkdir -p "$HOME/.config"

# Symlink ssh config incl server aliases
touch "$HOME/.ssh/config"
touch "$DOTFILES_DIR/.ssh/config"
ln -sf "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"

mkdir -p "$HOME/Library/Application\ Support/Code/User"

ln -sf "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/.gitignore" "$HOME/.gitignore"
ln -sf "$DOTFILES_DIR/.rspec" "$HOME/.rspec"
ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/settings.json" "$HOME/Library/Application\ Support/Code/User/settings.json"
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

echo "Dotfiles symlinked!"