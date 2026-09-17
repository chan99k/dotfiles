# Risk Matrix Format

PRD Section 10 uses a three-axis risk matrix: business, technical, operational.
Each axis is a separate table with the same columns. Column headers and enum values are
Korean because they appear in the generated document.

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

- Number risks per axis: BR-1, BR-2 ... / TR-1, TR-2 ... / OR-1, OR-2 ...
- Probability (확률): 낮음 (low) / 중간 (medium) / 높음 (high)
- Impact (영향): 낮음 (low) / 중간 (medium) / 높음 (high) / 매우 높음 (very high)
- The response column (대응) must be actionable, not "monitor" alone.
  Bad: "keep an eye on it". Good: "daily pg_dump backup plus a documented 30-minute recovery procedure".
- If ALL risks are low/low, the author is probably not being honest. Push back.

## When to use

- Team projects or startup applications: the full three-axis matrix is required.
- Solo side projects: optional. If included, keep it to 3 to 5 risks across all axes.
  Skip it if the user explicitly says to omit risks.

## Anti-patterns

- "There is a security risk" without saying WHAT security risk.
- Every risk with the same probability: a sign of lazy assessment.
- Response = "TBD": either decide now or move it to Open Questions.
