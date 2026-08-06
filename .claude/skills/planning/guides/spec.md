# Spec Guide

A spec answers "WHAT exactly to implement" — domain models, API contracts, data flows,
acceptance criteria. It bridges Design Doc (architecture decisions) to code (implementation).

Design Doc decides HOW. Spec defines WHAT to build within that decision.

## Linear Hierarchy Mapping

```
Initiative / Project  ←  Design Doc
  Issue               ←  Spec (Full)      → 1 PR
    Sub-issue          ←  Spec (Light)     → commit ~ PR
```

## When to use

- After a design doc's architecture decisions are made, before coding starts.
- When the user says "스펙", "spec", "구현 명세", "명세서", "implementation spec".
- When `/new-spec` is invoked directly.
- When decomposing an issue into sub-issues with clear acceptance criteria.

## Scale: Full vs Lightweight

**Full Spec** (100-200 lines): Issue level. One PR deliverable.
Use `templates/spec.md`. All sections required.
Includes Sub-issue Breakdown section that lists child work units.

**Lightweight Spec** (30-80 lines): Sub-issue level. Commit-to-PR deliverable.
Use `templates/spec-light.md`. Minimal sections — scope, spec body, acceptance criteria.
No further decomposition needed. This IS the smallest work unit.

**Intent Ticket** (10-25 lines): Jira/팀 트래커용 의도 중심 티켓. Use `templates/spec-jira-light.md`.
Sections: What / How / Out-of-scope / Done when. 도메인 모델·API·data flow 같은 구현
상세는 **일부러 뺀다** — 티켓에 박으면 코드와 어긋나 죽은 정보가 된다. 의도와 경계,
완료 조건만 남긴다. Out-of-scope는 독립 헤더로 둬 경계 분쟁을 막는다.

Decide scale:
- 구현 상세까지 정의해야 하나? → 도메인 모델/API가 필요하면 **Full** 또는 **Lightweight**.
- 의도·경계·완료 조건만으로 충분한가(구현은 PR/코드에 맡김)? → **Intent Ticket**.
- 더 쪼개지는가? Yes → Full, No → Lightweight/Intent.

## Workflow

### Step 1 — Scope

Gather (ask only for what's missing):
- Project name + Linear team (if known)
- Parent document: Design Doc or existing Linear Issue URL
- One-line goal: "이 spec이 완료되면 뭐가 달라지는가?"
- Scale: Full (Issue) or Lightweight (Sub-issue)?

### Step 2 — Draft

Write into the appropriate template, applying these rules:

**Section-specific guidance:**

| Section | Brainstorm? | Notes |
|---------|-------------|-------|
| Scope | No | One paragraph, boundary statement |
| Context | No | Link parent doc, cite relevant decisions |
| Domain Model | No | Kotlin/SQL code blocks, actual field names |
| API Contract | No | Endpoint, method, request/response shape |
| Data Flow | No | ASCII diagram showing the happy path |
| Edge Cases | **Yes** | Generate 5-10 candidates, user curates |
| Acceptance Criteria | **Yes** | Generate checklist candidates, user curates |
| Sub-issue Breakdown | **Yes** | Full spec only — propose decomposition |

**Domain model format:**

```kotlin
data class {EntityName}(
    val id: UUID,
    // fields with types and constraints as comments
)
```

**API contract format:**

```
{METHOD} /api/v1/{resource}
Request:  { field: type }
Response: { field: type }
Status:   200 / 400 (validation) / 404 / 409 (conflict)
```

**Acceptance criteria format:**

```markdown
- [ ] {observable behavior} — {verification method}
```

Each criterion must be: observable (not "코드가 깨끗하다"), verifiable (test or manual check),
and independent (not "위의 것이 되면").

### Step 3 — Challenge

Before finishing, review adversarially:
- Can a developer start coding from this spec alone (without reading the design doc)?
- Are all field names, types, and constraints explicit? No "적절한" or "필요한" placeholders?
- Does every acceptance criterion have a verification method?
- Are edge cases covered or explicitly marked as out-of-scope?
- "이 spec을 넘겨받은 다른 개발자가 PR을 열 수 있는가?"

Fix gaps or add to acceptance criteria.

### Step 4 — Linear

After spec completion, offer Linear integration:

**For Full Spec (Issue level):**
- "Linear Issue 생성할까요?" → create issue with:
  - Title: spec의 one-line goal
  - Description: scope + acceptance criteria summary
  - Label: `spec`
  - Parent: project (if known)
  - Sub-issues: from Sub-issue Breakdown section (each with title + acceptance criteria)

**For Lightweight Spec (Sub-issue level):**
- "Linear Sub-issue 생성할까요?" → create sub-issue with:
  - Title: spec의 one-line goal
  - Description: scope + acceptance criteria
  - Label: `spec`
  - Parent issue: from context

**Common Linear fields:**
- Status: Backlog (default) or Todo (if immediately actionable)
- Assignee: ask if needed
- After creation: write Linear issue URL back into spec frontmatter (`linear_issue` field)

### Step 5 — Next Steps

After spec + Linear completion, offer:
- "Lightweight Spec으로 Sub-issue 상세화 → 각 sub-issue에 대해 spec-light 작성"
- "구현 시작 → 코딩"
- "페르소나 리뷰 → 3인 관점 피드백"
- "여기서 끝"

## Anti-patterns

- **No design decisions here**: Approach comparison belongs in Design Doc.
  If you're debating A vs B, you need a design doc first.
- **No vague acceptance criteria**: "잘 동작한다" is not a criterion.
  Every criterion needs an observable behavior + verification method.
- **No premature sub-issue breakdown in lightweight specs**: Lightweight IS the leaf.
  If it needs sub-issues, upgrade to full spec.
- **No orphan specs**: Every spec must reference a parent (design doc or Linear issue).
  A spec without context is a spec that will be ignored.
- **No duplicate content from design doc**: Reference decisions, don't repeat rationale.
  `(ref: Design Doc BeD3)` is enough.

## Conventions

- Frontmatter: same as other planning docs (created, status, tags, related with wikilinks).
  Add `linear_issue: ` field (populated after Linear creation).
  Add `scale: full | light` field.
- Status values: `draft` → `in-review` → `approved` → `implemented`.
- ASCII diagrams for data flows. Code blocks for domain models and API contracts.
- Output language: Korean. Instruction text: English.
- Filename: `YYMMDD-{SCOPE}-{NN}-spec.md`
- Save path: same as other planning docs.
