# Add custom binaries first
export PATH="$HOME/.local/bin:$PATH"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Better defaults
export LESS='-R'

# Tokens (real values should be placed in ~/.zsh_secrets)
export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
export HF_TOKEN="${HF_TOKEN:-}"
export GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

# Network proxy settings
export HTTP_PROXY="${HTTP_PROXY:-${http_proxy:-}}"
export HTTPS_PROXY="${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-}}}"
export NO_PROXY="${NO_PROXY:-${no_proxy:-localhost,127.0.0.1,::1}}"

# Lowercase compatibility for CLI tools
export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export no_proxy="$NO_PROXY"
