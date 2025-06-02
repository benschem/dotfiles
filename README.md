# Ben’s Dotfiles

This repo contains my personal dotfiles and setup scripts to bootstrap a new Mac or Linux machine with my preferred environment and tools.

## MacOS

### Install command line tools

```zsh
xcode-select --install
```

### Install homebrew package manager

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```zsh
brew update
```

### Install software packages:

```zsh
brew upgrade git || brew install git
brew upgrade gh || brew install gh
brew upgrade wget || brew install wget
brew upgrade imagemagick || brew install imagemagick
brew upgrade jq || brew install jq # command line JSON procssor
brew upgrade openssl || brew install openssl
```

### Log in to Github CLI

```zsh
gh auth login -s 'user:email' -w
```

### Global .gitignore

```zsh
git config --global core.excludesfile ~/.dotfiles/.gitignore_global
```

Keeps junk like .DS_Store, .vscode/, etc. out of all repos by default.

### Creating symlinks for dotfiles

Symlinks keep your dotfiles in this repo while allowing tools to read them from their expected locations.

```zsh
ln -sf ~/code/benschem/dotfiles/zshrc ~/.zshrc
ln -sf ~/code/benschem/dotfiles/starship.toml ~/.config/starship.toml
```

Do this for every dotfile in this repo or eventually use the `setup.sh` script.

Everything should go in `~/` except `settings.json` for VSCode and `starship.toml`.

There is a setup script for this - see below.

### Install programming languages

- Install `rbenv` and `ruby`
- Install `bundler` and global gems: `gem install pry-byebug rake rails rspec rubocop-performance`

- Install `nvm`, `node`, and `yarn`
- Install `sqlite` and `postgres`

### Set up Shell

Clone these plugins into ~/.config/zsh/

```zsh
git clone https://github.com/romkatv/zsh-defer.git $ZSH/zsh-defer
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search $ZSH/zsh-history-substring-search
```

Restart shell:

```zsh
exec zsh
```

### Set up SSH

1. Generate a new SSH key pair

```zsh
ssh-keygen -t ed25519 -C "name@email.com"
```

2. Add to ssh-agent

```zsh
eval "$(ssh-agent -s)"

# macOS only (stores key in keychain)
ssh-add -K ~/.ssh/id_ed25519

# Linux (or fallback)
ssh-add ~/.ssh/id_ed25519and GitHub:
```

3. Copy public key

```zsh
# macOS
pbcopy < ~/.ssh/id_ed25519.pub

# Linux
cat ~/.ssh/id_ed25519.pub
```

Then:

- GitHub: Paste in Settings > SSH Keys
- Server: Paste to `~/.ssh/authorized_keys`

4. Alias commonly accessed servers:

```ssh
# .ssh/config

# General settings
Host *
  UseKeychain yes # macOS only but harmless on Linux
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519

# Example shortcut to login as root on server
Host server-root
  HostName IP_ADDRESS_OF_SERVER
  User root
```

So instead of:

```zsh
ssh root@IP_ADDRESS_OF_SERVER
```

You can just do:

```zsh
ssh server-root
```

## Linux differences

No need for homebrew or xcode.

Adjust package manager commands as needed:

Fedora:

```zsh
sudo dnf update -y
sudo dnf install -y git wget jq curl openssl
```

Ubuntu/Debian:

```zsh
sudo apt update && sudo apt upgrade -y
sudo apt install -y git wget jq curl openssl
```

## TODO: Set up automatically

TODO: Finish the script `setup.sh` to automate all of the above.

So far it only sets up symlinks.

Setup script will need permission to execute:

```zsh
chmod +x setup.sh
```

Then:

```zsh
zsh setup.sh
```

## Adding new config

1. Add the file to this repo
2. Add symlink
3. Add symlink setup to setup.sh
4. Update README.md
5. Commit and push