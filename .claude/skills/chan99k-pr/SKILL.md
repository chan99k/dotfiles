---
name: chan99k-pr
description: Create a GitHub PR with the project PR template, auto-checking checklist items based on actual changes. Generic fallback for repos that have no project-level pr skill; bundles a default template.
---

## GitHub PR 생성

현재 branch의 변경사항을 분석하고, 프로젝트 PR 템플릿의 체크리스트를 자동으로 채운 뒤 `gh pr create`로 PR을 생성한다.

### Step 1: 변경사항 수집

base branch를 먼저 탐지한다:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

아래 명령들을 병렬로 실행하여 변경사항을 파악한다 (`<base>`는 위에서 탐지한 값):

- `git log <base>..HEAD --oneline` — 이 branch의 커밋 목록
- `git diff <base>..HEAD --stat` — 변경된 파일 목록
- `git diff <base>..HEAD` — 전체 diff

### Step 2: 체크리스트 자동 판정

PR 템플릿(`.github/pull_request_template.md`)을 읽는다.

**템플릿이 있는 경우**: 모든 체크리스트 항목은 그대로 유지한다. 항목을 삭제하거나 문구를 수정하지 않는다.

**템플릿이 없는 경우**: 이 스킬과 함께 저장된 `PR_TEMPLATE_DEFAULT.md`를 기본 템플릿으로 사용한다.
스킬 경로 기준: `.claude/skills/chan99k-pr/PR_TEMPLATE_DEFAULT.md` (전역) 또는 프로젝트 `.claude/skills/pr/PR_TEMPLATE_DEFAULT.md`.
해당 파일을 읽어 구조(Summary / Context / Problem / Solution / Non-Goals / Resulting Context / Risks and Assumptions / Checklists)를 그대로 유지하면서 내용을 채운다.

판정 규칙:
- 해당 변경사항이 있고, 조치가 완료된 항목 → `[x]` 체크
- 해당 변경사항이 있지만, 조치가 미완료된 항목 → `[ ]` 미체크
- 해당 변경사항이 없는 항목 → `[ ]` 미체크 (그대로 둠)

판정 기준:

**Dependencies** — `build.gradle.kts`, `libs.versions.toml`, `package.json`, `pom.xml` 등에 변경이 있는지 확인
**Database & Migration** — Entity/Flyway/migration 변경이 있는지, migration SQL이 포함되었는지 확인
**Environment & Configuration** — 환경 변수, Dockerfile, compose 변경이 있는지 확인
**Testing** — 소스 코드 변경이 있을 때 테스트가 추가/수정되었는지 확인

### Step 3: PR 본문 작성

커밋 히스토리와 diff를 바탕으로:
1. **Summary**: 1-3줄 요약 작성
2. **Changes**: 변경사항 bullet point
3. **Related Issues**: 커밋 메시지에서 이슈 번호 추출 (없으면 비워둠)
4. **Checklist**: Step 2의 판정 결과 반영

### Step 4: PR 생성

```
gh pr create --title "[PREFIX] 제목" --body "<작성된 본문>" --base <base>
```

- PR 제목 prefix는 변경사항 성격에 따라 다음 중 하나를 사용:
  - `[FEAT]` — 새로운 기능 추가
  - `[FIX]` — 버그 수정
  - `[HOTFIX]` — 긴급 수정
  - `[REFACTOR]` — 리팩토링, 구조 개선
- prefix 뒤에는 변경 사항을 대표하는 간결한 제목
- `--base`는 Step 1에서 탐지한 default branch 사용
- 생성된 PR URL을 출력
