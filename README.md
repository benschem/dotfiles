# Ben’s Sysadmin Dotfiles

This repo sets up a sysadmin user on an Ubuntu or Fedora server with my preferred shell, prompt and tools.

## Setup

1. Copy the setup script to the server:

```bash
scp setup_sysadmin.sh user@SERVER_IP:/home/user/
```

2. Log in to the server:

```bash
ssh user@SERVER_IP
```

3. Make the script executable and run it:

```bash
chmod +x setup_sysadmin.sh
bash setup_sysadmin.sh
```

4. After the script completes, reload your shell:

```bash
exec zsh
```

## Notes

- Do not run as root
- Requires `sudo`
- Supports Ubuntu, Debian, Fedora
- Installs: git, curl, zsh, vim (or vim-enhanced on Fedora), bat, ripgrep, Starship prompt, and some zsh plugins.
