# Requires:
# - zsh installed
# - rbenv, nvm, starship installed
# - nerd font set in terminal (for starship icons)
# - .config/zsh with zsh-syntax-highlighting & zsh-history-substring-search cloned manually or symlinked

# Load environment variables
export ZSH="$HOME/.config/zsh"

# Plugin to enable defering other plugins so prompt loads quicker
source $ZSH/zsh-defer/zsh-defer.plugin.zsh

# Plugin to enable syntax highlighting
source $ZSH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Plugin to enable history substring search
source $ZSH/zsh-history-substring-search/zsh-history-substring-search.zsh

# Add a directory for my own personal tools
mkdir -p "$HOME/bin"
export PATH="$HOME/bin:$PATH"

# Encoding stuff for the terminal
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Load starship prompt
# eval "$(starship init zsh)"
eval "$(starship init zsh --print-full-init)"

# Return to the last directory on a new shell `cd -`
setopt AUTO_PUSHD
DIRSTACKSIZE=10

# Set history file
export HISTFILE=~/.zsh_history
export HISTSIZE=5000
export SAVEHIST=5000

# Enable menu completion (cycle through options with tab)
setopt MENU_COMPLETE

# Disable automatic listing of completions on ambiguous tab
unsetopt AUTO_LIST

# Enable tab completion and cache
autoload -Uz compinit && compinit -C # `-C`` caches completions if not already cached, which speeds up shell start

# Load the module required for menu selection
zmodload zsh/complist

# Use a menu select style for better navigation
zstyle ':completion:*' menu select=long-list

# Prevent auto-entering directories on completion
zstyle ':completion:*' auto-menu false

# Accept exact matches automatically
zstyle ':completion:*' accept-exact 'true'

# Makes zsh re-read your $PATH to find new executables on tab-completion
# so that commands you've added to your system recently (like from a brew install) are found without restarting the shell.
zstyle ':completion:*' rehash true # compinit can be slow without caching

# Autocomplete hostnames you've previously accessed via SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'


# This makes Tab and ShiftTab, when pressed on the command line, enter the menu instead of inserting a completion
complete-and-menu-select() {
  zle complete-word
  zle menu-select
}
zle -N complete-and-menu-select
bindkey '^I' complete-and-menu-select
bindkey '\e[Z' reverse-menu-complete

# Enable history substring search key bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# (macOS-only) Prevent Homebrew from reporting - https://github.com/Homebrew/brew/blob/master/docs/Analytics.md
export HOMEBREW_NO_ANALYTICS=1

# Determine which text editor to open when an editor is needed
# Fallback to vim on servers and then nano
if [ -n "$SSH_CONNECTION" ]; then
  export VISUAL="${VISUAL:-vim}"
elif command -v code >/dev/null 2>&1; then
  export VISUAL="${VISUAL:-code -w}"
elif command -v vim >/dev/null 2>&1; then
  export VISUAL="${VISUAL:-vim}"
else
  export VISUAL="${VISUAL:-nano}"
fi
export EDITOR="${EDITOR:-$VISUAL}"
export BUNDLER_EDITOR="$EDITOR"

# Find the custom functions location
# Consider changing how this works later - the alternative would be to symlink them
if [[ -L "$HOME/.zshrc" ]]; then
  TARGET="$(readlink "$HOME/.zshrc")"
  [[ "$TARGET" = /* ]] || TARGET="$HOME/$TARGET"
  DOTFILES_DIR="$(cd "$(dirname "$TARGET")" && pwd)"
else
  echo "Warning: ~/.zshrc is not a symlink. Falling back to \$HOME."
  DOTFILES_DIR="$HOME"
fi

# Custom functions
for f in $DOTFILES_DIR/zsh/functions/*.zsh; do
  source "$f"
done

# Store aliases in the ~/.aliases file and load them here
# Load them below function declarations so you can alias the functions
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"


# BEGIN ANSIBLE MANAGED BLOCK
# Add asdf to PATH
. $(brew --prefix asdf)/libexec/asdf.sh

# Add asdf completions
fpath=(${ASDF_DIR}/completions $fpath)
# END ANSIBLE MANAGED BLOCK
