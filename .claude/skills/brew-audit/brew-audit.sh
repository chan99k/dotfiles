#!/usr/bin/env bash
# brew-audit.sh — Homebrew 패키지 사용 빈도 분석 및 정리
#
# 사용법:
#   bash brew-audit.sh                 분석 리포트 (dry-run)
#   bash brew-audit.sh --remove-stale  6개월+ 미사용 패키지 제거
#   bash brew-audit.sh --install-logger  usage logger 설치 (한 번만)
#   bash brew-audit.sh --logger-status   logger 상태 확인

set -euo pipefail
export LC_ALL=C

MODE="${1:---dry-run}"
NOW_EPOCH=$(date +%s)
THREE_MONTHS_AGO=$(( NOW_EPOCH - 90 * 86400 ))
SIX_MONTHS_AGO=$(( NOW_EPOCH - 180 * 86400 ))
HISTORY_FILE="${HOME}/.zsh_history"
BREWFILE="${HOME}/Brewfile"
USAGE_LOG="${HOME}/.brew-usage.log"
WRAPPER_DIR="${HOME}/.brew-wrappers"
CELLAR="/opt/homebrew/Cellar"
[ -d "$CELLAR" ] || CELLAR="/usr/local/Cellar"
BREW_BIN="/opt/homebrew/bin"
[ -d "$BREW_BIN" ] || BREW_BIN="/usr/local/bin"

# ─── Usage Logger 설치/관리 ───

install_logger() {
  echo "=== Usage Logger 설치 ==="
  echo ""

  mkdir -p "$WRAPPER_DIR"
  touch "$USAGE_LOG"
  chmod 600 "$USAGE_LOG"

  # brew leaves에서 바이너리 목록 추출
  local leaves
  leaves=$(brew leaves 2>/dev/null)
  local count=0

  for pkg in $leaves; do
    local bins
    bins=$(brew list --formula "$pkg" 2>/dev/null | grep '/bin/' | xargs -I{} basename {} 2>/dev/null | sort -u || true)
    for bin in $bins; do
      local real_path="${BREW_BIN}/${bin}"
      [ -x "$real_path" ] || continue

      # 이미 wrapper인 경우 건너뜀
      if head -1 "$real_path" 2>/dev/null | grep -q 'brew-usage-wrapper'; then
        continue
      fi

      local wrapper="${WRAPPER_DIR}/${bin}"
      # M3: symlink 공격 방지
      [ -L "$wrapper" ] && { echo "  ⚠ symlink detected, skip: $wrapper" >&2; continue; }
      cat > "$wrapper" << 'WRAPPER_EOF'
#!/usr/bin/env bash
# brew-usage-wrapper
echo "$(date +%s) $(basename "$0")" >> "${HOME}/.brew-usage.log"
exec "${HOME}/.brew-wrappers/.real/$(basename "$0")" "$@"
WRAPPER_EOF
      chmod +x "$wrapper"
      count=$((count + 1))
    done
  done

  # PATH 앞에 wrapper 디렉터리 추가 안내
  echo "Wrapper ${count}개 생성: ${WRAPPER_DIR}/"
  echo ""
  echo "─── 설정 필요 ───"
  echo ".zshrc에 다음 줄을 추가하세요 (brew PATH 앞에):"
  echo ""
  echo "  export PATH=\"\${HOME}/.brew-wrappers:\${PATH}\""
  echo ""
  echo "그리고 실제 바이너리 심볼릭 링크 디렉터리를 만드세요:"
  echo ""
  echo "  mkdir -p ${WRAPPER_DIR}/.real"
  echo "  for f in ${WRAPPER_DIR}/*; do"
  echo "    [ -f \"\$f\" ] && ln -sf \"${BREW_BIN}/\$(basename \"\$f\")\" \"${WRAPPER_DIR}/.real/\$(basename \"\$f\")\""
  echo "  done"
  echo ""
  echo "⚠ wrapper 방식 대신 더 가벼운 대안:"
  echo "  .zshrc에 preexec hook 추가 (바이너리 호출 시 자동 로깅):"
  echo ""
  cat << 'HOOK_SUGGESTION'
  # ~/.zshrc — brew-usage preexec hook
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
HOOK_SUGGESTION
  echo ""
  echo "preexec hook이 더 간단하고 PATH 조작이 불필요합니다."
  echo "hook 설치 후 다음 audit부터 정확한 데이터가 수집됩니다."
}

logger_status() {
  echo "=== Usage Logger 상태 ==="
  if [ -f "$USAGE_LOG" ]; then
    local lines
    lines=$(wc -l < "$USAGE_LOG" | tr -d ' ')
    local first_date last_date
    first_date=$(head -1 "$USAGE_LOG" | awk '{print $1}' | xargs -I{} date -r {} '+%Y-%m-%d' 2>/dev/null || echo "?")
    last_date=$(tail -1 "$USAGE_LOG" | awk '{print $1}' | xargs -I{} date -r {} '+%Y-%m-%d' 2>/dev/null || echo "?")
    local unique_cmds
    unique_cmds=$(awk '{print $2}' "$USAGE_LOG" | sort -u | wc -l | tr -d ' ')
    echo "  로그 파일: ${USAGE_LOG}"
    echo "  총 기록: ${lines}건"
    echo "  기간: ${first_date} ~ ${last_date}"
    echo "  고유 명령어: ${unique_cmds}개"
    echo ""
    echo "  최근 10건:"
    tail -10 "$USAGE_LOG" | while read -r epoch cmd rest; do
      local d
      d=$(date -r "$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "?")
      echo "    ${d}  ${cmd}"
    done
  else
    echo "  ⚠ 로그 파일 없음 (${USAGE_LOG})"
    echo "  --install-logger 로 설치하세요."
  fi
}

# ─── 모드 분기 ───
case "$MODE" in
  --install-logger) install_logger; exit 0 ;;
  --logger-status)  logger_status; exit 0 ;;
esac

# ─── 메인 감사 로직 ───
echo "=== Homebrew Audit Report ($(date '+%Y-%m-%d %H:%M')) ==="
echo ""

LEAVES=$(brew leaves 2>/dev/null)
LEAF_COUNT=$(echo "$LEAVES" | wc -l | tr -d ' ')
ALL_COUNT=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')

echo "총 설치: ${ALL_COUNT} formulae, leaf(직접 설치): ${LEAF_COUNT}"

# 신호 소스 상태
echo ""
echo "── 신호 소스 ──"
[ -f "$HISTORY_FILE" ] && echo "  ✓ zsh_history: $(wc -l < "$HISTORY_FILE" | tr -d ' ')건" || echo "  ✗ zsh_history 없음"
[ -f "$USAGE_LOG" ]    && echo "  ✓ usage logger: $(wc -l < "$USAGE_LOG" | tr -d ' ')건" || echo "  ✗ usage logger 미설치 (--install-logger)"
[ -f "$BREWFILE" ]     && echo "  ✓ Brewfile: ${BREWFILE}" || echo "  ✗ Brewfile 없음"
echo ""

# Brewfile 선언 목록
BREWFILE_PKGS=""
if [ -f "$BREWFILE" ]; then
  BREWFILE_PKGS=$(grep '^brew "' "$BREWFILE" | sed 's/brew "//;s/".*//' || true)
fi

# hook/launchd/cron 참조 수집
HOOK_PKGS=""
for lh in $(find "${HOME}" -maxdepth 5 \( -name "lefthook.yml" -o -name "lefthook-local.yml" -o -name ".pre-commit-config.yaml" \) 2>/dev/null | head -10); do
  # lefthook.yml 존재 = lefthook 패키지 사용 중
  case "$(basename "$lh")" in
    lefthook*) HOOK_PKGS="${HOOK_PKGS} lefthook" ;;
  esac
  # 파일 내에서 참조되는 도구 추출
  HOOK_PKGS="${HOOK_PKGS} $(grep -oE '[a-z][-a-z0-9]+' "$lh" 2>/dev/null || true)"
done

LAUNCHD_PKGS=""
for plist in "${HOME}"/Library/LaunchAgents/*.plist; do
  [ -f "$plist" ] 2>/dev/null && LAUNCHD_PKGS="${LAUNCHD_PKGS} $(grep -oE '/opt/homebrew/[^ <"]+' "$plist" 2>/dev/null | xargs -I{} basename {} 2>/dev/null || true)"
done
CRON_PKGS=$(crontab -l 2>/dev/null | grep -oE '/opt/homebrew/[^ ]+' | xargs -I{} basename {} 2>/dev/null || true)

# dotfiles 간접 참조 (.gitconfig, .zshrc, .zprofile 등)
CONFIG_PKGS=""
for cfg in "${HOME}/.gitconfig" "${HOME}/.zshrc" "${HOME}/.zprofile" "${HOME}/.zshenv" "${HOME}/.tmux.conf" "${HOME}/.vimrc"; do
  [ -f "$cfg" ] || continue
  # 경로 기반 참조
  CONFIG_PKGS="${CONFIG_PKGS} $(grep -oE '/opt/homebrew/bin/[^ "]+' "$cfg" 2>/dev/null | xargs -I{} basename {} 2>/dev/null || true)"
  # 잘 알려진 brew 도구 이름 직접 매칭
  CONFIG_PKGS="${CONFIG_PKGS} $(grep -oE '\b(delta|lazygit|bat|eza|fd|rg|fzf|zoxide|starship|autojump|thefuck)\b' "$cfg" 2>/dev/null || true)"
  # zsh source/plugin 참조 (예: source .../zsh-syntax-highlighting.zsh)
  CONFIG_PKGS="${CONFIG_PKGS} $(grep -oE 'source.*/([-a-z]+)\.zsh' "$cfg" 2>/dev/null | grep -oE '/([-a-z]+)\.zsh' | sed 's|^/||;s|\.zsh$||' || true)"
  # zsh plugin 목록 (plugins=(... autojump ...))
  CONFIG_PKGS="${CONFIG_PKGS} $(grep -oE 'plugins=\([^)]+\)' "$cfg" 2>/dev/null | tr '()' ' ' | tr ' ' '\n' | grep -v '^$' || true)"
done

# ─── 패키지별 분석 ───
echo "──────────────────────────────────────────────────────────────────────────"
printf "%-7s | %-25s | %-35s | %-10s | %s\n" "분류" "패키지" "설명" "마지막신호" "근거"
echo "──────────────────────────────────────────────────────────────────────────"

AUTO_REMOVE=()
RECOMMEND_REMOVE=()
KEEP=()

for pkg in $LEAVES; do
  # H1: 패키지명 허용 문자 검증 (인젝션 방지)
  [[ "$pkg" =~ ^[a-zA-Z0-9._@/+-]+$ ]] || { echo "SKIP: invalid pkg name: $pkg" >&2; continue; }

  DESC=$(brew desc "$pkg" 2>/dev/null | sed "s|^${pkg}: ||" || echo "?")

  # 바이너리 이름 해석
  BINARIES=$(brew list --formula "$pkg" 2>/dev/null | grep '/bin/' | xargs -I{} basename {} 2>/dev/null | sort -u || true)
  # H2: 바이너리명에 경로 구분자 포함 시 차단
  SAFE_BINARIES=""
  for bin in $BINARIES; do
    [[ "$bin" != */* ]] && SAFE_BINARIES="${SAFE_BINARIES} ${bin}"
  done
  BINARIES="${SAFE_BINARIES:-$pkg}"

  # ── 신호 1: usage logger (가장 신뢰) ──
  LATEST_USAGE=0
  if [ -f "$USAGE_LOG" ]; then
    for bin in $BINARIES; do
      local_epoch=$(grep -w "$bin" "$USAGE_LOG" 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
      [ "$local_epoch" -gt "$LATEST_USAGE" ] 2>/dev/null && LATEST_USAGE=$local_epoch
    done
  fi

  # ── 신호 2: zsh_history ──
  LATEST_HIST=0
  if [ -f "$HISTORY_FILE" ]; then
    for bin in $BINARIES; do
      HIST_EPOCH=$(grep -F "$bin" "$HISTORY_FILE" 2>/dev/null \
        | grep -E "^: [0-9]+:0;" | tail -1 | sed 's/^: //;s/:.*//' || echo "0")
      [ "$HIST_EPOCH" -gt "$LATEST_HIST" ] 2>/dev/null && LATEST_HIST=$HIST_EPOCH
    done
  fi

  # ── 신호 3: hook/launchd 참조 ──
  IN_HOOKS="no"
  for bin in $BINARIES $pkg; do
    echo "$HOOK_PKGS $LAUNCHD_PKGS $CRON_PKGS $CONFIG_PKGS" | grep -qw "$bin" 2>/dev/null && IN_HOOKS="yes"
  done

  # ── 신호 4: Brewfile ──
  IN_BREWFILE="no"
  echo "$BREWFILE_PKGS" | grep -qx "$pkg" 2>/dev/null && IN_BREWFILE="yes"

  # ── 최종 신호 = max(usage_log, history) ──
  # Cellar mtime 의도적 제외 (매일 brew upgrade 시 무의미)
  LATEST_SIGNAL=$LATEST_USAGE
  [ "$LATEST_HIST" -gt "$LATEST_SIGNAL" ] 2>/dev/null && LATEST_SIGNAL=$LATEST_HIST

  SIGNAL_SOURCE=""
  if [ "$LATEST_USAGE" -gt 0 ] && [ "$LATEST_USAGE" -ge "$LATEST_HIST" ]; then
    SIGNAL_SOURCE="logger"
  elif [ "$LATEST_HIST" -gt 0 ]; then
    SIGNAL_SOURCE="history"
  fi

  if [ "$LATEST_SIGNAL" -gt 0 ] 2>/dev/null; then
    SIGNAL_DATE=$(date -r "$LATEST_SIGNAL" '+%Y-%m-%d' 2>/dev/null || echo "?")
  else
    SIGNAL_DATE="—"
  fi

  # ── 분류 ──
  REASON=""
  if [ "$IN_HOOKS" = "yes" ]; then
    CATEGORY="KEEP"
    REASON="hook/service"
  elif [ "$LATEST_SIGNAL" -gt "$THREE_MONTHS_AGO" ] 2>/dev/null; then
    CATEGORY="KEEP"
    REASON="최근(${SIGNAL_SOURCE})"
  elif [ "$LATEST_SIGNAL" -gt "$SIX_MONTHS_AGO" ] 2>/dev/null; then
    CATEGORY="REVIEW"
    REASON="3~6개월(${SIGNAL_SOURCE})"
  elif [ "$LATEST_SIGNAL" -gt 0 ] 2>/dev/null; then
    CATEGORY="STALE"
    REASON="6개월+(${SIGNAL_SOURCE})"
  else
    # 신호 없음 — 사용 데이터 없으면 함부로 제거 불가
    if [ "$IN_BREWFILE" = "yes" ]; then
      CATEGORY="REVIEW"
      REASON="신호없음(Brewfile선언)"
    else
      CATEGORY="REVIEW"
      REASON="신호없음(수동확인)"
    fi
  fi

  # Brewfile 선언 패키지는 STALE→REVIEW 격상
  if [ "$CATEGORY" = "STALE" ] && [ "$IN_BREWFILE" = "yes" ]; then
    CATEGORY="REVIEW"
    REASON="${REASON}+Brewfile"
  fi

  case "$CATEGORY" in
    STALE)   AUTO_REMOVE+=("$pkg") ;;
    REVIEW)  RECOMMEND_REMOVE+=("$pkg") ;;
    KEEP)    KEEP+=("$pkg") ;;
  esac

  printf "%-7s | %-25s | %-35s | %-10s | %s\n" \
    "$CATEGORY" "$pkg" "${DESC:0:35}" "$SIGNAL_DATE" "$REASON"
done

# ─── 요약 ───
echo ""
echo "=== 요약 ==="
echo "  KEEP (유지):     ${#KEEP[@]}"
echo "  REVIEW (검토):   ${#RECOMMEND_REMOVE[@]}"
echo "  STALE (제거):    ${#AUTO_REMOVE[@]}"
echo ""

if [ ${#RECOMMEND_REMOVE[@]} -gt 0 ]; then
  echo "── REVIEW 패키지 상세 ──"
  for pkg in "${RECOMMEND_REMOVE[@]}"; do
    DESC=$(brew desc "$pkg" 2>/dev/null | sed "s|^${pkg}: ||" || echo "?")
    DEPS=$(brew uses --installed "$pkg" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
    [ -z "$DEPS" ] && DEPS="없음"
    echo "  📦 ${pkg}"
    echo "     설명: ${DESC}"
    echo "     역의존: ${DEPS}"
    echo ""
  done
fi

if [ ${#AUTO_REMOVE[@]} -gt 0 ]; then
  echo "── STALE 패키지 (6개월+ 미사용, Brewfile 미선언) ──"
  for pkg in "${AUTO_REMOVE[@]}"; do
    DESC=$(brew desc "$pkg" 2>/dev/null | sed "s|^${pkg}: ||" || echo "?")
    echo "  ✗ ${pkg}: ${DESC}"
  done
  echo ""

  if [ "$MODE" = "--remove-stale" ]; then
    echo "STALE 패키지 제거 실행..."
    for pkg in "${AUTO_REMOVE[@]}"; do
      echo "  brew uninstall ${pkg}"
      brew uninstall "$pkg" 2>&1 || echo "  ⚠ ${pkg} 제거 실패"
    done
    echo ""
    echo "고아 의존성 정리..."
    brew autoremove
    echo "완료."
  else
    echo "제거 명령: bash ~/.claude/skills/brew-audit/brew-audit.sh --remove-stale"
    echo "개별 제거: brew uninstall <패키지>"
  fi
fi

if ! [ -f "$USAGE_LOG" ]; then
  echo ""
  echo "💡 usage logger 미설치 — 정확한 사용 추적을 위해 설치를 권장합니다:"
  echo "   bash ~/.claude/skills/brew-audit/brew-audit.sh --install-logger"
fi

echo ""
echo "캐시/구버전 정리: brew cleanup"
