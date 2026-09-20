#!/usr/bin/env bash
# Claude Code statusLine — agnoster 프롬프트(prompt_context) 스타일 재현
# stdin 으로 세션 JSON 을 받아 한 줄 상태를 출력한다.

input=$(cat)

cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
[ -z "$cwd" ] && cwd="$PWD"

# .zshrc prompt_context 와 동일한 emoji 세트 (bash 0-index)
emojis=("⚡️" "🔥" "🍻" "🚀" "💡" "🎉" "🌙")
emoji="${emojis[$((RANDOM % ${#emojis[@]}))]}"

user=$(whoami)

# git 브랜치 (cwd 기준)
branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
  || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

dir_name=$(basename "$cwd")

# ANSI 색상 (agnoster 세그먼트 느낌: user=흰, dir=파랑, branch=초록, model=회색)
c_reset=$'\033[0m'; c_user=$'\033[1;37m'; c_dir=$'\033[36m'; c_git=$'\033[32m'; c_model=$'\033[90m'

line="${c_user}${user} ${emoji}${c_reset}  ${c_dir}${dir_name}${c_reset}"
[ -n "$branch" ] && line="${line} ${c_git}(${branch})${c_reset}"
line="${line}  ${c_model}${model}${c_reset}"

printf '%s' "$line"
