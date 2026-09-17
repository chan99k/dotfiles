# Design Doc Guide

A design doc answers "HOW to build it": architecture, technology choices, approach
comparison, layer-by-layer spec. It follows the PRD, which answers "WHAT to build".

## When to use

- After a PRD is done and before implementation starts.
- When the user asks for a design document (설계서, design doc, 아키텍처 설계, 기술 설계).
- When comparing architectural approaches (A vs B vs C) for a feature or system.
- When `/new-design-doc` is invoked directly.

## Scale: Full vs Lightweight

**Full Design Doc** (500+ lines): for a new project or a major feature.
All sections required. Updated while building, frozen when the change ships
(see "Living document, with traces").

**Lightweight Design Spec** (200 to 400 lines): for a sub-feature or an isolated technical
decision. Sections marked optional can be skipped. Standalone, or linked from a parent design doc.

Decide the scale by how many people will read it, how many components are affected, and how
reversible the decisions are. Default to lightweight unless the scope clearly warrants full.

## Workflow

### Step 1: Scope

Gather only what is missing:
- Project name and topic
- One-line problem: what has to be designed?
- Existing PRD, if any (link or read it)
- Known constraints (budget, timeline, team size, mandated tech stack)
- Who will read this (teammates, interviewers, the author only)

### Step 2: Draft

Write into `templates/design-doc.md`, applying these rules.

**Section-specific guidance:**

| Section | Brainstorm? | Notes |
|---------|-------------|-------|
| Problem Statement | No | One paragraph with a clear core question |
| Demand Evidence / Status Quo | No | Facts only, cite sources |
| Constraints | No | List format |
| Premises | No | Numbered, each labeled accepted / conditional / deferred |
| Approaches Considered | **Yes** | 2 to 4 options, each with code or a diagram plus trade-offs |
| Recommended Approach | No | Layer-by-layer spec of the chosen approach |
| Architecture | No | ASCII diagram mandatory |
| Glossary | No | (optional) One-sentence definitions. Include when the doc coins or overloads terms |
| Service Level Objectives | No | (optional) Numbers plus a measurement method. Reject abstract words such as "fast" or "safe" |
| Dependencies | No | (optional) External services, libraries, teams, with failure impact and fallback |
| Security, Privacy, Legal | No | (optional) Include whenever the system stores personal data or makes a legal or contractual promise |
| Logging & Monitoring | No | (optional) What is logged, what is excluded, how SLO breaches are detected |
| Stakeholders & Concerns | No | (optional, ISO 42010) Who makes decisions from this doc and what they need answered; map each concern to a section |
| Views: Information / Interface / Interaction / State | No | (optional, IEEE 1016) Draw only the views where an expensive-to-reverse decision lives. Each view ends with one correspondence line to another view |
| Quality Attribute Scenarios | **Yes** | (optional, ATAM) stimulus / environment / response / measure. Pair with SLO rows. Brainstorm 3 to 6 candidates. The user curates |
| Traceability | No | (optional, ISO/IEC/IEEE 29148) PRD FR-id to decision or view to verification. Mandatory when a requirement carries a legal or contractual promise |
| 생략한 절 (omitted sections) | No | Ledger of optional sections the user explicitly declined, with the reason and a revisit trigger. Never leave an empty optional section; never drop one silently |
| Open Questions | **Yes** | Split into "decision needed" and "confirmation needed" |

**Section walkthrough (mandatory):**

Do not draft the whole document in one pass. Walk the template top to bottom, one section
per turn, and get an explicit answer before moving on.

- Required section: ask the one question that fills it, or confirm the draft you propose.
- Optional section: ask "Does this document need {section}?" and accept only one of two
  answers: include it (then fill it), or "not needed now" (then write one row in
  `## 생략한 절` with the reason and, if the reason is "later", the revisit trigger).
  Silence, "let's see later", or your own judgement do NOT count as an answer. Frame the
  question with the reversal-cost test: "Is there a decision in this section that would be
  expensive to reverse later?" If the user says no, that is the reason to record.
- Ask one question per message. Prefer a 2 to 4 option multiple choice with your
  recommendation first. Do not batch several sections into one question.
- Skip the question only when the answer is already on record in this conversation or in
  the PRD, and say so in one line instead of asking.

This is how the house grammar gets written at all: each section exists because the user
answered it, not because the template had a heading.

**What goes in, what stays out (Lynch's reversal-cost test):**

Include a decision only if reversing it later would be expensive: language, framework,
storage structure, data boundaries, external contracts. Leave out decisions that are cheap
to change later: page sizes, button labels, exact timeouts. If a section would be filled with
cheap decisions, drop the section. The five optional sections Glossary, SLO, Dependencies,
Security/Privacy/Legal and Logging come from Michael Lynch's design-doc template; see the
vault note "AI 시대 설계 문서 논쟁 마이클 린치 코딩하는기술사" in `raw/digests`.

**Not sacred: decisions can be wrong:**

Every decision in the doc is the best call at the time, not a rule to defend. Label the
evidence behind each decision with [사실] (fact), [가정] (assumption), [내 의견] (opinion) or
[미검증] (unverified). Assumption rows are the ones most likely to be overturned. When new
evidence during build or operation contradicts a decision, do not answer with "the doc says
so". State the contradiction and propose the change. The user decides; the AI's job is to
notice first.

**Living document, with traces:**

A design doc describes one change, not the system forever, but it stays alive for as long as
that change is being built and revisited. "Alive" means changes leave a trace, never a silent
overwrite.
- While building: put a D-marker `(D{N} 갱신 YYYY-MM-DD): {what changed}` at the changed spot
  and bump `version` in frontmatter.
- After the change ships: set status `approved`. Further changes go to a new doc or an ADR
  entry that carries `supersedes: [[this-doc]]`, and this doc gets `superseded_by`.
- If the doc rests on assumptions that may expire, declare `review_trigger: [...]` in
  frontmatter (borrowed from the vault's policy type) so "when to re-read this" is explicit.
- Revision history is git. No separate document store is needed.
The current architecture lives in a separate document (README or ADR log), not here.

**Approach comparison format:**

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

**Layer-by-layer spec (for the recommended approach):**

After the approach is selected, break it into implementation layers. Each layer gets a
purpose, the technology, a key code or config example, and constraints. Layer names are
domain-specific (for example Capture, Matching, Extraction, Visualization, Sharing).

**Living document markers:**

See "Living document, with traces" above. D-prefixed references (D1, D2, ...) mark decision
points that changed after the first draft: `(D{N} 갱신 YYYY-MM-DD): {what changed}`.

### Step 3: Challenge

Before finishing, review adversarially:
- Does every approach have at least one pro AND one con? (no straw men)
- Is the rejection rationale for each non-chosen approach honest?
- Are the constraints real (verified) or assumed?
- Would a fresh reader know enough to start implementation?
- Could another developer who inherits this design doc start implementing right away?

Fix the gaps, or surface them under Open Questions.

### Step 4: Next Steps

After the design doc is complete, offer:
- If there is no PRD yet: write the PRD.
- If a screen spec or mockup is needed: continue with that guide.
- Persona review: feedback from three viewpoints.
- Stop here.

## Anti-patterns

- **No straw man approaches**: if Approach A exists only to make B look good, remove it.
  Every approach must be a genuine candidate the author considered.
- **No architecture astronautics**: code examples should be real or near-real, not
  hypothetical class diagrams. Show the actual method signature, not a UML box.
- **No premature optimization**: the v1 spec targets v1 constraints. Future-proofing goes
  under the "확장 계획" (expansion plan) section, not into the core architecture.
- **No copy-paste from the PRD**: the design doc references the PRD, it does not duplicate
  it. Link the PRD in the frontmatter `related` field.

## Conventions

- Frontmatter: same as other planning docs (scope, disclosure, created, project, status,
  version, tags, related with wikilinks) plus `supersedes`, `superseded_by`, `review_trigger`.
- Status values: `draft`, `in-review`, `approved`, `superseded`.
- If a design doc supersedes another, add `supersedes: [[old-doc]]` to frontmatter.
- ASCII diagrams for architecture. Mermaid only if the user explicitly prefers it.
- Output language is Korean. Instruction text is English.
