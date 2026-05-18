# Script Reviewer

Score a YouTube script against 10 criteria (each 0-10, total 100). Compare against reference videos as benchmark. Two reviewers run in parallel with different perspectives.

## Input

- `script`: Full script text
- `success_analysis`: Phase 1 results
- `reference_videos`: Benchmark video info
- `reviewer_id`: "A" (viewer) or "B" (producer)
- `iteration`: Current round (1, 2, 3...)

## Scoring Criteria

| # | Criterion | Weight | What to evaluate |
|---|-----------|--------|-----------------|
| 1 | Hook power | HIGH | First 30s retention. Must create personal stake (not just facts). Does the viewer think "this affects ME"? |
| 2 | Info density | MED | Key info per minute. Not too sparse, not too dense. ~3 data points per minute is ideal. |
| 3 | Structure | MED | Logical flow intro->body->conclusion. Smooth transitions. |
| 4 | Retention devices | HIGH | Open Loops (min 2), Pattern Interrupts (every 2-3min), Recap Anchors. Check: does each section end with a forward hook? |
| 5 | Fact reliability | MED | Accuracy of claims. Sources cited. Fact-check reflected. |
| 6 | Emotion curve | HIGH | Tension-release rhythm every 2-3min. NOT flat info delivery. Check: is there a "signature moment" (one stat/insight so surprising it's shareable)? |
| 7 | CTA naturalness | MED | Subscribe/like prompts tied to viewer benefit, not generic boilerplate. Must include reason to subscribe ("다음 영상에서 X 분석"). |
| 8 | Differentiation | MED | Unique angle vs reference videos. |
| 9 | Spoken naturalness | MED | Conversational Korean. No written-style or AI-sounding phrases. Check tone-guide compliance. |
| 10 | Overall vs reference | MED | Quality level compared to benchmark videos. |

**Weight guide**: HIGH criteria (1, 4, 6) are common failure points from past reviews. Score these strictly — they drive the difference between 82 and 92.

## Reviewer Perspectives

- **Reviewer A (Viewer)**: Is it fun? Easy to understand? Emotionally engaging? Worth watching to the end? Focus on: Hook (personal stake), Emotion curve (signature moment), Retention (open loops).
- **Reviewer B (Producer)**: Accurate and deep? Structurally sound? Brand consistent? SEO optimized? Focus on: Fact accuracy, CTA wording, brand voice ("팩트와 숫자로만"), SEO title/tag alignment.

## Output Format

```markdown
## Review (Reviewer {id}, Round {iteration})

### Score: {total}/100

| # | Criterion | Score | vs Reference | Comment |
|---|-----------|-------|-------------|---------|
| 1 | Hook | {N}/10 | {comparison} | {note} |
| ... | ... | ... | ... | ... |

### Strengths (8+ items)
1. {strength}: {why}

### Improvements needed (<8 items, priority order)

#### 1. {criterion} ({current}/10 -> target {goal}/10)
**Problem**: {specific issue}
**Reference approach**: {how benchmark handled it}
**Fix**:
- **Location**: {section/timestamp}
- **Current**: "{text}"
- **Suggested**: "{revised text}"
- **Rationale**: {why this raises the score}

### Verdict: PASS / REVISE
- Current: {score}/100, Target: 90/100
- **Focus areas for next round** (if REVISE): {list}
```

## Fix Quality Rules

Each improvement MUST include:
1. **Exact location** (section + line reference)
2. **Current text** (verbatim quote)
3. **Suggested replacement** (ready to copy-paste)
4. **Score impact estimate** (e.g., "+1 to emotion curve")

Do NOT give vague feedback like "make the middle section more engaging." Instead: quote the flat section, write the replacement, explain why it scores higher.

## Common Patterns to Check (learned from past reviews)

- **Missing open loops**: Every section should end with a question or teaser for the next section
- **Flat middle**: Body sections (03:00-07:00) tend to become info dumps. Look for 2+ emotion peaks
- **Signature moment**: Is there one stat so surprising the viewer would screenshot or share it? If not, suggest one
- **Generic CTA**: "좋아요 구독 부탁드려요" alone scores 7/10 max. Needs viewer benefit tied to it
- **Hook without personal stake**: Raw stats (96%!) score 8/10. Stats + "this affects your portfolio" scores 10/10

## Loop Rules

1. avg(A, B) >= 90 -> PASS
2. avg < 90 -> Apply fixes, re-review (iteration + 1)
3. After 3 rounds still < 90 -> Ask user whether to proceed with best version
