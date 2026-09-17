---
scope: personal                  # personal | company | oss
disclosure: internal             # public | masked | internal
created: {{YYMMDD}}
project: {{project}}
status: draft                    # draft | in-review | approved | implemented
scale: full
tags: [{{domain-tags}}, spec]
jira_issue:        # primary team-tracker reference (e.g. PROJ-123), only when a matching issue exists
linear_issue:      # personal tracker handle (e.g. LIN-45)
related:
  - "[[{{Design Doc 파일명}}]]"
---

# {{한 줄 목표}}

> Linear 대응: Issue (1 PR)
<!-- H1 is the goal only. The doc type lives in the frontmatter tag spec, the status in the status field -->

## Scope

{{이 spec의 경계. 무엇을 포함하고 무엇을 포함하지 않는가. 한 문단.}}

## Context

- 상위 설계: [[{{Design Doc}}]] - {{관련 결정 ID 참조 (예: BeD3, ClD5)}}
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

- [ ] {{관찰 가능한 동작}} - {{검증 방법}}
- [ ] {{관찰 가능한 동작}} - {{검증 방법}}
- [ ] {{관찰 가능한 동작}} - {{검증 방법}}

## Sub-issue Breakdown

| # | Sub-issue | 작업 단위 | 완료 조건 |
|---|-----------|----------|----------|
| S1 | {{제목}} | {{commit~PR}} | {{}} |
| S2 | {{제목}} | {{commit~PR}} | {{}} |
| S3 | {{제목}} | {{commit~PR}} | {{}} |

<!-- Each sub-issue can be detailed as a Lightweight Spec (spec-light) -->

## 관련 자료

- Design Doc: [[{{}}]]
- 코드 경로: {{}}
- 참고: {{}}
