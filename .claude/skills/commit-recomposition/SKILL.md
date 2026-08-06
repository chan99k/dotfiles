---
name: commit-recomposition
description: Use when a finished branch's commit history needs reshaping before review — collapsing WIP and fixup commits, splitting mixed changes apart, or reordering into units a reviewer can read one at a time.
---

# Commit Recomposition

Reshape a branch's commits into units a reviewer can read in order, without changing what the branch contains.

**Core principle:** Recomposition changes how the work is presented, never what the work is. The final tree must be byte-identical to the tree you started from, and you find that out by checking, not by feeling confident.

## When to Use

**Use when:**
- A finished branch has WIP, fixup, "asdf", or self-cancelling commits
- One commit mixes unrelated concerns and a reviewer would have to untangle them
- A stack's branch needs a readable history before its PR opens

**Don't use when:**
- The branch is already pushed and others have based work on it → rewriting breaks them; ask your human partner
- The history is already reviewable → leave it alone
- You are moving a branch onto a new base → that is `git rebase`, see `stacked-worktrees`

## The Invariant

```
git diff <original-HEAD> HEAD    →    empty
```

That is the whole contract. Any commit boundary is allowed; any content change is a defect.

**Record the original HEAD before touching anything**, because after the reset there is no other handle on it:

```bash
ORIG=$(git rev-parse HEAD)
echo "$ORIG"    # write it down — you need it at the end
```

Tests passing is not this check. In observed runs, a recomposition that silently dropped a blank line and one that reordered two blocks both passed the full test suite, and both were reported as successful. The suite tests behavior; this check tests fidelity, and they fail independently.

## Procedure

```
  record ORIG ──> soft reset to base ──> stage a unit ──> commit ──> repeat
                                              │                        │
                                              │                   staged empty?
                                              │                        │
                                              ▼                        ▼
                                   content comes from the         verify tree
                                   index, never retyped                │
                                                          ┌────────────┴───────────┐
                                                       empty diff              any diff
                                                          │                        │
                                                        done                 reset --hard ORIG
                                                                             and start over
```

```bash
ORIG=$(git rev-parse HEAD)
BASE=$(git merge-base HEAD main)      # or the branch below in the stack

git reset --soft "$BASE"              # all work is now staged, nothing lost

git reset                             # unstage; work is now in the worktree
git add -p calc.py                    # stage one unit's hunks
git commit -m "feat: ..."
# ... repeat until `git status` is clean ...

git diff "$ORIG" HEAD                 # MUST be empty
```

**Take content from the index, not from your editor.** `git add -p`, `git checkout -p`, and `git stash` replay bytes that are already there. Opening the file and retyping the version you want is how a blank line goes missing and how two blocks swap places — the two failures observed most often, both invisible to tests and to review.

If a hunk needs to be split further than `add -p` will go, use `e` to edit the hunk rather than editing the file.

## What Makes a Unit

A commit is one unit when a reviewer can read it alone and say yes or no.

| Signal | Split them | Keep them together |
|---|---|---|
| A typo fix and a new function | Yes — different questions | |
| A function and the tests for that function | | Together — the tests are the evidence the function works |
| Two independent features | Yes | |
| A refactor and a behavior change | Yes — otherwise the behavior change hides in the noise | |
| A change and its own later fixup | | Together — the reviewer should never see the broken intermediate |

**Ship each behavior with the tests that cover it.** A history where all the code lands first and all the tests land last passes CI at every commit while proving nothing at any of them — each feature commit is green only because nothing tests it yet. Bisect becomes useless for exactly the thing bisect is for.

**Self-cancelling work disappears by construction.** A rename applied in one commit and reverted in the next contributes nothing to the final tree, so it never appears in any new commit. If it shows up, you rebuilt it by hand instead of replaying it.

## Verification — required before you report

Run these and put the output in the report. Not a summary of the output — the output.

**Run the diff with no pathspec first.** A filtered diff can be made empty by choosing the filter, so a check you scoped yourself proves only that you scoped it well. Run it bare, then account for whatever comes back:

```bash
git diff "$ORIG" HEAD --stat          # no pathspec, no exclude
```

Anything in that output is either a defect or a generated file you decided not to carry. Both go in the report, named, with which one it is and why — a build artifact you dropped on purpose is a decision your reviewer should see, and a lost line is a defect wearing the same clothes. Rerunning with an exclude afterwards is fine; replacing the bare run with it is not.

```bash
git diff "$ORIG" HEAD --stat          # expect: no output at all
git log --oneline "$BASE"..HEAD       # the new history
for c in $(git rev-list --reverse "$BASE"..HEAD); do
  git stash -q 2>/dev/null
  git checkout -q "$c" && <your test command> \
    && echo "$c ok" || echo "$c BROKEN"
done
git checkout -q -                     # back to the branch
```

**If the tree diff is not empty, the recomposition failed.** Do not fix it forward by adding a commit with the missing bytes — that leaves the boundaries wrong and hides what happened. `git reset --hard "$ORIG"` and redo it, replaying hunks this time.

## Report

```markdown
## 커밋 재구성 — {branch}

### 트리 동일성
$ git diff {ORIG} HEAD --stat
{paste the actual output of the unfiltered run — empty means the line after the command is blank}

{If it was not empty, one line per remaining path:
   <path> — 생성물, 의도적으로 제외  |  결함
 A path you cannot classify is a defect until you can.}

### 새 히스토리
{git log --oneline output}

### 커밋별 테스트
{one line per commit: sha, ok/BROKEN, subject}

### 분리 근거
{why these boundaries — which concerns were pulled apart, what was dropped as self-cancelling}
```

An "성공적으로 재구성했습니다" with no diff output is not a report. Every observed failure came with that sentence.

## Quick Reference

| Situation | Action |
|-----------|--------|
| About to `git reset --soft` | Record `$ORIG` first |
| Need to split a hunk | `git add -p` then `e`, not an editor |
| Tree diff non-empty | `reset --hard $ORIG`, redo — never patch forward |
| Tests pass, diff non-empty | Still failed; tests do not measure fidelity |
| Repo has generated files in the tree | Run the bare diff anyway; list them in the report as dropped-on-purpose |
| Tempted to add a pathspec to the check | Run it bare first — a self-chosen filter proves nothing |
| Feature and its tests | One commit |
| Typo fix riding along with a feature | Separate commit |
| Rename later reverted | Appears nowhere |
| Branch already pushed and depended on | Stop; ask your human partner |

## Common Mistakes

**Treating a green test run as proof.** It proves behavior survived. It says nothing about whitespace, ordering, comments, or any byte the suite does not exercise.

**Patching the difference forward.** Adding "restore missing newline" as a ninth commit makes the tree match and the history a lie. Reset and redo.

**Losing the original HEAD.** After `reset --soft` it is only in the reflog, and after enough operations it is inconvenient to find. One `ORIG=$(git rev-parse HEAD)` up front costs nothing.

**Splitting until each commit is small.** Small is not the goal; answerable is. A three-line commit a reviewer cannot evaluate alone is worse than a thirty-line one they can.

## Integration

**UPSTREAM:** `review-until-threshold` — recomposition happens after the work passes its gate
**DOWNSTREAM:** `stacked-worktrees` — the recomposed branch is what its PR shows
