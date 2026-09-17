# PR Message Guide

A PR message explains WHAT changed and WHY to a reviewer. Not a log, not a spec: a
persuasion document that helps reviewers approve with confidence.

## When to use

- When the user asks for a PR message (PR 작성, PR 메시지, PR 본문).
- When `/new-pr-message` is invoked.
- When `gh pr create` is about to be called and the user wants a structured body.

## Scale Decision

```
Judge the PR's size and nature
  |
  +-- Bug fix, small change (< 100 lines)
  |     Summary + Description + Testing + Linked Issues
  |
  +-- Feature, refactoring (100 to 500 lines)
  |     + Motivation + Non-Goals + Alternatives + Future Improvements
  |
  +-- Large or architectural change (500+ lines)
        + Risks and Assumptions + Impact (Breaking / Migration / Documentation)
```

## Workflow

### Step 1: Analyze

Gather context, asking only for what is missing:
- Which branch or diff is this PR for? (read `git diff` or `git log`)
- Related tracker issue or spec? The team tracker key comes first, the personal tracker
  handle goes in parentheses as a secondary reference, for example `JIRA-123 (LIN-45)`.
  Omit when there is no matching issue. GitHub `closes #N` is separate; see Linked Issues.
- Any design decisions or rejected alternatives worth mentioning?

If in a git repo, read the diff automatically to understand the changes.

### Step 2: Draft

Apply `templates/pr-message.md`, selecting sections by scale.
Remove sections that do not apply. Empty sections are noise.

**Writing rules:**
- Summary: one sentence, present tense, active voice ("Add X", "Fix Y", not "Added X").
- Motivation: WHY, not WHAT. The diff shows WHAT.
- Description: the implementation highlights a reviewer needs to know. Not a line-by-line
  walkthrough; focus on the non-obvious choices.
- Alternatives: only if a genuine alternative was considered and rejected. No straw men.
- Testing: concrete steps or test names. "Tests done" is not enough.
- Linked Issues: `closes #N` for auto-close, `relates to #N` for reference.

### Step 3: Output

The output format depends on context:
- Creating the PR via `gh pr create`: output as the `--body` argument (heredoc format).
- The user wants to copy and paste: output as a raw markdown block.
- Editing an existing PR: output as the replacement body.

## Anti-patterns

- **No diff summary**: do not list every changed file. The diff is right there.
- **No empty sections**: if Alternatives does not apply, remove it entirely.
- **No "please review"**: opening a PR IS the review request.
- **No scope-creep narrative**: if it took five attempts to get here, the reviewer does not
  need that story. Just the final state.

## Conventions

- Language: Korean, matching the commit message convention in CLAUDE.md.
- No Obsidian frontmatter. This is a GitHub artifact, not a vault document.
- Align with the existing CLAUDE.md PR creation workflow.
- Respect `feedback_no_scope_in_commit.md`: no parenthetical scope in the PR title either.
- Respect `feedback_pr_message_evidence_proportionality.md`: qualitative motivation first,
  metrics as supporting evidence only.
