#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

GITHUB_TOKEN_VALUE=""
HF_TOKEN_VALUE=""
PROXY_VALUE=""
INSTALL_UV=0

usage() {
  cat <<'EOF'
Usage: bash install.sh [options]

Options:
  -g <token>   Set GITHUB_TOKEN in ~/.zsh_secrets
  -h <token>   Set HF_TOKEN in ~/.zsh_secrets
  -p <proxy>   Set HTTP_PROXY/HTTPS_PROXY in ~/.zsh_secrets and current process
  -u           Install uv (optional, disabled by default)
  --help       Show help

Example:
  bash install.sh -g <GITHUB_TOKEN> -h <HF_TOKEN> -p http://127.0.0.1:7890 -u
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -g)
        [[ $# -ge 2 ]] || { echo "[error] -g requires a value"; exit 1; }
        GITHUB_TOKEN_VALUE="$2"
        shift 2
        ;;
      -h)
        [[ $# -ge 2 ]] || { echo "[error] -h requires a value"; exit 1; }
        HF_TOKEN_VALUE="$2"
        shift 2
        ;;
      -p)
        [[ $# -ge 2 ]] || { echo "[error] -p requires a value"; exit 1; }
        PROXY_VALUE="$2"
        shift 2
        ;;
      -u)
        INSTALL_UV=1
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "[error] unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

escape_for_double_quotes() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

upsert_export_var() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped_value

  escaped_value="$(escape_for_double_quotes "$value")"

  awk -v key="$key" -v value="$escaped_value" '
    BEGIN { updated = 0 }
    $0 ~ "^export " key "=" {
      print "export " key "=\"" value "\""
      updated = 1
      next
    }
    { print }
    END {
      if (!updated) {
        print "export " key "=\"" value "\""
      }
    }
  ' "$file" > "${file}.tmp"

  mv "${file}.tmp" "$file"
}

apply_proxy_env_if_provided() {
  if [[ -z "$PROXY_VALUE" ]]; then
    return
  fi

  export HTTP_PROXY="$PROXY_VALUE"
  export HTTPS_PROXY="$PROXY_VALUE"
  export http_proxy="$PROXY_VALUE"
  export https_proxy="$PROXY_VALUE"
  export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1}"
  export no_proxy="$NO_PROXY"

  echo "[env] proxy applied to current install process"
}

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
          sudo -E DEBIAN_FRONTEND=noninteractive apt-get update
          sudo -E DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y tzdata
          sudo -E DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y "${packages[@]}"
        else
          DEBIAN_FRONTEND=noninteractive apt-get update
          DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y tzdata
          DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y "${packages[@]}"
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

install_uv_if_needed() {
  if command -v uv >/dev/null 2>&1; then
    echo "[ok] uv already installed"
    return
  fi

  echo "[install] uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
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

apply_cli_values_to_secrets() {
  local target_file="$HOME/.zsh_secrets"

  [[ -f "$target_file" ]] || return

  if [[ -n "$GITHUB_TOKEN_VALUE" ]]; then
    upsert_export_var "$target_file" "GITHUB_TOKEN" "$GITHUB_TOKEN_VALUE"
    echo "[write] GITHUB_TOKEN updated in $target_file"
  fi

  if [[ -n "$HF_TOKEN_VALUE" ]]; then
    upsert_export_var "$target_file" "HF_TOKEN" "$HF_TOKEN_VALUE"
    echo "[write] HF_TOKEN updated in $target_file"
  fi

  if [[ -n "$PROXY_VALUE" ]]; then
    upsert_export_var "$target_file" "HTTP_PROXY" "$PROXY_VALUE"
    upsert_export_var "$target_file" "HTTPS_PROXY" "$PROXY_VALUE"
    if ! grep -q '^export NO_PROXY=' "$target_file"; then
      upsert_export_var "$target_file" "NO_PROXY" "localhost,127.0.0.1,::1"
    fi
    echo "[write] proxy vars updated in $target_file"
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

main() {
  parse_args "$@"
  apply_proxy_env_if_provided

  echo "Installing dotfiles from: $DOTFILES_DIR"

  local os
  os="$(detect_os)"
  echo "Detected OS: $os"

  install_deps "$os"

  install_zsh_if_needed
  install_oh_my_zsh_if_needed
  setup_zsh_secrets_if_needed
  apply_cli_values_to_secrets

  if [[ $INSTALL_UV -eq 1 ]]; then
    install_uv_if_needed
  else
    echo "[skip] uv installation (use -u to enable)"
  fi

  backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
  backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

  if [[ "$SHELL" != *"zsh" ]]; then
    echo "[hint] current login shell is not zsh"
    echo "       run: chsh -s $(command -v zsh)"
  fi

  echo "Done. Restart shell with: exec zsh"
}

main "$@"
