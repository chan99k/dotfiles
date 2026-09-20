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

# 볼트 대기열 감지 (알림만, 실행하지 않는다)
#
# 260920 개정: loci-check 에서 이름과 범위를 넓혔다. 전에는 raw/research 만 봤고
# 거기는 늘 0건이었다. 정작 쌓이는 곳은 raw/inbox 였는데 아무도 세지 않아
# 146건이 될 때까지 몰랐다.
#
# 승격과 분류 자체는 세션에서 직접 돌린다 - 판정 근거를 눈으로 보고 개입할 수
# 있어야 잘못된 승격이 조용히 굳지 않는다 (260911 headless 경로 폐기).
#
# 세는 것:
#   research 미승격   raw/research 에서 승격됨 마커가 없는 노트
#   inbox 승격대기    dest: knowledge 인데 아직 마커가 없는 노트
#   브런치 초안       status 별. 사용자가 직접 쓰는 것이라 세기만 한다
#   미분류            status 도 dest 도 없는 노트. 행선지가 정해지지 않았다
#   미추적 .md        커밋되지 않은 노트. 구볼트 git 이 이 수치로 죽었다
vault-check() {
    local V="$HOME/vault" f
    [[ -d "$V" ]] || { echo "vault: $V 없음, 건너뜀"; return 0 }

    local -a research_pending inbox_pending unclassified
    for f in "$V"/raw/research/*.md(N); do
        [[ "${f:t}" == "승격-대장.md" ]] && continue
        head -14 -- "$f" | grep -q '승격됨' || research_pending+=("${f:t}")
    done

    local skeleton=0 flesh=0 ready=0 st
    for f in "$V"/raw/inbox/*.md(N); do
        # 재료팩과 대장은 Jira 가 상태를 들고 있다. 여기서 세면 이중 계상이다
        [[ "${f:t}" == *재료팩* || "${f:t}" == *대장* ]] && continue
        if grep -q '^dest: knowledge' -- "$f"; then
            head -14 -- "$f" | grep -q '승격됨' || inbox_pending+=("${f:t}")
            continue
        fi
        st=$(grep -m1 '^status:' -- "$f")
        case "$st" in
            *draft-skeleton*)   (( skeleton++ )); continue ;;
            *draft-flesh*)      (( flesh++ ));    continue ;;
            *ready-to-publish*) (( ready++ ));    continue ;;
        esac
        grep -qE '^(status|dest):' -- "$f" || unclassified+=("${f:t}")
    done

    local untracked
    untracked=$(git -C "$V" ls-files --others --exclude-standard -- '*.md' 2>/dev/null | wc -l | tr -d ' ')

    print -r -- "vault: research 미승격 ${#research_pending} | inbox 승격대기 ${#inbox_pending} | 브런치 skeleton ${skeleton} flesh ${flesh} 발행대기 ${ready} | 미분류 ${#unclassified} | 미추적 .md ${untracked}"

    (( ${#research_pending} )) && { echo "  [research] 세션에서 loci 를 돌리세요"; printf '    %s\n' "${research_pending[@]}" }
    (( ${#inbox_pending} ))    && { echo "  [inbox] 팩트체크 대기";               printf '    %s\n' "${inbox_pending[@]}" }
    (( ${#unclassified} ))     && { echo "  [미분류] 행선지를 정하세요";           printf '    %s\n' "${unclassified[@]}" }
    return 0
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

    echo "\n=== vault ==="
    vault-check

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

# ── Anthropic API 키 (Keychain) ────────────────────────────────────────────
# 규칙: service = anthropic-<프로젝트>-<환경>, account = $USER
#   예) anthropic-blog-interview-prod, anthropic-blog-interview-local
# 값은 Keychain에만 둔다 — .secrets(평문 파일)에 넣지 않는다.

anthkey() {
  [ -z "$1" ] && { print -u2 "usage: anthkey <프로젝트>-<환경>   예: blog-interview-prod"; return 2 }
  security find-generic-password -a "$USER" -s "anthropic-$1" -w 2>/dev/null \
    || { print -u2 "anthropic-$1 없음 — 등록: anthkey-set $1"; return 1 }
}

anthkey-set() {
  [ -z "$1" ] && { print -u2 "usage: anthkey-set <프로젝트>-<환경>"; return 2 }
  local k; read -rs "k?ANTHROPIC_API_KEY ($1): "; echo
  # 빈 값 가드 — 비에코 프롬프트가 값을 못 받으면 조용히 빈 항목이 저장된다.
  # 그 경우 나중에 401/403으로만 드러나 원인 추적이 오래 걸린다.
  [ -z "$k" ] && { print -u2 "빈 값 — 중단"; return 1 }
  security add-generic-password -a "$USER" -s "anthropic-$1" -w "$k" -U && echo "저장: anthropic-$1"
}

