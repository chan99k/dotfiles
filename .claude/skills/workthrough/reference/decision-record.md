# Decision Record Block

Every non-trivial decision in a workthrough uses this 4-block format (Korean output):

### D{N} — {short title}
**상황**: the context / what forced the choice
**선택지**: list each option; mark the chosen one in **bold** (or a table with the chosen row bold)
**결정**: what was chosen
**이유**: why — and, critically, why each rejected option was rejected

Rules:
- Number decisions D1, D2, … in the order they were made.
- Use a comparison table when options differ on several axes (cost / risk / effort).

## Depth: Lean vs Narrative

**Lean** (4-block, stays in the workthrough as-is):
- Reversible or low-impact decisions.
- Fewer than 3 options, trade-offs are obvious.
- Example: "로깅 프레임워크로 SLF4J 선택"

**Narrative** (expand in-place within the workthrough):
- Hard to reverse: schema, public API contract, module boundary, communication pattern.
- 3+ options with non-obvious trade-offs across multiple axes.
- Requires code examples, ASCII diagrams, or comparison tables to explain properly.
- Example: "도메인 이벤트 발행 구조 A안 vs B안", "서브 도메인 모듈 경계 설정"

When narrative, expand the D-block to include:
1. Full option descriptions (with code snippets if relevant)
2. Comparison table on multiple axes (복잡도 / 확장성 / 유지보수 비용 / ...)
3. ASCII diagram of before/after architecture (if structural)
4. Explicit rejection rationale per rejected option
5. Resulting context: consequences + new constraints introduced

This replaces the old guidance of "extract to a standalone ADR". Narrative decisions
live inside the workthrough. After the workthrough is done, a lean one-liner is also
appended to the project's ADR log (see guides/adr.md).
