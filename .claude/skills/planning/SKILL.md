---
name: planning
description: 기획 문서 작성 (PRD / 화면명세 / HTML 목업 / Design Doc / Spec / PR Message / 리뷰 체크리스트) — 하우스 문법에 맞춰 기획 산출물을 생성합니다. 전체 체인 또는 개별 문서 유형을 지원. "PRD 써줘", "기획서 만들어줘", "설계서", "design doc", "스펙", "spec", "PR 작성", "화면 명세", "목업 만들어줘" 요청 시 트리거.
---

# Planning

A skill for writing planning documents that match the user's established house grammar.
Not generic internet PRDs — documents that reflect how THIS user defines problems,
structures requirements, handles exceptions, and communicates with reviewers.

## Document Types

| Type | Guide | Template | When |
|------|-------|----------|------|
| PRD | `guides/prd.md` | `templates/prd.md` | Product requirements for a feature or project |
| Screen Spec | `guides/screen-spec.md` | `templates/screen-spec.md` | Per-screen states, interactions, edge cases |
| HTML Mockup | `guides/mockup.md` | (generated) | Interactive single-file prototype |
| Design Doc | `guides/design-doc.md` | `templates/design-doc.md` | Architecture, tech choices, approach comparison |
| Spec | `guides/spec.md` | `templates/spec.md`, `templates/spec-light.md`, `templates/spec-jira-light.md` | Implementation spec (domain model, API, acceptance criteria) + Linear issue. `spec-jira-light` = intent-only Jira ticket (What/How/Out-of-scope/Done when) |
| PR Message | `guides/pr-message.md` | `templates/pr-message.md` | PR body for GitHub (scale-adaptive sections) |
| Review Checklist | — | `templates/review-checklist.md` | "Can we go to review with this?" gate |

## Routing

1. Identify which document type(s) the user wants.
2. Load the corresponding guide from `guides/`.
3. Follow that guide's workflow.

If the user asks for a "full chain" or "풀체인" or mentions PRD + mockup together,
run in sequence: PRD → Screen Spec → Mockup → Review Checklist.
Between each step, ask: "다음 단계로 진행할까요?" and respect the answer.

If the user asks for just one type (e.g., "PRD만"), run only that guide.

## Needs-Driven Flow

Do NOT force a fixed phase sequence. Instead:
- After completing any document, offer the natural next steps.
- Let the user choose: continue, skip, pivot, or stop.
- Example flow after PRD: "PRD 완성. (a) 화면명세 (b) HTML 목업 (c) 페르소나 리뷰 (d) 여기서 끝"

## Brainstorming (from doc-coauthoring pattern)

For high-uncertainty sections (requirements, policies/exceptions, risks):
- Generate 5-10 candidate items.
- Present numbered list. User curates: "1,3,5 유지 / 2 삭제 / 4+7 병합".
- Draft the section from curated items.
Skip brainstorming for low-uncertainty sections (background, goals) — draft directly.

## Reader Testing (optional, from doc-coauthoring pattern)

After PRD or screen spec completion, offer:
"Reader Testing을 실행할까요? (서브에이전트가 이 문서만 보고 개발 시작 가능한지 검증)"

If accepted:
- Spawn a sub-agent with ONLY the document content (no conversation context).
- Ask: "이 문서만 읽고 개발을 시작할 수 있나? 빠진 정보, 모호한 부분, 모순은?"
- Report gaps. Fix them or surface under "오픈 이슈".

## Persona Review Integration

After any document completion, if the user wants multi-perspective feedback,
suggest: "페르소나 리뷰를 실행할까요?" — this triggers the existing `persona-review` skill.
Do NOT re-implement it here.

## Save Path

```
{OBSIDIAN_VAULT}/01-Projects/{project}/docs/planning/{topic}/
```
- {project}: lowercase, matching 01-Projects/ subfolder
- {topic}: kebab-case subject grouping (e.g., admin-approval, alert-system)
- Create directory chain if it doesn't exist.
- Filename: `YYMMDD-{SCOPE}-{NN}-{type}.md` (or `.html` for mockups)
- Compute NN from existing files sharing that date+SCOPE across all topic folders.

## Conventions

- Frontmatter: Obsidian YAML (`created`, `status`, `tags`, `related` with `[[wikilinks]]`).
- Numbered section headers (`## 1.`, `## 2.`...) for PRD and screen spec.
- ASCII diagrams mandatory for value chain, UX flow, architecture overview.
  See `reference/ascii-diagram-examples.md` for house style examples.
- Korean output. English instruction text in skill files.

## Keywords

PRD, 기획서, 기획 문서, 화면 명세, 상세기획, 목업, mockup, screen spec, planning,
제품 요구사항, 요구사항 정의, planning document, 풀체인, full chain,
design doc, 설계서, 설계 문서, 기술 설계, 아키텍처 설계, architecture design,
technical design, 접근법 비교, approaches considered,
spec, 스펙, 구현 명세, 명세서, implementation spec, 구현 스펙, acceptance criteria,
도메인 모델 정의, API contract, sub-issue 분해,
PR 작성, PR 메시지, PR 본문, pull request message, PR body
