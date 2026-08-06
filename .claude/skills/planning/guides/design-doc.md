# Design Doc Guide

A design doc answers "HOW to build it" — architecture, tech choices, approach comparison,
layer-by-layer spec. It follows the PRD (which answers "WHAT to build").

## When to use

- After a PRD is done and before implementation starts.
- When the user says "설계서", "design doc", "아키텍처 설계", "기술 설계".
- When comparing architectural approaches (A vs B vs C) for a feature or system.
- When `/new-design-doc` is invoked directly.

## Scale: Full vs Lightweight

**Full Design Doc** (500+ lines): for a new project or major feature.
All sections required. Living document — updated as decisions are made.

**Lightweight Design Spec** (200-400 lines): for a sub-feature or isolated technical decision.
Sections marked (optional) can be skipped. Standalone or linked from a parent design doc.

Decide scale based on: how many people will read this, how many components are affected,
how reversible the decisions are. Default to lightweight unless scope clearly warrants full.

## Workflow

### Step 1 — Scope

Gather (ask only for what's missing):
- Project name + topic
- One-line problem: "무엇을 설계해야 하는가?"
- Existing PRD (if any) — link or read
- Known constraints (budget, timeline, team size, tech stack mandates)
- Who will read this (팀원, 면접관, 본인 only)

### Step 2 — Draft

Write into `templates/design-doc.md`, applying these rules:

**Section-specific guidance:**

| Section | Brainstorm? | Notes |
|---------|-------------|-------|
| Problem Statement | No | One paragraph, clear핵심 질문 |
| Demand Evidence / Status Quo | No | Facts only, cite sources |
| Constraints | No | List format |
| Premises | No | Numbered, each labeled (수용/조건부/보류) |
| Approaches Considered | **Yes** | 2-4 options, each with code/diagram + trade-offs |
| Recommended Approach | No | Layer-by-layer spec of chosen approach |
| Architecture | No | ASCII diagrams mandatory |
| Open Questions | **Yes** | Split into 결정 필요 / 확인 필요 |

**Approach Comparison format:**

For each approach, provide:
```markdown
### Approach {letter}: {name}
- Carrier: {tech stack}
- Effort: {hours} ({S/M/L/XL})
- Risk: {Low/Med/High}
- {Key differentiator}: {value}

**Architecture:**
{ASCII diagram or code example}

**Trade-offs:**
- Pro: ...
- Con: ...

**거부/선택 이유:** {why rejected or chosen}
```

**Layer-by-layer spec (for recommended approach):**

After approach selection, break the chosen approach into implementation layers.
Each layer gets: purpose, tech, key code/config example, constraints.
Layer names are domain-specific (e.g., Capture → Matching → Extraction → Visualization → Sharing).

**Living document markers:**

Design docs are updated as decisions are made during build.
Use D-prefixed references (D1, D2, ...) for decision points that change the spec.
Format: `(D{N} 갱신 YYYY-MM-DD): {what changed}`

### Step 3 — Challenge

Before finishing, review adversarially:
- Does every approach have at least one Pro AND one Con? (no straw men)
- Is the rejection rationale for each non-chosen approach honest?
- Are constraints real (verified) or assumed?
- Would a fresh reader know enough to start implementation?
- "이 설계서를 넘겨받은 다른 개발자가 바로 구현 시작할 수 있는가?"

Fix gaps or surface under Open Questions.

### Step 4 — Next Steps

After design doc completion, offer:
- "PRD 아직 없으면 → PRD 작성"
- "화면명세 / 목업 필요하면 → 해당 가이드 진행"
- "페르소나 리뷰 → 3인 관점 피드백"
- "여기서 끝"

## Anti-patterns

- **No straw man approaches**: If Approach A exists only to make B look good, remove it.
  Every approach must be a genuine candidate the author considered.
- **No architecture astronautics**: Code examples should be real (or near-real), not
  hypothetical class diagrams. Show the actual method signature, not a UML box.
- **No premature optimization**: v1 spec should target v1 constraints. Future-proofing
  goes under "확장 계획" section, not into the core architecture.
- **No copy-paste from PRD**: Design doc references the PRD, doesn't duplicate it.
  Link to the PRD in frontmatter `related` field.

## Conventions

- Frontmatter: same as other planning docs (created, status, tags, related with wikilinks).
- Status values: `draft` → `in-review` → `approved` → `superseded`.
- If a design doc supersedes another, add `supersedes: [[old-doc]]` to frontmatter.
- ASCII diagrams for architecture. Mermaid only if the user explicitly prefers it.
- Output language: Korean. Instruction text: English.
