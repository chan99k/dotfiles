#!/usr/bin/env bash
# PreToolUse guard: git push의 hook-스킵/강제 플래그를 위치 무관하게 차단.
# Installed: 2026-07-01
#
# --no-verify는 git이 pre-push hook을 스킵시키므로 Layer 1(pre-push)로는
# 못 잡는다. 이 hook이 Claude 도구 계층(메인+서브에이전트)에서 그 구멍을
# 메운다. 정규식으로 명령 문자열 전체를 검사하므로 플래그 위치와 무관.
#
# 입력: PreToolUse JSON(stdin). exit 2 = 차단(stderr가 Claude에 전달됨).

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

# git push 명령만 검사 (&&, ;, | 뒤 / git -C 변형 포함)
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push\b'; then
    # --no-verify / --force / -f / --force-with-lease 를 위치 무관하게 탐지
    if printf '%s' "$cmd" | grep -Eq -- '(--no-verify|--force\b|[[:space:]]-f([[:space:]]|$))'; then
        echo "🛑 차단: git push에 --no-verify/--force 계열 플래그 감지 (위치 무관)." >&2
        echo "   강제/hook-스킵 push는 사용자가 직접 터미널에서 실행하세요." >&2
        exit 2
    fi
fi
exit 0
