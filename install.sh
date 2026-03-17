#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [[ -f /etc/os-release ]] && grep -qi '^ID=ubuntu' /etc/os-release; then
        echo "ubuntu"
      else
        echo "linux-unsupported"
      fi
      ;;
    *) echo "unsupported" ;;
  esac
}

install_deps() {
  local os="$1"

  case "$os" in
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "[error] Homebrew is required on macOS: https://brew.sh"
        exit 1
      fi

      local packages=()
      command -v zsh >/dev/null 2>&1 || packages+=(zsh)
      command -v tmux >/dev/null 2>&1 || packages+=(tmux)
      command -v vim >/dev/null 2>&1 || packages+=(vim)
      command -v git >/dev/null 2>&1 || packages+=(git)
      command -v wget >/dev/null 2>&1 || packages+=(wget)
      command -v curl >/dev/null 2>&1 || packages+=(curl)
      command -v python3 >/dev/null 2>&1 || packages+=(python)

      if ! command -v ifconfig >/dev/null 2>&1; then
        packages+=(inetutils)
      fi

      if [[ ${#packages[@]} -gt 0 ]]; then
        echo "[install] macOS deps via Homebrew: ${packages[*]}"
        brew install "${packages[@]}"
      else
        echo "[ok] dependencies already installed"
      fi
      ;;

    ubuntu)
      local packages=()
      dpkg -s zsh >/dev/null 2>&1 || packages+=(zsh)
      dpkg -s tmux >/dev/null 2>&1 || packages+=(tmux)
      dpkg -s vim >/dev/null 2>&1 || packages+=(vim)
      dpkg -s git >/dev/null 2>&1 || packages+=(git)
      dpkg -s wget >/dev/null 2>&1 || packages+=(wget)
      dpkg -s curl >/dev/null 2>&1 || packages+=(curl)
      dpkg -s net-tools >/dev/null 2>&1 || packages+=(net-tools)
      dpkg -s sudo >/dev/null 2>&1 || packages+=(sudo)
      dpkg -s python3-dev >/dev/null 2>&1 || packages+=(python3-dev)

      if [[ ${#packages[@]} -gt 0 ]]; then
        echo "[install] Ubuntu deps via apt: ${packages[*]}"
        if command -v sudo >/dev/null 2>&1; then
          sudo apt-get update
          sudo apt-get install -y "${packages[@]}"
        else
          apt-get update
          apt-get install -y "${packages[@]}"
        fi
      else
        echo "[ok] dependencies already installed"
      fi
      ;;

    *)
      echo "[error] Unsupported OS. Supported: macOS, Ubuntu"
      exit 1
      ;;
  esac
}

install_uv_if_needed() {
  if command -v uv >/dev/null 2>&1; then
    echo "[ok] uv already installed"
    return
  fi

  echo "[install] uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_zsh_if_needed() {
  if command -v zsh >/dev/null 2>&1; then
    echo "[ok] zsh already installed"
    return
  fi

  echo "[error] zsh is still unavailable after dependency installation"
  exit 1
}

install_oh_my_zsh_if_needed() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "[ok] oh-my-zsh already installed"
    return
  fi

  echo "[install] oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

setup_zsh_secrets_if_needed() {
  local target_file="$HOME/.zsh_secrets"
  local template_file="$DOTFILES_DIR/zsh/.zsh_secrets.example"

  if [[ -f "$target_file" ]]; then
    echo "[ok] private env file already exists: $target_file"
    return
  fi

  if [[ -f "$template_file" ]]; then
    cp "$template_file" "$target_file"
    chmod 600 "$target_file"
    echo "[create] $target_file from template"
    echo "[hint] edit $target_file and fill your real token/proxy values"
  fi
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

OS="$(detect_os)"
echo "Detected OS: $OS"

install_deps "$OS"

install_zsh_if_needed
install_uv_if_needed
install_oh_my_zsh_if_needed
setup_zsh_secrets_if_needed

backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

if [[ "$SHELL" != *"zsh" ]]; then
  echo "[hint] current login shell is not zsh"
  echo "       run: chsh -s $(command -v zsh)"
fi

echo "Done. Restart shell with: exec zsh"
