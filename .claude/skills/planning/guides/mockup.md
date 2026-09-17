# HTML Mockup Generation Guide

## Purpose

Generate a single-file interactive HTML mockup from a PRD or a screen spec.
No external libraries, no build step: one `.html` file anyone can open in a browser.
The goal is NOT pixel-perfect design but a reviewable prototype where stakeholders can click
through the flow and say "yes, this is what I meant" or "no, this needs X".

## When to use

- After a PRD or screen spec, when the user wants a visual prototype.
- When the user asks for a mockup (목업 만들어줘, mockup, HTML 프로토타입).
- As the third step of a full-chain planning flow.

## Constraints

1. **Single HTML file**: all CSS and JS inline. No external CDN, no frameworks.
2. **No external dependencies**: must work offline, opened as a local file.
3. **Interactive**: buttons work, modals open and close, state changes.
4. **Data is hardcoded**: realistic sample data, not "Lorem ipsum".
5. **Responsive not required**: desktop-first is fine for internal tools.

## Workflow

### Step 1: Determine Scope

From the PRD or screen spec, identify which screens to include in the mockup.
For complex features, a single mockup file can contain multiple views with tab or nav switching.

Ask whether to include every screen or only the core screens.

### Step 2: Generate

Build the HTML file following these patterns.

**Layout:**
```html
<!-- Navigation or tabs at the top for multi-screen mockups -->
<!-- Main content area -->
<!-- Modals (hidden by default, shown on button click) -->
```

**Required UI patterns (pick what applies):**

| Pattern | When | Implementation |
|---------|------|----------------|
| Data table | List views | `<table>` with sort headers, status badges |
| Detail panel | Item detail | Right panel or full page with labeled fields |
| Modal dialog | Confirm or input actions | Overlay with backdrop, form fields, submit and cancel |
| Status badge | State display | `<span>` with a background color per status |
| Action buttons | User actions | Disabled or hidden based on permission and state |
| History log | Audit trail | Reverse-chronological list with timestamps |
| Empty state | Zero items | Centered message with an icon or illustration |
| Toast / alert | Feedback | Temporary notification after an action |

**Styling guidelines:**
- Clean and minimal. No heavy shadows or gradients.
- Use CSS custom properties for colors so they are easy to adjust.
- Status colors: pending (대기) `#f59e0b` amber, approved (승인) `#10b981` green, rejected (반려) `#ef4444` red.
- Font: the system font stack (`-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`).

**Interaction guidelines:**
- Table row click shows the detail and highlights the selected row.
- Action button opens a modal with the required fields.
- Modal submit updates the status badge and adds a history log entry.
- Permission toggle shows or hides buttons per role.

### Step 3: Verify

After generating, check:
- [ ] The file opens in a browser without errors (no console errors).
- [ ] All buttons are clickable and produce a visible result.
- [ ] Modals open and close correctly.
- [ ] State changes are reflected (badge color, history entry).
- [ ] Permission-based UI works (role switcher, if applicable).
- [ ] Sample data is realistic (Korean names, realistic dates, plausible content).

### Step 4: Next Steps

After the mockup is complete, tell the user to open it in a browser and offer:
```
(a) Generate the review checklist
(b) Reader testing
(c) Persona review
(d) Stop here
```

## Scaling Note

The single-file approach works well up to about 5 to 7 screens. Beyond that the file becomes
unwieldy. If the user hits this limit, suggest:
- Splitting into multiple HTML files, one per major flow.
- Or a lightweight framework, which is outside this skill's scope.

## Anti-Patterns

- Lorem ipsum data. Use realistic Korean sample data.
- Buttons that do nothing. Every visible button must have a click handler.
- Missing empty states. What does the screen look like with zero items?
- Forgetting the modal backdrop. Clicking outside should close the modal.
- Hardcoded pixel widths that break on other screens. Use `max-width` plus `margin: auto`.
