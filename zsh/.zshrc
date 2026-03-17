# ---------- Base ----------
setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

# ---------- Oh My Zsh ----------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="muse"
plugins=(git)

if [[ -s "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# ---------- Common tools ----------
export EDITOR="vim"
export PAGER="less"

if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# ---------- Modular configs ----------
DOTFILES_ZSH_DIR="${${(%):-%N}:A:h}"

[[ -f "$DOTFILES_ZSH_DIR/exports.zsh" ]] && source "$DOTFILES_ZSH_DIR/exports.zsh"
[[ -f "$DOTFILES_ZSH_DIR/aliases.zsh" ]] && source "$DOTFILES_ZSH_DIR/aliases.zsh"
[[ -f "$DOTFILES_ZSH_DIR/functions.zsh" ]] && source "$DOTFILES_ZSH_DIR/functions.zsh"
