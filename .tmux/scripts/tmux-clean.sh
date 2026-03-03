#!/bin/bash
# Kill detached tmux sessions older than N days (default: 3)
MAX_AGE_DAYS="${1:-3}"
cutoff=$(date -v-${MAX_AGE_DAYS}d +%s 2>/dev/null || date -d "${MAX_AGE_DAYS} days ago" +%s)
count=0

while IFS=' ' read -r name attached activity; do
  if [[ "$attached" == "0" && "$activity" -lt "$cutoff" ]]; then
    tmux kill-session -t "$name" 2>/dev/null && ((count++))
  fi
done < <(tmux list-sessions -F '#{session_name} #{session_attached} #{session_activity}' 2>/dev/null)

if [[ "$count" -gt 0 ]]; then
  echo "tmux-clean: killed $count stale session(s)"
else
  echo "tmux-clean: no stale sessions"
fi
