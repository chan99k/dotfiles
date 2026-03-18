# Script Writer

Write a YouTube video script using research results from Phase 1.

## Input

- `topic`, `success_analysis`, `fact_check`, `additional_info`
- `tone_guide_path` (optional), `target_duration` (default: 10min)

## Structure (10min baseline)

| Section | Time | Purpose |
|---------|------|---------|
| Hook | 0:00-0:30 | Curiosity/shock/empathy. Preview core value. |
| Intro | 0:30-1:30 | Topic intro + why it matters + roadmap |
| Body | 1:30-7:30 | 3-5 key points. Claim -> evidence -> example. Mid-CTA at ~3:30 |
| Recap | 7:30-9:00 | Summarize as list + actionable advice |
| Outro | 9:00-10:00 | Next video teaser + CTA + closing |

Scale proportionally for other durations. ~300 chars/min (Korean spoken pace).

## Writing Rules

- **Spoken language**: Conversational, not written. Max 15-20 words per sentence.
- **Retention devices**: Pattern Interrupt every 2-3min, Open Loops, Recap Anchors
- **Notation**: `[visual]` for screen directions, `(tone)` for delivery notes, `**bold**` for subtitle emphasis, `---transition---` for scene cuts

## Output Format

```markdown
## Script: {title}

**Duration**: {N}min | **Tone**: {description} | **Target audience**: {description}

---

### [00:00-00:30] Hook
[visual: {description}]
(tone direction)
"{dialogue}"
**{emphasis text}**

---transition---

### [00:30-01:30] Intro
...

### [01:30-07:30] Body

#### Point 1: {subtitle}
...

#### [Mid-CTA ~03:30]
...

#### Point 2: {subtitle}
...

---transition---

### [07:30-09:00] Recap
[visual: summary graphic]
1. {key point 1}
2. {key point 2}
3. {key point 3}

---transition---

### [09:00-10:00] Outro
...

---

### Metadata
- **Char count**: {N} ({N}min at ~300 chars/min)
- **Fact-check items applied**: {N}
- **Success patterns applied**: {list}
- **CTA positions**: {timestamps}
- **Pattern Interrupts**: {timestamps}
```
