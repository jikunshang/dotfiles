#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

install_zsh_if_needed() {
  if command -v zsh >/dev/null 2>&1; then
    echo "[ok] zsh already installed"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    echo "[install] zsh via Homebrew"
    brew install zsh
  else
    echo "[error] zsh not found and Homebrew is unavailable."
    echo "        install Homebrew first: https://brew.sh"
    exit 1
  fi
}

install_oh_my_zsh_if_needed() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "[ok] oh-my-zsh already installed"
    return
  fi

  echo "[install] oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

backup_and_link() {
  local source_file="$1"
  local target_file="$2"

  if [[ -e "$target_file" || -L "$target_file" ]]; then
    mv "$target_file" "${target_file}.backup.${TIMESTAMP}"
    echo "[backup] $target_file -> ${target_file}.backup.${TIMESTAMP}"
  fi

  ln -s "$source_file" "$target_file"
  echo "[link] $source_file -> $target_file"
}

echo "Installing dotfiles from: $DOTFILES_DIR"

install_zsh_if_needed
install_oh_my_zsh_if_needed

backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

if [[ "$SHELL" != *"zsh" ]]; then
  echo "[hint] current login shell is not zsh"
  echo "       run: chsh -s $(command -v zsh)"
fi

echo "Done. Restart shell with: exec zsh"
