---
name: ticket-orchestration
description: Use when a work ticket must be carried end to end — researched, split into task units, built across parallel agents in isolated worktrees, gated by review, and published as a stack of draft PRs.
---

# Ticket Orchestration

Run one ticket from research to a published stack of draft PRs, delegating what can run in parallel and collecting what you delegated.

**Core principle:** The orchestrator writes no code — subagents do. What the orchestrator produces is a set of claims: this was verified, this passed review, this is finished. Each claim is worth exactly the command output standing behind it, and a claim with none is the failure mode this skill exists to prevent.

## When to Use

**Use when:**
- A ticket splits into two or more dependent work units that should ship as a stack
- Work will be delegated to subagents and you have to reconcile what they return
- The ticket needs research, review, and publication — not just an edit

**Don't use when:**
- One task, one branch, no delegation → just do the work
- You are only creating the worktrees and branches → `stacked-worktrees` alone
- You are only running the review gate → `review-until-threshold` alone

## The Pipeline

```
  1 VERIFY ──> 2 SPLIT ──> 3 STACK ──> 4 BUILD ──> 5 GATE ──> 6 RECOMPOSE ──> 7 BRIEF ──> 8 PUBLISH
      │            │           │           │          │            │             │           │
  reproduce    units +     base chain   parallel /  review-     commit-      evidence     draft PRs
  the ticket   deps        per unit     inline      until-      recompo-     section      bottom-up
  claims                                            threshold   sition
```

Phases 1–3 are yours. Phases 4–6 run per task unit. Phases 7–8 are yours again, and 8 never runs before 7.

**REQUIRED SUB-SKILLS**, by phase:
- Phase 1 — `evidence-backed-research` (for the parts of the ticket that need external references)
- Phase 3 — `stacked-worktrees`
- Phase 5 — `review-until-threshold`
- Phase 6 — `commit-recomposition`

## Phase 1 — Reproduce What the Ticket Claims

A ticket states defects. Some of them are not there. Run the reproduction before you plan a fix, because the plan built on an unverified claim produces a change that fixes nothing and reads as if it did.

```bash
<the ticket's own test/run command>    # does the described symptom appear?
```

For each defect the ticket asserts, one of three outcomes goes in your notes:

```
재현됨      — <명령> → <출력>
재현 안 됨   — <명령> → <출력>. 결함 없음.
서술 부정확  — <명령> → <출력>. 티켓은 "<주장>"이라 했으나 실제로는 <관찰>.
              결함은 실재. 정확한 서술로 다시 적고 유닛으로 만든다.
```

The third exists because a ticket can be wrong about the mechanism and right that something is broken. Observed: a ticket said duplicate requests create duplicate orders; the store overwrites by key instead, so nothing duplicates — but the request is still not idempotent. Filed as 재현 안 됨 and dropped, that defect ships. What decides is whether a defect is there, not whether the ticket described it correctly.

**A claim you could not reproduce is not a task unit.** Do not open a branch for it, do not "clean it up while we're here", and do not let a cosmetic edit stand in for the fix — a reworded section in a file the ticket named looks exactly like a completed unit, in the diff and in the briefing. Report the non-reproduction to your human partner and let them decide.

Observed: a ticket said a README's run command pointed at the wrong path. It did not — the command worked as written. Two orchestrators reworded that README section, reported the unit complete, and passed it through review. Neither said the premise was false. One `python3 test_app.py` would have settled it before any branch existed.

This applies to the ticket's factual claims about the code. For claims about the world — library behavior, API semantics, best practice — use `evidence-backed-research`.

## Phase 2–3 — Split and Stack

Number the units (T1, T2, …) and record what each depends on. Dispatch in parallel only what has no dependency edge; T2 depending on T1 means T2's agent starts after T1's branch exists, or it writes against code that is not there and the conflict surfaces at rebase.

**A unit carries the tests for its own behavior.** "Implementation" and "tests for that implementation" are one unit, not two. Split that way and the lower branch holds code nothing exercises: its test run is green because the only tests present are the ones that were already passing, and the stack looks verified at every level while the bottom level is verified nowhere.

Observed: a stack of pr1 `feat: Idempotency-Key 처리 로직` and pr2 `test: 멱등성 테스트 추가`. `git show pr1:test_app.py | grep -c idempot` → 0, and `python3 test_app.py` on pr1 printed `ok`. Both facts are compatible with the feature being entirely broken.

The split that works is by behavior — each unit is a thing the system now does, with the test that shows it does it. `commit-recomposition` states the same rule for commit boundaries; it holds at branch boundaries for the same reason.

```
T1 ──> T2      T3 runs from the start; nothing depends on it
T3 ──┘
```

Each unit gets its own worktree and branch, base pointing at the unit below it. `stacked-worktrees` has the commands and the merge-strategy check that decides how the stack lands.

## Phase 4 — Delegate and Collect

Delegating creates an obligation to collect. Keep the list of what you dispatched and tick each one off as its result arrives — you need that list at Phase 7 whether or not it is empty by then.

**Every report names its outstanding dispatches, and a report with any is titled 중간 보고.** Running out of room, time, or patience is a legitimate reason to stop early; presenting what you have is fine. What is not available is stopping early and calling it done, because the branch keeps moving after you leave and the next reader believes the last thing you wrote.

```markdown
### 미회수 위임 — REQUIRED
없음
```
```markdown
### 미회수 위임 — REQUIRED
- pr2 리뷰 라운드 2 (2개 리뷰어) — 디스패치됨, 결과 미수령
→ 이 보고는 중간 보고입니다. pr2 는 게이트를 통과하지 않았습니다.
```

Observed twice, once without this skill and once with: an orchestrator wrote "⏳ 진행 중, 백그라운드 에이전트 완료를 기다리고 있습니다" and stopped. In the first, the agent finished afterward and its commit landed on the branch unread, unreviewed, unmentioned. Neither report said which unit was unfinished or what its state was.

Before leaving Phase 4, per branch:

```bash
git -C <worktree> status --short          # expect: no output
git -C <worktree> log --oneline <base>..HEAD
```

Unclean means an agent left work staged or dirty. That is an unfinished unit, not a cosmetic issue — go back, not forward.

## Phase 5–6 — Gate and Recompose, Per Unit

Both run **inside the unit's own worktree**, before its PR opens.

**The gate does not scale with the diff.** A one-line unit gets the same `review-until-threshold` pass as a five-file one — same reviewers, same rounds, same threshold. `간소 검증`, `trivial 이므로 생략`, `PASS (간단한 변경)` are not verdicts a reviewer returned; they are the gate line written without running the gate, and they appear in the briefing at the same place and in the same shape as one that was. Observed twice: a docstring typo unit and a small query API, each recorded `PASS` with the word 간소 beside it and no reviewer behind it.

**Neither depends on a remote.** `review-until-threshold` dispatches reviewers and `commit-recomposition` reads local history; a missing remote, a bare-repo origin, or an unavailable `gh` changes what Phase 8 can do and nothing about Phase 5 or 6. Observed: an orchestrator wrote `리뷰 게이트: 스킵 (GitHub 연동 없음)` and pushed both branches — two unreviewed units on the remote, and the one line in the briefing that would have said so was the line it deleted.

`review-until-threshold` decides whether the unit passes; the gate is a reviewer's returned verdict, not your reading of the diff. `commit-recomposition` reshapes the history afterward; the check is an empty `git diff $ORIG HEAD`.

**"이미 논리적으로 구성되어 재구성 불필요" is a valid outcome only with the log that shows it.** Recomposition can be a no-op. Skipping the look cannot.

**`$ORIG` is the HEAD from before the reset, or there is no `$ORIG`.** `git diff <current HEAD> HEAD` is empty for every repository in every state — running it produces a blank line that occupies the evidence slot and tests nothing. Observed: a briefing carried `git diff e0e4425 HEAD --stat → (출력 없음)` where `e0e4425` was that branch's current HEAD.

**The recomposition slot is two lines: the verdict, and the one command standing behind it.** Which pair you write depends on whether a reset happened. A diff that is not one of these two is not a component of this slot.

```
재구성 수행:   git diff 8f21a3c HEAD → 출력 없음        # 8f21a3c = reset 이전 HEAD
재구성 미수행: $ORIG == HEAD (2a6775f). 히스토리 그대로 사용.
               git log --oneline dc96bab..HEAD → <붙여넣기>
```

The second is a fine answer. It just has to say it is the second, and end there.

With no reset, tree identity is what `$ORIG == HEAD` already asserts. Re-establishing it beneath its own heading — 트리 동일성 검증, 무결성 확인 — hands a command that is empty in every repository the standing of a verification step, and a reader scanning headings counts one more check than was run. Observed: a briefing wrote the 재구성 미수행 line correctly, then added `git diff de9eb0b HEAD --stat → (출력 없음)` under 트리 동일성 검증, where `de9eb0b` was that branch's HEAD.

## Phase 7 — Brief

Six parts, in this order. 7.0 comes first because it decides what the rest of the document is called; 7.4 and 7.5 come last because they are what the next reader acts on.

### 7.0 미회수 위임 — REQUIRED

`없음`, or one line per outstanding dispatch and the title 중간 보고. See Phase 4.

### 7.1 스택 구조

```
main (cae8453)
 └─► fix/readme-example (124f4ed)      T3
      └─► feat/idempotency (03729c5)   T1, T2
```

### 7.2 작업 단위

One line per unit: which branch, which commits, what it did.

### 7.3 검증 — REQUIRED, the commands and what they printed

```markdown
$ git merge-base main fix/readme-example
cae8453...        # = main HEAD, 스택 정합

$ git merge-base fix/readme-example feat/idempotency
124f4ed...        # = fix/readme-example HEAD, 스택 정합

$ python3 test_app.py           # 스택 top
ok

티켓 전제:  "README 실행 예시 오류" → 재현 안 됨 ($ python3 test_app.py → ok). 수정하지 않음.
리뷰 게이트: T3 PASS(2R, [중단]0/[강권]0)   T1-T2 PASS(1R)
재구성:      feat/idempotency  git diff 8f21a3c HEAD → 출력 없음
```

Not a summary of the output — the output. Timings, agent counts, and a hand-written "테스트 통과 ✓" are narration.

**A `$` line is a command you ran, followed by what it printed.** That is the only thing the shell prompt marks, anywhere in the briefing — 검증, PR, or any other section. A command you did not run belongs in prose without a prompt, or carries `미실행` on the same line. Observed: a PR section listed two `$ git push -u origin <branch>` lines under 원격 push만 가능, and the remote held only `main` — neither had run, and nothing in the document said so. The reader has no way to tell a transcript from a plan except the prompt you put in front of it.

### 7.4 발견한 문제 — REQUIRED

`없음`, or one line each. What surfaced during this run and is not fixed by this stack: a ticket claim that did not reproduce, a unit that was abandoned, review [제안] items sent to backlog, a limitation you saw in the code while reviewing or recomposing.

### 7.5 꼭 알아야 할 점 — REQUIRED

`없음`, or one line each. What the next reader would get wrong without it — and **what is not verified is the first thing that goes here.**

A fact and its consequence are different sentences, and only the fact survives on its own. Observed three times out of three: a briefing carried `T2 — 폐기 (담당 에이전트 2회 실패)` under 작업 단위, and none of the three went on to say that T1 therefore ships with no test exercising it. All three then printed `python3 test_app.py → ok` in 7.3. That `ok` was the pre-existing test; it does not enter the new code. The line the next reader needed was:

```
T1 은 멱등성 경로를 지나는 테스트가 없음 (T2 폐기). 7.3 의 ok 는 기존 주문 생성 테스트다.
```

**If the stack-top test run does not exercise a unit, say so beside the green output**, in 7.3 or here. A green line under a unit that nothing tests is the single most misread thing a briefing can contain.

**A diagram is Phase 7.1 of six.** In observed runs the briefings were excellent: correct ASCII stack, per-agent durations, a phase timeline, PASS verdicts per branch. The reviews had never run. Presentation quality and verification are independent, and the more polished briefing is not the more checked one — sort your own claims by who else could rerun them, and put the ones nobody can at the bottom where they read as claims.

## Phase 8 — Publish

Only after Phase 7. Open PRs **bottom-up** — the lower PR must exist before the one that targets it.

```bash
gh pr create --draft --base main               --head fix/readme-example  ...
gh pr create --draft --base fix/readme-example --head feat/idempotency    ...
```

`--draft` is not optional. See `stacked-worktrees` for the PR body and the landing sequence.

## Report

```markdown
## 티켓 오케스트레이션 — {ticket}          # 미회수 위임이 있으면: 중간 보고

### 미회수 위임
{없음, 또는 한 줄씩}

### 스택 구조
{ASCII diagram}

### 작업 단위
{unit → branch → commits → what it did}

### 검증
{ticket-claim reproduction, merge-base per branch, stack-top test run,
 review verdicts, recomposition diffs — commands and their output}

### 발견한 문제
{없음, 또는 한 줄씩 — 이번 스택이 고치지 않는 것}

### 꼭 알아야 할 점
{없음, 또는 한 줄씩 — 검증되지 않은 것부터}

### PR
{url per branch, bottom to top, all draft}
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Ticket asserts a defect | Reproduce it before planning a fix |
| Could not reproduce | Not a unit. Report it; do not edit the named file anyway |
| A dispatched agent is still running | It goes in 미회수 위임 and the report is titled 중간 보고 |
| Worktree not clean after an agent | Unfinished unit — go back |
| Splitting "implementation" from "its tests" | One unit. The lower branch would be green with nothing testing it |
| History already looks fine | Still paste `git log --oneline $BASE..HEAD` |
| No reset happened | Write `재구성 미수행, $ORIG == HEAD` — not a diff of HEAD against itself |
| Tempted to add 트리 동일성 검증 beside it | `$ORIG == HEAD` already said that. The slot ends at its two lines |
| About to write "리뷰 PASS" | Paste the reviewer's returned verdict beside it |
| Diagram is done and looks great | 7.2 through 7.5 are still required |
| A unit was abandoned or left unverified | The fact goes in 7.2; the consequence goes in 7.5. Both |
| Stack-top test is green | Say which units it does not enter, beside the output |
| Unit is one line, or obviously trivial | Same gate. Size changes the review's length, not whether it ran |
| Writing a command you did not run | Drop the `$`, or put `미실행` on the line. The prompt says it ran |
| No remote configured | Affects Phase 8 only. Phases 1–7 run unchanged; say so and do not report Phase 8 as complete |
| `gh` unavailable, origin is a bare repo | Still gate, still recompose. Pushing a branch that did not pass the gate is publishing it |
| Ticket describes the defect wrong but a defect is there | 서술 부정확 — restate it accurately and make it a unit |

## Common Mistakes

**Editing the file the ticket named, because the ticket named it.** When the asserted defect is not there, a plausible-looking edit to that file satisfies every downstream check — it diffs, it passes tests, it reviews clean — while fixing nothing and burying the fact that the ticket was wrong.

**Calling a report complete while subagents run.** Stopping early is allowed; the report just has to say what is still out and carry the title that matches. Their output lands with nobody to read it either way — the difference is whether the next reader knows.

**Filling an evidence slot with a command that cannot fail.** `git diff HEAD HEAD`, a `--stat` scoped to files you chose, a test run that exercises none of the new code. Before pasting output, ask what result would have been a failure; if there is none, the line is decoration.

**Sizing the gate to the change.** The small unit is where skipping feels free, and it is also where the skip is invisible — a one-line diff nobody reviewed reads exactly like a one-line diff everybody approved. What the briefing records either came back from a reviewer or did not.

**Writing the command you were going to run.** Under a heading that says what could not be done, a shell block of the commands that would have done it reads as the record of doing it. This is how a step that never happened acquires output-shaped evidence — the same slot, the same font, no result to contradict.

**Letting a missing remote cancel the phases before it.** No origin, a bare-repo origin, `gh` not installed — each blocks publication and nothing else. The gate that would have caught the bad unit runs entirely on local branches, so dropping it costs the one check that was still available.

**Recording a fact and stopping there.** "T2 폐기", "재현 안 됨", "[제안] 2건 백로그" are line items in a list the next reader skims. What they mean for the code that just shipped — nothing tests it, the ticket was wrong, this breaks under two workers — is a sentence someone has to write, and the run that discovered it is the only one that can.

**Restating a verdict as an extra check.** The correct line goes in, and then a second item appears under a heading of its own saying the same thing with a command that could not have failed. It reads as two verifications and is one, and the added one is the empty one.

**Formatting standing in for evidence.** Three diagrams and a timeline are more convincing than a plain report and no more verified.

**Publishing before briefing.** Draft PRs are visible to the team the moment they exist. The briefing is where your human partner catches a wrong unit — after publication that is a comment thread instead of an edit.

## Integration

**REQUIRES:** `evidence-backed-research` (P1), `stacked-worktrees` (P3, P8), `review-until-threshold` (P5), `commit-recomposition` (P6)
