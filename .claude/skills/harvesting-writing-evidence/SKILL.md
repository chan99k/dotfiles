---
name: harvesting-writing-evidence
description: Use when the user is going to write a blog post, portfolio entry, or retrospective themselves and asks for research, source material, fact-checking, or "글감/재료/근거" from git history, PRs, CI runs, or vault notes. Also use when a brunch-writer or workthrough request should produce evidence instead of prose.
---

# Harvesting Writing Evidence

## Overview

The user writes every sentence of the article. You produce an **evidence pack**: verified facts with sources, arranged along five axes, plus a list of questions only the author can answer. You write no prose that could appear in the article.

Core rule, borrowed from Ptacek's "How To Write With An LLM" (2026-09-17): the author may not use a single word the model suggested. So the pack contains quotations, numbers, paths, dates, and labels. It contains no titles, no angles, no "this would make a good story", no praise.

## When to Use

- "이 작업으로 글 쓰려는데 재료 뽑아줘", "글감 조사", "팩트체크해서 근거만"
- A brunch-writer or workthrough style request where the user will draft the text
- Input is a commit range, commit hashes, a PR number, a topic line, or a whole project folder

Do not use when the user asks you to draft, outline, or polish text. Do not use for copy-editing a finished draft (separate skill).

## Output Contract

One vault note at `{OBSIDIAN_VAULT}/raw/inbox/<검색어형-파일명>-재료팩.md`, Korean, following `template.md` in this directory. The note has exactly these parts, in order:

```
frontmatter        created, project, scope, disclosure, purpose, input (범위), sources
0 범위             what was included, what was excluded and why, range overreach noted
1 문제 발견        when, what, how it surfaced             each item: [label] + source
2 해결책 탐색      what was tried, in what order, what failed
3 결정 근거        why this was chosen                       quote the source verbatim
4 기각한 대안      what was not done and why                 if none in sources: say so
5 결과와 성과      measurements, before/after, what remains  read-only aggregates only
6 공개 제약        approval requirement, publication gate result, do-not-write list
7 빈 곳            questions for the author, one per line, no suggested answers
8 근거 대장        fact-check table: claim | checker A | checker B | verdict
```

Every item in sections 1 to 5 carries one label and one source:

| Label | Meaning | Source form |
|---|---|---|
| `[사실]` | Verified against a primary source by two checkers | `커밋 abc1234`, `PR #12 본문`, `path/file.kt:40`, `gh run 2026-01-19..31 n=63` |
| `[추정]` | Inferred; the inference is stated as an inference | same, plus the reasoning in one clause |
| `[미검증]` | Found in a secondary source, not confirmed | note path or URL |
| `[미측정]` | Would need a run or benchmark; not executed | the command that would measure it |

## Recipe

1. **Scope.** Resolve the input to commits. For a range on a shared branch, filter by path so unrelated merges drop out, and report the raw count next to the filtered count. For a topic line or a whole project folder, build the candidate set first and stop: show it to the user (for a folder, group commits into subjects and list one pack per subject) and continue only with the subjects the user picks. Never extract from an unconfirmed candidate set.
2. **Sources, in this order.** `git log`, `git show` (commit bodies are primary). `gh pr view` body and review comments. `gh run list` with `--created` for CI duration and failure counts. Vault notes (`grep -rl` in `raw/`, `knowledge/`). Existing published posts on the same subject (they are a source to reconcile, not to reuse). All read-only.

   Source tiers decide the label ceiling. Primary (commit, PR, CI run, file at a commit) can support `[사실]`. A vault note supports `[사실]` only when its frontmatter `author:` is the user or absent and the note quotes the user; a note with `author: claude` or "Assistant" is secondary and caps at `[미검증]` unless a primary source confirms it. A published post is secondary. Say the tier next to the source when it is not primary.
3. **Extract** into sections 1 to 5. Quote commit bodies and review comments verbatim. Numbers come from aggregation scripts you can rerun; put the script in the scratchpad and cite it — never from counting by hand.

   **Attribution gate.** Before an item enters sections 1 to 5, check the author of the commit it rests on. On a shared repo, a branch, a PR, or a subject the user named can still be mostly someone else's work. Keep only the user's commits; put the excluded count and the reason in section 0, and name in section 0 any part of the subject that turns out to be another author's. A reader will take the whole article as the author's own, so an unchecked attribution is the one error that cannot be fixed after publication.
4. **Fact-check** every `[사실]` item with two competing subagents (see feedback memory `competing-subagents`): same claim list, independent verification, cross-compare. Mismatches are re-verified by you and recorded in section 8. Items that fail become `[미검증]` or are removed.
5. **Publication gate.** Locate the project's gate (for this vault: the regex in `블로그-글감-인덱스.md`, "오염 현황과 발행 게이트") and the approval rule (security pledge, NDA). Run the gate on the pack itself. Section 6 lists identifiers that must not appear in the article and the approval step, if any.
6. **Gaps.** Whatever git cannot answer (why this over that, what it felt like, who decided, what was on the whiteboard) becomes a question in section 7.

   A question has exactly one sentence, ends with a question mark, and asks about a past fact. Write it in one of these shapes and no other: `<fact>의 계기는 무엇입니까?`, `<fact>를 정한 사람은 누구입니까?`, `<fact>는 언제였습니까?`, `<fact>는 어떻게 처리됐습니까?`. Nothing before the fact, nothing after the question mark. This is the rule agents break most often — in an 18-pack run, four packs shipped a question with an alternative ("A입니까, 아니면 B입니까"), a trailing explanation, or a request for the author's framing, and every one had to be rewritten.

   Axis placement: section 3 holds only reasons stated in a source. A number you derived (an interval, a count) belongs in section 5, even when it is interesting.
7. **Write the note** as `raw/inbox/<검색어>-재료팩.md`. Register it as a Jira Task named `<검색어>-블로그-재료팩` with the epic below as parent and the note path in the description (see "Tracking"). Then reply with the path, the issue key, the counts (facts / inferences / unverified / questions), and one line: 재료는 여기까지입니다. 글은 직접 쓰세요.

## Tracking

Personal Jira via the local `atlassian` MCP (`mcp__atlassian__*`), never the company Rovo connector.

```
site        chan99k.atlassian.net   cloudId 9e888b82-e9d4-4929-8758-16a932312b21
project     C9K (todolist)
parent epic C9K-7 "블로그 글감"
issue type  작업 (Task), parent = C9K-7      (subtasks cannot sit under an epic)
create      mcp__atlassian__createJiraIssue  projectKey C9K, issueTypeName 작업, parent C9K-7
```

The issue is personal tracking; never reference its key in anything pushed to a team repo (see feedback memory `remote-artifact-isolation`).

## Read-Only Boundary

Aggregating existing history is allowed. Running a build, a benchmark, a test suite, or a container to produce a number is not; write the command under `[미측정]` and let the author decide. Never push, never open a PR, never modify tracked files in the target repo.

## What the Pack Never Contains

These are shape violations. If one appears, remove it before writing the note.

- A title, subtitle, tag, or slug candidate
- A section named 글감 포인트, 서사, 훅, 교훈, 시사점, or any framing of "what the story is"
- A sentence evaluating the work ("좋은 회고 소재", "인상적인 결정", "깔끔한 설계")
- A paraphrase where a quotation was available
- An inference labeled as fact ("~로 보임", "~했던 것으로 추정" belong under `[추정]`, not in a `[사실]` line)
- Prose paragraphs longer than two sentences. The pack is lists, tables, and quotes

## Common Mistakes

| Mistake | Fix |
|---|---|
| Range on a shared branch includes 100+ unrelated commits | Path-filter, report both counts in section 0 |
| Timeline instead of five axes | Timeline is allowed inside section 1 or 2, but every axis must exist, even if it reads "소스에 없음" |
| Section 4 silently empty | State "git, PR, 노트 어디에도 기각 대안 기록 없음" and add a section 7 question |
| Section 5 has no numbers | Run `gh run list --created` aggregation, count tests in the diff, cite; if nothing measurable, `[미측정]` with the command |
| Inference dressed as fact | Move to `[추정]` and add the reasoning clause |
| Suggesting how to frame it | Delete. Section 7 asks about facts ("스켈레톤 결정은 누가 내렸습니까?"), never about framing ("어떻게 다루고 싶습니까?") |
| Two-option question in section 7 | Split into one fact question; the second option was a framing suggestion |
| Assistant-authored vault note cited as `[사실]` | Cap at `[미검증]`, find the primary source, or drop |
| Repo file read from the working tree | The checkout may not be the branch you mean. Read with `git show <branch>:<path>` |
| Another author's commit used as the user's work | Check `git log --format=%an` per commit before the item is written, not after |
| Reusing a published post's sentences as material | Cite the post as a source to reconcile; quote only to show a discrepancy |

## Related Skills

- brunch-writer: superseded for research; its dictation phases are not used
- workthrough: produces prose retrospectives; do not invoke from here
- competing-agents: the fact-check pattern in step 4
