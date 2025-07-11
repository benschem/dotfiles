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
zsh-defer source $ZSH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Plugin to enable history substring search
zsh-defer source $ZSH/zsh-history-substring-search/zsh-history-substring-search.zsh

# Add a directory for my own personal tools
mkdir -p "$HOME/bin"
export PATH="$HOME/bin:$PATH"

# Load rbenv if installed (to manage Ruby versions)
export PATH="${HOME}/.rbenv/bin:${PATH}"
command -v rbenv > /dev/null && zsh-defer eval "$(rbenv init -)"

# Load nvm (to manage node versions)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && zsh-defer source "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && zsh-defer source "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Defer setting up nvm auto-switching
zsh-defer autoload -U add-zsh-hook
zsh-defer () {
  load-nvmrc() {
    if command -v nvm > /dev/null; then
      local node_version="$(nvm version)"
      local nvmrc_path="$(nvm_find_nvmrc)"

      if [ -n "$nvmrc_path" ]; then
        local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

        if [ "$nvmrc_node_version" = "N/A" ]; then
          nvm install
        elif [ "$nvmrc_node_version" != "$node_version" ]; then
          nvm use --silent
        fi
      elif [ "$node_version" != "$(nvm version default)" ]; then
        nvm use default --silent
      fi
    fi
  }

  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
}

# Encoding stuff for the terminal
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Load starship prompt
eval "$(starship init zsh)"

# Return to the last directory on a new shell `cd -`
setopt AUTO_PUSHD
DIRSTACKSIZE=10

# Set history file
export HISTFILE=~/.zsh_history
export HISTSIZE=5000
export SAVEHIST=5000

# Store aliases in the ~/.aliases file and load them here
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Load completions
zstyle ':completion:*' rehash true # compinit can be slow without caching

# Autocomplete hostnames you've previously accessed via SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

autoload -Uz compinit && compinit -C # `-C`` caches completions if not already cached, which speeds up shell start

# Use a faster history search
# Enable history substring search key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

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

# Custom functions
## Make a directory and change into it
mkcd() {
  mkdir -p "$1" && cd "$1";
}
## Rerun the last command with sudo
please() {
  sudo $(fc -ln -1)
  # fc -ln -1 outputs the last command exactly as typed
}
## For when you try to drop a postges db and it won't let you.
killdb() {
  if [ -z "$1" ]; then
    echo "Usage: killdb YourAppName"
  else
    ps -ef | grep postgres | grep "$1" | awk '{print $2}' | xargs -r kill -9
    # ps -ef
    # Lists all processes
    #
    # | grep postgres
    # Filters for PostgreSQL processes
    #
    # | grep YourAppName
    # Further filters for YourAppName processes
    #
    # | awk '{print $2}'
    # get the PID from the second field of each line
    #
    # | xargs kill -9:
    # Passes the PID to kill -9 to terminate
  fi
}
