#!/bin/bash
# context-monitor.sh - 컨텍스트 크기 조기 경고
# PostToolUse hook (모든 도구에 적용)
#
# JSONL 파일 크기는 토큰 사용량의 프록시 지표 (정비례하지 않음)
# Claude Code는 토큰 사용량을 hook에 노출하지 않으므로 파일 크기로 대체
#
# 캘리브레이션 방법:
#   경고 발생 시 /cost 명령으로 실제 토큰 사용량 확인 후 기록
#   예: "JSONL 45MB → 토큰 320K", "JSONL 80MB → 토큰 600K"
#   데이터 3-5개 수집 후 아래 임계치(30/60/90 MB)를 조정
#
# 현재 임계치 (초기값, 캘리브레이션 전):
#   WARNING_MB=30, HIGH_MB=60, CRITICAL_MB=90

# 캐시 파일 및 상태 파일
CACHE_FILE="/tmp/claude-session-cache"
WARN_FILE="/tmp/claude-context-level"
CACHE_VALID_SEC=300

# 함수: 경고 출력
warn_if_needed() {
  local SIZE_MB=$1
  local CURRENT_LEVEL="ok"

  [ "$SIZE_MB" -ge 90 ] && CURRENT_LEVEL="critical" || {
    [ "$SIZE_MB" -ge 60 ] && CURRENT_LEVEL="high" || {
      [ "$SIZE_MB" -ge 30 ] && CURRENT_LEVEL="warning"
    }
  }

  [ -f "$WARN_FILE" ] && [ "$(cat "$WARN_FILE")" = "$CURRENT_LEVEL" ] && return

  echo "$CURRENT_LEVEL" > "$WARN_FILE"

  case "$CURRENT_LEVEL" in
    warning)
      echo "info: 세션 JSONL ${SIZE_MB}MB. 세션이 길어지고 있습니다."
      ;;
    high)
      echo "warning: 세션 JSONL ${SIZE_MB}MB. 세션이 상당히 커졌습니다. 복잡한 새 작업은 별도 세션을 고려하세요."
      ;;
    critical)
      echo "warning: 세션 JSONL ${SIZE_MB}MB. /compact 실행 또는 새 세션을 강력히 권장합니다."
      ;;
  esac
}

# 캐시 유효성 확인
if [ -f "$CACHE_FILE" ]; then
  CACHE_MTIME=$(stat -f%m "$CACHE_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  CACHE_AGE=$((NOW - CACHE_MTIME))

  if [ "$CACHE_AGE" -lt "$CACHE_VALID_SEC" ]; then
    SESSION_FILE=$(cat "$CACHE_FILE")
    if [ -f "$SESSION_FILE" ]; then
      SIZE=$(stat -f%z "$SESSION_FILE" 2>/dev/null)
      if [ -n "$SIZE" ]; then
        SIZE_MB=$((SIZE / 1048576))
        warn_if_needed "$SIZE_MB"
        exit 0
      fi
    fi
  fi
fi

# 캐시 미스 - 새로 검색
SESSION_FILE=$(find ~/.claude/projects -maxdepth 2 -name "*.jsonl" -type f ! -path "*/subagents/*" -mmin -10 2>/dev/null | head -1)
[ -z "$SESSION_FILE" ] && exit 0

echo "$SESSION_FILE" > "$CACHE_FILE"

SIZE=$(stat -f%z "$SESSION_FILE" 2>/dev/null)
[ -z "$SIZE" ] && exit 0

SIZE_MB=$((SIZE / 1048576))
warn_if_needed "$SIZE_MB"
