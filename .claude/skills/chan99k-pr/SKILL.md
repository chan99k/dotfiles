---
name: chan99k-pr
description: Create a GitHub PR with the project PR template, auto-checking checklist items based on actual changes. Generic fallback for repos that have no project-level pr skill; bundles a default template.
---

## GitHub PR 생성

현재 branch의 변경사항을 분석하고, 커밋 히스토리가 리뷰용인지 점검한 뒤, 프로젝트 PR 템플릿의
체크리스트를 자동으로 채워 `gh pr create`로 PR을 생성한다.

### Step 1: 변경사항 수집

base branch를 먼저 탐지한다:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

아래 명령들을 병렬로 실행하여 변경사항을 파악한다 (`<base>`는 위에서 탐지한 값):

- `git log <base>..HEAD --oneline` - 이 branch의 커밋 목록
- `git diff <base>..HEAD --stat` - 변경된 파일 목록
- `git diff <base>..HEAD` - 전체 diff
- `git rev-list --left-right --count @{u}...HEAD 2>/dev/null` - 원격에 이미 push됐는지
  (upstream 존재 여부와 동기 상태). Step 2의 게이트가 이 값에 따라 달라진다

### Step 2: 커밋 히스토리 정리 게이트

**PR 본문을 쓰기 전에** 커밋 시퀀스가 리뷰용인지 먼저 점검한다. 프로젝트 규칙이 squash merge를
하지 않는다고 정하면(히스토리 보존 merge), 리뷰어가 보는 커밋이 곧 base에 landing하는 커밋이라
지저분한 히스토리가 그대로 남는다. squash 하는 레포라도 리뷰 단위로서 커밋 정리는 유효하다.

이 단계는 **건너뛰지 않는다.** 커밋이 이미 깔끔하면 "정리 불필요"로 명시하고 통과한다.

1. **진단** - Step 1의 `git log`를 보고 아래 신호가 있는지 판정:
   - `wip`, `fix typo`, `진짜 고침`, `pr feedback` 류 checkpoint 메시지
   - 같은 파일을 반복 정제한 연속 커밋 (이해 과정의 기록)
   - rename/이동과 로직 변경이 한 커밋에 섞임
   - 포맷터 noise가 signal 커밋에 섞임
   - 되돌린(revert) 시행착오가 히스토리에 남음

2. **도구 선택** (신호가 있을 때):

   | 상황 | 도구 |
   |------|------|
   | 뒤엉킨 변경을 논리 단위로 **새로 쪼갬** | soft-reset |
   | 대체로 유지, 일부 squash/reword/reorder로 **다듬음** | rebase -i |
   | 이미 논리 단위 | 정리 없이 통과 |

   > 실행 절차(안전망, 명령, 검증)는 [reference/commit-restructure.md](reference/commit-restructure.md) 참조.
   > soft-reset 경로는 `commit-recomposition` 스킬과 같은 절차다. 그 스킬이 있으면 그쪽을 따른다.

3. **결정 게이트 - 절대 자동 실행 금지.** 진단 결과와 권고안(어느 커밋을 어떻게 묶을지)을
   사용자에게 제시하고, **승인받은 뒤에만** 재구성한다. 이유:
   - 히스토리 재작성은 되돌리기 어렵다
   - **이미 push된 브랜치**의 재구성은 기본적으로 하지 않는다. 부득이하면 force push 조건은
     Step 5의 push-preflight 점검(fast-forward, 연결 PR)을 따른다
   - 히스토리를 보존하는 팀에서 과잉 재구성은 오히려 비선호 신호일 수 있다

4. **PR 분할 옵션** - 변경이 여러 관심사로 갈리고, 프로젝트에 작업 단위 크기 규칙(예: 프로덕션
   코드 500줄)이 있으며 그것을 넘으면, 커밋 정리를 넘어 별도의 작은 PR로 분할할지 사용자에게 제안한다.

### Step 3: 체크리스트 자동 판정

PR 템플릿(`.github/pull_request_template.md`)을 읽는다.

**템플릿이 있는 경우**: 모든 체크리스트 항목은 그대로 유지한다. 항목을 삭제하거나 문구를 수정하지 않는다.

**템플릿이 없는 경우**: 이 스킬과 함께 저장된 `PR_TEMPLATE_DEFAULT.md`를 기본 템플릿으로 사용한다.
스킬 경로 기준: `.claude/skills/chan99k-pr/PR_TEMPLATE_DEFAULT.md` (전역) 또는 프로젝트 `.claude/skills/pr/PR_TEMPLATE_DEFAULT.md`.
해당 파일을 읽어 구조(Summary / Context / Problem / Solution / Non-Goals / Resulting Context / Risks and Assumptions / Checklists)를 그대로 유지하면서 내용을 채운다.

판정 규칙:
- 해당 변경사항이 있고, 조치가 완료된 항목 -> `[x]` 체크
- 해당 변경사항이 있지만, 조치가 미완료된 항목 -> `[ ]` 미체크
- 해당 변경사항이 없는 항목 -> `[ ]` 미체크 (그대로 둠)

판정 기준:

**Dependencies** - `build.gradle.kts`, `libs.versions.toml`, `package.json`, `pom.xml` 등에 변경이 있는지 확인
**Database & Migration** - Entity/Flyway/migration 변경이 있는지, migration SQL이 포함되었는지 확인
**Environment & Configuration** - 환경 변수, Dockerfile, compose 변경이 있는지 확인
**Testing** - 소스 코드 변경이 있을 때 테스트가 추가/수정되었는지 확인

### Step 4: PR 본문 작성

정리된 커밋 히스토리와 diff를 바탕으로:
1. **Summary**: 1-3줄 요약 작성
2. **다이어그램** (optional): Summary 아래에 변경을 한눈에 보여주는 다이어그램을 붙인다.
   [reference/pr-diagram.md](reference/pr-diagram.md)의 섹션 메뉴(계층 변경 맵, 도메인 경계,
   동작 흐름, 변경 인과 흐름)에서 **트리거가 켜진 것을 임팩트순 최대 2개까지**. 트리거가 없으면
   (단일 파일과 단일 계층) 0개 - diff로 충분
3. **Changes**: 변경사항 bullet point. 각 커밋이 독립적인 설명을 요구하면 커밋 단위
   `###` 소제목으로 나눈다 (subject 뒤에 해시 병기, 해시는 백틱 없이)
4. **스크린샷** (해당 시): 화면이 달라졌으면 ASIS-TOBE 2열 표로 넣는다
5. **Related Issues**: 커밋 메시지에서 이슈 번호 추출 (없으면 비워둠)
6. **Checklist**: Step 3의 판정 결과 반영

길이(산문 목표 1,500자, 상한 2,000자, 초과분 이동), 커밋 단위 섹션 계약, 스크린샷 표 형식은
[reference/pr-body-composition.md](reference/pr-body-composition.md) 참조.

### Step 5: push 전 안전 점검

PR 생성이든 기존 PR 갱신이든, push 가 필요한 시점이면 먼저 `chan99k-push-preflight`
스킬을 호출해 10항목 점검을 통과시킨다. 하나라도 걸리면 push 와 PR 생성을 중단하고
걸린 항목을 보고한다. 특히:

- 점검 9(연결 PR)에서 열린 PR 이 이미 있으면 `gh pr create` 대신 push + `gh pr edit`
  경로로 분기한다 (edit 전 원격 본문 재확인)
- 점검 3(fast-forward)이 DIVERGED 면 자동 진행하지 않는다

추가로 **PR 제목과 본문 자체를 발행 직전에 스캔**한다 (push-preflight 는 커밋/diff 만 보고
PR 본문은 git 을 안 지나므로 여기가 유일한 관문이다):

- 개인 트래커 식별자 패턴 (`99K-` 등 개인 워크스페이스 접두어) -> 0건이어야 발행
- 금지 기호 (가운뎃점, em dash, 화살표 글리프) -> 0건이어야 발행
- 걸리면 발행을 중단하고 해당 줄을 보고한다. `gh pr edit` 로 기존 본문을 고칠 때도 같다

### Step 6: PR 생성

```
gh pr create --title "[PREFIX] 제목" --body "<작성된 본문>" --base <base>
```

- PR 제목 prefix는 변경사항 성격에 따라 다음 중 하나를 사용:
  - `[FEAT]` - 새로운 기능 추가
  - `[FIX]` - 버그 수정
  - `[HOTFIX]` - 긴급 수정
  - `[REFACTOR]` - 리팩토링, 구조 개선
  - `[CHORE]` - 빌드, 설정, 의존성 등 부수 작업
  - `[TEST]` - 테스트 추가, 수정
  - `[DOCS]` - 문서 변경
- prefix 뒤에는 변경 사항을 대표하는 간결한 제목
- `--base`는 Step 1에서 탐지한 default branch 사용
- 생성된 PR URL을 출력
