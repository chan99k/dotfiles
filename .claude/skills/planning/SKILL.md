---
name: planning
description: Write planning documents (PRD / screen spec / HTML mockup / design doc / spec / PR message / review checklist) in the user's house grammar. Supports the full chain or a single document type. Triggers on requests such as "PRD 써줘", "기획서 만들어줘", "설계서", "design doc", "스펙", "spec", "PR 작성", "화면 명세", "목업 만들어줘".
---

# Planning

A skill for writing planning documents that match the user's established house grammar.
Not generic internet PRDs. These documents reflect how THIS user defines problems,
structures requirements, handles exceptions, and communicates with reviewers.

## Document Types

| Type | Guide | Template | When |
|------|-------|----------|------|
| PRD | `guides/prd.md` | `templates/prd.md` | Product requirements for a feature or project |
| Screen Spec | `guides/screen-spec.md` | `templates/screen-spec.md` | Per-screen states, interactions, edge cases |
| HTML Mockup | `guides/mockup.md` | (generated) | Interactive single-file prototype |
| Design Doc | `guides/design-doc.md` | `templates/design-doc.md` | Architecture, tech choices, approach comparison |
| Spec | `guides/spec.md` | `templates/spec.md`, `templates/spec-light.md`, `templates/spec-jira-light.md` | Implementation spec (domain model, API, acceptance criteria) plus a Linear issue. `spec-jira-light` is an intent-only Jira ticket (What / How / Out of scope / Done when) |
| PR Message | `guides/pr-message.md` | `templates/pr-message.md` | PR body for GitHub, sections chosen by change size |
| Review Checklist | (none) | `templates/review-checklist.md` | The "can we take this into a review meeting?" gate |

## Routing

1. Identify which document type(s) the user wants.
2. Load the corresponding guide from `guides/`.
3. Follow that guide's workflow.

If the user asks for a "full chain" (풀체인) or mentions PRD and mockup together,
run in sequence: PRD, Screen Spec, Mockup, Review Checklist.
Between each step, ask whether to proceed to the next one, and respect the answer.

If the user asks for a single type (for example "PRD only"), run only that guide.

## Needs-Driven Flow

Do NOT force a fixed phase sequence. Instead:
- After completing any document, offer the natural next steps.
- Let the user choose: continue, skip, pivot, or stop.
- Example after a PRD: "PRD done. (a) screen spec (b) HTML mockup (c) persona review (d) stop here."

## Section Walkthrough (all document types)

Every house-grammar section is filled by asking the user, one section per turn, in template
order. For a required section, ask the question that fills it, or present a draft and get a
yes. For an optional section (marked "해당 시" in the template), ask whether it belongs in
this document and accept only two answers: include it, or "not needed now". A declined
section goes into the document's `생략한 절` (omitted sections) ledger with the reason.
Never fill an optional section on your own judgement, and never drop one silently.
Skip a question only when the answer is already on record, and say so in one line.
Per-type details live in each guide; `guides/design-doc.md` carries the full rule.

## Brainstorming (from the doc-coauthoring pattern)

For high-uncertainty sections (requirements, policies and exceptions, risks):
- Generate 5 to 10 candidate items.
- Present them as a numbered list. The user curates, for example "keep 1, 3, 5 / drop 2 / merge 4 and 7".
- Draft the section from the curated items.
Skip brainstorming for low-uncertainty sections (background, goals) and draft them directly.

## Reader Testing (optional, from the doc-coauthoring pattern)

After a PRD or screen spec is complete, offer reader testing: a sub-agent reads only the
document and judges whether development could start from it.

If accepted:
- Spawn a sub-agent with ONLY the document content, no conversation context.
- Ask it: can development start from this document alone? What is missing, ambiguous, or contradictory?
- Report the gaps. Fix them, or surface them under Open Questions.

## Persona Review Integration

After any document is complete, if the user wants multi-perspective feedback, offer a
persona review. That triggers the existing `persona-review` skill. Do NOT re-implement it here.

## Save Path

```
{OBSIDIAN_VAULT}/raw/inbox/
```
This is `/Users/chan99/vault/raw/inbox` under the vault convention of 2026-09-07.
The old vault path `01-Projects/...` is retired.

- Flat. No project or topic folder chain. Folders in this vault mean tier (raw vs knowledge),
  never subject. The subject axis lives in the frontmatter `project:` field and in `maps/` MOCs.
- Filename: search-term based. Use the words the user would type when thinking
  "didn't I have something about this?". Korean is fine. Examples:
  `ops-console-배치-최적화.md`, `chan99k-blog-드릴-루틴-설계.md`, `giftify-장바구니-cascade.md`.
  Project or document-type words may appear only when they are natural search words; they
  are NOT required slots. Attributes (date, project, document type, status, version,
  audience) live in frontmatter, never in the filename or the H1 title.
- Date-code filenames (`YYMMDD-SCOPE-NN-...`) are forbidden by the vault rules. Never generate them.
- H1 title = the subject only. No `Design:` / `Spec:` / `PRD` / `v1.0` / `[SCOPE]` prefixes or
  suffixes, and no "version / written on / audience / status" lines in the body. Those are
  frontmatter fields.
- Mockups: same name with the `.html` extension.
- If a project repo has its own docs directory the user prefers (for example
  `docs/superpowers/specs/`), that overrides the vault path. Ask only when both are plausible.

## Conventions

- Frontmatter: `raw/` requires `scope` (personal | company | oss), `disclosure`
  (public | masked | internal) and `created` (YYMMDD). Add `project`, `status`, `tags`,
  `related` with `[[wikilinks]]`, and `version` / `audience` where the template has them.
  The document type is expressed by a tag (`prd`, `screen-spec`, `design-doc`, `spec`),
  not by the filename or title. `type` and `author` are NOT set in `raw/`; they are assigned
  when a note is promoted to `knowledge/`.
- Numbered section headers (`## 1.`, `## 2.` ...) for PRD and screen spec.
- ASCII diagrams are mandatory for the value chain, the UX flow and the architecture overview.
  See `reference/ascii-diagram-examples.md` for house-style examples.
- Output language is Korean. Instruction text in skill files is English.

## Keywords

PRD, 기획서, 기획 문서, 화면 명세, 상세기획, 목업, mockup, screen spec, planning,
제품 요구사항, 요구사항 정의, planning document, 풀체인, full chain,
design doc, 설계서, 설계 문서, 기술 설계, 아키텍처 설계, architecture design,
technical design, 접근법 비교, approaches considered,
spec, 스펙, 구현 명세, 명세서, implementation spec, 구현 스펙, acceptance criteria,
도메인 모델 정의, API contract, sub-issue 분해,
PR 작성, PR 메시지, PR 본문, pull request message, PR body
