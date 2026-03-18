---
name: project-status
description: |
  프로젝트 루트 디렉토리나 심링크가 주어지면 Git/GitHub 현황을 종합 분석하여 레포트 출력.
  서브 에이전트 기반 병렬 처리로 메인 컨텍스트 절약.
  "프로젝트 현황", "project status", "현황 파악", "상태 확인" 등의 요청 시 자동 적용.
---

# Project Status Report Skill

## 개요

Git 레포지토리의 현재 상태를 종합 분석하여 터미널에 레포트로 출력하는 범용 스킬.
아침 업무 시작 전 현황 파악 또는 오랜만에 프로젝트 복귀 시 컨텍스트 회복 용도.

## 인수 (Arguments)

| 인수 | 설명 | 기본값 |
|------|------|--------|
| path (positional) | 프로젝트 루트 경로 | 현재 디렉토리의 git root |
| `--save` | Obsidian Daily Note에 삽입 | 미지정 시 터미널 출력만 |
| `--full` | 선택 항목(CI/CD, 코드 통계, 의존성 변경)까지 포함 | 기본 항목만 |

**사용 예시**:
- `/project-status` — 현재 디렉토리 기준 기본 레포트
- `/project-status /path/to/repo` — 특정 경로 레포트
- `/project-status --full` — 확장 항목 포함
- `/project-status --save` — 터미널 출력 + Daily Note 저장
- `/project-status /path/to/repo --full --save` — 전체 옵션

## 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Main Agent (Orchestrator)                 │
│  - Phase 1: 경로 결정, git root 탐색, 인수 파싱             │
│  - Phase 2: 서브 에이전트 병렬 실행                          │
│  - Phase 3: 결과 통합 + 레포트 출력                          │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Sub 1    │   │ Sub 2    │   │ Sub 3    │
        │ Git      │   │ GitHub   │   │ Extended │
        │ Local    │   │ Remote   │   │ (--full) │
        └──────────┘   └──────────┘   └──────────┘
              │               │               │
              └───────────────┼───────────────┘
                              ▼
                   ┌─────────────────┐
                   │ 레포트 출력      │
                   │ (+ Daily Note)  │
                   └─────────────────┘
```

---

## 실행 절차

### Phase 1: 초기화 (메인 에이전트 - 순차)

1. **인수 파싱**
```bash
# path가 주어진 경우 해당 경로 사용, 아니면 현재 디렉토리
PROJECT_PATH="${1:-$(pwd)}"
GIT_ROOT=$(cd "$PROJECT_PATH" && git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$GIT_ROOT" ]; then
  echo "ERROR: $PROJECT_PATH 는 git 레포지토리가 아닙니다."
  exit 1
fi

PROJECT_NAME=$(basename "$GIT_ROOT")
TODAY=$(date +%Y-%m-%d)
echo "프로젝트: $PROJECT_NAME ($GIT_ROOT)"
```

2. **기본 브랜치 감지**
```bash
# develop 또는 main 중 존재하는 것 사용
cd "$GIT_ROOT"
DEFAULT_BRANCH=$(git branch --list develop main | head -1 | tr -d ' *')
echo "기본 브랜치: $DEFAULT_BRANCH"
```

3. **GitHub remote 확인**
```bash
HAS_REMOTE=$(git remote -v 2>/dev/null | grep -c "origin")
HAS_GH=$(command -v gh &>/dev/null && echo "yes" || echo "no")
echo "GitHub remote: $HAS_REMOTE, gh CLI: $HAS_GH"
```

---

### Phase 2: 서브 에이전트 병렬 실행

> **중요**: 기본 2개 + --full 시 3개 서브 에이전트를 **단일 메시지에서 동시 호출**.
> 비용/속도 최적화를 위해 **haiku 모델** 사용.

---

#### SubAgent 1: Git Local Analyzer

**Task 호출 파라미터:**
| 파라미터 | 값 |
|---------|-----|
| description | "Git 로컬 분석" |
| subagent_type | "general-purpose" |
| model | "haiku" |

**프롬프트 (GIT_ROOT, DEFAULT_BRANCH 치환 필요):**

```
당신은 Git 레포지토리 로컬 상태 분석 전문가입니다. 코드를 작성하지 말고 분석만 수행하세요.

## 작업
{GIT_ROOT} 레포지토리의 로컬 Git 상태를 분석합니다.

## 실행 단계

1. 현재 브랜치 + 최근 커밋 5개:
   cd "{GIT_ROOT}" && git branch --show-current && git log --oneline -5

2. 기본 브랜치({DEFAULT_BRANCH}) 최근 커밋 5개:
   cd "{GIT_ROOT}" && git log {DEFAULT_BRANCH} --oneline -5

3. 미머지 브랜치 목록 (기본 브랜치 대비):
   cd "{GIT_ROOT}" && git branch --no-merged {DEFAULT_BRANCH} --format='%(refname:short) %(committerdate:short)' | sort -k2 -r | head -20

4. 워크트리 상태:
   cd "{GIT_ROOT}" && git worktree list

## 출력 형식 (마크다운으로 반환)

### Git 상태
- **현재 브랜치**: {branch}
- **최근 커밋**:
  {커밋 목록}

### {DEFAULT_BRANCH} 최근 커밋
{커밋 목록}

### 워크트리 ({N}개)
| 경로 | 브랜치 | 커밋 |
|------|--------|------|
(워크트리가 1개(메인)뿐이면 "추가 워크트리 없음" 반환)

### 미머지 브랜치 ({N}개)
- {branch} ({date})
(미머지 브랜치 없으면 "모든 브랜치가 머지됨" 반환)
```

---

#### SubAgent 2: GitHub Remote Analyzer

**Task 호출 파라미터:**
| 파라미터 | 값 |
|---------|-----|
| description | "GitHub 리모트 분석" |
| subagent_type | "general-purpose" |
| model | "haiku" |

**프롬프트 (GIT_ROOT 치환 필요):**

```
당신은 GitHub 프로젝트 원격 상태 분석 전문가입니다. 코드를 작성하지 말고 분석만 수행하세요.

## 작업
{GIT_ROOT} 레포지토리의 GitHub 원격 상태를 분석합니다.

## 사전 확인
먼저 gh CLI 사용 가능 여부를 확인하세요:
   command -v gh &>/dev/null && echo "available" || echo "unavailable"

gh가 없으면 "gh CLI 미설치 - GitHub 분석 건너뜀" 을 반환하고 종료하세요.

## 실행 단계

1. Open PR 목록:
   cd "{GIT_ROOT}" && gh pr list --state open --limit 20

2. 최근 머지된 PR 5개:
   cd "{GIT_ROOT}" && gh pr list --state merged --limit 5

3. Open Issues:
   cd "{GIT_ROOT}" && gh issue list --state open --limit 15

## 출력 형식 (마크다운으로 반환)

### Open PR ({N}개)
| # | 제목 | 브랜치 | CI | 날짜 |
|---|------|--------|-----|------|
(Open PR 없으면 "Open PR 없음" 반환)

### 최근 머지 (5개)
| # | 제목 | 브랜치 | 날짜 |
|---|------|--------|------|
(머지된 PR 없으면 "머지된 PR 없음" 반환)

### Open Issues ({N}개)
| # | 제목 | 라벨 | 날짜 |
|---|------|------|------|
(Open Issues 없으면 "Open Issues 없음" 반환)
```

---

#### SubAgent 3: Extended Analyzer (--full 옵션 시에만 실행)

**Task 호출 파라미터:**
| 파라미터 | 값 |
|---------|-----|
| description | "확장 분석" |
| subagent_type | "general-purpose" |
| model | "haiku" |

**프롬프트 (GIT_ROOT 치환 필요):**

```
당신은 프로젝트 확장 분석 전문가입니다. 코드를 작성하지 말고 분석만 수행하세요.

## 작업
{GIT_ROOT} 레포지토리의 CI/CD 상태, 코드 통계, 의존성 변경을 분석합니다.

## 실행 단계

1. CI/CD 최근 실행 (gh CLI 사용 가능 시):
   cd "{GIT_ROOT}" && gh run list --limit 5 2>/dev/null || echo "gh 미사용"

2. 코드 통계 - 최근 1주 변경:
   cd "{GIT_ROOT}" && git diff --stat "HEAD@{1 week ago}" HEAD 2>/dev/null | tail -1

3. 의존성 변경 감지 - 최근 1주 내 변경된 빌드/의존성 파일:
   cd "{GIT_ROOT}" && git diff --name-only "HEAD@{1 week ago}" HEAD 2>/dev/null | grep -iE "(package\.json|package-lock|yarn\.lock|pnpm-lock|build\.gradle|settings\.gradle|pom\.xml|Cargo\.toml|go\.mod|Gemfile|requirements\.txt|Pipfile|pyproject\.toml|Brewfile)" || echo "변경 없음"

4. 변경된 의존성 파일이 있으면 각각에 대해:
   cd "{GIT_ROOT}" && git diff "HEAD@{1 week ago}" HEAD -- {파일명} | head -30

## 출력 형식 (마크다운으로 반환)

### CI/CD 최근 실행
| 상태 | 워크플로우 | 브랜치 | 시간 | 날짜 |
|------|----------|--------|------|------|
(gh 미사용 시 "gh CLI 미설치 - CI/CD 분석 건너뜀" 반환)

### 코드 통계 (최근 1주)
- 변경: {N} files changed, {N} insertions(+), {N} deletions(-)

### 의존성 변경 (최근 1주)
- **{파일명}**: {변경 요약}
(변경 없으면 "최근 1주간 의존성 변경 없음" 반환)
```

---

### Phase 3: 결과 통합 및 레포트 출력 (메인 에이전트)

1. **서브 에이전트 결과 수집**
   - SubAgent 1, 2 결과 수집 (필수)
   - SubAgent 3 결과 수집 (--full 시)

2. **레포트 통합 출력**

```markdown
# {PROJECT_NAME} Status Report ({TODAY})

{SubAgent 1 결과}

{SubAgent 2 결과}

{SubAgent 3 결과 - --full 시에만}
```

3. **--save 옵션 처리** (지정된 경우)
   - Daily Note 경로 확인:
     ```
     DAILY_NOTE="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/chan99k's vault/chan99k's vault/02-Areas/dailies/{TODAY}.md"
     ```
   - 기존 Daily Note에 `## 프로젝트 현황` 섹션 추가 (Edit 도구)
   - Daily Note가 없으면 기본 템플릿으로 생성 후 섹션 추가 (Write 도구)

4. **완료 메시지**
   - 터미널 출력: 레포트 전체 내용
   - --save 시 추가: `Daily Note에 저장됨: {DAILY_NOTE 경로}`

---

## 에러 처리

| 상황 | 처리 |
|------|------|
| git 레포가 아닌 경로 | "ERROR: {path}는 git 레포지토리가 아닙니다." 출력 후 종료 |
| gh CLI 미설치 | SubAgent 2 결과를 "gh CLI 미설치 - GitHub 분석 건너뜀"으로 대체 |
| GitHub remote 없음 | SubAgent 2 결과를 "GitHub remote 미설정"으로 대체 |
| 서브 에이전트 실패 | 해당 섹션을 "분석 실패"로 표시, 나머지 결과는 정상 출력 |
| Daily Note 저장 실패 | 터미널 출력은 정상 수행, 저장 실패 메시지 표시 |

---

## 병렬 실행 핵심 원칙

1. **단일 응답에서 2~3개 Agent 동시 호출**
2. **haiku 모델 사용**: 비용/속도 최적화
3. **결과만 반환**: 각 서브 에이전트는 마크다운 텍스트만 반환
4. **메인 에이전트 역할 최소화**: 경로 결정 → Agent 호출 → 결과 조합

## 컨텍스트 절약 효과

| 구분 | 메인 직접 수행 | 서브 에이전트 방식 |
|------|--------------|-------------------|
| 메인 컨텍스트 | git/gh 출력 전부 로드 | 최종 마크다운만 수신 |
| 병렬 처리 | 불가 | 2~3개 동시 실행 |
| 실패 격리 | 전체 실패 | 개별 서브 에이전트만 재시도 |
