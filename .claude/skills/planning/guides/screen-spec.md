# Screen Spec Writing Guide

## Purpose

Break a PRD's UX flow into per-screen specifications. Each screen gets its own block
defining purpose, entry conditions, components, interactions, states and edge cases.
This bridges "what the system does" (PRD) and "what the user sees" (mockup).

## When to use

- After a PRD is written and the user wants to detail individual screens.
- When the user asks for a screen spec (화면 명세, 상세기획, screen spec).
- As the second step of a full-chain planning flow.

## Workflow

### Step 1: Identify Screens

From the PRD's UX flow section (or from conversation context), list all distinct screens.
Present them as a numbered list and confirm with the user. Example (rendered in Korean at
runtime):

```
Screens identified from the PRD:
1. Request list (table)
2. Request detail (side panel or separate page)
3. Approval reason modal
4. Rejection reason modal
5. Processing history area

Is this list right? Any screen to add or remove?
```

### Step 2: Spec Each Screen

For each screen, fill the template block from `templates/screen-spec.md`, following the
Section Walkthrough rule in `SKILL.md`.

**Per-screen checklist:**
- [ ] Purpose: one sentence. Why does this screen exist?
- [ ] Entry condition: how does the user get here?
- [ ] Components: every visible element (table columns, buttons, badges, inputs)
- [ ] Actions: what can the user DO here? (click, filter, sort, submit)
- [ ] States: which variations exist? (empty, loading, error, permission denied)
- [ ] Edge cases: what breaks? (concurrent edit, timeout, missing data)
- [ ] Exit: where does the user go next?

**Brainstorming for edge cases:**
For each screen, generate 3 to 5 edge-case candidates. The user curates.
This is where most specs fail: the happy path is easy, edge cases prevent production incidents.

### Step 3: Cross-Screen Consistency Check

After all screens are specced:
- Are status badge colors and labels consistent across screens?
- Do button labels match between list and detail views?
- Are permission rules applied consistently?
- Does the navigation flow form a complete loop, with no dead ends?

### Step 4: Next Steps

After the screen spec is complete, offer:
```
Screen spec done.
(a) Generate the HTML mockup -> guides/mockup.md
(b) Reader testing (sub-agent verification)
(c) Persona review
(d) Stop here
```

## Anti-Patterns

- Speccing the happy path only. Every screen needs at least one edge case.
- "The user can see the list" without defining table columns, sort order and pagination.
- Missing empty state. What does the user see when there are zero items?
- Inconsistent terminology between screens (for example "approve" on one screen and "permit" on another).
