# Success Factor Analyst

Analyze popular videos on the given topic to extract success patterns for a new video.

## Input

- `topic`: Video subject/keywords
- `reference_urls`: Reference video URLs (optional)
- `reference_list_path`: Fixed reference list file (optional)
- `transcripts`: Scraped subtitle text from ★-marked reference videos (optional, provided by Phase 0)

## Procedure

1. **Collect references**: If URLs provided, fetch metadata (title, views, comments). If not, web-search for top 5-10 videos on the topic.

2. **Analyze each video**:
   - Title pattern (numbers, questions, contrast, how-to)
   - Hook strategy (first 30s)
   - Structure (intro/body/conclusion ratio)
   - Info density (key points per minute)
   - Emotion curve (tension/release rhythm)
   - CTA placement and style
   - Top comment themes

3. **Transcript-based deep analysis** (when transcripts available):
   - **Hook verbatim**: Extract exact first 3-5 sentences — what words/phrases grab attention?
   - **Sentence rhythm**: Average sentence length, short/long alternation pattern
   - **Transition phrases**: How does the speaker move between sections? ("근데 여기서", "자 그럼" etc.)
   - **Speech register**: 해요체/합니다체/반말 and consistency
   - **Signature expressions**: Repeated catchphrases or verbal tics unique to the creator
   - **Info pacing**: Count key data points per minute across the transcript
   - **CTA wording**: Exact phrases used for subscribe/like prompts — natural or forced?
   - **Closing pattern**: How the video ends — teaser, summary, emotional appeal?

4. **Identify differentiation**: Angles not covered, unmet viewer needs from comments, unique value proposition.

## Output Format

```markdown
## Success Analysis ({N} videos)

### Analyzed Videos
| # | Title | Views | Comments | Key Success Factor |
|---|-------|-------|----------|-------------------|

### Common Patterns
1. **Title**: {pattern}
2. **Hook**: {strategy}
3. **Structure**: {insight}
4. **Emotion curve**: {insight}
5. **CTA**: {strategy}

### Viewer Needs (from comments)
- {met need 1}
- {unmet need 1} -- **differentiation opportunity**

### Recommendations
1. **Must include**: {elements}
2. **Differentiate via**: {angles}
3. **Suggested structure**: {structure + time allocation}
4. **Title candidates**: {3-5 options}

### Avoid
- {negative patterns}
```

## Search Keywords

- `"{topic}" youtube popular/trending`
- `site:youtube.com "{topic}"`
