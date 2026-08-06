# PR Message Guide

A PR message explains WHAT changed and WHY to a reviewer. Not a log, not a spec —
a persuasion document that helps reviewers approve with confidence.

## When to use

- When the user says "PR 작성", "PR 메시지", "PR 본문".
- When `/new-pr-message` is invoked.
- When `gh pr create` is about to be called and the user wants a structured body.

## Scale Decision

```
PR 크기/성격 판단
  |
  +-- 버그 수정, 소규모 변경 (< 100 lines)
  |     Summary + Description + Testing + Linked Issues
  |
  +-- 기능 추가, 리팩토링 (100-500 lines)
  |     + Motivation + Non-Goals + Alternatives + Future Improvements
  |
  +-- 대규모 변경, 아키텍처 변경 (500+ lines)
        + Risks and Assumptions + Impact (Breaking/Migration/Documentation)
```

## Workflow

### Step 1 — Analyze

Gather context (ask only for what's missing):
- What branch/diff is this PR for? (read `git diff` or `git log`)
- Related tracker issue or spec? 팀 트래커 키 우선, 개인 트래커 괄호 보조
  (예: `JIRA-123 (LIN-45)`). 대응 이슈 없으면 생략. (GitHub `closes #N`은 별개 — Linked Issues 참조)
- Any design decisions or rejected alternatives worth mentioning?

If in a git repo, read the diff automatically to understand the changes.

### Step 2 — Draft

Apply `templates/pr-message.md`, selecting sections by scale.
Remove sections that don't apply — empty sections are noise.

**Writing rules:**
- Summary: one sentence, present tense, active voice ("Add X", "Fix Y", not "Added X")
- Motivation: WHY, not WHAT (the diff shows WHAT)
- Description: implementation highlights the reviewer needs to know.
  Not a line-by-line walkthrough — focus on non-obvious choices.
- Alternatives: only if a genuine alternative was considered and rejected.
  Not a straw man exercise.
- Testing: concrete steps or test names. "테스트 완료" is not enough.
- Linked Issues: `closes #N` for auto-close, `relates to #N` for reference.

### Step 3 — Output

Output format depends on context:
- If creating PR via `gh pr create`: output as `--body` argument (heredoc format)
- If user wants to copy-paste: output as raw markdown block
- If editing existing PR: output as replacement body

## Anti-patterns

- **No diff summary**: Don't list every file changed. The diff is right there.
- **No empty sections**: If Alternatives doesn't apply, remove it entirely.
- **No "please review"**: The act of opening a PR IS the review request.
- **No scope creep narrative**: If it took 5 attempts to get here, the reviewer
  doesn't need that story. Just the final state.

## Conventions

- Language: Korean (matches commit message convention from CLAUDE.md)
- No Obsidian frontmatter (this is a GitHub artifact, not a vault document)
- Align with existing CLAUDE.md PR creation workflow
- Respect `feedback_no_scope_in_commit.md` — no parenthetical scope in PR title either
- Respect `feedback_pr_message_evidence_proportionality.md` — qualitative motivation first,
  metrics as supporting evidence only
