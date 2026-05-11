#!/usr/bin/env bash
# team-name.sh — agentic-team 의 *팀 이름*(로그·tmux 격리 키) 결정
#
# 본 명세 SPEC.md 4장(로그 정책)의 <team-name> 격리 메커니즘 구현.
# 여러 작업(Giftify, AIDEX, deep-dive 등)을 동시에 진행할 때 로그가
# 한 디렉토리에 섞이지 않도록, 호출 컨텍스트별 격리 키를 산출.
#
# 우선순위 (위에서 아래로 첫 비어있지 않은 값):
#   1. $AGENTIC_TEAM_NAME   — 호출자 명시 환경변수
#   2. tmux window option @agentic-team-name — 수동 setup
#   3. tmux session 이름    — 자동 격리(가장 흔한 케이스)
#   4. "solo"               — fallback (단독 작업)
#
# 사용:
#   source <이 파일>
#   team_name              # → stdout 으로 결정된 이름

# tmux 옵션 한 항목을 조용히 조회. 실패·미설정 시 빈 문자열.
_query_tmux_option() {
  local opt_name="$1"
  [ -z "${TMUX:-}" ] && { printf ''; return; }
  tmux show-options -wqv -t "${TMUX_PANE:-}" "$opt_name" 2>/dev/null \
    || printf ''
}

# 현재 tmux 세션 이름. 비-tmux 또는 실패 시 빈 문자열.
_query_tmux_session() {
  [ -z "${TMUX:-}" ] && { printf ''; return; }
  tmux display-message -p -t "${TMUX_PANE:-}" '#{session_name}' 2>/dev/null \
    || printf ''
}

# 우선순위대로 시도. 첫 hit 에서 즉시 출력.
team_name() {
  local picked

  # 1) 명시 환경변수
  picked="${AGENTIC_TEAM_NAME:-}"
  if [ -n "$picked" ]; then
    printf '%s\n' "$picked"
    return
  fi

  # 2) tmux window option (사용자가 setup 단계에서 박은 값)
  picked=$(_query_tmux_option '@agentic-team-name')
  if [ -n "$picked" ]; then
    printf '%s\n' "$picked"
    return
  fi

  # 3) tmux session 이름
  picked=$(_query_tmux_session)
  if [ -n "$picked" ]; then
    printf '%s\n' "$picked"
    return
  fi

  # 4) fallback — 단독 작업 의미
  printf 'solo\n'
}
