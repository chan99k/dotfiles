---
name: stacked-worktrees
description: Use when a ticket splits into multiple dependent tasks that each need their own branch and isolated worktree, or when creating, updating, or landing a chain of stacked pull requests where each PR builds on the one below.
---

# Stacked Worktrees

A chain of dependent tasks, each in its own isolated worktree, each branch based on the branch below it, published as stacked draft PRs.

**Core principle:** A stack is only correct while every branch's base is the branch below it — including after the bottom PR lands. Landing is the part that breaks.

## When to Use

**Use when:**
- One ticket splits into 2+ tasks where later tasks fail to compile without earlier ones
- Publishing a chain of PRs where each reviews as a small independent diff
- A stacked PR's base branch just got merged and the stack needs re-pointing

**Don't use when:**
- Tasks are genuinely independent → `superpowers:dispatching-parallel-agents`, plain worktrees
- Single task, single PR → `superpowers:using-git-worktrees` + `pr`
- Reading an existing stack to understand it → `walking-through-pr-stacks`
- `gt` (Graphite) is installed → use Graphite; it manages restacking for you

## Topology

```
        main
         │
         ├──● pr1   worktree ../repo-pr1   PR #177 → main
         │
         └──┴──● pr2   worktree ../repo-pr2   PR #178 → pr1
                │
                └──● pr3   worktree ../repo-pr3   PR #179 → pr2

  Each PR's diff shows ONLY its own task, because its base is the branch below.
  Reviewer sees 3 small PRs, not 1 big one.
```

**Branch naming (ops-console convention):** `pr{N}/{domain}/{brief-desc}`, numbered bottom-to-top within the stack — `pr1/novel/bug-ux-fixes`, `pr2/novel/detail-view-ui`, `pr3/novel/work-form-modal`. Standalone work keeps `feature/…`, `fix/…`, `refactor/…`.

## Step 0: Determine commit preservation (REQUIRED before landing)

The landing procedure is decided by one question: **do the branch's original commits become ancestors of the default branch when the PR merges?**

| Merge method | Original commits preserved? | Landing |
|---|---|---|
| Merge commit | **Yes** | Case B — retarget only |
| Squash | No — replaced by one new commit | Case A — rebase required |
| Rebase merge | No — replayed with new SHAs | Case A — rebase required |

### Team projects — Case B is the house convention

A repo owned by an organization rather than your own account is a team project.

```bash
gh repo view --json owner --jq '.owner.login'   # differs from `gh api user --jq .login` → team project
```

**Team project → merge commits, Case B.** Squash is not used. Reference: `infiniction-dev/ops-console` — squash disabled, merge commits practiced, `delete_branch_on_merge: true`.

Run one confirmation whose only job is to catch a repo that deviates from the convention:

```bash
gh api "repos/{owner}/{repo}" \
  --jq '{squash: .allow_squash_merge, merge_commit: .allow_merge_commit,
         rebase: .allow_rebase_merge, delete_branch_on_merge: .delete_branch_on_merge}'
```

If merge commits are unavailable, or the repo is configured to squash, it deviates from the house convention. **Stop and tell your human partner before landing anything.** Do not silently switch to Case A on your own — a team repo that squashes is a fact worth surfacing, not routing around.

### Personal projects — read the repo

No house convention applies. Run both checks and take the case from what they return.

```bash
gh api "repos/{owner}/{repo}" \
  --jq '{squash: .allow_squash_merge, merge_commit: .allow_merge_commit,
         rebase: .allow_rebase_merge, delete_branch_on_merge: .delete_branch_on_merge}'

git log origin/main --merges --format='%h %s' -5
```

`Merge pull request #N from …` entries in that log mean merge commits are the practiced method. Settings alone are not enough when several methods are enabled — read the merge log too. Record what the commands actually returned; never write down an expected value in place of a real one.

## Step 1: Create the stack

Create each worktree with its base ref given explicitly as the last argument.

```bash
git worktree add ../repo-pr1 -b pr1/novel/bug-ux-fixes    main
git worktree add ../repo-pr2 -b pr2/novel/detail-view-ui  pr1/novel/bug-ux-fixes
git worktree add ../repo-pr3 -b pr3/novel/work-form-modal pr2/novel/detail-view-ui
```

`git worktree add <path> -b <new-branch> <base-ref>` creates the branch and the worktree in one command. The trailing `<base-ref>` is what puts the branch on the stack.

**Do not create branches with `git checkout -b` first.** `git checkout -b X <base>` checks X out in your current worktree, and the following `git worktree add <path> X` then fails with `fatal: 'X' is already checked out at ...`. It also switches your working branch as a side effect.

## Step 2: Push bottom-to-top before creating any PR

`gh pr create --base <branch>` fails if `<branch>` does not exist on the remote. Push in stack order.

```bash
git -C ../repo-pr1 push -u origin pr1/novel/bug-ux-fixes
git -C ../repo-pr2 push -u origin pr2/novel/detail-view-ui
git -C ../repo-pr3 push -u origin pr3/novel/work-form-modal
```

## Step 3: Create the PRs

Every PR in a stack is created with these flags. All four are required.

| Flag | Value | Why |
|------|-------|-----|
| `--base` | the branch below (bottom PR: the default branch) | keeps the diff scoped to this task |
| `--head` | this task's branch | explicit, no reliance on cwd |
| `--draft` | always, on every PR in the stack | the stack is incomplete until every PR exists and every base is verified |
| `--title` / `--body-file` | per project convention | — |

```bash
gh pr create --draft --base main                     --head pr1/novel/bug-ux-fixes    --title "..." --body-file /tmp/pr1.md
gh pr create --draft --base pr1/novel/bug-ux-fixes   --head pr2/novel/detail-view-ui  --title "..." --body-file /tmp/pr2.md
gh pr create --draft --base pr2/novel/detail-view-ui --head pr3/novel/work-form-modal --title "..." --body-file /tmp/pr3.md
```

The PR body must contain a **Stack** section with these three slots filled:

```markdown
## Stack
- Position: 2/3
- Base PR: #177
- Merge method (Step 0): merge commit → Case B
```

Mark PRs ready for review only after every PR in the stack exists and Step 4 passes.

## Step 4: Verify the stack before handing it to reviewers

```bash
gh pr list --json number,headRefName,baseRefName,isDraft \
  --jq '.[] | select(.headRefName | startswith("pr"))'
```

Confirm each `baseRefName` is the branch below it. A PR whose base silently reads as the default branch is a broken stack — fix it before review, not after.

## Step 4.5: Restacking during review

When a lower branch changes during review — review feedback, a fix, a rename — every branch above it must be moved onto its new tip. This is required in **both** cases and has nothing to do with Step 0.

```bash
# pr1 was amended and pushed. Move pr2 onto its new tip:
cd ../ops-console-pr2
git fetch origin
git rebase origin/pr1/payment/webhook-signature-verifier
git push --force-with-lease
```

Then repeat upward, one level at a time, always bottom-to-top. PR base pointers do not change here — only the commits move, so Step 4's verification output should look the same afterward.

Skipping this leaves the upper PR compiling against a version of the lower task that no longer exists.

## Step 5: Landing

Land strictly bottom-first.

### Case B — merge commit (retarget only)

The merged commits are already ancestors of the default branch, so the diff stays clean without a rebase.

```bash
gh pr edit <next-PR#> --base main
```

**With `delete_branch_on_merge: true`, GitHub performs this retarget automatically** when the base branch is deleted at merge. Under Case B that is correct and needs no intervention — verify with Step 4's command and move on.

**At landing under Case B, the retarget is the entire procedure.** Do not add a rebase or a force-push to it — that rewrites history and discards review state for no benefit.

### Case A — squash or rebase merge (rebase required)

After `pr1/novel/bug-ux-fixes` merges:

```bash
cd ../repo-pr2
git fetch origin
git rebase --onto origin/main pr1/novel/bug-ux-fixes pr2/novel/detail-view-ui
git push --force-with-lease
gh pr edit <PR#> --base main
```

Repeat for each higher PR as the one below it lands, always passing **the branch directly below** as `<old-base>`.

Squash replaces the branch's commits with one new commit; rebase merge replays them under new SHAs. Either way the originals never become ancestors of the default branch, so retargeting without rebasing re-presents the lower task's entire diff inside the upper PR and conflicts against the landed commit.

**Under Case A, GitHub's automatic retarget is the failure, not the fix.** It moves the base pointer and never rebases. Treat a bottom PR merging as an event that obligates the rebase.

## Prohibitions

**Never flatten the stack to save time.**

- Do not re-point a middle or top branch to the default branch because the stack "got complicated"
- Do not rebuild upper tasks on the default branch after the bottom lands
- Do not merge upper PRs before lower ones
- Do not collapse the stack into one PR
- Do not retarget under Case A without running the rebase first
- Do not add a rebase or force-push to a Case B **landing** sequence

If the stack is genuinely wrong for the work, stop and tell your human partner it should be restructured. Do not silently unstack.

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "Deadline is today — just base them all on the default branch" | Then the upper task does not compile and its PR carries the lower task's diff. You moved the cost into review, not out of it. |
| "The team got burned by rebase hell last sprint, keep it simple" | Rebase hell comes from long-lived divergent branches. Landing a stack bottom-first is the procedure that prevents it. |
| "GitHub's base-change handles it, no rebase needed" | True only under merge commits. Run Step 0 and know which case you are in before claiming this. |
| "This team repo squashes, so switch to Case A and carry on" | It deviates from the house convention. Say so before landing anything — the deviation is the finding. |
| "GitHub auto-retargeted it already, so it's fine" | Correct under Case B, silently broken under Case A. The check is Step 0, not the fact that it happened. |
| "Rebase is safer, land both cases the same way" | Landing under Case B needs no rebase; adding one drops review state for zero benefit. Landing under Case A cannot skip it. The cases differ — Step 0 tells you which you are in. |
| "Just this once, unstack and re-split later" | Re-splitting means redoing published work. There is no later. |
| "Reviewers will not notice the extra commits" | The reviewer re-reviews an already-approved task. That is the exact cost stacking exists to remove. |
| "pr3 only needs pr1, so base it on pr1" | Base on the branch directly below in merge order. Skipping a level makes pr3 unmergeable until pr2 lands anyway. |

## Red Flags — stop and re-check

- Writing `git checkout -b` before `git worktree add`
- A `gh pr create` line in a stack without `--draft`
- Landing started without Step 0 having been run
- `gh pr edit --base` under Case A with no `git rebase --onto` above it
- A rebase or force-push appearing in a Case B **landing** sequence
- Passing a non-adjacent branch as `<old-base>` to `git rebase --onto`
- Proposing "abandon the stack" as a time-saving option

## Quick Reference

| Situation | Action |
|-----------|--------|
| Creating stack branch | `git worktree add <path> -b <br> <base-ref>` |
| Branch name | `pr{N}/{domain}/{brief-desc}`, N bottom-to-top |
| Base ref for task N | branch of task N-1 (task 1: default branch) |
| Before any `gh pr create` | push all branches bottom-to-top |
| Every PR in stack | `--draft --base <below> --head <own>` |
| Team project (org-owned repo) | Case B by house convention; confirm, don't re-derive |
| Team repo that turns out to squash | stop and tell your human partner; do not switch to Case A alone |
| Personal project | read settings + merge log, pick the case |
| Lower branch changed during review | restack upward: `git rebase origin/<below>` → force-with-lease (both cases) |
| Case B landing | retarget only, often automatic |
| Case A landing | `git rebase --onto origin/<default> <below> <self>` → force-with-lease → `gh pr edit --base` |
| `<old-base>` for rebase --onto | the branch directly below, always |
| Stack feels too complicated | tell your human partner; never silently flatten |

## Common Mistakes

**Creating the branch before the worktree.** `git checkout -b` claims the branch in the current worktree; `git worktree add` then refuses it and your working branch has been switched as a side effect.

**Creating PRs before pushing.** `gh pr create --base <branch>` requires the base to exist on the remote.

**Landing top-down.** Merging the top PR first pulls the lower tasks into the default branch through its diff, and the lower PRs become empty or conflicted.

**Rebasing onto the wrong old-base.** `git rebase --onto origin/<default> <old-base> <branch>` drops exactly the commits reachable from `<old-base>`. Naming a non-adjacent branch drops the wrong range.

**Applying Case A's procedure to a Case B repo.** A force-push that was never needed, with review state lost.

## Integration

**REQUIRED BACKGROUND:** `superpowers:using-git-worktrees` — isolation mechanics and native-tool detection. It has no notion of stack base; this skill supplies it.
**RELATED:** `walking-through-pr-stacks` — reading an existing stack
**DOWNSTREAM:** `pr` — project PR template and checklist
**RELATED:** `commit-blueprint` — safety before state-mutating git commands
