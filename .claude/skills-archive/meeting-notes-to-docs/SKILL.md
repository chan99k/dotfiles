---
name: meeting-notes-to-docs
description: Use when converting raw, unstructured meeting notes or memos into structured project documents. Triggers include messy bullet points from design discussions, domain modeling sessions, policy debates, or sprint planning that need to become ADRs, ubiquitous language definitions, policy documents, action item lists, or meeting summaries.
---

# Meeting Notes to Docs

Transform raw meeting notes into structured project documents. The output must match the project's existing document templates exactly — not generic formats from training data.

## Document Types

| Type | Output Format | When to Use |
|------|--------------|-------------|
| `adr` | Markdown | Design decisions with alternatives considered |
| `language` | YAML | Domain term definitions for a bounded context |
| `policy` | Markdown | Process or rule discussions needing formalization |
| `actions` | Markdown | TODO extraction with owners and deadlines |
| `summary` | Markdown | Meeting recap for absent stakeholders |

## Core Rules

1. **Template over improvisation.** Use the exact template for each type. Do not invent sections, rename headings, or merge fields.
2. **Korean body, English terms.** Section headings in Korean. Technical terms (class names, patterns) in English.
3. **Preserve attribution.** If notes say "민서: X가 낫다", the document must attribute that position to 민서.
4. **Decisions are atomic.** One ADR = one decision. If notes contain 5 decisions, produce 5 separate ADRs (or ask the user which to bundle).
5. **Extract, don't embellish.** Only include information present in the notes. Flag gaps with `[확인 필요]` rather than inventing content.
6. **Separate concerns.** ADR captures WHY a decision was made. Language YAML captures WHAT terms mean. Don't duplicate across types.
7. **Multi-decision triage.** If notes contain multiple decisions, first list them all and ask the user which to bundle or split. Default: produce one ADR per major decision, noting related decisions in 영향 section with cross-references.

## Templates

### ADR (Architecture Decision Record)

```markdown
# {NNNN}. {한 줄 제목}

- **상태**: 제안 | 확정 | 폐기
- **일자**: YYYY-MM-DD
- **관련 이슈**: [{이슈 번호}]

## 맥락

왜 이 결정이 필요했는지. 문제 상황과 제약 조건을 서술한다.

## 결정

무엇을 결정했는지 1-3문장으로 명확하게 기술한다.
- 테이블명, 패키지, 구현 방식 등 구체적 산출물 명시

## 근거

### 1. {근거 제목}
상세 설명. 번호를 매겨 구분한다.

### 2. {근거 제목}
...

## 영향

- 후속 작업이나 제약 사항을 bullet list로 기술
- 다른 ADR이나 이슈 참조 가능
```

Required fields: 상태, 일자, 관련 이슈 (없으면 `[미정]`)
Section headings: 맥락, 결정, 근거, 영향 — exactly these, in Korean
Numbering: `{NNNN}.` prefix in title (ask user for number if unknown)

### Ubiquitous Language YAML

```yaml
# {BC} Bounded Context — Ubiquitous Language
# 이 파일은 {BC} BC의 도메인 용어를 정의한다.
# 코드·문서·대화에서 이 용어를 일관되게 사용한다.

bounded_context: {bc_name}

terms:

  TermName:
    definition: 한 줄 정의
    note: >
      추가 설명. 다른 용어와의 구분, 채택 배경, 참여자 의견 등.
    code: com.example.package.ClassName
    decision: docs/decisions/NNNN-xxx.md
    constraints:
      - unique
      - not null

boundaries:
  in_domain:
    - field_name       # 도메인 관심사인 이유
  in_base_entity:
    - field_name       # 인프라/감사 관심사인 이유
  excluded:
    - field_name       # 제외 사유
```

Required top-level keys: `bounded_context`, `terms`, `boundaries`
Each term requires: `definition`, `note` (at minimum)
Optional term keys: `code`, `decision`, `constraints`, `values`, `future_values`
boundaries must have: `in_domain`, `in_base_entity`, `excluded`
Format: **Pure YAML only.** No Markdown headings (`##`) inside YAML.

### Policy Discussion

```markdown
# {정책 제목}

- **상태**: 논의 중 | 확정 | 보류
- **일자**: YYYY-MM-DD
- **참석**: {참석자 목록}

## 배경

정책이 필요한 맥락. 현재 문제점이나 리스크.

## 논의 내용

### {논점 1}
- **{참석자A}**: 의견 내용
- **{참석자B}**: 반론 또는 보충
- **합의**: 결론 또는 `[미합의]`

## 확정 사항

- 합의된 정책을 bullet list로 기술

## 미결 사항

- 추가 논의가 필요한 항목
```

### Action Items

```markdown
# 액션 아이템 — {회의 제목} ({일자})

| # | 항목 | 담당 | 기한 | 상태 |
|---|------|------|------|------|
| 1 | {할 일} | {담당자} | {기한 또는 미정} | 대기 |
```

Extract from: TODO lists, "다음에", "해야 할", checkbox items in notes.
If no owner specified: `[미정]`. If no deadline: `[미정]`.

### Meeting Summary

```markdown
# 회의 요약 — {제목} ({일자})

- **참석**: {참석자}
- **목적**: 한 줄 요약

## 주요 논의

1. **{토픽 1}**: 논의 내용 요약 (2-3문장)
2. **{토픽 2}**: ...

## 결정 사항

- {결정 1}
- {결정 2}

## 다음 단계

- {후속 작업}
```

## Transformation Process

```
1. Read notes completely
2. Identify document type (or ask user)
3. Extract: decisions, terms, actions, participants, dates
4. Map to template fields
5. Flag gaps with [확인 필요] or [미정]
6. Validate: every template field filled or explicitly marked missing
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| English section headings (Context, Decision) | Always Korean (맥락, 결정) |
| Inventing `bounded_context` field name | Use exact field from template |
| Merging boundaries into terms | Keep `boundaries:` as separate top-level key |
| Adding Markdown `##` inside YAML | Pure YAML, comments with `#` only |
| Anonymizing participant opinions | Preserve "민서: X" attribution in `note` |
| One mega-ADR for all decisions | One ADR per decision. Ask user about bundling. |
| Adding Glossary, Checklist sections to YAML | Only `bounded_context`, `terms`, `boundaries` |
| Using `Accepted` instead of `확정` | Status values in Korean |
