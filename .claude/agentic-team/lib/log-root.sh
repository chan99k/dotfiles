#!/usr/bin/env bash
# log-root.sh — agentic-team 로그 루트 디렉토리 결정
#
# 본 명세 SPEC.md 4장의 우선순위 정책 구현:
#   1) $AGENTIC_TEAM_LOG_ROOT     — 호출자 명시
#   2) git toplevel + .agentic-team/log — git 관리 프로젝트 안일 때
#   3) $PWD + .agentic-team/log   — 그 외 (Obsidian vault 등 git 미관리)
#
# Monorepo 의 sub-package 에서 호출해도 git toplevel 기준으로 한 군데에 모임.
# Sub-package 별 분리가 필요하면 사용자가 1) 환경변수로 override.
#
# 사용:
#   source <이 파일>
#   log_root               # → stdout 으로 절대경로 출력

# git 작업 트리이면 toplevel, 그 외에는 빈 문자열.
_git_toplevel_or_empty() {
  command -v git >/dev/null 2>&1 || { printf ''; return; }
  git rev-parse --show-toplevel 2>/dev/null || printf ''
}

log_root() {
  local picked

  # 1) env override
  picked="${AGENTIC_TEAM_LOG_ROOT:-}"
  if [ -n "$picked" ]; then
    printf '%s\n' "$picked"
    return
  fi

  # 2) git toplevel + .agentic-team/log
  local top
  top=$(_git_toplevel_or_empty)
  if [ -n "$top" ]; then
    printf '%s/.agentic-team/log\n' "$top"
    return
  fi

  # 3) cwd fallback (Obsidian vault 작업 등 git 미관리 케이스 커버)
  printf '%s/.agentic-team/log\n' "$PWD"
}
