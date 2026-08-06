---
created: {{YYYY-MM-DD}}
status: draft
scale: full
tags: [{{domain-tags}}, spec]
jira_issue:        # 팀 트래커 1차 참조 (예: PROJ-123). 대응 이슈 있을 때만
linear_issue:      # 개인 트래커 핸들 (예: LIN-45)
related:
  - "[[{{Design Doc 파일명}}]]"
---

# Spec: {{한 줄 목표}}

> Linear 대응: Issue (1 PR)
> 상태: {{draft / in-review / approved / implemented}}

## Scope

{{이 spec의 경계. 무엇을 포함하고 무엇을 포함하지 않는가. 한 문단.}}

## Context

- 상위 설계: [[{{Design Doc}}]] — {{관련 결정 ID 참조 (예: BeD3, ClD5)}}
- 선행 조건: {{이 작업 전에 완료되어야 하는 것}}
- 제약: {{이 scope 안에서의 기술/시간/규제 제약}}

## Domain Model

```kotlin
{{실제 필드명, 타입, 제약 조건을 포함한 도메인 모델}}
```

## API Contract

```
{{METHOD}} /api/v1/{{resource}}
Request:  { {{fields}} }
Response: { {{fields}} }
Status:   {{200 / 400 / 404 / 409 ...}}
```

## Data Flow

```
{{happy path를 보여주는 ASCII 다이어그램}}
```

## Edge Cases

| # | 상황 | 기대 동작 | 비고 |
|---|------|----------|------|
| E1 | {{}} | {{}} | {{}} |

## Acceptance Criteria

- [ ] {{관찰 가능한 동작}} — {{검증 방법}}
- [ ] {{관찰 가능한 동작}} — {{검증 방법}}
- [ ] {{관찰 가능한 동작}} — {{검증 방법}}

## Sub-issue Breakdown

| # | Sub-issue | 작업 단위 | 완료 조건 |
|---|-----------|----------|----------|
| S1 | {{제목}} | {{commit~PR}} | {{}} |
| S2 | {{제목}} | {{commit~PR}} | {{}} |
| S3 | {{제목}} | {{commit~PR}} | {{}} |

<!-- 각 Sub-issue는 Lightweight Spec (spec-light)으로 상세화 가능 -->

## 관련 자료

- Design Doc: [[{{}}]]
- 코드 경로: {{}}
- 참고: {{}}
