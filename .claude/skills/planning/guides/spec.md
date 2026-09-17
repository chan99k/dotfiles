# Spec Guide

A spec answers "WHAT exactly to implement": domain models, API contracts, data flows,
acceptance criteria. It bridges the design doc (architecture decisions) to code.

The design doc decides HOW. The spec defines WHAT to build within that decision.

## Linear Hierarchy Mapping

```
Initiative / Project  <-  Design Doc
  Issue               <-  Spec (Full)      -> 1 PR
    Sub-issue         <-  Spec (Light)     -> commit to PR
```

## When to use

- After a design doc's architecture decisions are made, before coding starts.
- When the user asks for a spec (스펙, spec, 구현 명세, 명세서, implementation spec).
- When `/new-spec` is invoked directly.
- When decomposing an issue into sub-issues with clear acceptance criteria.

## Scale: Full, Lightweight, Intent Ticket

**Full Spec** (100 to 200 lines): issue level, one PR deliverable.
Use `templates/spec.md`. All sections required. Includes a Sub-issue Breakdown section that
lists the child work units.

**Lightweight Spec** (30 to 80 lines): sub-issue level, commit-to-PR deliverable.
Use `templates/spec-light.md`. Minimal sections: scope, spec body, acceptance criteria.
No further decomposition. This IS the smallest work unit.

**Intent Ticket** (10 to 25 lines): an intent-centered ticket for Jira or another team
tracker. Use `templates/spec-jira-light.md`. Sections: What / How / Out of scope / Done when.
Implementation detail such as domain models, APIs and data flows is left out on purpose:
once pinned into a ticket it drifts from the code and becomes dead information. Keep only
the intent, the boundary and the completion condition. Out of scope gets its own header to
prevent boundary disputes.

Decide the scale:
- Do implementation details need to be defined? If a domain model or API is needed,
  choose **Full** or **Lightweight**.
- Are intent, boundary and completion condition enough (implementation left to the PR and
  code)? Choose **Intent Ticket**.
- Does it split further? Yes: Full. No: Lightweight or Intent.

## Workflow

### Step 1: Scope

Gather only what is missing:
- Project name and Linear team (if known)
- Parent document: design doc, or an existing Linear issue URL
- One-line goal: what is different once this spec is done?
- Scale: Full (issue), Lightweight (sub-issue) or Intent Ticket

### Step 2: Draft

Write into the appropriate template, following the Section Walkthrough rule in `SKILL.md`
and these section rules.

**Section-specific guidance:**

| Section | Brainstorm? | Notes |
|---------|-------------|-------|
| Scope | No | One paragraph, a boundary statement |
| Context | No | Link the parent doc, cite the relevant decisions |
| Domain Model | No | Kotlin or SQL code blocks, actual field names |
| API Contract | No | Endpoint, method, request and response shape |
| Data Flow | No | ASCII diagram showing the happy path |
| Edge Cases | **Yes** | Generate 5 to 10 candidates. The user curates |
| Acceptance Criteria | **Yes** | Generate checklist candidates. The user curates |
| Sub-issue Breakdown | **Yes** | Full spec only. Propose the decomposition |

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
- [ ] {observable behavior} - {verification method}
```

Each criterion must be observable (not "the code is clean"), verifiable (a test or a manual
check), and independent (not "once the one above works").

### Step 3: Challenge

Before finishing, review adversarially:
- Can a developer start coding from this spec alone, without reading the design doc?
- Are all field names, types and constraints explicit? No "appropriate" or "as needed" placeholders?
- Does every acceptance criterion have a verification method?
- Are edge cases covered, or explicitly marked out of scope?
- Could another developer who inherits this spec open a PR?

Fix the gaps, or add them to the acceptance criteria.

### Step 4: Linear

After the spec is complete, offer Linear integration.

**For a Full Spec (issue level):** offer to create a Linear issue with:
- Title: the spec's one-line goal
- Description: scope plus a summary of the acceptance criteria
- Label: `spec`
- Parent: the project, if known
- Sub-issues: from the Sub-issue Breakdown section, each with a title and acceptance criteria

**For a Lightweight Spec (sub-issue level):** offer to create a Linear sub-issue with:
- Title: the spec's one-line goal
- Description: scope plus acceptance criteria
- Label: `spec`
- Parent issue: from context

**Common Linear fields:**
- Status: Backlog by default, or Todo if immediately actionable
- Assignee: ask if needed
- After creation, write the Linear issue URL back into the spec frontmatter (`linear_issue`)

### Step 5: Next Steps

After the spec and Linear steps, offer:
- Detail each sub-issue as a Lightweight Spec (spec-light)
- Start implementation
- Persona review: feedback from three viewpoints
- Stop here

## Anti-patterns

- **No design decisions here**: approach comparison belongs in the design doc.
  If you are debating A vs B, you need a design doc first.
- **No vague acceptance criteria**: "it works well" is not a criterion.
  Every criterion needs an observable behavior plus a verification method.
- **No premature sub-issue breakdown in lightweight specs**: lightweight IS the leaf.
  If it needs sub-issues, upgrade to a full spec.
- **No orphan specs**: every spec must reference a parent (design doc or Linear issue).
  A spec without context is a spec that will be ignored.
- **No duplicate content from the design doc**: reference decisions, do not repeat the
  rationale. `(ref: Design Doc BeD3)` is enough.

## Conventions

- Frontmatter: same as other planning docs (scope, disclosure, created, project, status,
  tags, related with wikilinks). Add `linear_issue` (populated after Linear creation) and
  `scale: full | light | intent`.
- Status values: `draft`, `in-review`, `approved`, `implemented`.
- ASCII diagrams for data flows. Code blocks for domain models and API contracts.
- Output language is Korean. Instruction text is English.
- Filename: search-term based, no date code (for example `giftify-장바구니-cascade.md`).
  Sub-issue specs add the sub-issue keyword. The `spec` tag and the `scale` field carry the
  document type; do not encode them in the filename or the H1.
- Save path: same as other planning docs (`raw/inbox/`, see the Save Path section in `SKILL.md`).
