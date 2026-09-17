기획 문서 작성 (PRD / 화면명세 / HTML 목업) — 하우스 문법에 맞춰 기획 산출물을 생성합니다.

Create planning documents using the planning skill.

Ask only for missing inputs: project name / topic keywords / one-line problem /
who is the user / what exists today / what should change.

Follow the skill's needs-driven flow:
- Identify which document type(s) the user wants (PRD, screen spec, mockup, or full chain).
- Load the corresponding guide from guides/.
- After each document, offer next steps — do NOT force a fixed phase sequence.
- Between each step in a full chain, confirm before proceeding.

Apply the house grammar: numbered sections, ASCII diagrams, comparison tables,
Obsidian frontmatter, Korean output.

Save to {OBSIDIAN_VAULT}/raw/inbox/ with a search-term based filename (Korean ok, .html for mockups).
No date code, no required project/type slots. Attributes (created YYMMDD, scope, disclosure, project,
status, version, doc type via tags) live in frontmatter, never in the filename or H1.
