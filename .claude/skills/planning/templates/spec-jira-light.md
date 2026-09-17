---
scope: company                   # personal | company | oss (a Jira ticket is usually company)
disclosure: internal             # public | masked | internal
created: {{YYMMDD}}
project: {{project}}
status: draft                    # draft | in-review | approved | implemented
scale: intent
tags: [{{domain-tags}}, spec]
jira_issue:        # primary team-tracker reference (e.g. PROJ-123). Jira is the SSOT
linear_issue:      # personal tracker handle (e.g. LIN-45), secondary and only when a Jira mapping exists
related:
  - "[[{{상위 Spec / Design Doc 파일명}}]]"
---

# {{한 줄 목표}}

<!-- H1 is the goal only. The doc type lives in the frontmatter tag spec, the status in the status field -->

## What

{{무엇을, 왜 - 사용자·시스템이 얻는 결과. 구현 방법이 아니라 결과를 적는다.}}

## How

{{접근 방향 1~2줄. 상세 구현(클래스/필드/엔드포인트)은 적지 않는다 - 코드와 어긋나
드리프트가 생긴다. 그 수준이 필요하면 Lightweight/Full Spec을 쓴다.}}

## Out of scope

{{이번에 일부러 하지 않는 것. 경계 오해·스코프 크리프 방지. 짧아도 독립 헤더로 둔다.}}

## Done when

- [ ] {{관찰 가능한 완료 조건}} - {{검증 방법}}
