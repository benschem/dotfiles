# Ben's Dotfiles

My personal dotfiles and setup scripts for bootstrapping a machine with my preferred config and tooling.

- `setup.sh` for a developer workstation (macOS or Linux desktop).
- `setup-server.sh` for a headless Debian/Ubuntu box. It installs its own tools and skips anything that needs a GUI.

Safe to re-run. Doesn't overwrite existing config.

## Workstation - macOS

### Prerequisites

Command line tools and Homebrew, neither of which the script can bootstrap:

```zsh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
```

### Clone and run

```zsh
git clone git@github.com:benschem/dotfiles.git ~/code/benschem/dotfiles
cd ~/code/benschem/dotfiles
chmod +x setup.sh
./setup.sh
```

That takes seconds and only touches config. To also install every package in the Brewfile (minutes, and it needs the network):

```zsh
./setup.sh --with-packages
```

### What it does

- Symlinks config into place: `.zshrc`, `.aliases`, `.gitconfig`, `.gitignore_global`, `.vimrc`, `.rspec`, `starship.toml`, VS Code `settings.json`, `.ssh/config`, and the Claude Code config plus the skills and output styles I wrote
- Seeds `~/.gitconfig.local` with my identity, and wires in the workstation-only git settings (see Git config below)
- Clones the three zsh plugins and installs starship
- Symlinks everything in `bin/` onto `PATH` via `~/.local/bin`
- Registers every LaunchAgent in `LaunchAgents/` (see Maintenance jobs below)
- With `--with-packages`, installs from the Brewfile

The Brewfile is the source of truth for what's installed. After installing something new run:

```zsh
brew bundle dump --file=~/code/benschem/dotfiles/Brewfile --force --describe
```

### Still manual

Log in to the GitHub CLI:

```zsh
gh auth login -s 'user:email' -w
```

Install a NerdFont [like this](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#meslo-nerd-font-patched-for-powerlevel10k) and set it in the terminal, or starship's icons won't render.

Language toolchains, which are version-managed per project and not worth pinning here:

- `rbenv` and `ruby`, then `bundler` and global gems: `gem install pry-byebug rake rails rspec rubocop-performance`
- `nvm`, `node`, and `yarn`
- `sqlite` and `postgres`

## Server - Debian/Ubuntu

```bash
git clone git@github.com:benschem/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x setup-server.sh
./setup-server.sh
```

To also install zsh and starship:

```bash
./setup-server.sh --with-zsh
```

Installs CLI tools (`tmux`, `ncdu`, `jq`, `ripgrep`, `bat`, `fd`, `tree`, `htop`, `vim`, plus `git`, `curl`, `wget`, `unzip`, `ca-certificates`), symlinks the portable config, generates the `en_AU.UTF-8` locale that `.zshrc` expects, and enables the systemd timers.

It doesn't change the login shell. Confirm zsh works first by running `zsh` then `echo $0` (expect zsh). Then change it:

```bash
chsh -s "$(command -v zsh)"
```

Deliberately skipped: Homebrew, VS Code settings, launchd jobs, Ruby tooling, and the Claude Code config. Those are workstation concerns.

## Set up SSH

1. Generate a new SSH key pair

```zsh
ssh-keygen -t ed25519 -C "name@email.com"
```

2. Add to ssh-agent

```zsh
eval "$(ssh-agent -s)"

# macOS only (stores key in keychain)
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Linux (or fallback)
ssh-add ~/.ssh/id_ed25519
```

3. Copy the public key

```zsh
# macOS
pbcopy < ~/.ssh/id_ed25519.pub

# Linux
cat ~/.ssh/id_ed25519.pub
```

Then paste it into GitHub under Settings > SSH Keys, or onto a server at `~/.ssh/authorized_keys`.

### Alias commonly accessed servers

Add a `.ssh/config` file based on `.ssh/config.example`. With your server details aliased, instead of:

```zsh
ssh user@IP_ADDRESS_OF_SERVER
```

you can just do:

```zsh
ssh servername
```

## Git config

Three layers, so the same committed config works on a laptop and a headless server:

- `.gitconfig` — portable, symlinked to `~/.gitconfig` on every machine. Aliases, colours, config. Nothing here needs a GUI.
- `~/.gitconfig.local` — identity and anything machine-specific. Copied from `.gitconfig.local.example` on first run and never touched again, so a work machine can use a different address, or none. Not committed.
- `.gitconfig.workstation` — the GUI-only settings: `code --wait` as editor, VS Code as merge and diff tool. `setup.sh` appends an include of it to `~/.gitconfig.local`; `setup-server.sh` doesn't, so a server never sees it.

Git applies values in order and the last one wins, so the chain resolves base → identity → workstation overrides.

Two things worth knowing if you change this:

- **The workstation include has to be appended by `setup.sh`, not declared in `.gitconfig`.** Git resolves a relative include path against the *symlink's* directory (`~/`), not the real file, so `path = .gitconfig.workstation` silently finds nothing and the whole layer vanishes without an error. An absolute path works, and it's only knowable at setup time.

Check what actually resolved with `git config --list --show-origin`. Note that `git config --global --list` will *not* show included values — it reads that one file only, which makes an include look broken when it isn't.

### Two gitignores, deliberately

- `.gitignore_global` — symlinked to `~/.gitignore_global` and wired up by `excludesfile`. Applies to **every repo on the machine**: `.DS_Store`, tool caches, `**/.claude/settings.local.json`.
- `.gitignore` — this repo only. `.ssh/config` and the Claude Code state paths, which exist here purely because parts of `~` get symlinked back in.

These used to be one file, symlinked to `~/.gitignore` and doing both jobs. That meant `.ssh/config` was silently ignored in *every* repo — so any project with that path would never show up in `git status`, with nothing in the project to explain why.

The rule: a pattern only belongs in `.gitignore_global` if it's junk in any repo anywhere. When something is ignored and you can't see why:

```zsh
git check-ignore -v path/to/file
```

## Machine-local shell config

Same idea as `~/.gitconfig.local`, for the shell. Two paths that live in `~` and are never committed:

- `~/.aliases.local` — aliases and exports for one machine only.
- `~/.config/zsh/functions.local/*.zsh` — functions for one machine only.

`.zshrc` sources both at the very end if they exist, so they override anything the repo set. Neither is required — on a machine without them nothing happens and the shell starts normally.

This is where work tooling goes that doesn't belong in a public dotfiles repo or on the personal machine.

It replaces the `work-machine` branch, which did the same job by forking the whole repo and then needed merging forever. That branch is preserved as tag `archive/work-machine`.

Eg. Adding a work-only alias is now:

```zsh
echo "alias deploy='...'" >> ~/.aliases.local
```

## Maintenance jobs

Scheduled cleanups live in `bin/`, with their schedules in `LaunchAgents/` (macOS) and `systemd/` (Linux). Both setup scripts glob those directories, so adding a job means dropping the files in and re-running. No script edits.

### Keep the Docker build cache in check

BuildKit's build cache will happily eat tens of gigabytes - it's happened.

To guard against it, set a size cap by symlinking `buildkitd.toml` to `~/.config/buildkit/`. BuildKit's garbage collector is on by default, but its ceiling is proportional to disk size, which is far too generous. This pins it to 8 GB and raises `minFreeSpace` so it backs off hard when the disk gets tight.

The catch is that Kamal gives you no way to pass this config: `driver_options` in `kamal/commands/builder/base.rb` is hardcoded. But `kamal/cli/build.rb` only creates a builder when `inspect_builder` fails, so a builder that already exists gets adopted, config and all. Create it by hand once:

```zsh
docker buildx create --name kamal-local-docker-container \
  --driver docker-container \
  --config ~/.config/buildkit/buildkitd.toml
```

Confirm the policy took with `docker buildx inspect --bootstrap <name>`. The GC Policy rules should show the capped numbers, not the disk-proportional defaults.

A weekly prune (`bin/prune-buildx-cache.sh`) runs Sundays at 11am and drops everything in the cache untouched for 30 days across every builder. This exists because `buildkitd` only runs while the Docker daemon does, so a machine that hasn't started Docker in months never garbage collects anything. When there's no daemon the script skips quietly instead of waking one on a timer.

The script is the same everywhere; only the scheduler differs.

On macOS it's `LaunchAgents/dev.benschem.prune-buildx-cache.plist`, registered by `setup.sh` behind a `Darwin` check. Logs to `~/Library/Logs/prune-buildx-cache.log`.

```zsh
launchctl kickstart -k gui/$(id -u)/dev.benschem.prune-buildx-cache   # run now
launchctl bootout gui/$(id -u)/dev.benschem.prune-buildx-cache        # disable
```

On Debian, Ubuntu and Fedora it's `systemd/prune-buildx-cache.{service,timer}`, symlinked into `~/.config/systemd/user/` and enabled by `setup-server.sh`. Logs to `~/.local/state/prune-buildx-cache.log` (the XDG state dir, same on all three).

```bash
systemctl --user start prune-buildx-cache.service    # run now
systemctl --user list-timers prune-buildx-cache      # when does it next fire
systemctl --user disable --now prune-buildx-cache.timer
```

Watch out for lingering. User timers only fire while you have a session, and on a headless box you're normally logged out, so without `loginctl enable-linger $USER` the timer silently never runs. `setup-server.sh` enables it (needs sudo). It's the single most likely reason a working-looking timer does nothing.

Also set `Persistent=true`. systemd doesn't catch up on missed runs by default the way launchd does. With it, a box that was off on Sunday prunes at next boot.

`journalctl --user -u prune-buildx-cache` will be nearly empty, because the script redirects its own output to the log file above instead of stdout.

No systemd? A weekly cron line does the same job, minus the catch-up:

```bash
(crontab -l 2>/dev/null; echo "0 11 * * 0 \$HOME/.local/bin/prune-buildx-cache.sh") | crontab -
```

Worth knowing when disk space vanishes: a `docker-container` driver builder keeps its cache inside its own state volume, so it is invisible to `docker system df` and untouched by `docker system prune -a`. Check it directly with `docker buildx du --builder <name>`.

### Keep the Neural Engine cache in check

macOS caches compiled Neural Engine model bundles in directories named `com.apple.e5rt.e5bundlecache`. The copy belonging to `mediaanalysisd`, the daemon that scans Photos for faces, objects and scenes, grows without ever evicting. In August 2026 it hit 17 GB but it was back to 8 GB within two days.

`bin/prune-ane-cache.sh` clears every copy, but only when the total exceeds 5 GB. The threshold matters: deleting the cache forces Photos to re-analyse, which means fan noise and battery drain, so it isn't worth paying that to reclaim a few hundred megabytes. Scheduled Sundays at 11:15am by `LaunchAgents/dev.benschem.prune-ane-cache.plist`. Logs to `~/Library/Logs/prune-ane-cache.log`.

It needs Full Disk Access to work unattended. macOS TCC protects app container data: a process without the grant can `stat` the mediaanalysisd cache but not traverse it, so `find` silently omits it. Terminal normally has the grant; launchd agents don't. Left unhandled, the scheduled run would report a confident "under threshold" while 8 GB sat there, so the script probes for this first and exits 1 with a `BLIND:` message instead of giving a false all-clear.

The script targets Apple-internal paths with no stability guarantee, so if macOS ever renames or moves the cache it will quietly find nothing. It can't tell that apart from the normal post-clean state, since macOS recreates these lazily and zero is expected for a while after a successful run. So it logs the ambiguity: if `no directories named ... found` keeps appearing for weeks while you're using Photos, the path has moved and this needs updating.

To make it actually run, either grant Full Disk Access to the program launchd uses to run it (the shell), which works but is a broad grant applying to everything else that program runs, or run it by hand from a Terminal that already has the grant. If you go the second way the scheduled job becomes a weekly reminder, logging `BLIND:` and exiting 1 until you do.

```zsh
prune-ane-cache.sh                                                 # run now
launchctl kickstart -k gui/$(id -u)/dev.benschem.prune-ane-cache   # test the scheduled path
```

## Adding new config

1. Add the file to this repo
2. Add a `link` call to `setup.sh`, and to `setup-server.sh` if it makes sense on a server
3. Update this README
4. Commit and push

Three directories are globbed, so anything dropped in them is picked up with no script changes: `bin/` (scripts onto `PATH`), `LaunchAgents/` (macOS schedules), `systemd/` (Linux schedules). A script that doesn't apply to a given machine is expected to no-op itself instead of being filtered out by the setup script.
