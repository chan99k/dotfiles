---
scope: personal                  # personal | company | oss
disclosure: internal             # public | masked | internal
created: {{YYMMDD}}
project: {{project}}
status: draft                    # draft | in-review | approved | superseded
version: 1.0                     # bump on every D-marker update
supersedes:                      # the earlier doc this one replaces, [[...]] (if any)
superseded_by:                   # the doc that replaced this one, [[...]] (if any)
review_trigger: []               # conditions that break this doc's assumptions, e.g. [MAU 100 초과, Workers KV 한도 도달]
tags: [{{domain-tags}}, design-doc]
related:
  - "[[{{PRD 파일명}}]]"
---

# {{프로젝트/기능명}}

> {{한 줄 목적}}
<!-- H1 is the subject only. The "Design:" prefix, version and status live in frontmatter -->

## Problem Statement

{{이 설계가 해결하려는 핵심 질문. 한 문단.}}

> "{{한 문장 핵심 질문}}"

## Demand Evidence (해당 시)

{{이 문제가 실재함을 보여주는 근거. 데이터, 사용자 인용, 시장 사례.}}

## Status Quo

{{현재 어떻게 동작하고 있는가. 비용/마찰/한계.}}

## Constraints

- {{시간 제약}}
- {{예산 제약}}
- {{팀 구성 제약}}
- {{기술 스택 제약}}
- {{법/규제 제약 (해당 시)}}

## Premises

1. **P1 - {{전제 이름}} ({{수용/조건부/보류}})**: {{설명}}
2. **P2 - {{전제 이름}} ({{수용/조건부/보류}})**: {{설명}}

## Approaches Considered

### Approach A: {{이름}}
- Carrier: {{기술 스택}}
- Effort: {{시간}} ({{S/M/L/XL}})
- Risk: {{Low/Med/High}}

**아키텍처:**
```
{{ASCII 다이어그램 또는 코드 예시}}
```

**Trade-offs:**
- Pro: {{}}
- Con: {{}}

**거부/선택 이유:** {{}}

---

### Approach B: {{이름}}
- Carrier: {{기술 스택}}
- Effort: {{시간}} ({{S/M/L/XL}})
- Risk: {{Low/Med/High}}

**아키텍처:**
```
{{ASCII 다이어그램 또는 코드 예시}}
```

**Trade-offs:**
- Pro: {{}}
- Con: {{}}

**거부/선택 이유:** {{}}

## Recommended Approach: Approach {{letter}} ({{선택 이유 한 줄}})

### 레이어별 상세 스펙

#### {{Layer 1 이름}}
{{목적, 기술, 핵심 코드/설정 예시, 제약}}

#### {{Layer 2 이름}}
{{목적, 기술, 핵심 코드/설정 예시, 제약}}

### Architecture

```
{{전체 아키텍처 ASCII 다이어그램}}
```

### 기술 결정 요약

| 관점 | 결정사항 |
|------|---------|
| {{}} | {{}} |

## Glossary (해당 시)

| 용어 | 정의 (1문장) |
|------|-------------|
| {{}} | {{}} |

## Service Level Objectives (해당 시)

<!-- No abstract words such as "fast" or "safe". Write numbers and how they are measured -->

| 항목 | 목표 수치 | 측정 방법 |
|------|----------|----------|
| {{p95 응답시간 / 가용성 / 처리량 / 비용 상한 ...}} | {{}} | {{}} |

## Dependencies (해당 시)

<!-- External services, libraries, other teams or systems. Include the failure impact and the fallback path -->

| 종속성 | 용도 | 장애 시 영향 | 대체/폴백 |
|--------|------|-------------|----------|
| {{}} | {{}} | {{}} | {{}} |

## Security, Privacy, Legal (해당 시)

- 보안: {{인증/인가, 데이터 보호, 위협 경계}}
- 개인정보: {{수집 항목, 보관 기간, 삭제 경로}}
- 법적 고려: {{약관, 규제, 서명/증명이 약속하는 것과 약속하지 않는 것}}

## Logging & Monitoring (해당 시)

- 로그: {{무엇을 남기고 무엇을 남기지 않는가 (본문/비밀 제외 규칙)}}
- 메트릭/알림: {{SLO 위반을 어떻게 감지하는가}}

## Stakeholders & Concerns (해당 시, ISO 42010)

<!-- The people who will make decisions from this doc and the questions they need answered. Link each concern to the section that answers it -->

| 이해관계자 | 관심사 (알고 싶은 것) | 답하는 절 |
|-----------|---------------------|----------|
| {{본인 / 팀원 / 리뷰어 / 면접관 / 운영자 / 법무}} | {{}} | {{}} |

## Views (해당 시, IEEE 1016)

<!-- Draw only the views where an expensive-to-reverse decision lives. A doc that needs all four is rare.
     End each view with one line of correspondence to another view -->

### Information View
{{핵심 엔티티, 관계, 소유 경계. 어떤 데이터가 어느 경계 안에 사는가}}
```
{{ASCII ERD 또는 경계 박스}}
```
대응: {{예: 이 뷰의 DrillRecord 는 Interface View 의 POST /drills 응답 본문과 같다}}

### Interface View
{{밖에 내놓는 계약과 밖에서 받는 계약. 요청/응답 형태, 오류 의미, 버전 정책. 상세 필드는 Spec 으로}}
대응: {{}}

### Interaction View
{{대표 시나리오 1~3개의 시퀀스. 누가 누구를 어떤 순서로 부르는가}}
```
{{ASCII 시퀀스}}
```
대응: {{}}

### State View
{{상태를 가진 것의 전이표. 상태 기계가 없으면 이 뷰는 생략}}
| 현재 상태 | 이벤트 | 다음 상태 | 부수 효과 |
|----------|--------|----------|----------|
| {{}} | {{}} | {{}} | {{}} |
대응: {{}}

## Quality Attribute Scenarios (해당 시, ATAM 형식)

<!-- The SLO table says "how much". This table says "in which situation, given what input, how must the system respond".
     Ideally each SLO row has one matching scenario -->

| 속성 | 자극 (무엇이 들어오나) | 환경 (어떤 상태에서) | 응답 (시스템이 뭘 하나) | 측정 (어떻게 판정하나) |
|------|----------------------|--------------------|----------------------|----------------------|
| {{성능 / 가용성 / 보안 / 변경용이성 ...}} | {{}} | {{}} | {{}} | {{}} |

## Traceability (해당 시, ISO/IEC/IEEE 29148)

<!-- Requirements that carry a legal or contractual promise (signatures, personal data, trust layer) must be traced.
     Use the PRD's FR-n IDs as they are -->

| 요구사항 (PRD FR-n) | 이 문서의 결정 / 뷰 | 검증 (Spec 인수 조건 또는 테스트) |
|--------------------|-------------------|--------------------------------|
| {{FR-1}} | {{}} | {{}} |

## 확장 계획 (해당 시)

| Phase | 시점 | 내용 |
|-------|------|------|
| Phase 1 (MVP) | {{}} | {{}} |
| Phase 2 | {{}} | {{}} |

## Open Questions

### 결정 필요
| # | 질문 | 영향 범위 | 결정 기한 |
|---|------|----------|----------|
| Q1 | {{}} | {{}} | {{}} |

### 확인 필요
| # | 질문 | 확인 방법 |
|---|------|----------|
| Q1 | {{}} | {{}} |

## 생략한 절

<!-- Optional sections the user explicitly declined for this doc. Do not leave an empty section; record the reason here.
     If the reason is "later", record the revisit trigger as well -->

| 절 | 생략 이유 | 재검토 시점 |
|----|----------|------------|
| {{State View}} | {{상태 기계 없음}} | {{}} |

## 관련 자료

- PRD: [[{{}}]]
- 참고 문서: {{}}
- 코드 경로: {{}}
