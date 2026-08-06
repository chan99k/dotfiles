---
name: workthrough
description: 워크스루(작업 회고) 문서 작성 및 ADR 로그 관리 — 배경+가설, 타임라인, 핵심 발견, 의사결정 기록, 정량 결과, 한계, 메타학습을 포함하는 회고 기록을 하우스 문법에 맞춰 생성합니다. "워크스루", "작업 기록", "ADR 정리" 요청 시 트리거.
---

# Workthrough

A workthrough is a *retrospective* — not a plan, not a raw log. It records what was
attempted, what actually happened (timeline), what was found, which decisions were made
and why, what the numbers say, what could NOT be verified, and what to do next.
Honesty about hypothesis-vs-evidence and about limitations is the whole point.

## When to use
- "워크스루 써줘", "작업 기록 만들어줘", "write a workthrough"
- After a measurement / debugging / optimization / design cycle worth logging
- Updating an existing workthrough with new findings
- "ADR 정리", "아키텍처 결정 기록", "ADR 로그" → route to ADR log mode (guides/adr.md)

## Workflow (three lightweight phases)
If the user only wants the empty skeleton, fill templates/workthrough.md with their
SCOPE/filename and stop.

### Phase 1 — Gather
Ask only for what's missing (skip anything already in context). Target:
SCOPE + target project name (must match 01-Projects/ subfolder) + topic folder name
(kebab-case subject grouping, e.g. cascade-perf) + one-line topic; timeline (timestamps if any); key
findings and which prior assumptions were wrong; decisions made + the rejected options;
before/after numbers + how they were measured; what could NOT be done/measured.
Keep questions tight; shorthand answers welcome; do not pad.

### Phase 2 — Draft
Write into templates/workthrough.md, applying the house grammar:
- Korean section headers (match the existing corpus).
- Separate hypothesis from verification; mark wrong early assumptions as "(오류)".
- Each decision uses the 4-block format in reference/decision-record.md.
  - If a decision involved multiple options with significant trade-offs (schema, API contract,
    module boundary, communication pattern), expand it into narrative depth: full option
    descriptions with code examples, comparison tables on multiple axes, ASCII diagrams of
    before/after architecture, and explicit rejection rationale per option. This IS the
    narrative ADR — no separate document needed.
- Use ASCII diagrams for flows and comparison tables for numbers — house style, use freely.
- Always keep "한계" and "메타-학습"; never drop them to look cleaner.
Filename: YYMMDD-{SCOPE}-{NN}-{kebab-brief}.md (date = work date).
Save path: {OBSIDIAN_VAULT}/01-Projects/{project}/docs/workthroughs/{topic}/
  - {project}: lowercase project name matching 01-Projects/ subfolder (e.g. giftify, blog)
  - {topic}: kebab-case subject grouping (e.g. cascade-perf, cart-optimization)
  - Create the directory chain if it doesn't exist.
  - Compute NN from existing files sharing that date+SCOPE across all topic folders.

### Phase 3 — Challenge (honesty pass)
Before finishing, review the draft adversarially and report gaps:
- Any hypothesis stated as verified fact?
- Any number without a stated measurement method?
- "If a Toss CTO read this, what would they push back on?"
Fix it, or surface it under "한계". This stands in for a fresh-reader test for a solo author.

## Conventions
- Frontmatter: created (authoring date; may differ from filename date),
  status (freeform: plan-confirmed | in-progress | done | blocked),
  tags (domain tags + workthrough), related (Obsidian [[wikilinks]]).
- Body order: 배경(+가설) → 사건 흐름 → 핵심 발견 → 의사결정 기록 → 정량 결과 → 한계 → 다음 액션 → 메타-학습 → 관련 자료.
- Output language: Korean. Instruction text in these skill files: English.

## ADR Log mode
When the user asks for an ADR log (not a full workthrough), load guides/adr.md.
This produces a single per-project document listing lean architecture decisions as a
timestamped log, grouped by module then by decision type.
Path: {OBSIDIAN_VAULT}/01-Projects/{project}/docs/adr-log.md

## Keywords
워크스루, workthrough, 작업 기록, 회고, retrospective, dev log, 의사결정 기록, 측정 사이클, ADR, 아키텍처 결정, architecture decision record, ADR 로그, ADR 정리
