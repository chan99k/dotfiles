---
description: Generates a fact-checked troubleshooting blog post from the current debugging conversation. Extracts timeline, builds narrative, writes blog, and verifies claims with web search.
argument-hint: "<optional: comma-separated list of user's key questions if you want to guide the extraction>"
allowed-tools: Read, Write, Bash, Glob, Grep, WebSearch, WebFetch, Task
---

# MISSION

Analyze the current debugging/troubleshooting conversation to generate a **fact-checked technical blog post**. The post should honestly document the discovery process, including wrong turns and corrections.

# CONTEXT

Optional user-provided key questions: "$ARGUMENTS"
If provided, use these as the authoritative list of debugging steps. Otherwise, infer from conversation history.

# VAULT PATH
```
VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/chan99k's vault/chan99k's vault
```

# CORE CONSTRAINTS

1. **No Hindsight Bias**: Present discoveries in the order they happened. Do not rewrite history.
2. **Honesty About Uncertainty**: If root cause was not conclusively found, say so with confidence level.
3. **No Hallucinated References**: Only include sources actually found via web search.
4. **Language**: Blog post body in **Korean**. Code snippets, CLI output, and file paths remain in English.
5. **Loop Limit**: Maximum 2 attempts. If both fail, report failure with specific details.

# PROCESS

## STEP 1: Extract Debugging Timeline

Analyze the conversation and extract each debugging step chronologically.

**Actions:**
1. If `$ARGUMENTS` is provided, use it as the list of user's key questions/commands.
2. Otherwise, scan the conversation for each user question, hypothesis, or debugging action.
3. Assign sequential IDs: Q1, Q2, Q3, ...
4. For each Q, record:
   - The user's original question (preserve wording)
   - The assistant's key findings (2-3 bullets)
   - Interim conclusion at that point
   - Whether any correction/error occurred

**Output (internal working document):**

```
Q1: [original question]
  - Finding: ...
  - Finding: ...
  - Conclusion: ...
  - Error/Correction: [if any]

Q2: [original question]
  ...
```

**Constraints:**
- Do not reorder or merge questions.
- If the assistant was wrong and later corrected, note BOTH the error and the correction.

---

## STEP 2: Build Structured Narrative

Using Q1...QN, construct a structured outline.

**Required Sections:**

### BACKGROUND
- System/project context
- What the user was trying to achieve
- Architecture relevant to the problem

### DISCOVERY_FLOW
For each Q, document the chain:
```
Question -> Facts Discovered -> Interim Conclusion -> What Led to Next Question
```

### ROOT_CAUSE
- Final identified cause
- Confidence level: `confirmed` | `likely` | `uncertain`
- Supporting evidence

### CHANGES_APPLIED
- Files modified with before/after summaries
- Configuration changes
- Commands executed

### LESSONS
- Actionable takeaways as checklist items

**Constraints:**
- Be honest about uncertainty.
- Do not add post-hoc rationalizations.
- If there were dead ends or wrong hypotheses, include them.

---

## STEP 3: Write Blog Post

Using the structured narrative, write the blog post in Markdown.

**Required Sections and Format:**

```markdown
# [Title: "디버깅 [Problem]: [Key Insight]" format]

## TL;DR
[2-3 sentences max. Problem -> Root Cause -> Fix.]

## 배경
[System context. Architecture diagram (ASCII/Mermaid) if helpful.]

## 발견 과정

### Q1: [Question title]
[First person narrative. "처음에 ~를 확인했다...", "~라고 추측했지만..."]

### Q2: [Question title]
[Continue discovery. Include wrong turns honestly.]

### Q3: ...
[Each Q gets its own subsection.]

## 근본 원인
[Technical explanation. Code snippets if relevant.]
[Confidence: confirmed/likely/uncertain]

## 수정 사항
[Code/config diffs in fenced blocks with language tags.]
[Before -> After format.]

## 교훈
- [ ] Lesson 1
- [ ] Lesson 2
- [ ] Lesson 3

## References
| Claim | Source | Credibility |
|-------|--------|-------------|
| ...   | ...    | High/Medium/Low |
```

**Style Rules:**
- First person for Discovery section
- Technical but approachable tone
- Fenced code blocks with language tags
- ASCII or Mermaid diagrams where helpful
- No emojis

---

## STEP 4: Fact-Check and Add References

**Actions:**
1. Extract all verifiable technical claims from the blog post.
2. For each claim, use **WebSearch** to find authoritative sources:
   - Prefer: official documentation, GitHub issues/PRs, Stack Overflow with high votes
   - Avoid: random blog posts, AI-generated content
3. If a claim is **wrong or imprecise**, correct the blog post text directly.
4. Build the References table:
   - Minimum 3, maximum 10 references
   - Columns: Claim | Source (as markdown link) | Credibility (High/Medium/Low)
   - Unverifiable claims: mark with "unverified -- based on conversation context only"
5. Do NOT add references for trivial/obvious facts.

---

## STEP 5: File Generation

**Path Convention:**
```
$VAULT/00-Inbox/YYMMDD-troubleshooting-{NN}-{short-description}.md
```

**Actions:**
1. Get current date: `date +%y%m%d`
2. Check existing files for numbering:
   ```bash
   ls "$VAULT/00-Inbox/" 2>/dev/null | grep -E "^[0-9]{6}-troubleshooting-" | tail -1
   ```
3. Ensure directory exists: `mkdir -p "$VAULT/00-Inbox"`
4. Write the finalized blog post
5. Verify: read back the first 30 lines to confirm

---

# ERROR HANDLING

If any step fails:

1. **Attempt 2**: Fix the specific issue and retry that step only.
2. **If Attempt 2 fails**:
   ```
   tBlog generation failed.

   Failed Step: STEP {N}
   Error: {details}
   Manual Action Needed: {what user should do}

   Partial Output: {show what was completed}
   ```

# EXECUTION REMINDER

Before starting:
1. Verify conversation contains debugging/troubleshooting content
2. If `$ARGUMENTS` is empty, inform user you'll infer the timeline from conversation
3. Start with STEP 1
