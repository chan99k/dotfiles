#!/usr/bin/env bash
# dashboard-render.sh — agentic-team status 추출·렌더·watch 루프
#
# 본 명세 SPEC.md §8 (tmux 3-pane Dashboard) 구현. raw 로그는 디스크에 두고
# *추출된 status 만* 압축 표시. flicker-free 는 cksum 비교로 변경 시만 redraw.
#
# 외부 의존성 0 — bash + 표준 awk/grep/tput 만 사용.
#
# Public 함수:
#   dashboard_extract_codex  <log_file>   — _DRC_* 글로벌 set
#   dashboard_extract_gemini <log_file>   — _DRG_* 글로벌 set
#   dashboard_extract_audit  <log_file>   — _DRA_* 글로벌 set (persona 포함)
#   dashboard_render_codex   <log_file>   — stdout 으로 ANSI 색상 프레임
#   dashboard_render_gemini  <log_file>   — stdout 으로 ANSI 색상 프레임
#   dashboard_render_audit   <log_file>   — stdout (persona 색상 분기)
#   dashboard_watch          <which> <log_dir>  — 무한 폴링 루프 (q/space/l 키)
#                                            which ∈ {codex, gemini, audit}

# ---- ANSI 색상 (terminfo 표준 시퀀스) -----------------------------------
_DR_RESET=$'\e[0m'
_DR_BOLD=$'\e[1m'
_DR_DIM=$'\e[2m'
_DR_RED=$'\e[31m'
_DR_GREEN=$'\e[32m'
_DR_YELLOW=$'\e[33m'
_DR_BLUE=$'\e[34m'
_DR_CYAN=$'\e[36m'

# ---- 헬퍼: 긴 문자열 trunc + ellipsis ----------------------------------
dashboard_truncate() {
  local s="$1" maxlen="$2"
  if [ "${#s}" -gt "$maxlen" ]; then
    printf '%s…' "${s:0:$((maxlen-1))}"
  else
    printf '%s' "$s"
  fi
}

# ---- Codex 로그 status 추출 --------------------------------------------
# 응답 구간 한정 파싱 — 프롬프트의 Output Contract 예시(verdict 형식 보여줌)
# 와 실제 응답을 혼동 안 하도록 `--- RESPONSE ---` ~ `--- END` 사이만 본다.
#
# 실제 환경 관찰 (smoke test §9.9):
#   1) codex CLI 가 streaming 중간 결과 + 최종 요약을 둘 다 stdout 으로 내보내
#      `## Verdict` 블록이 RESPONSE 영역 안에서 여러 번 등장. 단순 누적은 N배 bloat.
#      → `## Verdict` 만날 때마다 카운트 리셋해 *마지막 블록* 만 살린다.
#   2) 응답 실패 (quota, network 등 rc!=0) 시 응답이 비거나 잘려 verdict 가
#      template literal (`<one of: ...>`) 로 새는 케이스 발생.
#      → verdict 화이트리스트 + rc!=0 둘 다 zero out (defence in depth).
dashboard_extract_codex() {
  local log="$1"

  _DRC_VERDICT=""
  _DRC_VERDICT_REASON=""
  _DRC_BLOCKER=0
  _DRC_MAJOR=0
  _DRC_MINOR=0
  _DRC_FOCUS=""
  _DRC_RUNNING=0

  [ -f "$log" ] || return 1

  _DRC_FOCUS=$(grep -m1 '^focus:' "$log" 2>/dev/null | sed 's/^focus: //')

  # running = RESPONSE 시작했지만 END 아직 미도착
  if grep -q '^--- RESPONSE ---' "$log" 2>/dev/null \
     && ! grep -q '^--- END (rc=' "$log" 2>/dev/null; then
    _DRC_RUNNING=1
  fi

  # rc 추출 — END 마커 있으면 캡쳐. 종료 마커 도착 전(running) 이면 빈 문자열.
  local rc_line rc=""
  rc_line=$(grep -m1 '^--- END (rc=' "$log" 2>/dev/null || true)
  if [ -n "$rc_line" ]; then
    rc=$(printf '%s' "$rc_line" | sed -E 's/^--- END \(rc=([0-9]+)\).*/\1/')
  fi

  # 단일 awk 패스 — verdict line + Blocker/Major/Minor 카운트 동시 추출.
  # `## Verdict` 진입마다 카운터 리셋 → streaming 중간 + 최종 요약의 중복을 흡수,
  # 마지막 완전한 블록만 결과로 살아남는다.
  local awk_out
  awk_out=$(awk '
    /^--- RESPONSE ---/ { f=1; next }
    /^--- END/         { f=0 }
    !f                  { next }
    /^## Verdict/      {
      vmode=1
      b=0; m=0; n=0; verdict_line=""
      sec=""
      next
    }
    vmode && NF        { verdict_line=$0; vmode=0 }
    /^### Blocker/     { sec="b"; next }
    /^### Major/       { sec="m"; next }
    /^### Minor/       { sec="n"; next }
    /^## /             { sec="" }
    sec=="b" && /^- /  { b++ }
    sec=="m" && /^- /  { m++ }
    sec=="n" && /^- /  { n++ }
    END {
      printf "%d\t%d\t%d\t%s\n", b+0, m+0, n+0, verdict_line
    }
  ' "$log")

  IFS=$'\t' read -r _DRC_BLOCKER _DRC_MAJOR _DRC_MINOR _verdict_line <<<"$awk_out"

  if [ -n "${_verdict_line:-}" ]; then
    _DRC_VERDICT=$(printf '%s' "$_verdict_line" | awk '{print $1}')
    _DRC_VERDICT_REASON=$(printf '%s' "$_verdict_line" | sed 's/^[^—]*— //')
  fi

  # verdict 화이트리스트 — Output Contract 미준수 / template literal 누출 차단.
  # 세 값 외에는 모든 status 무효 처리.
  case "${_DRC_VERDICT:-}" in
    SHIP|NEEDS-FIX|DISCUSS) ;;
    *)
      _DRC_VERDICT=""
      _DRC_VERDICT_REASON=""
      _DRC_BLOCKER=0
      _DRC_MAJOR=0
      _DRC_MINOR=0
      ;;
  esac

  # rc != 0 → codex CLI 실패. 응답 일부가 verdict 형식을 통과해도 신뢰 불가 → zero.
  if [ -n "$rc" ] && [ "$rc" != "0" ]; then
    _DRC_VERDICT=""
    _DRC_VERDICT_REASON=""
    _DRC_BLOCKER=0
    _DRC_MAJOR=0
    _DRC_MINOR=0
  fi
}

# ---- Gemini 로그 status 추출 -------------------------------------------
dashboard_extract_gemini() {
  local log="$1"

  _DRG_QUERY=""
  _DRG_LEAD=""
  _DRG_SOURCES=0
  _DRG_RUNNING=0

  [ -f "$log" ] || return 1

  _DRG_QUERY=$(grep -m1 '^query:' "$log" 2>/dev/null | sed 's/^query: //')

  if grep -q '^--- RESPONSE ---' "$log" 2>/dev/null \
     && ! grep -q '^--- END (rc=' "$log" 2>/dev/null; then
    _DRG_RUNNING=1
  fi

  # lead = 응답 첫 비어있지 않은 줄
  _DRG_LEAD=$(awk '
    /^--- RESPONSE ---/ { f=1; next }
    /^--- END/          { f=0 }
    f && NF             { print; exit }
  ' "$log")

  # sources = 응답 구간 안 http/https URL 갯수
  _DRG_SOURCES=$(awk '
    /^--- RESPONSE ---/ { f=1; next }
    /^--- END/          { f=0 }
    !f                  { next }
    {
      while (match($0, /https?:\/\/[^ )"\047>]+/)) {
        n++
        $0 = substr($0, RSTART + RLENGTH)
      }
    }
    END { print n+0 }
  ' "$log")
}

# ---- Codex pane 프레임 렌더 (ANSI 색상) --------------------------------
dashboard_render_codex() {
  local log="$1"
  dashboard_extract_codex "$log" || true

  printf '%s%sCodex · reviewer%s\n' "$_DR_BOLD" "$_DR_CYAN" "$_DR_RESET"
  printf '%sFocus:%s   %s\n' "$_DR_DIM" "$_DR_RESET" \
    "$(dashboard_truncate "${_DRC_FOCUS:-(no activity)}" 38)"

  # verdict 색상바
  local color label
  if [ "${_DRC_RUNNING:-0}" = "1" ]; then
    color=$_DR_YELLOW; label='⏳ running'
  else
    case "${_DRC_VERDICT:-}" in
      SHIP)        color=$_DR_GREEN;  label='SHIP' ;;
      NEEDS-FIX)   color=$_DR_RED;    label='NEEDS-FIX' ;;
      DISCUSS)     color=$_DR_YELLOW; label='DISCUSS' ;;
      *)           color=$_DR_DIM;    label='—' ;;
    esac
  fi
  printf '%sVerdict:%s %s%s%s\n' "$_DR_DIM" "$_DR_RESET" "$color" "$label" "$_DR_RESET"

  if [ -n "${_DRC_VERDICT_REASON:-}" ]; then
    printf '          %s%s%s\n' "$_DR_DIM" \
      "$(dashboard_truncate "$_DRC_VERDICT_REASON" 38)" "$_DR_RESET"
  fi

  printf '%sFindings:%s %s%d%s b / %s%d%s M / %s%d%s m\n' \
    "$_DR_DIM" "$_DR_RESET" \
    "$_DR_RED"    "${_DRC_BLOCKER:-0}" "$_DR_RESET" \
    "$_DR_YELLOW" "${_DRC_MAJOR:-0}"   "$_DR_RESET" \
    "$_DR_DIM"    "${_DRC_MINOR:-0}"   "$_DR_RESET"
}

# ---- Gemini pane 프레임 렌더 (ANSI 색상) -------------------------------
dashboard_render_gemini() {
  local log="$1"
  dashboard_extract_gemini "$log" || true

  printf '%s%sGemini · researcher%s\n' "$_DR_BOLD" "$_DR_BLUE" "$_DR_RESET"
  printf '%sQuery:%s  %s\n' "$_DR_DIM" "$_DR_RESET" \
    "$(dashboard_truncate "${_DRG_QUERY:-(no activity)}" 38)"

  if [ "${_DRG_RUNNING:-0}" = "1" ]; then
    printf '%sStatus:%s %s⏳ running%s\n' "$_DR_DIM" "$_DR_RESET" "$_DR_YELLOW" "$_DR_RESET"
  elif [ -n "${_DRG_LEAD:-}" ]; then
    printf '%sStatus:%s %s✓ done%s\n' "$_DR_DIM" "$_DR_RESET" "$_DR_GREEN" "$_DR_RESET"
  else
    printf '%sStatus:%s %s—%s\n' "$_DR_DIM" "$_DR_RESET" "$_DR_DIM" "$_DR_RESET"
  fi

  if [ -n "${_DRG_LEAD:-}" ]; then
    printf '%sLead:%s    %s\n' "$_DR_DIM" "$_DR_RESET" \
      "$(dashboard_truncate "$_DRG_LEAD" 38)"
  fi

  printf '%sSources:%s %d\n' "$_DR_DIM" "$_DR_RESET" "${_DRG_SOURCES:-0}"
}

# ---- Audit 로그 status 추출 --------------------------------------------
# audit-codex 는 ask-codex 와 동일한 Output Contract — verdict/findings 파싱은
# byte-identical 가드 룰 적용. 다만 전역 변수 prefix 는 _DRA_ 로 분리해 watch
# 루프 내 render_codex / render_audit 가 서로의 상태를 덮어쓰지 않도록 한다.
# 추가로 헤더의 `persona:` 라인 (ceo|cto) 을 추출.
#
# extract_codex 와 동일한 3-layer 방어 (streaming 중복 흡수 / verdict 화이트리스트
# / rc!=0 zero out) 적용 — 같은 codex CLI stdout 패턴을 공유하므로 같은 버그.
dashboard_extract_audit() {
  local log="$1"

  _DRA_VERDICT=""
  _DRA_VERDICT_REASON=""
  _DRA_BLOCKER=0
  _DRA_MAJOR=0
  _DRA_MINOR=0
  _DRA_FOCUS=""
  _DRA_PERSONA=""
  _DRA_RUNNING=0

  [ -f "$log" ] || return 1

  _DRA_FOCUS=$(grep -m1 '^focus:' "$log" 2>/dev/null | sed 's/^focus: //')
  _DRA_PERSONA=$(grep -m1 '^persona:' "$log" 2>/dev/null | sed 's/^persona: //')

  if grep -q '^--- RESPONSE ---' "$log" 2>/dev/null \
     && ! grep -q '^--- END (rc=' "$log" 2>/dev/null; then
    _DRA_RUNNING=1
  fi

  local rc_line rc=""
  rc_line=$(grep -m1 '^--- END (rc=' "$log" 2>/dev/null || true)
  if [ -n "$rc_line" ]; then
    rc=$(printf '%s' "$rc_line" | sed -E 's/^--- END \(rc=([0-9]+)\).*/\1/')
  fi

  local awk_out
  awk_out=$(awk '
    /^--- RESPONSE ---/ { f=1; next }
    /^--- END/         { f=0 }
    !f                  { next }
    /^## Verdict/      {
      vmode=1
      b=0; m=0; n=0; verdict_line=""
      sec=""
      next
    }
    vmode && NF        { verdict_line=$0; vmode=0 }
    /^### Blocker/     { sec="b"; next }
    /^### Major/       { sec="m"; next }
    /^### Minor/       { sec="n"; next }
    /^## /             { sec="" }
    sec=="b" && /^- /  { b++ }
    sec=="m" && /^- /  { m++ }
    sec=="n" && /^- /  { n++ }
    END {
      printf "%d\t%d\t%d\t%s\n", b+0, m+0, n+0, verdict_line
    }
  ' "$log")

  IFS=$'\t' read -r _DRA_BLOCKER _DRA_MAJOR _DRA_MINOR _verdict_line <<<"$awk_out"

  if [ -n "${_verdict_line:-}" ]; then
    _DRA_VERDICT=$(printf '%s' "$_verdict_line" | awk '{print $1}')
    _DRA_VERDICT_REASON=$(printf '%s' "$_verdict_line" | sed 's/^[^—]*— //')
  fi

  case "${_DRA_VERDICT:-}" in
    SHIP|NEEDS-FIX|DISCUSS) ;;
    *)
      _DRA_VERDICT=""
      _DRA_VERDICT_REASON=""
      _DRA_BLOCKER=0
      _DRA_MAJOR=0
      _DRA_MINOR=0
      ;;
  esac

  if [ -n "$rc" ] && [ "$rc" != "0" ]; then
    _DRA_VERDICT=""
    _DRA_VERDICT_REASON=""
    _DRA_BLOCKER=0
    _DRA_MAJOR=0
    _DRA_MINOR=0
  fi
}

# ---- Auditor pane 프레임 렌더 (페르소나 색상) --------------------------
# 페르소나로 색상 분기 — ceo=파랑(비즈니스), cto=시안(시스템). 빈 페르소나
# (= idle) 는 dim 회색으로. 동일 wrapper 라도 PM 이 어떤 페르소나로 호출했는지
# 시각적으로 즉시 구분.
dashboard_render_audit() {
  local log="$1"
  dashboard_extract_audit "$log" || true

  local persona_color persona_label
  case "${_DRA_PERSONA:-}" in
    ceo) persona_color=$_DR_BLUE; persona_label='ceo' ;;
    cto) persona_color=$_DR_CYAN; persona_label='cto' ;;
    '')  persona_color=$_DR_DIM;  persona_label='idle' ;;
    *)   persona_color=$_DR_DIM;  persona_label="${_DRA_PERSONA}" ;;
  esac

  printf '%s%sAuditor%s %s· %s%s%s\n' \
    "$_DR_BOLD" "$_DR_YELLOW" "$_DR_RESET" \
    "$_DR_DIM" "$persona_color" "$persona_label" "$_DR_RESET"
  printf '%sFocus:%s   %s\n' "$_DR_DIM" "$_DR_RESET" \
    "$(dashboard_truncate "${_DRA_FOCUS:-(no activity)}" 38)"

  local color label
  if [ "${_DRA_RUNNING:-0}" = "1" ]; then
    color=$_DR_YELLOW; label='⏳ running'
  else
    case "${_DRA_VERDICT:-}" in
      SHIP)        color=$_DR_GREEN;  label='SHIP' ;;
      NEEDS-FIX)   color=$_DR_RED;    label='NEEDS-FIX' ;;
      DISCUSS)     color=$_DR_YELLOW; label='DISCUSS' ;;
      *)           color=$_DR_DIM;    label='—' ;;
    esac
  fi
  printf '%sVerdict:%s %s%s%s\n' "$_DR_DIM" "$_DR_RESET" "$color" "$label" "$_DR_RESET"

  if [ -n "${_DRA_VERDICT_REASON:-}" ]; then
    printf '          %s%s%s\n' "$_DR_DIM" \
      "$(dashboard_truncate "$_DRA_VERDICT_REASON" 38)" "$_DR_RESET"
  fi

  printf '%sFindings:%s %s%d%s b / %s%d%s M / %s%d%s m\n' \
    "$_DR_DIM" "$_DR_RESET" \
    "$_DR_RED"    "${_DRA_BLOCKER:-0}" "$_DR_RESET" \
    "$_DR_YELLOW" "${_DRA_MAJOR:-0}"   "$_DR_RESET" \
    "$_DR_DIM"    "${_DRA_MINOR:-0}"   "$_DR_RESET"
}

# ---- watch 루프 — 폴링 + 키 핸들링 -------------------------------------
# 키:
#   q     종료
#   space 일시정지/재개 (last frame 유지)
#   l     less 로 raw 로그 보기 → 복귀 시 강제 redraw
dashboard_watch() {
  local which="$1"      # codex | gemini | audit
  local log_dir="$2"    # team 격리된 로그 디렉토리
  local link="${log_dir}/latest-${which}.log"

  local paused=0
  local last_cksum=""

  # 커서 숨김 + 종료 시 복원
  trap 'tput cnorm 2>/dev/null; printf "\e[?25h\n"; exit 0' INT TERM EXIT
  tput civis 2>/dev/null || printf '\e[?25l'

  while :; do
    if [ "$paused" = "0" ]; then
      local frame
      case "$which" in
        codex)  frame=$(dashboard_render_codex   "$link") ;;
        gemini) frame=$(dashboard_render_gemini  "$link") ;;
        audit)  frame=$(dashboard_render_audit   "$link") ;;
        *)      frame="(unknown watcher: $which)" ;;
      esac

      local current_cksum
      current_cksum=$(printf '%s' "$frame" | cksum)

      if [ "$current_cksum" != "$last_cksum" ]; then
        # \e[H = 커서 home, \e[2J = 화면 클리어. atomic redraw.
        printf '\e[H\e[2J%s\n%s—%s\n' "$frame" "$_DR_DIM" "$_DR_RESET"
        printf '%s%s · %s · q quit / space pause / l log%s' \
          "$_DR_DIM" "$which" "$(date +%H:%M:%S)" "$_DR_RESET"
        last_cksum="$current_cksum"
      fi
    fi

    # 1초 timeout 키 입력 — sleep 대용 + 응답성 유지
    local key=""
    read -rsn1 -t 1 key 2>/dev/null || true
    case "$key" in
      q) trap - INT TERM EXIT; tput cnorm 2>/dev/null; printf '\e[?25h\n'; return 0 ;;
      ' ')
        paused=$((1 - paused))
        if [ "$paused" = "1" ]; then
          printf '\n%s[paused — space to resume]%s' "$_DR_YELLOW" "$_DR_RESET"
        else
          last_cksum=""  # resume 시 강제 redraw
        fi
        ;;
      l)
        if [ -f "$link" ]; then
          tput cnorm 2>/dev/null
          ${PAGER:-less} "$link"
          tput civis 2>/dev/null || printf '\e[?25l'
          last_cksum=""
        fi
        ;;
    esac
  done
}
