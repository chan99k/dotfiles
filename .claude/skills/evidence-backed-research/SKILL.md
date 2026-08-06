---
name: evidence-backed-research
description: Use when researching a work ticket or technical decision before designing an approach — when the recommendation will rest on how a library, database, or framework actually behaves, and someone will act on what you report.
---

# Evidence-Backed Research

Research a ticket so that a reader can tell, for every claim, where it came from and how to check it.

**Core principle:** The goal is not a more accurate answer. It is an answer whose accuracy the reader can verify without trusting you. A correct claim with no source and a fabricated claim with no source are indistinguishable on the page.

## When to Use

**Use when:**
- A ticket needs investigation before a design can be proposed
- The recommendation depends on how a specific tool actually behaves
- You are about to write an API name, parameter value, version number, or config key into a design

**Don't use when:**
- The question is about this codebase only → read the code
- The decision is a team convention, not a technical fact → ask your human partner
- You are implementing an already-researched design → the research already happened

## Source Tiers

Every claim carries a tier. The tier is part of the claim, not metadata about it.

| Tier | What counts | Examples |
|------|-------------|----------|
| **공식** | Published by the project itself | `docs.spring.io`, PostgreSQL manual, RFC, the project's own source or release notes |
| **준공식** | Written by a maintainer or the vendor | JetBrains blog, core committer's talk, vendor engineering blog |
| **커뮤니티** | Third party | Medium, Stack Overflow, personal blogs, conference talks by users |
| **기억** | You did not open it | — |

**Tier is set by what you opened, not by who published it.** A passage you recalled from the Spring documentation is 기억, not 공식 — the tier records your access to the page, and the publisher's name is not something you verified by remembering it. A well-formed citation built from memory is still 기억: making it look right does not make it read.

**기억 is a permitted tier.** It is not a failure state and it does not need to be eliminated. It needs to be *labeled*. An unlabeled claim reads as 공식 whether or not it is.

Community agreement is evidence about *practice*. Official documentation is evidence about *behavior*. They answer different questions — do not substitute one for the other, and do not present a Medium post as though it settled what the software does.

## The Output Contract

Produce this shape. Sections that do not apply are removed; slots inside a section that appears are filled.

```markdown
## 진단
{What is actually going wrong, and why}

**근거 (공식)**
> {verbatim excerpt}
— [{page title}]({URL})

**근거 (커뮤니티)**
> {verbatim excerpt}
— [{page title}]({URL})

## 설계안
{The approach, with the alternatives considered and why they lost}

## 교차 검증
| 설계 요소 | 상태 | tier | 근거 |
|---|---|---|---|

{One row per element in 설계안 — an element with no row is the failure this section catches.

 상태 is 확인 or 미확인. Nothing else. Confidence does not belong in this column;
 it belongs in tier, which is why the two are separate columns. `확인 (기억)` has
 nowhere to go here: 확인 requires 공식/준공식/커뮤니티 in the tier column, and
 anything at tier 기억 is 미확인 however sure you are.

 확인 requires, in the 근거 column, an excerpt you read plus its link — the excerpt
 must contain the claim in this row. A real link to a page that does not state this
 particular fact is not 확인. If the page you cite covers the topic but not the value,
 that row is 미확인.

 미확인 requires a stated way to confirm it.}

## 반증 탐색
{What you searched for that would show this approach failing, and what came back.
 If nothing contradicting was found, say what you searched — an empty result is
 only meaningful if the reader knows what query produced it.}

## Sources
공식: {links}
준공식: {links}
커뮤니티: {links}
```

**A quote without a link, or a link without a quote, is half a citation.** The link lets the reader go there; the quote lets them see you did. Both, every time.

**A `>` block means text you copied out of a page you opened.** That is what the mark asserts, and a remembered passage set in one makes it lie even when the wording comes out right — you cannot tell from the inside whether it did.

When a quote is asked for and you cannot open the page, the block carries its own attribution line:

```
> "In proxy mode (which is the default), only external method calls coming in
>  through the proxy are intercepted..."

— 기억에서 재구성, 원문 대조 안 함. 확인 방법: Spring Framework Reference 의
  Declarative Transaction Management 섹션
```

Attribution goes directly under the block, in the same place a real citation would go, so it travels with the quote when someone copies it.

**The excerpt has to contain the claim.** A page about the right topic is not evidence for a specific value, version, or default inside it. Before writing 확인, check that the words you pasted actually say the thing you are citing them for; if the page covers the area but not the fact, the claim is still unconfirmed.

## The Identifier Rule

The following must be read from a source you opened, not recalled:

- API, class, method, and annotation names
- Parameter values, magic numbers, and enum constants
- Version numbers and version requirements
- Configuration keys and CLI flags
- **URLs** — a URL you did not open is a guess, and a guessed URL that lands in a Sources list or a "확인 권장 경로" reads as a citation

**When you cannot open the page but a URL is asked for, write it in this form:**

```
https://docs.spring.io/spring-framework/reference/data-access/transaction.html
  (미열람 — 기억에서 쓴 추정 경로. 열리지 않으면 검색어 "spring transaction self-invocation")
```

The marker goes on the line with the URL, not in a tier note at the top of the document — the reader who clicks never sees the top of the document. The fallback search term is what makes the guess recoverable when the path has moved.

**This applies inside code blocks.** A code block is the part a reader copies and runs, so it is where a wrong value costs the most — and it is the part where the question "what is the source for this?" does not arise on its own. Every identifier in a snippet is subject to this rule exactly as if it appeared in a sentence. Cite the snippet's source above it, or mark the specific line:

```kotlin
// 미확인: SKIP LOCKED 에 해당하는 힌트 값. 확인 방법 — Hibernate LockOptions 상수 정의.
@QueryHints(QueryHint(name = "jakarta.persistence.lock.timeout", value = "???"))
```

Write the source next to it, or write it as unverified:

```
미확인: Hibernate 에서 SKIP LOCKED 에 해당하는 lock.timeout 값.
       확인 방법 — LockOptions 상수 정의를 확인.
```

**Why this rule is narrow.** Conceptual explanations can be re-derived and are usually right. A specific value is either recalled or invented, and an invented one looks exactly like a recalled one. Two independent agents given the same ticket wrote two *different* wrong values for the same annotation parameter, each explaining confidently that it produced the intended behavior. Narrow the requirement to where it pays.

## What You Hand Back

If the report goes into a file and you reply with a summary, **the summary is what gets acted on.** Someone reads it in a standup, pastes it into a ticket, and decides. The file may never be opened.

So the summary carries the evidence too. For every claim it repeats:

- Keep the qualifier. "아직 동작하지만 deprecated 계열" and "deprecated 계열" are different claims, and dropping four words changes the recommendation.
- Keep the tier. A claim that was 기억 in the file is 기억 in the summary.
- Keep the link for anything the recommendation rests on. One or two links in a summary is not clutter — it is the difference between a recommendation and an assertion.

A summary with no links and no tiers has undone the research, whatever the file says.

## Cross-Verifying the Design

Confirming the diagnosis is not confirming the design. They are separate claims and they need separate evidence.

A reference that explains *why the bug happens* says nothing about whether your proposed fix is the right one. After the design is drafted, go back to the references and check the design's own elements — the mechanism it relies on, the version it requires, the constraint it assumes.

Then run one search aimed at breaking it: where this approach is reported to fail, what it costs at scale, who moved away from it and why. Report what that search returned, including when it returned nothing.

## Quick Reference

| Situation | Action |
|-----------|--------|
| About to state a version number | Open a source or mark 미확인 |
| Found a Medium post explaining behavior | Useful, but find the official page for the behavior itself |
| Official docs don't cover it | Say so explicitly; 커뮤니티 becomes the best available, labeled as such |
| Asked to skip searching for speed | Answer at tier 기억, labeled, and say what is unconfirmed |
| No contradicting evidence found | Report the query, not just the absence |
| Design element has no supporting reference | List it under 교차 검증 as unconfirmed |
| Search returns nothing usable | Say so — do not fill the slot from memory |

## Common Mistakes

**Citing the diagnosis and calling the design verified.** The Spring docs explaining self-invocation do not endorse any particular fix. Two claims, two evidence requirements.

**Collecting links at the end.** A Sources list assembled after the writing is a bibliography, not evidence — nothing in it is tied to a specific claim. Attach each source where the claim is made.

**Treating a search that found nothing as confirmation.** Absence of contradicting evidence is only informative alongside the query. Report both.

**Dropping the tier when summarizing.** The tier travels with the claim into every summary, briefing, and ticket comment downstream. A summary that flattens 기억 into an unmarked assertion has undone the work.

## Red Flags — stop and re-check

- A parameter value, version, or config key with no source next to it
- A code block whose identifiers came from memory while the surrounding prose is cited
- A URL written from memory with no `(미열람)` marker on its own line
- `확인` in a 교차 검증 row with no link, or any status word other than 확인/미확인
- A cited page that covers the topic but never states the specific value being cited
- A `>` quote assembled from memory with no attribution line saying so
- A source you cited recommending against the approach you recommended, unreported
- A summary or standup blurb that carries the recommendation but not the tiers or links
- A `>` quote with no link, or a link with no quote
- Sources listed only at the end, none attached to a claim
- 커뮤니티 sources used to establish what the software does
- 반증 탐색 section reporting a conclusion but no query
- A design element that appears in 설계안 but nowhere in 교차 검증

## Integration

**DOWNSTREAM:** `stacked-worktrees` — the researched ticket splits into the stack's tasks
**DOWNSTREAM:** `review-until-threshold` — reviewers read this output as the design's justification
