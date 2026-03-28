# Personal Dotfiles

A minimal, extensible dotfiles framework for macOS and Ubuntu development, including:

- `zsh` setup
- `oh-my-zsh` setup (`muse` theme)
- `tmux` setup
- `gh` (GitHub CLI) installation
- one-command symlink installer

## Structure

```text
.
├── install.sh
├── git
│   └── .gitconfig
├── zsh
│   ├── .zshrc
│   ├── .zsh_secrets.example
│   ├── aliases.zsh
│   ├── exports.zsh
│   ├── functions.zsh
│   └── history.seed
└── tmux
    └── .tmux.conf
```

## Quick Start

```bash
cd ~/dev/dotfiles
./install.sh
```

With tokens/proxy:

```bash
bash install.sh -g <GITHUB_TOKEN> -h <HF_TOKEN> -p <PROXY>
```

`-g` writes both `GH_TOKEN` and `GITHUB_TOKEN` for compatibility with `gh` and other GitHub tooling.

Install `uv` optionally:

```bash
bash install.sh -u
```

Supported systems:

- macOS (via Homebrew)
- Ubuntu (via apt)

Then restart shell:

```bash
exec zsh
```

## Customize

- Add aliases in `zsh/aliases.zsh`
- Add environment variables in `zsh/exports.zsh`
- Put private tokens/proxy values in `~/.zsh_secrets` (template: `zsh/.zsh_secrets.example`)
- Add shared command history seeds in `zsh/history.seed`
- Add shell functions in `zsh/functions.zsh`
- Add git aliases/settings in `git/.gitconfig`
- Tune terminal multiplexing in `tmux/.tmux.conf`

## History Sync

After pulling latest dotfiles, run:

```bash
hsync
```

`hsync` merges commands from `zsh/history.seed` into local `~/.zsh_history` without deleting or overwriting your existing machine history.

## Notes

- `install.sh` auto-detects macOS/Ubuntu and installs missing deps.
- Requested packages are included on Ubuntu: `vim git wget curl net-tools sudo python3-dev` (plus `zsh` and `tmux`). GitHub CLI is also installed automatically.
- Ubuntu install runs in non-interactive mode (`DEBIAN_FRONTEND=noninteractive`, `TZ=Etc/UTC`) to avoid timezone prompts.
- On macOS, equivalent tools are installed via Homebrew (for `net-tools`, it installs `inetutils` if needed), including `gh`.
- `uv` installation is optional; enable with `-u`.
- When enabled, `install.sh` installs `uv` via: `curl -LsSf https://astral.sh/uv/install.sh | sh`.
- `install.sh` installs `oh-my-zsh` if missing.
- `install.sh` automatically switches your default login shell to `zsh`.
- `install.sh` creates `~/.zsh_secrets` from template when missing.
- `-g/-h/-p` writes values into `~/.zsh_secrets` automatically.
- `-g` writes the same GitHub token into both `GH_TOKEN` and `GITHUB_TOKEN`.
- `-p` also applies proxy env for current install process (helps when network requires proxy and git is not installed yet).
- `hsync` is provided as alias for `sync_dotfiles_history`.
- Existing `~/.zshrc` and `~/.tmux.conf` are backed up automatically (timestamped) before replacing.
- Existing `~/.gitconfig` is also backed up automatically before replacing.
- This framework intentionally stays lightweight so you can grow it gradually.
