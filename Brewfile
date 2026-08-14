# Everything Homebrew installs on a workstation: taps, formulae, casks and
# VS Code extensions.
#
# Only explicitly-installed formulae are listed - `brew bundle dump` records
# leaves, not the dependency tree, so plenty more gets pulled in on restore.
#
# Restore with:
#   brew bundle --file=~/code/benschem/dotfiles/Brewfile
# or just run ./setup.sh --with-packages
#
# After installing something new, refresh this file with:
#   brew bundle dump --file=~/code/benschem/dotfiles/Brewfile --force
#
# Note: dump discards these comments, so paste them back afterwards.

tap "dart-lang/dart", trusted: true
tap "heroku/brew", trusted: true
tap "sass/sass", trusted: true
# Clone of cat(1) with syntax highlighting and Git integration
brew "bat"
# New way of working with Protocol Buffers
brew "buf"
# GitHub command-line tool
brew "gh"
# Interpreter for PostScript and PDF
brew "ghostscript"
# Distributed revision control system
brew "git"
# Syntax-highlighting pager for git and diff output
brew "git-delta"
# Lightweight and flexible command-line JSON processor
brew "jq"
# Simple terminal UI for git commands
brew "lazygit"
# Postgres C API library
brew "libpq"
# C implementation of a Sass compiler
brew "libsass"
# Next-gen compiler infrastructure
brew "llvm"
# Clone of ls with colorful output, file type icons, and more
brew "lsd"
# Process manager for Procfile-based applications and tmux
brew "overmind"
# Object-relational database system
brew "postgresql@15", restart_service: :changed, link: true
# Interpreted, interactive, object-oriented programming language
brew "python@3.11"
# Ruby version manager
brew "rbenv"
# Search tool like grep and The Silver Searcher
brew "ripgrep"
# Static analysis and lint tool, for (ba)sh scripts
brew "shellcheck"
# SMART hard drive monitoring
brew "smartmontools"
# Cross-shell prompt for astronauts
brew "starship"
# Display directories as trees (with optional color/HTML output)
brew "tree"
# Vi 'workalike' with many additional features
brew "vim"
# Image processing library
brew "vips"
# Internet file retriever
brew "wget"
# Library to create, extract, and modify Windows Imaging files
brew "wimlib"
# Utilities to create and convert Web Open Font File (WOFF) files
brew "woff2"
# JavaScript package manager
brew "yarn"
# SDK
brew "dart-lang/dart/dart", trusted: true
# Everything you need to get started with Heroku
brew "heroku/brew/heroku", trusted: true
# Stylesheet Preprocessor
brew "sass/sass/sass", trusted: true
# Automated testing of webapps for Google Chrome
cask "chromedriver"
cask "font-source-code-pro-for-powerline"
# Terminal emulator that uses platform-native UI and GPU acceleration
cask "ghostty"
# Tool to control external monitor brightness & volume
cask "monitorcontrol"
# Reverse proxy, secure introspectable tunnels to localhost
cask "ngrok"
# Quick Look generator for Markdown files
cask "qlmarkdown"
vscode "akil-s.tokyo-dark"
vscode "alexcvzz.vscode-sqlite"
vscode "anteprimorac.html-end-tag-labels"
vscode "astro-build.astro-vscode"
vscode "beardedbear.beardedtheme"
vscode "bradlc.vscode-tailwindcss"
vscode "christian-kohler.path-intellisense"
vscode "csstools.postcss"
vscode "dbaeumer.vscode-eslint"
vscode "dracula-theme.theme-dracula"
vscode "eamodio.gitlens"
vscode "emmanuelbeziat.vscode-great-icons"
vscode "esbenp.prettier-vscode"
vscode "eserozvataf.one-dark-pro-monokai-darker"
vscode "fisheva.eva-theme"
vscode "formulahendry.auto-rename-tag"
vscode "github.github-vscode-theme"
vscode "huytd.nord-light"
vscode "ionutvmi.path-autocomplete"
vscode "kamikillerto.vscode-colorize"
vscode "kisstkondoros.vscode-gutter-preview"
vscode "misbahansori.svg-fold"
vscode "naumovs.color-highlight"
vscode "oderwat.indent-rainbow"
vscode "phoenisx.cssvar"
vscode "rubymaniac.vscode-paste-and-indent"
vscode "setobiralo.erb-commenter"
vscode "shopify.ruby-lsp"
vscode "sissel.shopify-liquid"
vscode "svelte.svelte-vscode"
vscode "syler.sass-indented"
vscode "unifiedjs.vscode-mdx"
vscode "usernamehw.errorlens"
vscode "viktorqvarfordt.vscode-pitch-black-theme"
vscode "vincaslt.highlight-matching-tag"
vscode "zignd.html-css-class-completion"
vscode "zneuray.erb-vscode-snippets"
npm "corepack"
