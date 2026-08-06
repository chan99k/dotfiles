---
name: apply-review
description: >-
  GitHub PR 리뷰 코멘트를 가져와서 분류하고 코드에 반영한다.
  필수/제안/질문 레벨을 파싱하여 우선순위를 정하고, 코드 수정 후 테스트를 실행한다.
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(gh api*)
  - Bash(gh pr*)
  - Bash(./gradlew*)
  - Bash(git *)
  - Bash(mkdir*)
---

# Apply Review — GitHub PR 리뷰 반영

> PR에 달린 리뷰 코멘트를 가져와서 분류하고, 코드에 반영한다.

`$ARGUMENTS`에 PR 번호 또는 URL을 받는다.

## 실행 순서

### Phase 0: 스택 감지

```bash
gh pr list --json number,headRefName,baseRefName,isDraft
```

대상 PR의 `baseRefName`이 default branch가 아니거나, 다른 PR의 `baseRefName`이 대상의
`headRefName`이면 **스택이다.** `stacked-worktrees` 스킬의 `reference/stack-review-context.md`를
읽고 Phase 3+ / Phase 6.5를 함께 수행한다.

스택이 아니면 이 Phase를 건너뛰고 아래를 그대로 따른다.

### Phase 1: 리뷰 코멘트 수집

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
gh api repos/{owner}/{repo}/issues/{pr_number}/comments
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews
```

### Phase 2: 코멘트 분류

리뷰어의 태그 시스템을 파싱한다:

| 태그 | 의미 | 우선순위 | 조치 |
|------|------|----------|------|
| `[필수]` | 반드시 수정 | **1** | 코드 수정 필수 |
| `[적극/제안]` | 적극적으로 권장 | **2** | 코드 수정 권장, 근거와 함께 판단 |
| `[제안]` | 고려해볼 만한 사항 | **3** | 판단 후 적용 여부 결정 |
| `[질문]` | 설계 의도 확인 | **4** | 답변 작성 (코드 수정 불필요할 수 있음) |
| `[칭찬]` | 좋은 점 | -- | 별도 조치 없음 |
| 태그 없음 | 일반 코멘트 | **3** | 내용 분석 후 판단 |

### Phase 3: 변경 계획 수립

각 코멘트에 대해:
1. **대상 파일과 라인** 확인 (코멘트의 `path`, `line` 필드)
2. **현재 코드** 읽기
3. **변경 방법** 결정
4. **영향 범위** 파악 (해당 파일을 참조하는 다른 파일)

변경이 크거나 아키텍처에 영향을 주는 경우 사용자에게 확인을 받는다.

### Phase 3+: 수정 위치 결정 (스택인 경우만)

코멘트가 가리키는 코드를 **어느 PR의 worktree에서 고칠지** 먼저 정한다. 코멘트가 달린
PR이 항상 정답은 아니다.

| 코멘트가 겨냥하는 것 | 수정할 PR |
|---|---|
| 이 PR이 도입한 코드 | 이 PR |
| 하위 PR이 세운 계약(시그니처·가시성·불변식) | **하위 PR** |
| 상위 PR에서만 드러나는 문제 | 원인을 만든 PR |

하위 PR의 결함을 상위 PR에서 우회 수정하지 않는다. 하위 PR이 먼저 착지하므로,
우회 수정은 결함을 그대로 default branch에 올려보낸다.

수정 대상이 다른 PR이면 그 worktree에서 작업한다 — 대상 PR의 worktree에서 상대 경로로
건드리지 않는다.

### Phase 4: 코드 수정

우선순위 순서대로 수정:
1. `[필수]` 먼저 전부 처리
2. `[적극/제안]` 처리
3. `[제안]`은 타당한 경우만 적용

**수정 원칙:**
- 매 수정마다 관련 테스트 실행
- 리팩터링과 기능 변경을 분리 (별도 커밋)
- 변경 범위를 리뷰어가 지적한 부분으로 한정 (과잉 수정 금지)

### Phase 5: 검증

프로젝트 빌드도구를 탐지하여 테스트를 실행한다:

- **Gradle** (`gradlew` 존재): `./gradlew test` / `./gradlew detekt ktlintCheck`
- **Maven** (`mvnw` 또는 `pom.xml` 존재): `./mvnw test`
- **npm/yarn** (`package.json` 존재): `npm test` / `yarn test`
- **기타**: 프로젝트 루트의 README나 Makefile에서 테스트 명령 확인

테스트 로그 저장 (Gradle 예):
```bash
mkdir -p .log
./gradlew test 2>&1 | tee .log/test-$(date +%H%M%S).log
```

### Phase 6: 질문 답변 작성

`[질문]` 코멘트에 대해:
1. 코드의 설계 의도를 분석
2. 답변 초안을 사용자에게 보여줌
3. 코드 변경이 필요한 경우 Phase 4로 돌아감

### Phase 6.5: restack (스택인 경우 REQUIRED)

수정한 브랜치보다 **위에 있는 모든 브랜치**를 새 tip 위로 옮긴다. 하나라도 빠뜨리면 상위 PR은
더 이상 존재하지 않는 버전의 하위 코드에 대고 컴파일된다.

절차는 `stacked-worktrees` Step 4.5를 따른다. bottom-to-top으로 한 단계씩:

```bash
cd ../repo-pr2
git fetch origin
git rebase origin/pr1/<수정한 브랜치>
git push --force-with-lease
```

이것은 **Step 4.5(리뷰 중 restack)이지 Step 5(landing)가 아니다.** Step 0의 Case A/B와
무관하며, 두 경우 모두 필요하다. "Case B니까 rebase 불필요"는 landing에만 해당한다.

완료 후 검증:

```bash
gh pr list --json number,headRefName,baseRefName --jq '.[] | select(.headRefName | startswith("pr"))'
```

각 `baseRefName`이 여전히 아래 브랜치를 가리키는지 확인한다. restack은 base 포인터를
바꾸지 않으므로 이 출력은 수정 전과 같아야 한다.

## 출력 형식

```markdown
## Review Application Report

**PR**: #<number>
**코멘트 수**: <total> (필수: n, 적극/제안: n, 제안: n, 질문: n)

### 반영 완료
| # | 태그 | 파일 | 코멘트 요약 | 조치 |
|---|------|------|-----------|------|
| 1 | [필수] | ... | ... | 코드 수정 |

### 질문 답변
| # | 파일 | 질문 요약 | 답변 |
|---|------|----------|------|

### 미반영 (사유)
| # | 태그 | 코멘트 요약 | 미반영 사유 |
|---|------|-----------|-----------|

### 스택 처리 (스택인 경우만, 아니면 이 절 삭제)
| 항목 | 결과 |
|------|------|
| 수정한 PR | #177 (하위 PR 계약 문제라 #178 대신 여기서 수정) |
| restack 대상 | #178, #179 |
| base 검증 | 각 baseRefName 아래 브랜치 유지 확인 |

### Harness 개선 제안
이번 리뷰에서 harness(rule/agent/skill)가 사전에 잡을 수 있었던 이슈:
| # | 코멘트 | 관련 harness | 개선 방안 |
|---|--------|-------------|----------|
```

## Harness 피드백 루프

**중요**: Phase 5 완료 후, 리뷰에서 발견된 이슈 중 harness가 사전에 감지할 수 있었던 것을 식별한다.

예시:
- "의존성 방향 위반" → 레이어 검증 규칙 보강 (프로젝트 rule 파일 있으면 해당 파일, 없으면 CLAUDE.md)
- "SQL injection 위험" → parameterized query 규칙 추가
- "직렬화 포맷 누출" → api-contract 필드 동기화 검증 보강

이 피드백은 사용자에게 보고하여 rule/skill 개선에 반영한다.
