mkcd() {
  mkdir -p "$1" && cd "$1"
}

extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz) tar xzf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.rar) unrar x "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar xf "$1" ;;
      *.tbz2) tar xjf "$1" ;;
      *.tgz) tar xzf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7z x "$1" ;;
      *) echo "cannot extract: $1" ;;
    esac
  else
    echo "not a valid file: $1"
  fi
}

sync_dotfiles_history() {
  local history_file="${HISTFILE:-$HOME/.zsh_history}"
  local seed_file="${DOTFILES_ZSH_DIR}/history.seed"
  local tmp_existing
  local added_count=0

  if [[ ! -f "$seed_file" ]]; then
    echo "history seed file not found: $seed_file"
    return 1
  fi

  mkdir -p "$(dirname "$history_file")"
  touch "$history_file"

  tmp_existing="$(mktemp)"
  awk '
    {
      line = $0
      if (line ~ /^: [0-9]+:[0-9]+;/) {
        sub(/^: [0-9]+:[0-9]+;/, "", line)
      }
      print line
    }
  ' "$history_file" | sort -u > "$tmp_existing"

  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    [[ "$cmd" == '#'* ]] && continue

    if ! grep -Fxq "$cmd" "$tmp_existing"; then
      printf ': %s:0;%s\n' "$(date +%s)" "$cmd" >> "$history_file"
      print -r -- "$cmd" >> "$tmp_existing"
      added_count=$((added_count + 1))
      if [[ -o interactive ]]; then
        print -s -- "$cmd"
      fi
    fi
  done < "$seed_file"

  rm -f "$tmp_existing"
  echo "history sync done: added $added_count command(s)"
}
