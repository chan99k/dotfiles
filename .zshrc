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

# SOPS (Secret management)
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"


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
alias tmux-clean='~/.tmux/scripts/tmux-clean.sh'

# Obsidian CLI: run commands against the vault from anywhere
export OBSIDIAN_VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/chan99k's vault/chan99k's vault"
obs() { (cd "$OBSIDIAN_VAULT" && obsidian "$@") }


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
    brew upgrade --cask claude-code
    echo "Claude Code updated to: $(claude --version)"
}

# Morning system update (all-in-one)
morning-update() {
    echo "=== Brew ==="
    brew update && brew upgrade

    echo "\n=== Node.js LTS ==="
    update-node-lts

    echo "\n=== Gemini CLI ==="
    npm update -g @google/gemini-cli
    echo "Gemini CLI: $(gemini --version 2>/dev/null || echo 'version check failed')"

    echo "\n=== Done ==="
    echo "Next:"
    echo "  tmux new -s dev   # 새 세션"
    echo "  tmux attach       # 기존 세션 복귀"
    echo "  claude             # tmux 안에서 실행 후 /daily-work-logger"
}

# yazi: cd to selected directory on exit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# secret masking 용 alias
alias masking='sed "s/=.*/=****/"'

# yt-dlp: use security wrapper (blocks --exec, --netrc-cmd, --ignore-config)
alias yt-dlp='~/.local/bin/yt-dlp-safe'
