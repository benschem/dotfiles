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

# Don't save duplicate commands in history
setopt HIST_IGNORE_ALL_DUPS

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

# Determine which text editor to open when an editor is needed
export VISUAL="${VISUAL:-vim}"
export EDITOR="${EDITOR:-$VISUAL}"

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
