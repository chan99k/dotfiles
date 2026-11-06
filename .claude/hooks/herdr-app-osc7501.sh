#!/bin/sh
# Herdr 앱 칸에서 Claude Code 상태를 OSC 7501 로 herdr-core 에 보고한다.
# herdr-agent-state.sh 는 herdr 가 관리해 재설치 때 덮어쓰므로 건드리지 않고 이 파일을 옆에 둔다.
# 사용: herdr-app-osc7501.sh <session-start|prompt|post-tool|perm|idle-prompt|stop|session-end>
#
# - stdout 은 모델 컨텍스트로 주입될 수 있고 exit 2 는 Stop/UserPromptSubmit 을 막는다.
#   그래서 아무것도 출력하지 않고 항상 exit 0 한다 (set -e 쓰지 않음)
# - hook 프로세스에는 제어 tty 가 없어 $(tty) 가 실패한다. 조상을 올라가며 tty 가 있는 첫 프로세스를 쓴다
# - ps 출력의 ?? 가 glob 으로 풀리지 않도록 set -f 로 끈다

set -f

[ -n "${HC_TERMINAL_ID:-}" ] || exit 0

event="${1:-}"
state_file="${TMPDIR:-/tmp}/herdr-app-state.${HC_TERMINAL_ID}"
last=""
[ -r "$state_file" ] && read -r last < "$state_file"

# 권한 대기(blocked) 뒤에는 Stop 전까지 working 으로 돌려줄 훅이 없다. blocked 일 때만 PostToolUse 가
# 일하게 하고, 아니면 아무것도 띄우지 않고 바로 끝낸다 (도구 호출마다 도는 경로라 이 줄이 비용을 정한다)
if [ "$event" = post-tool ] && [ "$last" != blocked ]; then
  exit 0
fi

kind=""
case "$event" in
  session-start) state=idle ;;
  prompt|post-tool) state=working ;;
  perm) state=blocked; kind=":kind=permission" ;;
  idle-prompt)
    # Esc 로 끊으면 Stop 이 안 오므로 working 이었을 때만 idle 로 내린다 (done 을 지우지 않는다)
    [ "$last" = working ] || exit 0
    state=idle ;;
  stop) state=done ;;
  session-end) state=clear ;;
  *) exit 0 ;;
esac

tty=""
pid=$$
depth=0
while [ -n "$pid" ] && [ "$pid" -gt 1 ] && [ "$depth" -lt 10 ]; do
  info=$(ps -o tty=,ppid= -p "$pid" 2>/dev/null) || break
  set -- $info
  case "${1:-}" in
    ''|'?'|'??') ;;
    *) tty="$1"; break ;;
  esac
  pid="${2:-}"
  depth=$((depth + 1))
done

if [ -n "$tty" ] && [ -c "/dev/$tty" ] && [ -w "/dev/$tty" ]; then
  printf '\033]7501;:state=%s%s:app=claude-code\033\\' "$state" "$kind" 2>/dev/null > "/dev/$tty"
  if [ "$state" = clear ]; then
    rm -f "$state_file" 2>/dev/null
  else
    printf '%s\n' "$state" 2>/dev/null > "$state_file"
  fi
fi

exit 0
