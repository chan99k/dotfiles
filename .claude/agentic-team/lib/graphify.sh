#!/usr/bin/env bash
# graphify.sh — graphify 그래프 탐지·컨텍스트 발췌 헬퍼
#
# 본 명세 SPEC.md 5장 구현. agentic-team 은 그래프를 *생성하지 않음* —
# 발견 시 사용, 미발견 시 알림 후 그대로 진행.
#
# 탐색 우선순위:
#   1) $AGENTIC_TEAM_GRAPHIFY_DIR/graph.json
#   2) $PWD/graphify-out/graph.json
#   3) git toplevel/graphify-out/graph.json
#
# 첨부 cap (큰 프로젝트·Obsidian vault 의 거대 그래프 방어):
#   $AGENTIC_TEAM_GRAPHIFY_MAX_BYTES (default 8192 = 8KB)
#
# 사용:
#   source <이 파일>
#   if dir=$(graphify_dir); then
#     excerpt=$(graphify_context_excerpt)
#     # excerpt 를 <graphify_context> 태그로 감싸 prompt 에 첨부
#   else
#     printf '[%s] no graph for this project\n' "$caller" >&2
#   fi

# 그래프 디렉토리 탐색. 발견 시 stdout 출력 + return 0. 미발견 return 1.
graphify_dir() {
  local probe

  # 1) env override
  probe="${AGENTIC_TEAM_GRAPHIFY_DIR:-}"
  if [ -n "$probe" ] && [ -f "${probe}/graph.json" ]; then
    printf '%s\n' "$probe"
    return 0
  fi

  # 2) cwd
  probe="${PWD}/graphify-out"
  if [ -f "${probe}/graph.json" ]; then
    printf '%s\n' "$probe"
    return 0
  fi

  # 3) git toplevel
  if command -v git >/dev/null 2>&1; then
    local top
    top=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [ -n "$top" ]; then
      probe="${top}/graphify-out"
      if [ -f "${probe}/graph.json" ]; then
        printf '%s\n' "$probe"
        return 0
      fi
    fi
  fi

  return 1
}

# GRAPH_REPORT.md 의 head 발췌 + 그래프 절대경로 메타데이터.
# 그래프 발견 + report 존재 시 stdout 마크다운 출력 + return 0.
# 미발견 시 빈 출력 + return 1.
graphify_context_excerpt() {
  local dir
  dir=$(graphify_dir) || return 1

  local report="${dir}/GRAPH_REPORT.md"
  [ -f "$report" ] || return 1

  local cap="${AGENTIC_TEAM_GRAPHIFY_MAX_BYTES:-8192}"
  local excerpt
  excerpt=$(head -c "$cap" "$report" 2>/dev/null) || return 1

  # 발췌 + 출처 메타. 본 출력은 호출자가 trust-boundary strip 후
  # <graphify_context> 태그로 감싸 prompt 에 첨부.
  printf '%s\n\n전체 그래프: %s/graph.json\n' "$excerpt" "$dir"
}
