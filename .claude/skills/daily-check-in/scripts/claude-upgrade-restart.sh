#!/usr/bin/env bash
# Claude Code 를 brew 로 올리고, 옛 바이너리로 떠 있는 herdr pane 의 claude 세션을 같은 세션 ID 로 다시 연다.
# - working/blocked 인 pane 과 이 스크립트를 실행한 pane 은 건드리지 않는다
# - 사용법: claude-upgrade-restart.sh [--dry-run] [--no-upgrade] [--only <pane_id>]
set -uo pipefail

DRY=0; UPGRADE=1; ONLY=""
while [ $# -gt 0 ]; do a="$1"; shift
  case "$a" in
    --dry-run) DRY=1 ;;
    --no-upgrade) UPGRADE=0 ;;
    --only) ONLY="$1"; shift ;;
  esac
done

command -v herdr >/dev/null || { echo "herdr 없음, 건너뜀"; exit 0; }
command -v jq >/dev/null || { echo "jq 없음, 건너뜀"; exit 0; }

if [ "$UPGRADE" = 1 ]; then
  if brew outdated --cask --greedy claude-code@latest 2>/dev/null | grep -q claude-code; then
    echo "brew upgrade claude-code@latest"
    [ "$DRY" = 1 ] || brew upgrade --cask claude-code@latest
  else
    echo "Claude Code 최신 ($(claude --version 2>/dev/null))"
  fi
fi

BIN=$(readlink -f "$(command -v claude)")
BIN_MTIME=$(stat -f %m "$BIN")
SELF="${HERDR_PANE_ID:-}"

restarted=0; skipped=0
while IFS=$'\t' read -r pane status sid; do
  [ -n "$sid" ] || continue
  [ -z "$ONLY" ] || [ "$pane" = "$ONLY" ] || continue
  if [ "$pane" = "$SELF" ]; then
    echo "[$pane] 현재 pane, 직접 다시 열어야 함"; skipped=$((skipped+1)); continue
  fi
  pid=$(herdr pane process-info --pane "$pane" 2>/dev/null | jq -r '.result.process_info.foreground_process_group_id // empty')
  [ -n "$pid" ] || continue
  started=$(date -j -f '%a %b %d %T %Y' "$(ps -o lstart= -p "$pid" | sed 's/^ *//')" +%s 2>/dev/null || echo 0)
  if [ "$started" -ge "$BIN_MTIME" ]; then
    continue  # 이미 새 바이너리로 떠 있음
  fi
  if [ "$status" != idle ] && [ "$status" != done ]; then
    echo "[$pane] $status, 건너뜀 (다음 실행 때 재시도)"; skipped=$((skipped+1)); continue
  fi
  echo "[$pane] 재시작: claude --resume $sid"
  [ "$DRY" = 1 ] && { restarted=$((restarted+1)); continue; }

  herdr pane send-text "$pane" "/exit" >/dev/null && herdr pane send-keys "$pane" enter >/dev/null
  # claude 가 빠지고 셸이 foreground 로 돌아올 때까지 최대 30초
  ok=0
  for _ in $(seq 1 30); do
    sleep 1
    fg=$(herdr pane process-info --pane "$pane" 2>/dev/null | jq -r '.result.process_info.foreground_process_group_id // empty')
    if [ -n "$fg" ] && [ "$fg" != "$pid" ]; then ok=1; break; fi
  done
  if [ "$ok" != 1 ]; then
    echo "[$pane] 종료 확인 실패, 수동 확인 필요"; skipped=$((skipped+1)); continue
  fi
  herdr pane run "$pane" "claude --resume $sid" >/dev/null && restarted=$((restarted+1))
done < <(herdr agent list 2>/dev/null | jq -r '.result.agents[] | select(.agent=="claude") | [.pane_id, .agent_status, (.agent_session.value // "")] | @tsv')

echo "재시작 $restarted, 건너뜀 $skipped"
