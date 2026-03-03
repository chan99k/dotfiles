---
description: Analyzes the current session to generate a structured walkthrough document. Features domain-based folder sorting, session change tracking, and a dialectic review process.
argument-hint: "<greater-context-of-the-task>"
allowed-tools: Read, Write, Bash, Glob, Task
---

# MISSION
Analyze the conversation history of the current session to generate a structured 'Walkthrough' document. Save the file to the Obsidian vault `00-Inbox/` directory following the specified conventions.

# CONTEXT
The Greater Context provided by the user: "$ARGUMENTS"

# CORE CONSTRAINTS (ABSOLUTE)
1. **Loop Limit**: Maximum 2 attempts. If not completed within 2 attempts, abort and report failure with specific error details.
2. **Valid References**: Only include references explicitly mentioned or used during the conversation.
3. **Language**: Output content in **Korean** (Title, Sections, Descriptions). File names and code snippets remain in English.
4. **Mermaid Diagrams**: At least ONE Mermaid diagram is MANDATORY in the "해결책 탐색 과정" section.

# VAULT PATH
```
VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/chan99k's vault/chan99k's vault
```

# PROCESS

## STEP 1: Environment & Path Setup

1. **Get Current Date**:
   ```bash
   date +%y%m%d
   ```
   Store result as `YYMMDD`.

2. **Extract Domain**:
   - Analyze the conversation to identify the primary domain/scope.
   - Choose ONE keyword from: `blueprints`, `setup`, `bugfix`, `decision`, `refactor`, `security`, `performance`, `misc`
   - Use lowercase English only.
   - Store as `{problem-domain-scope-name}`.

3. **Prepare Directory**:
   ```bash
   mkdir -p "$VAULT/00-Inbox"
   ```

4. **Determine Numbering**:
   ```bash
   ls "$VAULT/00-Inbox/" | grep -E "^[0-9]{6}-${problem-domain-scope-name}-" | tail -1
   ```
   - If no files exist: numbering = `01`
   - If files exist: Parse the highest `{numbering}` and increment by 1

5. **Generate Short Description**:
   - Concise kebab-case description (max 5 words, English only)
   - Store as `{short-description}`

6. **Final Filename**:
   ```
   $VAULT/00-Inbox/YYMMDD-{problem-domain-scope-name}-{numbering}-{short-description}.md
   ```

7. **Collect Session Changes** (from wrap-up):
   ```bash
   # Changed files in current git repo (if applicable)
   git diff --stat HEAD 2>/dev/null || echo "No git repo"
   git log --oneline -5 2>/dev/null || echo "No git history"
   ```

## STEP 2: Content Analysis & Outlining

Analyze the conversation history and extract:

1. **문제 발견 (Problem Discovery)**:
   - What was the initial pain point or trigger?
   - What inefficiencies or issues were identified?

2. **해결책 탐색 과정 (Solution Exploration)**:
   - What alternatives were considered?
   - What were the pros/cons of each approach?
   - What experiments or investigations were performed?
   - **MANDATORY**: Identify at least one flow/architecture/comparison for Mermaid visualization

3. **해결책 결정 (Decision)**:
   - What was the final choice?
   - Why was this approach selected over alternatives?

4. **결과 (Results)**:
   - What was achieved?
   - What files were created/modified? (use git diff from Step 1.7)
   - Quantifiable improvements (if any)?

5. **참고 자료 (References)**:
   - Extract ONLY references explicitly mentioned in the conversation
   - Include: documentation URLs, file paths, command outputs

6. **더 큰 맥락 통합 (Context Integration)**:
   - How does this work relate to $ARGUMENTS?
   - Broader principles or patterns demonstrated?

## STEP 3: Drafting (Pass 1)

Create the initial draft following the OUTPUT FORMAT template below.

## STEP 4: Self-Review (Pass 2)

Perform a critical self-review:

**Review Checklist**:
- [ ] Logical Flow: problem -> exploration -> decision -> results?
- [ ] "Why" Clarity: reasons for decisions clearly explained?
- [ ] Technical Accuracy: details correct and precise?
- [ ] Reference Validity: all references real and from conversation?
- [ ] Korean Language: entire content (except code/filenames) in Korean?
- [ ] Mermaid Diagram: at least one diagram that adds value?
- [ ] Context Integration: $ARGUMENTS referenced meaningfully?
- [ ] File Changes: session's git changes documented in results?

Apply Thesis-Antithesis-Synthesis approach to strengthen weak sections.

## STEP 5: File Generation

Write the finalized content and verify:
```bash
head -50 "$VAULT/00-Inbox/{filename}.md"
```

# OUTPUT FORMAT (Markdown Template)

```markdown
# {Title in Korean}

**작성일:** {YYYY년 M월 D일}
**상태:** {완료|진행중|검토중}
**더 큰 맥락:** $ARGUMENTS
**주제:** {One-line summary in Korean}

---

## 목차

1. [개요](#1-개요)
2. [문제 발견](#2-문제-발견)
3. [해결책 탐색 과정](#3-해결책-탐색-과정)
4. [해결책 결정](#4-해결책-결정)
5. [결과](#5-결과)
6. [참고 자료](#6-참고-자료)

---

## 1. 개요

### 1.1 배경

{Context that led to this work}

### 1.2 목표

{Specific goals and objectives}

### 1.3 핵심 질문

> "{Central question this work aimed to answer}"

---

## 2. 문제 발견

### 2.1 {Specific Issue 1}

{Problem, inefficiencies, or pain points discovered}

### 2.2 {Specific Issue 2}

{Additional issues if applicable}

---

## 3. 해결책 탐색 과정

### 3.1 {Approach/Investigation 1}

{First approach considered or investigated}

**장점**:
- {Pro 1}
- {Pro 2}

**단점**:
- {Con 1}
- {Con 2}

### 3.2 {Approach/Investigation 2}

{Alternative approaches}

### 3.3 {Visualization Title}

```mermaid
{Insert relevant diagram: flowchart, sequenceDiagram, graph, etc.}
```

{Explanation of the diagram}

---

## 4. 해결책 결정

### 4.1 최종 선택

{Final decision made}

### 4.2 근거

**기술적 이유**:
1. {Technical justification 1}
2. {Technical justification 2}

### 4.3 트레이드오프

{What was sacrificed or compromised}

---

## 5. 결과

### 5.1 달성한 것

**생성/수정된 파일**:
- `{file-path-1}`: {Description}
- `{file-path-2}`: {Description}

**정량적 개선** (if applicable):
- {Metric 1}: {Before} -> {After}

**정성적 개선**:
- {Improvement 1}
- {Improvement 2}

### 5.2 더 큰 맥락에서의 의미

{How this work relates to $ARGUMENTS}

### 5.3 향후 확장 가능성

{What can be built upon this work?}

---

## 6. 참고 자료

### 6.1 공식 문서

- [{Document Title}]({URL}): {Brief description}

### 6.2 프로젝트 컨텍스트

- `{file-path}`: {How this file was referenced}

### 6.3 검증 방법

{How the solution was validated or tested}

---

**문서 이력**:

| 버전 | 날짜 | 작성자 | 변경 내용 |
|:-----|:-----|:------|:---------|
| 1.0 | {YYYY-MM-DD} | Claude | 초안 작성 |
```

<knowledge_checkpoint>
"Protect your time, not the code."
1. Update plan file with current state if work is in progress
2. Extract context to files for next session continuity
3. Git commit as checkpoint
4. On implementation failure -> git reset and retry cheaply from saved plan
</knowledge_checkpoint>

# ERROR HANDLING

If any step fails:
1. **Attempt 2**: Fix the specific issue and retry
2. **If Attempt 2 fails**:
   ```
   Workthrough generation failed.

   Failed Step: STEP {N}
   Error: {details}
   Manual Action Needed: {what user should do}
   Partial Output: {what was completed}
   ```
