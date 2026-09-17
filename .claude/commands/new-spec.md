구현 명세서 작성 (Spec) — 도메인 모델, API contract, acceptance criteria를 하우스 문법에 맞춰 생성하고 Linear 이슈로 발행합니다.

Create a spec using the planning skill's spec guide.

Ask only for missing inputs: project name / parent design doc or Linear issue /
one-line goal / scale (full or lightweight).

Follow the spec guide workflow:
- Step 1: Scope (gather context + determine scale)
- Step 2: Draft (domain model + API + data flow + acceptance criteria)
- Step 3: Challenge (adversarial review)
- Step 4: Linear (issue or sub-issue creation)
- Step 5: Next steps

Apply the house grammar: ASCII diagrams, code blocks for domain models,
Obsidian frontmatter, Korean output.

Save to {OBSIDIAN_VAULT}/raw/inbox/ with a search-term based filename (Korean ok).
No date code, no required project/type slots. Attributes (created YYMMDD, scope, disclosure, project,
status, scale, `spec` tag) live in frontmatter, never in the filename or H1.
