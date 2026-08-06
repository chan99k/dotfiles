---
name: review-until-threshold
description: Use when a completed work unit must pass a quality gate before proceeding — running persona-review or a similar multi-reviewer pass repeatedly, deciding whether findings still block, and determining when to stop iterating.
---

# Review Until Threshold

Run a multi-reviewer pass on a completed work unit, fix what blocks, re-review, and stop on a fixed rule rather than on a judgment call.

**Core principle:** The gate is a constant, not a variable. Whoever is under deadline pressure does not get to redefine what blocks.

## When to Use

**Use when:**
- A work unit is implemented and must clear a quality bar before commit, PR, or the next task
- A review round returned findings and you must decide: proceed, or another round
- Iteration has run several rounds and you must decide whether to stop

**Don't use when:**
- Running a review once for information, with no gate → `persona-review` directly
- Line-level craftsmanship review of a diff → `preflight-review` agent
- No reviewer output exists yet → run the review first

## The Gate

**These severities and their gate status are fixed. Do not redefine them for a given situation.**

| Severity | Blocks? | Discharged by |
|----------|---------|---------------|
| `[중단]` | **Yes** | Fixing it. Nothing else. |
| `[강권]` | **Yes** | Fixing it, **or** a tracked follow-up issue plus the raising reviewer accepting the deferral in a later round |
| `[제안]` | No | Recorded in the round report, then backlogged at pass |
| `[질문]` | No | Answered in the round report |
| `[관찰]` | No | Nothing |

**PASS requires all three:**
1. Zero unresolved `[중단]`
2. Zero unresolved `[강권]` (fixed or discharged as above)
3. Every reviewer returned a result this round

Verdicts (`APPROVE` / `CONCERNS` / …) are context, not the gate. A reviewer may return `CONCERNS` while raising only `[제안]` — that passes. A reviewer may return `APPROVE` while raising a `[강권]` — that blocks.

**Do not count verdicts.** No majority rule, no 2-of-3. `persona-review` exists to preserve disagreement; tallying it into a consensus discards the signal the panel was run to produce.

## Round Limit

**Three rounds.** Fixed.

The limit does not move with the deadline, the ticket's importance, or how close the work feels. A shorter deadline is a reason to escalate sooner, never a reason to lower the bar.

### On reaching round 3 without a pass

**Escalate to your human partner. Do not pass the work and do not start round 4.**

Report:
- What still blocks, by severity, with the raising reviewer
- What changed in each round
- Which findings recurred across rounds
- Options you see (fix, defer with tracking, restructure the task, renegotiate scope)

Recurring findings across all three rounds usually mean the task is wrong, not that the fix is wrong. Say so.

## Process

```
  ┌─ round N (N ≤ 3) ────────────────────────────────┐
  │                                                   │
  │  run reviewers ──> collect ──> classify by       │
  │       │                        severity           │
  │       │                          │                │
  │  any reviewer                    │                │
  │  missing/failed ─────> BLOCKED   │                │
  │                                  ▼                │
  │              [중단] or [강권] unresolved?         │
  │                    │                  │           │
  │                   yes                 no          │
  │                    │                  │           │
  │              make a change        ─> PASS         │
  │                    │                             │
  └────────────────────┼─────────────────────────────┘
                       │
              N = 3 ──> ESCALATE (never auto-pass)
```

### Each round produces a report with these slots

```markdown
## Review Round {N}/3 — {work unit}

### Reviewer results
| Reviewer | Verdict | [중단] | [강권] | [제안] | Returned? |
|---|---|---|---|---|---|

### Blocking findings
| # | Finding | Severity | Raised by | Status |

### Changed since last round
{What changed, taken from the diff or the change record you actually read.
 Detail you were told but did not verify goes under a `reported, unverified:` line.
 "none" is not a valid value — a round with no change should not have been run.}

### Gate
PASS / BLOCKED / ESCALATE — with the rule that decided it
```

## Fail Closed

A reviewer that times out, errors, or returns nothing **has not approved**. Treat the round as BLOCKED and re-run that reviewer.

Never assign a default verdict to an absent reviewer. The reviewer most likely to be missing is the one whose lens the work most needs.

A round that did not collect every reviewer never completed. Re-running the absent reviewer **completes that round** — it is not a new round, it does not consume the round limit, and it needs no change to the work.

## Between Rounds

Something in the work must change before a re-review. Re-running reviewers on unchanged code is not a round — it is a coin flip on reviewer variance.

If you believe a finding is wrong rather than unfixed, do not re-review hoping it disappears. Say so in the round report and take it to your human partner.

## Prohibitions

- Do not redefine a severity's gate status for the situation at hand
- Do not pass work with an unresolved `[중단]`, for any reason
- Do not treat reaching the round limit as passing
- Do not tally verdicts into a majority decision
- Do not default a missing reviewer to approval
- Do not re-review without a change
- Do not scale the round limit or the bar to the time remaining

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "2 of 3 approved, that's a pass" | The gate counts findings by severity, not reviewers by verdict. One `[중단]` blocks against any number of approvals. |
| "`[강권]` isn't really blocking" | It blocks. Fix it, or file the follow-up and get the raising reviewer to accept the deferral. Those are the only two exits. |
| "Deadline is today, two rounds is enough here" | The limit is three and the bar is fixed. A tight deadline means escalate earlier, not require less. |
| "We've done 4 rounds, ship it" | Round 3 without a pass is an escalation, not a pass. Hand it to your human partner. |
| "Only `[제안]` left but the reviewer still says CONCERNS" | That is a pass. Backlog the suggestions and move on — the verdict is not the gate. |
| "cto timed out, the other two approved" | The absent reviewer has not approved. Re-run it. |
| "Nothing changed but reviewers are noisy — try again" | Re-review without a change tests variance, not quality. |
| "This finding is just the reviewer's preference" | Then argue it explicitly to your human partner. Do not launder it through another round. |
| "The bar should be lower for an internal tool" | Set scope before reviewing, not after seeing findings you would rather not fix. |

## Red Flags — stop and re-check

- A severity table being restated with different gate statuses than the one above
- A pass criterion that mentions the deadline
- A round limit computed from time remaining
- "Majority", "과반", "2 of 3" appearing in a pass decision
- A default verdict for a reviewer that did not return
- Round N+1 with an empty "Changed since last round"
- File names, numbers, or identifiers in the round report that you did not read from the work itself
- A re-run of an absent reviewer being counted as a new round
- Reaching the limit and completing the work anyway

## Quick Reference

| Situation | Action |
|-----------|--------|
| `[중단]` present | BLOCKED — fix, re-review |
| `[강권]` present | BLOCKED — fix, or track + reviewer accepts deferral |
| Only `[제안]`/`[질문]`/`[관찰]` left | PASS — backlog, answer questions in report |
| Reviewer returned CONCERNS, findings all `[제안]` | PASS |
| Reviewer returned APPROVE with a `[강권]` | BLOCKED |
| Reviewer missing or errored | BLOCKED — re-run that reviewer; the round is incomplete, not spent |
| Round 3 still blocked | ESCALATE to your human partner |
| Nothing changed since last round | Do not re-review |
| Deadline pressure | Escalate earlier; bar and limit unchanged |

## Common Mistakes

**Setting the threshold after seeing the findings.** The gate table is fixed before the first round. Deciding what counts as blocking once you know what was found is how the bar ends up wherever it needs to be.

**Turning the limit into a timer.** "Three rounds then done" makes the gate a formality. Three rounds then *escalate*.

**Losing the `[제안]`s.** Non-blocking is not nothing. They go in the round report and into the backlog at pass, with the round and reviewer recorded.

**Re-reviewing to change a verdict.** If you disagree with a finding, that is a conversation with your human partner, not another round.

## Integration

**REQUIRED SUB-SKILL:** `persona-review` — supplies the reviewers, severity tags, and verdicts this gate reads
**UPSTREAM:** `stacked-worktrees` — the work unit under review is typically one branch in a stack
**DOWNSTREAM:** `post-cleanup` — commit and issue tracking after a pass
