---
created: {{YYYY-MM-DD}}
status: draft
scale: intent
tags: [{{domain-tags}}, spec]
jira_issue:        # 팀 트래커 1차 참조 (예: PROJ-123). Jira가 SSOT
linear_issue:      # 개인 트래커 핸들 (예: LIN-45). Jira 매핑 있을 때만 보조
related:
  - "[[{{상위 Spec / Design Doc 파일명}}]]"
---

# {{한 줄 목표}}

## What

{{무엇을, 왜 — 사용자·시스템이 얻는 결과. 구현 방법이 아니라 결과를 적는다.}}

## How

{{접근 방향 1~2줄. 상세 구현(클래스/필드/엔드포인트)은 적지 않는다 — 코드와 어긋나
드리프트가 생긴다. 그 수준이 필요하면 Lightweight/Full Spec을 쓴다.}}

## Out of scope

{{이번에 일부러 하지 않는 것. 경계 오해·스코프 크리프 방지. 짧아도 독립 헤더로 둔다.}}

## Done when

- [ ] {{관찰 가능한 완료 조건}} — {{검증 방법}}
