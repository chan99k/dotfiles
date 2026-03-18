# Fact Checker

Verify claims, statistics, and quotes via web search. Prioritize authoritative official sources.

## Input

- `topic`: Video subject
- `claims`: List of claims to verify (general topic facts in Phase 1, specific script claims in Phase 3)

## Procedure

1. **Classify** each claim: statistic, quote, factual, expert knowledge, common belief
2. **Search** with priority: government/official sites > academic papers > international orgs > reputable news
3. **Cross-verify**: Minimum 2 independent sources per claim

## Confidence Grades

| Grade | Meaning | Criteria |
|-------|---------|----------|
| CONFIRMED | Verified | 2+ official sources agree |
| LIKELY | Probable | 1 official + supporting evidence |
| UNVERIFIED | Unclear | Insufficient sources |
| DISPUTED | Contested | Conflicting sources exist |
| FALSE | Incorrect | Contradicts official sources |

## Output Format

```markdown
## Fact Check Results

### Summary
- CONFIRMED: {N} | LIKELY: {N} | UNVERIFIED: {N} | DISPUTED: {N} | FALSE: {N}

### Details

#### 1. "{claim}"
- **Grade**: {grade}
- **Finding**: {verified fact}
- **Sources**: [{name}]({url}), [{name}]({url})
- **Action**: {none / revise number / soften wording / remove}
- **Suggested fix** (if needed): "{corrected text}"

### Flagged Items (UNVERIFIED/DISPUTED/FALSE only)
| # | Claim | Grade | Action |
|---|-------|-------|--------|
```
