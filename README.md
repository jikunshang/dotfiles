# Personal Dotfiles

A minimal, extensible dotfiles framework for macOS development, including:

- `zsh` setup
- `oh-my-zsh` setup (`muse` theme)
- `tmux` setup
- one-command symlink installer

## Structure

```text
.
├── install.sh
├── zsh
│   ├── .zshrc
│   ├── aliases.zsh
│   ├── exports.zsh
│   └── functions.zsh
└── tmux
    └── .tmux.conf
```

## Quick Start

```bash
cd ~/dev/dotfiles
./install.sh
```

Then restart shell:

```bash
exec zsh
```

## Customize

- Add aliases in `zsh/aliases.zsh`
- Add environment variables in `zsh/exports.zsh`
- Add shell functions in `zsh/functions.zsh`
- Tune terminal multiplexing in `tmux/.tmux.conf`

## Notes

- `install.sh` installs `zsh` (if missing, via Homebrew) and installs `oh-my-zsh` (if missing).
- Existing `~/.zshrc` and `~/.tmux.conf` are backed up automatically (timestamped) before replacing.
- This framework intentionally stays lightweight so you can grow it gradually.
