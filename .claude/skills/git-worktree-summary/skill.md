---
name: git-worktree-summary
description: |
  Git 워크트리와 브랜치 현황을 종합 분석하여 요약 테이블로 출력.
  로컬 브랜치의 커밋 수, GitHub PR 연동 여부, 푸시 상태, 워크트리 여부를 한눈에 파악.
  "워크트리 현황", "브랜치 현황", "branch summary", "git summary" 등의 요청 시 자동 적용.
---

# Git Worktree Summary

Git 레포지토리의 워크트리 및 브랜치 상태를 종합 분석하여 한눈에 파악할 수 있는 요약 테이블을 출력하는 스킬.

## Trigger

- "워크트리 현황", "브랜치 현황", "branch summary", "git summary", "git 현황"

## Prerequisites

| 도구 | 필수 여부 | 확인 명령어 |
|------|----------|------------|
| git | 필수 | `command -v git` |
| gh (GitHub CLI) | 선택 | `command -v gh` |

gh CLI가 없으면 PR 정보를 제외하고 나머지 정보만 표시합니다.

## Workflow

### Phase 1: Git Repository 확인

```bash
# 현재 디렉토리가 git 레포지토리인지 확인
git rev-parse --show-toplevel 2>/dev/null
```

- **실패 시**: "ERROR: 현재 디렉토리는 git 레포지토리가 아닙니다." 출력 후 종료
- **성공 시**: 레포지토리 루트 경로 저장

### Phase 2: 기본 브랜치 감지

```bash
# develop 또는 main 중 존재하는 것 사용
DEFAULT_BRANCH=$(git branch --list develop main | head -1 | tr -d ' *')

# 둘 다 없으면 origin/HEAD가 가리키는 브랜치 사용
if [ -z "$DEFAULT_BRANCH" ]; then
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
fi

# 그래도 없으면 main으로 fallback
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
```

### Phase 3: 데이터 수집 (병렬)

다음 정보를 수집합니다:

#### 3.1. 활성 워크트리 목록

```bash
git worktree list --porcelain
```

출력 파싱하여 각 워크트리의 경로와 브랜치 추출.

#### 3.2. 로컬 브랜치 목록

```bash
# 모든 로컬 브랜치 (최근 커밋 날짜 포함)
git for-each-ref --format='%(refname:short)|%(upstream:track)|%(committerdate:iso8601)' refs/heads/ | sort -t'|' -k3 -r
```

출력 형식 예시 (파이프 구분):
```
feature/login|[ahead 3]|2026-03-17T15:30:00+09:00
chore/cleanup|[gone]|2026-03-15T10:20:00+09:00
develop||2026-03-16T18:45:00+09:00
```

**파싱 방법:**
```bash
while IFS='|' read -r branch track date; do
  # branch: 브랜치명
  # track: upstream 추적 상태 (비어있으면 동기화됨)
  # date: ISO 8601 형식 날짜 (YYYY-MM-DD만 추출: ${date:0:10})
done < <(git for-each-ref --format='%(refname:short)|%(upstream:track)|%(committerdate:iso8601)' refs/heads/)
```

`%(upstream:track)` 필드 해석:
- ` ` (공백/빈 문자열): remote와 동기화됨 (push 완료)
- `[ahead N]`: N개 커밋이 미푸시됨
- `[behind N]`: remote보다 N개 커밋 뒤처짐
- `[ahead N, behind M]`: 로컬/리모트 모두 커밋 있음 (diverged)
- `[gone]`: remote 브랜치 삭제됨 (stale branch)

#### 3.3. 각 브랜치별 커밋 수 집계

```bash
# develop 대비 미머지 커밋 수
while IFS= read -r branch; do
  if [ "${branch}" != "${DEFAULT_BRANCH}" ]; then
    COUNT=$(git rev-list --count "${DEFAULT_BRANCH}".."${branch}" 2>/dev/null || echo "0")
    echo "${branch}|${COUNT}"
  fi
done < <(git branch --format='%(refname:short)')
```

**출력 예시 (파이프 구분):**
```
feature/login|3
chore/cleanup|0
hotfix/payment|1
```

#### 3.4. GitHub PR 정보 (gh CLI 있을 경우)

```bash
# gh CLI 사용 가능 여부 확인
if command -v gh &>/dev/null; then
  # 모든 PR 목록 (open + closed)
  gh pr list --state all --json number,headRefName,state --limit 200
fi
```

PR 번호를 브랜치명으로 매핑.

### Phase 4: 데이터 통합 및 테이블 생성

**데이터 구조:**

각 브랜치에 대해 다음 정보를 연관 배열(associative array) 또는 구조화된 형태로 통합:

```bash
# 예시 데이터 구조 (Bash 연관 배열 사용)
declare -A branch_commit_count    # branch -> commit count
declare -A branch_track_status    # branch -> upstream track
declare -A branch_date            # branch -> last commit date
declare -A branch_pr              # branch -> PR number & state
declare -A branch_worktree        # branch -> worktree path (없으면 empty)

# Phase 3에서 수집한 데이터로 채움
# 예: branch_commit_count["feature/login"]="3"
#     branch_track_status["feature/login"]="[ahead 3]"
#     branch_pr["feature/login"]="#123 (OPEN)"
#     branch_worktree["feature/login"]="/path/to/worktree"
```

**통합 절차:**

1. Phase 3.1 워크트리 목록에서 `branch_worktree` 채우기
2. Phase 3.2 브랜치 목록 순회하면서 각 브랜치에 대해:
   - `branch_track_status`, `branch_date` 저장
   - Phase 3.3 커밋 수 매칭: `branch_commit_count` 저장
   - Phase 3.4 PR 목록에서 headRefName 매칭: `branch_pr` 저장
3. Stale branches 카운트: `branch_track_status` 값이 `[gone]`인 브랜치 개수
4. Unpushed branches 카운트: `branch_track_status` 값이 `[ahead N]` 패턴인 브랜치 개수

**테이블 생성:**

수집한 정보를 브랜치별로 통합하여 출력:

| 브랜치명 | 커밋 수 | PR | 푸시 상태 | 워크트리 | 최근 커밋 |
|---------|---------|-----|----------|---------|----------|
| feature/login | 3 | #123 (OPEN) | ❌ ahead 3 | ✅ | 2026-03-17 |
| chore/cleanup | 0 | - | ❌ gone | ❌ | 2026-03-15 |
| hotfix/payment | 1 | #120 (MERGED) | ✅ | ❌ | 2026-03-16 |
| develop | - | - | ✅ | ✅ (main) | 2026-03-16 |

**컬럼 설명:**
- **브랜치명**: 로컬 브랜치 이름
- **커밋 수**: `develop..{branch}` 미머지 커밋 개수 (develop 브랜치는 `-` 표시)
- **PR**: GitHub PR 번호 및 상태 (없으면 `-`, gh 미설치 시 `N/A`)
- **푸시 상태**:
  - ✅: remote와 동기화됨
  - ❌ ahead N: N개 커밋 미푸시
  - ❌ gone: remote 브랜치 삭제됨
  - ❌ behind N: remote보다 뒤처짐
  - ❌ diverged: 로컬/리모트 모두 변경
- **워크트리**: ✅ (경로 표시) 또는 ❌
- **최근 커밋**: YYYY-MM-DD 형식

### Phase 5: 요약 통계 출력

```
=== Git Worktree & Branch Summary ===
Repository: /Users/chan99/IdeaProjects/grep/giftify-be
Default Branch: develop

📊 Statistics:
  - Total Branches: 8
  - With Unpushed Commits: 3
  - Linked to Open PRs: 2
  - Active Worktrees: 3 (main + 2 additional)
  - Stale Branches (remote gone): 1
```

### Phase 6: 권장 액션 (선택)

분석 결과에 따라 권장 액션 제시. 다음 조건을 만족하는 브랜치만 표시:

**액션 생성 규칙:**

| 조건 | 권장 액션 |
|------|----------|
| `branch_track_status`가 `[ahead N]` 패턴 | "N commits ready to push" |
| `branch_track_status`가 `[gone]` | "Remote branch deleted, consider: git branch -d {branch}" |
| `branch_pr` 상태가 `MERGED` | "PR merged, safe to delete: git branch -d {branch}" |
| `branch_commit_count`가 0이고 PR 없음 | "No commits ahead, consider: git branch -d {branch}" |

**출력 예시:**
```
💡 Recommendations:
  - feature/login: 3 commits ready to push
  - chore/cleanup: Remote branch deleted, consider: git branch -d chore/cleanup
  - hotfix/payment: PR merged, safe to delete: git branch -d hotfix/payment
```

권장 액션이 없으면 "💡 Recommendations: None" 표시.

## Output Format

전체 출력 예시:

```markdown
=== Git Worktree & Branch Summary ===
Repository: /Users/chan99/IdeaProjects/grep/giftify-be
Default Branch: develop

📊 Statistics:
  - Total Branches: 8
  - With Unpushed Commits: 3
  - Linked to Open PRs: 2
  - Active Worktrees: 3 (main + 2 additional)
  - Stale Branches (remote gone): 1

| 브랜치명 | 커밋 수 | PR | 푸시 상태 | 워크트리 | 최근 커밋 |
|---------|---------|-----|----------|---------|----------|
| feature/login | 3 | #123 (OPEN) | ❌ ahead 3 | ✅ /path/to/worktree | 2026-03-17 |
| chore/cleanup | 0 | - | ❌ gone | ❌ | 2026-03-15 |
| hotfix/payment | 1 | #120 (MERGED) | ✅ | ❌ | 2026-03-16 |
| develop | - | - | ✅ | ✅ (main) | 2026-03-16 |
| ... | ... | ... | ... | ... | ... |

💡 Recommendations:
  - feature/login: 3 commits ready to push
  - chore/cleanup: Remote branch deleted, consider: git branch -d chore/cleanup
  - hotfix/payment: PR merged, safe to delete: git branch -d hotfix/payment
```

## Error Handling

| 상황 | 처리 |
|------|------|
| git 레포가 아님 | "ERROR: 현재 디렉토리는 git 레포지토리가 아닙니다." 출력 후 종료 |
| gh CLI 미설치 | PR 컬럼을 `N/A`로 표시, 나머지 정보는 정상 출력 |
| 브랜치 없음 (bare repo) | "No branches found." 출력 |
| git 명령어 실패 | 해당 필드를 `ERROR`로 표시, 스킬 종료 안 함 |
| 권한 문제 (worktree 접근 불가) | 워크트리 정보 제외, 경고 메시지 표시 |

## Implementation Notes

### 성능 최적화

- `git for-each-ref`: 브랜치 목록 한 번에 수집 (git branch 여러 번 호출 대비 효율적)
- PR 정보 한 번에 수집: `gh pr list --limit 200`로 모든 PR 가져와서 메모리에서 매칭
- 병렬 수집: git 명령어와 gh CLI 동시 실행 가능

### macOS 호환성

- `git`, `gh` CLI는 macOS에서 기본 제공되거나 Homebrew로 설치 가능
- 날짜 포맷: ISO 8601 형식 사용 (`committerdate:iso8601`)
- 이모지 사용: macOS 터미널에서 정상 표시됨 (✅ ❌ 📊 💡)

### Edge Cases

1. **브랜치가 기본 브랜치보다 뒤처진 경우**: 커밋 수를 `0`으로 표시하거나 별도 표시
2. **Detached HEAD 상태**: "(detached)" 표시
3. **워크트리가 삭제된 경로**: `git worktree prune` 권장 메시지 추가
4. **PR이 draft 상태**: `#123 (DRAFT)` 표시
5. **대용량 레포 (200+ 브랜치)**: 최근 30개만 표시 + "... and N more" 메시지
