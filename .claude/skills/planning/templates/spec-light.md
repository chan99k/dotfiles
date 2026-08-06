---
created: {{YYYY-MM-DD}}
status: draft
scale: light
tags: [{{domain-tags}}, spec]
jira_issue:        # 팀 트래커 1차 참조 (예: PROJ-123). 대응 이슈 있을 때만
linear_issue:      # 개인 트래커 핸들 (예: LIN-45)
related:
  - "[[{{상위 Spec 파일명}}]]"
---

# Spec: {{한 줄 목표}}

> Linear 대응: Sub-issue (commit ~ PR)
> 상위: [[{{상위 Spec}}]] S{{N}}

## Scope

{{이 sub-issue가 무엇을 구현하는가. 2-3문장.}}

## Spec

{{구현 상세. 도메인 모델 변경, API 추가/수정, 로직 설명 등.
필요한 만큼 코드 블록과 ASCII 다이어그램을 사용.
상위 spec에서 이미 정의된 내용은 반복하지 않고 참조.}}

## Acceptance Criteria

- [ ] {{관찰 가능한 동작}} — {{검증 방법}}
- [ ] {{관찰 가능한 동작}} — {{검증 방법}}
