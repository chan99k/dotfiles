# HTML Mockup Generation Guide

## Purpose

Generate a single-file interactive HTML mockup from a PRD or screen spec.
No external libraries, no build step — one `.html` file that anyone can open in a browser.
The goal is NOT pixel-perfect design but a reviewable prototype where stakeholders can
click through the flow and say "yes this is what I meant" or "no, this needs X".

## When to Use

- After PRD or screen spec, when the user wants a visual prototype.
- When the user says "목업 만들어줘", "mockup", "HTML 프로토타입".
- As the third step in a full-chain planning flow.

## Constraints

1. **Single HTML file** — all CSS and JS inline. No external CDN, no frameworks.
2. **No external dependencies** — must work offline, opened as a local file.
3. **Interactive** — buttons should work, modals should open/close, state should change.
4. **Data is hardcoded** — use realistic sample data, not "Lorem ipsum".
5. **Responsive not required** — desktop-first is fine for internal tools.

## Workflow

### Step 1 — Determine Scope

From the PRD or screen spec, identify which screens to include in the mockup.
For complex features, a single mockup file can contain multiple views with tab/nav switching.

Ask: "목업에 포함할 화면을 확인합니다. 전체 다 포함할까요, 핵심 화면만 할까요?"

### Step 2 — Generate

Build the HTML file following these patterns:

**Layout:**
```html
<!-- Navigation or tabs at top for multi-screen mockups -->
<!-- Main content area -->
<!-- Modals (hidden by default, shown on button click) -->
```

**Required UI Patterns (pick what applies):**

| Pattern | When | Implementation |
|---------|------|----------------|
| Data table | List views | `<table>` with sort headers, status badges |
| Detail panel | Item detail | Right panel or full page with labeled fields |
| Modal dialog | Confirm/input actions | Overlay with backdrop, form fields, submit/cancel |
| Status badge | State display | `<span>` with background color per status |
| Action buttons | User actions | Disabled/hidden based on permission/state |
| History log | Audit trail | Reverse-chronological list with timestamp |
| Empty state | Zero items | Centered message with icon/illustration |
| Toast/alert | Feedback | Temporary notification after action |

**Styling guidelines:**
- Clean, minimal — no heavy shadows or gradients.
- Use CSS custom properties for colors (easy to adjust).
- Status colors: 대기=`#f59e0b` (amber), 승인=`#10b981` (green), 반려=`#ef4444` (red).
- Font: system font stack (`-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`).

**Interaction guidelines:**
- Table row click → show detail (highlight selected row).
- Action button → open modal with required fields.
- Modal submit → update status badge + add history log entry.
- Permission toggle → show/hide buttons per role.

### Step 3 — Verify

After generating, check:
- [ ] File opens in browser without errors (no console errors).
- [ ] All buttons are clickable and produce visible results.
- [ ] Modal opens and closes correctly.
- [ ] State changes are reflected (badge color, history entry).
- [ ] Permission-based UI works (role switcher if applicable).
- [ ] Sample data is realistic (Korean names, realistic dates, plausible content).

### Step 4 — Next Steps

After mockup completion, offer:
```
HTML 목업 완성. 브라우저에서 열어 확인해보세요.
(a) 리뷰 체크리스트 생성
(b) Reader Testing
(c) 페르소나 리뷰
(d) 여기서 끝
```

## Scaling Note

This single-file approach works well up to ~5-7 screens. Beyond that, the file becomes
unwieldy. If the user hits this limit, suggest:
- Split into multiple HTML files (one per major flow).
- Or consider a lightweight framework (but that's outside this skill's scope).

## Anti-Patterns

- Lorem ipsum data — use realistic Korean sample data.
- Buttons that do nothing — every visible button must have a click handler.
- Missing empty states — what does the screen look like with 0 items?
- Forgetting the modal backdrop — clicking outside should close the modal.
- Hardcoded pixel widths that break on different screens — use `max-width` + `margin: auto`.
