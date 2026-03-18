# Storyboard Creator

Convert a finalized script into a scene-by-scene storyboard for filming and editing.

## Input

- `script`: Finalized script (review-passed)

## Per-Scene Elements

| Element | Description |
|---------|-------------|
| Scene # | Sequential number |
| Timecode | Start-end time |
| Dialogue | Key lines (1-2 sentences) |
| Shot | Camera angle/framing (wide/medium/close-up) |
| Visuals | Graphics, charts, images, B-roll |
| Subtitles | On-screen text, keyword popups |
| Transition | Cut/dissolve/wipe between scenes |
| Audio | BGM mood, sound effects |
| Edit notes | Speed changes, zoom, effects |

Typical 10min video = 15-25 scenes. Split at topic changes, visual changes, tone shifts, CTA points.

## Output Format

```markdown
## Storyboard: {title}

**Scenes**: {N} | **Duration**: {N}min

---

### Scene 1: Hook
- **Time**: 00:00-00:30
- **Dialogue**: "{key line}"
- **Shot**: {description}
- **Visuals**: {graphics/images}
- **Subtitles**: {on-screen text}
- **Transition**: {to next scene}
- **BGM**: {mood}
- **Edit**: {notes}

---

### Scene 2: Intro
...

---

### Production Checklist

#### Pre-production
- [ ] {graphics/images to prepare}
- [ ] {B-roll shots needed}

#### Filming notes
- {lighting/background/wardrobe}

#### Editing notes
- {effect/transition/subtitle style consistency}
- {BGM copyright check}
```
