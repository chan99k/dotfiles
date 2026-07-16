# gj — ~/git 하위 폴더로 점프. mshelp 패턴(TSV + fzf) + cd.
# 데이터: ~/.zsh.after/git-folders.tsv (<group>\t<name>\t<description>)
# 사용: gj [query]  → fzf 검색(그룹 태그로 그룹 필터) → Enter=cd ~/git/<name>

gj() {
  local file="$HOME/.zsh.after/git-folders.tsv"
  [[ -f "$file" ]] || { echo "[gj] not found: $file"; return 1; }
  local base="$HOME/git"

  local sel
  sel=$(awk -F'\t' '
    # $1=group(회색 태그), $2=name(청록), $3=description
    /^#/ { next }
    NF < 3 { next }
    { printf "\033[36m%-26s\033[0m \033[90m%-6s\033[0m %s\n", $2, "["$1"]", $3 }
  ' "$file" \
    | fzf --ansi --query="${1:-}" --reverse \
        --header='[group] 검색=그룹 필터 │ Enter=cd ~/git/<name>' \
        --preview="ls -la $base/{1} 2>/dev/null | head -25" \
        --preview-window=right:45%:wrap)

  [[ -n "$sel" ]] || return
  # 첫 컬럼(name) 추출 + ANSI 제거 + 공백 trim
  local name=$(echo "$sel" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
  [[ -n "$name" && -d "$base/$name" ]] || { echo "[gj] no dir: $base/$name"; return 1; }
  cd "$base/$name"
}
