---
name: persona-review
description: Use when user wants multi-perspective review of code, documents, or ideas by 3 real advisory agents (ceo=business/market, cto=tech/architecture, cpo=product/user-experience) competing independently. Triggers on "페르소나 리뷰", "3인 리뷰", "관점별 리뷰", "executive review", or explicit persona review requests.
---

# Persona Review

Three real advisory agents independently review the same artifact in parallel. Each brings a distinct lens. The user reads all three opinions and decides what to act on.

**Core principle:** A single reviewer has blind spots. Three competing perspectives with different evaluation criteria surface trade-offs that consensus-seeking misses.

## Reviewers

The three reviewers are **real agents** (`~/.claude/agents/`), not inline personas. Their lens, axes, severity tags, and gates live in one place and evolve there — this skill never keeps a drifting copy. It dispatches them and wraps their output in a shared template for comparison.

### `ceo` — Business & Market (green)
- **Lens:** PMF, business model & unit economics, GTM, competition & moat, partnership/regulatory risk
- **Asks:** "Is there a market? Who pays? How do we win?"
- **Under-weights:** product-experience detail and line-level execution

### `cto` — Technical & Org Strategy (blue)
- **Lens:** architecture, build-vs-buy, scope/priority, debt↔speed, team/process, risk/regulation
- **Asks:** "Will this hold at 10x? What breaks first? Build or buy?"
- **Under-weights:** may over-engineer for hypothetical future requirements

### `cpo` — Product & User Experience (pink)
- **Lens:** user value/JTBD, simplicity & first-principles, ship-bias, product cohesion, differentiated experience
- **Asks:** "Would a real user care? Is this the simplest form? Can we ship now?"
- **Under-weights:** may under-weight compliance/economics for speed

Each agent enforces its own axes and the shared severity tags (`[중단]`/`[강권]`/`[제안]`/`[질문]`/`[관찰]`) internally. This skill only supplies the artifact and asks for a comparable output shape.

## When to Use

**Use when:**
- User wants multi-perspective feedback before a decision
- Reviewing code changes (diff, PR, module), design documents (SRS, PRD, ADR), or ideas
- Trade-offs are unclear and different stakeholder views would help
- User explicitly requests persona-based or executive review

**Don't use when:**
- Task has a single correct answer (syntax fix, config change)
- User wants competing implementations → `competing-agents`
- User wants a single deep-dive review → just ask directly
- User wants line-level code craftsmanship review → `preflight-review` agent (this panel reviews at the strategic/product altitude — market, architecture, product experience — not code lines)

## Process

```
1. Scope  →  2. Dispatch (3 parallel)  →  3. Collect  →  4. Compare  →  5. User decides  →  6. Act
```

### Phase 1: Scope

Identify what is being reviewed and prepare context.

1. **Identify the artifact:** code diff, file(s), document, idea description
2. **Read the artifact fully** — reviewers need the complete picture
3. **Gather supporting context:** related specs, constraints, prior decisions
4. **Define review focus** (if user specified) or leave open for each persona's natural lens

**Output:** A self-contained context block that each agent prompt will include verbatim.

### Phase 2: Dispatch

Dispatch all 3 agents in a **single message** so they run concurrently. Use the Agent tool with `subagent_type` set to each real agent — do **NOT** inline persona descriptions. Each agent already carries its own identity, lens, and severity tags, so the prompt supplies only the artifact, context, focus, and the shared output format.

**Dispatch (single message, 3 Agent tool calls):**
- `Agent(subagent_type: "ceo", run_in_background: true, prompt: <REVIEW_PROMPT>)`
- `Agent(subagent_type: "cto", run_in_background: true, prompt: <REVIEW_PROMPT>)`
- `Agent(subagent_type: "cpo", run_in_background: true, prompt: <REVIEW_PROMPT>)`

**Defaults:**
- Model: agents inherit the session model. To override all three, pass `model` on each dispatch (see Model Override).
- Background: `run_in_background: true`

**REVIEW_PROMPT template (identical for all 3 — no persona injection):**

```
Review the following artifact through your lens. Apply your own axes and severity tags,
then format the result as the Output Format below so it can be compared with two other reviewers.

## Artifact Under Review
{FULL_ARTIFACT_CONTENT}

## Supporting Context
{SPECS, CONSTRAINTS, PRIOR_DECISIONS}

## Review Focus
{USER_SPECIFIED_FOCUS or "Open review from your lens"}

## Output Format
### Verdict: {STRONG_APPROVE | APPROVE | CONCERNS | REJECT}

### Key Findings (max 5)
For each finding:
- **Finding:** one-line summary
- **Severity:** [중단] / [강권] / [제안] / [질문] / [관찰]
- **Rationale:** why this matters from your lens
- **Suggestion:** concrete action (if applicable)

### What Works Well (max 3)
Acknowledge strengths — don't just criticize.

### Blind Spot Declaration
State what your lens under-weights on THIS artifact.

### One-Line Summary
A single sentence capturing your overall take.

Stay in your lens. Be direct. Disagree with conventional wisdom when your lens demands it.
Do NOT hedge with "it depends" — commit to a position and defend it.
```

> **Note:** `ceo` may capture verified facts to ZenNotes `raw/research/` as part of its normal behavior — that is expected and harmless (read-only toward code). `cto`/`cpo` are pure advisory and write nothing.

### Phase 3: Collect

Wait for all 3 background agents to complete. Do NOT poll.
- Record each persona's review as it arrives
- Proceed to comparison only after ALL three finish
- If one fails, note the failure and proceed with remaining reviews

### Phase 4: Compare

Present a structured comparison report:

```markdown
## Persona Review Report: {artifact_name}

### Verdict Matrix
| Aspect | ceo | cto | cpo |
|--------|-----|-----|-----|
| Verdict | ... | ... | ... |
| Top concern | ... | ... | ... |
| Top strength | ... | ... | ... |

### Agreement Points
{Findings where 2+ reviewers agree — these are high-confidence signals}

### Divergence Points
{Findings where reviewers disagree — these are the real trade-offs}
For each divergence:
- ceo says: ...
- cto says: ...
- cpo says: ...
- **Trade-off:** {what the user is choosing between}

### Combined Findings by Severity
| # | Finding | Severity | Raised by | Suggestion |
|---|---------|----------|-----------|------------|
| 1 | ... | [중단] | ceo, cto | ... |
| 2 | ... | [강권] | cpo | ... |
| ... |

### Synthesis
{2-3 sentence overall assessment: what's the core tension, what would each reviewer prioritize}
```

**Present the report and WAIT for user decision.**

### Phase 5: User Decides

The user may:
- Accept specific findings and ignore others
- Ask for deeper exploration of a divergence point
- Request one reviewer to respond to another's criticism (re-dispatch that agent with the other's finding as context)
- Dismiss all and proceed as-is
- Ask for implementation of suggested changes

### Phase 6: Act

Based on user decision:
- If changes requested → implement them (or delegate to appropriate skill)
- If no changes → conversation continues normally
- If follow-up review requested → re-dispatch with narrowed scope

## Model Override

By default the 3 agents inherit the session model (do not pass `model`). User can override for all three per-session by passing `model` on each dispatch:

| User says | Model passed |
|-----------|-----------|
| (nothing) | (inherit session model) |
| "opus로 리뷰" | opus for all 3 |
| "haiku로 빠르게" | haiku for all 3 |

Per-reviewer model override is NOT supported (adds complexity without clear value — lens differentiation comes from the agent, not the model).

## Integration

**RELATED:** `competing-agents` — For competing implementations (not reviews)
**DOWNSTREAM:** `post-cleanup` — If review leads to changes that need commit/cleanup
**MEMORY:** `feedback-competing-subagents` — Competition pattern preference applies here too

## Common Mistakes

**Thin context:** Reviewers with incomplete artifact context give surface-level feedback. Always include the full artifact and supporting specs.

**Leading the witness:** Don't include your own opinion in the prompt. Let each agent form independent judgments.

**Inlining personas:** Don't paste lens descriptions into the prompt — dispatch the real `ceo`/`cto`/`cpo` agents by `subagent_type`. Inline copies drift from the agent definitions.

**Ignoring divergence:** Agreement points are easy. The real value is in divergence — that's where trade-offs live. Don't flatten disagreements into consensus.

**Skipping blind spot declarations:** Each agent declaring what its lens under-weights is what makes the comparison honest. Don't remove it from the template.

## Red Flags

**Never:**
- Apply changes before user decides
- Merge reviews into a single "consensus" opinion (that defeats the purpose)
- Let one agent's prompt reference another's expected output
- Skip the comparison report

**Always:**
- Include full artifact in each agent prompt
- Dispatch all 3 in a single message (parallel)
- Present divergence points explicitly
- Wait for user's explicit decision before acting
