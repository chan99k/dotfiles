# PRD Writing Guide

## Purpose

Write a PRD that can be reviewed and acted upon, not a generic internet PRD.
The canonical format is derived from the user's bitz PRD: numbered sections, ASCII
diagrams, comparison tables, explicit non-goals and open questions.

## Workflow

### Step 1: Scope

Ask only for what is missing (skip anything already in context):
- Project name (lowercase; goes into the frontmatter `project:` field)
- Topic keywords for the filename (what the user would search for later)
- One-line problem statement
- Who the user or stakeholder is
- What exists today (as-is)
- What should change (to-be direction)

Keep the questions tight. Shorthand answers are welcome.

### Step 2: Draft

Fill `templates/prd.md` section by section, following the Section Walkthrough rule in
`SKILL.md`: one section per turn, explicit answer before moving on.

**Brainstorming sections** (high uncertainty, use the doc-coauthoring pattern):
- Section 4 (Functional Requirements): generate 5 to 10 candidate requirements.
  Present them numbered. The user curates. Then draft.
- Section 5 (Policies / Exceptions): generate 5 to 10 candidate policies.
  Present them numbered. The user curates. Then draft.
- Section 10 (Risk & Mitigation): generate 5 to 8 risks across business, technical and
  operational axes. Use the `reference/risk-matrix.md` format. The user curates.

**Direct-draft sections** (low uncertainty, write directly from context):
- Section 1 (Executive Summary)
- Section 2 (Business Context & Goals)
- Section 3 (User Personas)
- Section 6 (User Experience Flow), ASCII diagram mandatory
- Section 7 (Technical Considerations)
- Section 8 (Success Metrics)
- Section 9 (User Stories)
- Section 11 (Roadmap)
- Section 12 (Open Questions)

**ASCII diagram enforcement:**
- Section 1 MUST have a value chain diagram.
- Section 6 MUST have a UX flow diagram.
- Section 11 SHOULD have a timeline or week-breakdown diagram.
- If a section lacks a required diagram, do NOT submit. Generate it first.
- See `reference/ascii-diagram-examples.md` for style examples.

### Step 3: Challenge

Before finishing, review the draft:
- Is any requirement too vague to implement? ("the system responds quickly" is rejected)
- Is the Non-goals section present and honest?
- Is the Open Questions section present, with decision deadlines?
- Does every policy have at least one exception case considered?
- Does the risk matrix cover business, technical and operational axes?
- Could development start from this PRD alone?

Fix the gaps, or surface them under Section 12 (Open Questions).

### Step 4: Next Steps

After the PRD is complete, offer:
```
PRD done.
(a) Write the screen spec -> guides/screen-spec.md
(b) Generate the HTML mockup -> guides/mockup.md
(c) Reader testing (sub-agent verification)
(d) Persona review
(e) Stop here
```

## Section Checklist

| # | Section | Required | Diagram | Brainstorm |
|---|---------|----------|---------|------------|
| 1 | Executive Summary | Yes | Value chain | No |
| 2 | Business Context & Goals | Yes | (none) | No |
| 3 | User Personas | Yes | (none) | No |
| 4 | Functional Requirements | Yes | (none) | Yes |
| 5 | Policies / Exceptions | Yes | (none) | Yes |
| 6 | User Experience Flow | Yes | UX flow | No |
| 7 | Technical Considerations | Yes | Architecture (optional) | No |
| 8 | Success Metrics | Yes | (none) | No |
| 9 | User Stories | Yes | (none) | No |
| 10 | Risk & Mitigation | Side project: optional / Team: required | (none) | Yes |
| 11 | Roadmap | Yes | Timeline | No |
| 12 | Open Questions | Yes | (none) | No |

## Anti-Patterns

- Writing "the system must be stable": too vague to implement or test.
- Skipping Non-goals: scope creep starts here.
- Empty Open Questions: it means you have not thought hard enough, not that everything is decided.
- A risk matrix with only low/low entries: you are lying to yourself.
- A UX flow without edge cases: happy path only is a production incident waiting to happen.
