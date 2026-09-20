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

# Node.js — nvm으로 관리 (default: v20)

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

# uv tools (graphify, etc.)
export PATH="$HOME/.local/bin:$PATH"

# agentic-team wrappers (ask-codex, ask-gemini, team-layout)
export PATH="$HOME/.claude/agentic-team/bin:$PATH"

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


# ============================================================
# Aliases
# ============================================================

# alias zshconfig="nano ~/.zshrc"
# alias zshreload="source ~/.zshrc"
alias tmux-clean='~/.tmux/scripts/tmux-clean.sh'

# Obsidian CLI: run commands against the vault from anywhere
export OBSIDIAN_VAULT="$HOME/chan99k-workspace/chan99k's vault"
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

# loci 미처리 증거 감지 (알림만, 실행하지 않는다)
# 신볼트 raw/research 에서 `> 승격됨` 마커가 없는 노트를 세어 파일명까지 보여준다.
# 승격 자체는 세션에서 loci 를 직접 돌려 처리한다 - 판정 근거를 눈으로 보고
# 개입할 수 있어야 잘못된 승격이 조용히 굳지 않는다 (260911 headless 경로 폐기).
loci-check() {
    local dir="$HOME/vault/raw/research" f
    local -a pending
    [[ -d "$dir" ]] || { echo "loci: $dir 없음, 건너뜀"; return 0 }
    for f in "$dir"/*.md(N); do
        [[ "${f:t}" == "승격-대장.md" ]] && continue
        head -12 -- "$f" | grep -q '승격됨' || pending+=("${f:t}")
    done
    if (( ${#pending} == 0 )); then
        echo "loci: 미처리 증거 0건, 건너뜀"
        return 0
    fi
    echo "loci: 미처리 증거 ${#pending}건. 세션에서 loci 를 돌리세요."
    printf '  %s\n' "${pending[@]}"
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

    echo "\n=== loci ==="
    loci-check

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

# python: use Homebrew python3/pip3 as default
alias python='python3'
alias pip='pip3'

# brew-usage: brew 바이너리 호출 시 ~/.brew-usage.log에 타임스탬프 기록
brew_usage_preexec() {
  local cmd="${1%% *}"
  local bin_path
  bin_path=$(whence -p "$cmd" 2>/dev/null) || return
  case "$bin_path" in
    /opt/homebrew/bin/*|/usr/local/bin/*)
      echo "$(date +%s) $cmd" >> "${HOME}/.brew-usage.log"
      ;;
  esac
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec brew_usage_preexec

# 머신별 시크릿 (API 키 등) — git 미추적
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

