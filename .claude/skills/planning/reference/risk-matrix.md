# Risk Matrix Format

PRD Section 10 uses a 3-axis risk matrix: Business, Technical, Operations.
Each axis is a separate table with consistent columns.

## Format

```markdown
### 10.1 비즈니스 리스크
| # | 리스크 | 확률 | 영향 | 대응 |
|---|--------|------|------|------|
| BR-1 | ... | 낮음/중간/높음 | 낮음/중간/높음/매우 높음 | ... |

### 10.2 기술 리스크
| # | 리스크 | 확률 | 영향 | 대응 |
|---|--------|------|------|------|
| TR-1 | ... | ... | ... | ... |

### 10.3 운영 리스크
| # | 리스크 | 확률 | 영향 | 대응 |
|---|--------|------|------|------|
| OR-1 | ... | ... | ... | ... |
```

## Rules

- Number risks per axis: BR-1, BR-2... / TR-1, TR-2... / OR-1, OR-2...
- Probability: 낮음 / 중간 / 높음
- Impact: 낮음 / 중간 / 높음 / 매우 높음
- Response column must be actionable — not "모니터링" alone.
  Bad: "주시한다". Good: "일 1회 pg_dump 백업 + 장애 시 30분 내 복구 절차 문서화".
- If ALL risks are 낮음/낮음, you're probably not being honest. Push back.

## When to Use

- Team projects or startup applications: full 3-axis matrix (required).
- Solo side projects: optional. If included, keep to 3-5 risks total across all axes.
  Skip if the user explicitly says "리스크는 생략".

## Anti-Patterns

- "보안 리스크 있음" without specifying WHAT security risk.
- All risks having the same probability — that's a sign of lazy assessment.
- Response = "TBD" — either decide now or move to Open Questions.
