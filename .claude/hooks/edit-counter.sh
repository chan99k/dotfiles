#!/bin/bash
# edit-counter.sh - 동일 파일 반복 수정 경고
# PostToolUse hook for Edit/Write tools

FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-$1}"
if [ -z "$FILE_PATH" ]; then exit 0; fi

COUNTER_DIR="/tmp/claude-edit-counts"
mkdir -p "$COUNTER_DIR"

# 파일 경로를 해시로 카운터 파일명 생성 (macOS의 md5 명령 사용)
HASH=$(echo "$FILE_PATH" | md5)
COUNTER_FILE="$COUNTER_DIR/$HASH"
BASENAME="${FILE_PATH##*/}"

# 카운트 증가
if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE")
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi
echo "$COUNT" > "$COUNTER_FILE"

# 5회 이상이면 경고
if [ "$COUNT" -ge 5 ]; then
  echo "warning: ${BASENAME}을 이 세션에서 ${COUNT}회 수정했습니다. 구조 변경이나 일괄 처리를 고려하세요."
fi
