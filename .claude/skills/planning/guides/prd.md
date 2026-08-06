# PRD Writing Guide

## Purpose

Write a PRD that can be reviewed and acted upon — not a generic internet PRD.
The canonical format is derived from the user's bitz PRD (numbered sections, ASCII
diagrams, comparison tables, explicit non-goals and open questions).

## Workflow

### Step 1 — Scope

Ask only for what's missing (skip anything already in context):
- SCOPE (uppercase project code, e.g., GIFTIFY, BITZ, TIMEDROP)
- Target project name (must match `01-Projects/` subfolder)
- Topic folder name (kebab-case, e.g., admin-approval)
- One-line problem statement
- Who is the user / stakeholder
- What exists today (As-Is)
- What should change (To-Be direction)

Keep questions tight. Shorthand answers welcome.

### Step 2 — Draft

Fill `templates/prd.md` section by section.

**Brainstorming sections** (high uncertainty — use doc-coauthoring pattern):
- Section 4 (Functional Requirements): Generate 5-10 candidate requirements.
  Present numbered. User curates. Then draft.
- Section 5 (Policies / Exceptions): Generate 5-10 candidate policies.
  Present numbered. User curates. Then draft.
- Section 10 (Risk & Mitigation): Generate 5-8 risks across Business/Tech/Operations.
  Use `reference/risk-matrix.md` format. User curates.

**Direct-draft sections** (low uncertainty — write directly from context):
- Section 1 (Executive Summary)
- Section 2 (Business Context & Goals)
- Section 3 (User Personas)
- Section 6 (User Experience Flow) — include ASCII diagram, mandatory
- Section 7 (Technical Considerations)
- Section 8 (Success Metrics)
- Section 9 (User Stories)
- Section 11 (Roadmap)
- Section 12 (Open Questions)

**ASCII diagram enforcement:**
- Section 1 MUST have a value chain diagram.
- Section 6 MUST have a UX flow diagram.
- Section 11 SHOULD have a timeline/week breakdown diagram.
- If a section lacks a required diagram, do NOT submit — generate it first.
- See `reference/ascii-diagram-examples.md` for style examples.

### Step 3 — Challenge

Before finishing, review the draft:
- Any requirement too vague to implement? ("시스템은 빠르게 응답한다" → reject)
- Non-goals section present and honest?
- Open Questions section present with decision deadlines?
- Every policy has an exception case considered?
- Risk matrix covers Business + Tech + Operations?
- "이 PRD만 읽고 개발 착수할 수 있는가?"

Fix gaps or surface them under Section 12 (Open Questions).

### Step 4 — Next Steps

After PRD completion, offer:
```
PRD 완성.
(a) 화면명세 작성 → guides/screen-spec.md
(b) HTML 목업 생성 → guides/mockup.md
(c) Reader Testing (서브에이전트 검증)
(d) 페르소나 리뷰
(e) 여기서 끝
```

## Section Checklist

| # | Section | Required | Diagram | Brainstorm |
|---|---------|----------|---------|------------|
| 1 | Executive Summary | Yes | Value chain | No |
| 2 | Business Context & Goals | Yes | — | No |
| 3 | User Personas | Yes | — | No |
| 4 | Functional Requirements | Yes | — | Yes |
| 5 | Policies / Exceptions | Yes | — | Yes |
| 6 | User Experience Flow | Yes | UX flow | No |
| 7 | Technical Considerations | Yes | Architecture (optional) | No |
| 8 | Success Metrics | Yes | — | No |
| 9 | User Stories | Yes | — | No |
| 10 | Risk & Mitigation | Side project: optional / Team: required | — | Yes |
| 11 | Roadmap | Yes | Timeline | No |
| 12 | Open Questions | Yes | — | No |

## Anti-Patterns

- Writing "시스템은 안정적이어야 한다" — too vague to implement or test.
- Skipping Non-goals — scope creep starts here.
- Empty Open Questions — means you haven't thought hard enough, not that everything is decided.
- Risk matrix with only "낮음/낮음" entries — you're lying to yourself.
- UX Flow without edge cases — happy path only = production incident waiting.
