# ============================================================
# Oh-My-Zsh Configuration
# ============================================================

export ZSH="$HOME/.oh-my-zsh"

# Theme: agnoster (powerline-style prompt with git status)
ZSH_THEME="agnoster"

# Plugins: git utilities and autosuggestions
plugins=(
  git
  zsh-autosuggestions
  autojump
)

source $ZSH/oh-my-zsh.sh


# ============================================================
# Prompt Customization
# ============================================================

# Custom prompt with random emoji
prompt_context() {
  emojis=("⚡️" "🔥" "🍻" "🚀" "💡" "🎉" "🌙")
  RAND_EMOJI_N=$(( $RANDOM % ${#emojis[@]} + 1))

  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER ${emojis[$RAND_EMOJI_N]}"
  fi
}


# ============================================================
# Syntax Highlighting
# ============================================================

# zsh-syntax-highlighting: Real-time command syntax highlighting
source /opt/homebrew/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# ============================================================
# Language Runtime Managers
# ============================================================

# NVM (Node Version Manager): Manage multiple Node.js versions
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# jenv (Java Environment Manager): Manage multiple Java versions
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# RVM (Ruby Version Manager): Manage multiple Ruby versions
export PATH="$PATH:$HOME/.rvm/bin"


# ============================================================
# PATH Configuration
# ============================================================

# Node.js 20 (LTS)
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"

# Deno runtime
export PATH="/Users/chan99/.deno/bin:$PATH"

# Python 3.11
export PATH="/opt/homebrew/opt/python@3.11/libexec/bin:$PATH"

# MySQL 8.0 client
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"

# Go binaries
export PATH="$PATH:/Users/chan99/go/bin"

# Antigravity tool
export PATH="/Users/chan99/.antigravity/antigravity/bin:$PATH"

# Bun (JavaScript runtime & toolkit)
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# ============================================================
# Environment Variables
# ============================================================

# Google Cloud Project ID
export GOOGLE_CLOUD_PROJECT="gen-lang-client-0744229235"


# ============================================================
# Tool-specific Integrations
# ============================================================

# kiro terminal integration
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# gw (git worktree) shell integration
eval "$(gw shell-init zsh 2>/dev/null)"


# ============================================================
# Aliases
# ============================================================

# alias zshconfig="nano ~/.zshrc"
# alias zshreload="source ~/.zshrc"


# ============================================================
# Utility Functions
# ============================================================

# Node.js LTS update via nvm
update-node-lts() {
    echo "Updating to latest LTS..."
    nvm install --lts
    nvm alias default lts/\*
    nvm use default
    echo "Node.js updated to: $(node --version)"
}

# Claude Code update
update-claude-code() {
    echo "Updating Claude Code..."
    npm update -g @anthropic-ai/claude-code
    echo "Claude Code updated to: $(claude --version)"
}

# yazi: cd to selected directory on exit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}