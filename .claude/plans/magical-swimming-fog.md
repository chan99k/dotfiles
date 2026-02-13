# Plan: msbaek-tdd 플러그인 커밋 단위 추가

## Context

msbaek-tdd 플러그인의 TDD 워크플로우에서 각 단계마다 자동 커밋을 수행하도록 변경한다.
현재는 에이전트들이 `git status`, `git diff`만 가능하고 커밋 권한이 없다.
6개 단계 각각에서 커밋이 이루어지도록 수정한다.

## 커밋 포인트 및 메시지 컨벤션

| 단계 | 커밋 메시지 형식 | 파일 |
|------|------------------|------|
| SRS 작성 | `docs: SRS 작성 - [기능명]` | tdd-plan SKILL.md |
| 예제 작성 | `docs: 예제 작성 - [기능명]` | tdd-plan SKILL.md |
| 테스트 목록 | `docs: 테스트 케이스 목록 작성 - [기능명]` | tdd-plan SKILL.md |
| Red | `test: [실패하는 테스트 설명]` | tdd-red agent |
| Green | `feat: [테스트 통과 구현 설명]` | tdd-green agent |
| Blue | `refactor: [리팩토링 설명]` | tdd-blue agent |

## 변경 사항

### 1. `msbaek-tdd/agents/tdd-red.md`
- **tools 라인**: `Bash(git add:*), Bash(git commit:*)` 추가
- **작업 절차 섹션**: 5단계(실패 확인) 후에 커밋 단계 추가
  - `git add` → `git commit -m "test: [테스트 설명]"`
- **완료 조건**: 커밋 완료 항목 추가

### 2. `msbaek-tdd/agents/tdd-green.md`
- **tools 라인**: `Bash(git add:*), Bash(git commit:*)` 추가
- **작업 절차 섹션**: 4단계(테스트 확인) 후에 커밋 단계 추가
  - `git add` → `git commit -m "feat: [구현 설명]"`
- **완료 조건**: 커밋 완료 항목 추가

### 3. `msbaek-tdd/agents/tdd-blue.md`
- **tools 라인**: `Bash(git add:*), Bash(git commit:*)` 추가
- **작업 절차 섹션**: 4단계(테스트 검증) 후에 커밋 단계 추가
  - `git add` → `git commit -m "refactor: [리팩토링 설명]"`
  - Blue에서 변경이 없으면 커밋 생략
- **완료 조건**: 커밋 완료 항목 추가

### 4. `msbaek-tdd/skills/tdd-plan/SKILL.md`
- **단계 1 (SRS) 작업 절차**: 사용자 승인 후 커밋 단계 추가
- **단계 2 (예제) 작업 절차**: 사용자 승인 후 커밋 단계 추가
- **단계 3 (테스트 목록) 작업 절차**: 사용자 승인 후 커밋 단계 추가
- 각 단계에 커밋 메시지 형식 명시

### 5. `msbaek-tdd/skills/tdd-rgb/SKILL.md`
- **마이크로 사이클 섹션**: 각 R/G/B 단계에서 커밋이 에이전트 내에서 수행됨을 명시
- **RGB 사이클 실행 섹션**: 각 단계 설명에 "커밋 수행" 추가

## 커밋 절차 (공통)

에이전트에 포함할 커밋 절차:
```
1. git add [변경된 파일들]
2. git commit -m "[type]: [설명]"
```

- 한글 커밋 메시지가 필요한 경우 Write tool로 임시 파일 생성 후 `git commit -F` 사용
- 커밋 대상: 해당 단계에서 변경/생성된 파일만 (git add -A 금지)

## 검증

- 각 에이전트 YAML 헤더의 tools에 git add, git commit이 포함되었는지 확인
- 각 에이전트/스킬의 작업 절차에 커밋 단계가 포함되었는지 확인
- tdd-rgb 오케스트레이터와의 일관성 확인
