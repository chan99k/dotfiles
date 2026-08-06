# Screen Spec Writing Guide

## Purpose

Break a PRD's UX Flow into per-screen specifications. Each screen gets its own block
defining purpose, entry conditions, components, interactions, states, and edge cases.
This bridges the gap between "what the system does" (PRD) and "what the user sees" (mockup).

## When to Use

- After a PRD is written and the user wants to detail individual screens.
- When the user says "화면 명세", "상세기획", "screen spec".
- As the second step in a full-chain planning flow.

## Workflow

### Step 1 — Identify Screens

From the PRD's UX Flow section (or from conversation context), list all distinct screens.
Present as a numbered list and confirm with the user.

Example:
```
PRD에서 식별한 화면 목록:
1. 요청 목록 (테이블)
2. 요청 상세 (사이드 패널 or 별도 페이지)
3. 승인 사유 입력 모달
4. 반려 사유 입력 모달
5. 처리 이력 영역

이 목록이 맞나요? 추가/삭제할 화면이 있나요?
```

### Step 2 — Spec Each Screen

For each screen, fill the template block from `templates/screen-spec.md`.

**Per-screen checklist:**
- [ ] Purpose: one sentence — why does this screen exist?
- [ ] Entry condition: how does the user get here?
- [ ] Components: list every visible element (table columns, buttons, badges, inputs)
- [ ] Actions: what can the user DO here? (click, filter, sort, submit)
- [ ] States: what variations exist? (empty state, loading, error, permission-denied)
- [ ] Edge cases: what breaks? (concurrent edit, timeout, missing data)
- [ ] Exit: where does the user go next?

**Brainstorming for edge cases:**
For each screen, generate 3-5 edge case candidates. User curates.
This is where most specs fail — happy path is easy, edge cases prevent production incidents.

### Step 3 — Cross-Screen Consistency Check

After all screens are specced:
- Are status badge colors/labels consistent across screens?
- Do button labels match across list and detail views?
- Are permission rules applied consistently?
- Does the navigation flow form a complete loop (no dead ends)?

### Step 4 — Next Steps

After screen spec completion, offer:
```
화면명세 완성.
(a) HTML 목업 생성 → guides/mockup.md
(b) Reader Testing (서브에이전트 검증)
(c) 페르소나 리뷰
(d) 여기서 끝
```

## Anti-Patterns

- Speccing the happy path only — every screen needs at least one edge case.
- "사용자는 목록을 볼 수 있다" without defining table columns, sort order, pagination.
- Missing empty state — what does the user see when there are 0 items?
- Inconsistent terminology between screens (e.g., "승인" on one screen, "허가" on another).
