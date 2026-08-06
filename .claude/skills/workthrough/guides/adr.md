# ADR Log Guide

Lean Architecture Decision Records as a timestamped log in a single per-project document.
Each entry is a compact block — NOT a full workthrough. The full narrative lives in the
workthrough that triggered the decision; the ADR log is the index.

## When to use

- After a commit that includes a non-trivial architectural decision.
- When the user asks to "ADR 정리", "ADR 로그 업데이트", or "아키텍처 결정 기록".
- As a post-commit step: review recent commits/workthroughs and extract decisions.

## File location

```
{OBSIDIAN_VAULT}/01-Projects/{project}/docs/adr-log.md
```

One file per project. Create if it does not exist (use templates/adr-log.md as skeleton).

## Workflow

### Step 1 — Identify decisions

Scan for decisions from one of:
- The current workthrough's Section 4 (D1, D2, …)
- Recent git log messages
- User-provided context

### Step 2 — Classify each decision

Assign two labels:
1. **Module**: the Spring Modulith module, Gradle module, or logical domain area
   (e.g. `payment`, `wallet`, `screening`, `infra`, `shared`)
2. **Decision type**: the nature of the decision within that module
   (e.g. `통신 패턴`, `도메인 설계`, `스키마`, `기술 스택`, `배포 전략`, `테스트 전략`)

### Step 3 — Write the entry

Use this format per entry (Korean output):

```markdown
### ADR-{NNN}: {한 줄 제목}
- **상태**: Accepted | Proposed | Deprecated | Superseded by ADR-{NNN}
- **일자**: YYYY-MM-DD
- **상황**: {1-2 sentences: 왜 이 결정이 필요했는가}
- **결정**: {1-2 sentences: 무엇을 선택했는가}
- **결과**: {1-2 sentences: 주요 영향 + 새로운 제약}
- **상세**: [[{워크스루 파일명}]] (내러티브가 있는 경우)
```

### Step 4 — Place in the document

Insert the entry under the correct module heading, then under the correct decision type
subheading. Create headings if they don't exist yet. Maintain ascending ADR number order
within each subheading.

### Step 5 — Update the counter

The YAML frontmatter has `last_adr_number`. Increment it for each new entry.

## Numbering

- Global sequential across the entire project: ADR-001, ADR-002, …
- Do NOT reset per module or per type.
- If the project already has entries, continue from the highest existing number.

## Grouping order

```
## {Module A}
### {결정 유형 1}
ADR-001: ...
ADR-005: ...
### {결정 유형 2}
ADR-003: ...

## {Module B}
### {결정 유형 1}
ADR-002: ...
```

Modules are sorted alphabetically. Decision types within a module are sorted by first
appearance (the order they were first used in that module).

## Status transitions

```
Proposed → Accepted    (결정 확정)
Accepted → Deprecated  (더 이상 유효하지 않음)
Accepted → Superseded by ADR-{NNN}  (새 결정으로 대체)
```

When superseding, update the old entry's status AND add a new entry for the replacement.

## Anti-patterns

- Writing full narrative here. The log is an INDEX. Details go in the workthrough.
- Creating a separate file per ADR. One file per project.
- Mixing decisions from different projects in one file.
- Leaving status as "Proposed" indefinitely — resolve or remove.
