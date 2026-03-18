---
name: youtube-scriptwriter
description: YouTube script pipeline orchestrator. Takes topic/keywords and optional reference video URLs, then runs success analysis, fact-checking, script writing, review loop (until avg 90+), storyboard, and upload prep via parallel sub-agents. Triggers on "youtube script", "video script", "scriptwriting", or Korean equivalents.
---

# YouTube Scriptwriter Pipeline

Orchestrates 6 specialist sub-agents to produce a complete YouTube script package.

## Input

- **topic** (required): Video subject/keywords
- **reference_urls** (optional): Benchmark video URLs
- **target_duration** (optional, default 10min): Target video length
- **tone_guide**: Auto-loaded from `references/tone-guide.md` if exists
- **reference_list**: Auto-loaded from `references/reference-videos.md` if exists

## Pipeline

```
Phase 1 (parallel)              Phase 2           Phase 3 (parallel loop)
┌─────────────────┐
│ Success Analyst  │─┐
│ (sonnet)        │  │
└─────────────────┘  │      ┌─────────────┐    ┌──────────────┐
                     ├─────>│ Script Writer│───>│ Reviewer A   │─┐
┌─────────────────┐  │      │ (opus)      │    └──────────────┘  │
│ Fact Checker     │─┤      └─────────────┘    ┌──────────────┐  │
│ (sonnet)        │  │                         │ Reviewer B   │─┤
└─────────────────┘  │                         └──────────────┘  │
                     │                                           │
┌─────────────────┐  │      avg < 90? ◄──────────────────────────┘
│ Info Researcher  │─┘        Yes: revise + re-review (max 3x)
│ (sonnet)        │           No:  PASS
└─────────────────┘
                                │ PASS
                        Phase 3.5 (HUMAN GATE)
                       ┌──────────────────┐
                       │  Human Review    │
                       │  (대본 검토/수정) │
                       └────────┬─────────┘
                                │
                   ┌────────────┼────────────┐
                   │            │            │
                 approve    edit inline   request
                   │         (직접 수정)   AI revision
                   │            │            │
                   │            v            v
                   │      user edits    AI rewrites
                   │      04-script.md  + re-review
                   │            │            │
                   └────────────┴────────────┘
                                │
Phase 4                  Phase 5
┌─────────────┐        ┌─────────────┐
│ Storyboard  │───────>│ Upload Prep │──> User Briefing
│ (sonnet)    │        │ (sonnet)    │    + Obsidian save
└─────────────┘        └─────────────┘
```

## Output Structure

Save all artifacts to Obsidian vault:

```
VAULT={OBSIDIAN_VAULT}

01-Projects/youtube/inbox/{YYMMDD}-YT-{NN}-{kebab-topic}/
  00-reference-transcripts/    # ★ auto-scraped subtitles from reference videos
  01-success-analysis.md
  02-fact-check.md
  03-additional-research.md
  04-script.md
  05-review-log.md
  06-storyboard.md
  07-upload-package.md
  00-briefing.md
```

## Execution

### Phase 0: Init

Parse user input. Create output directory. Check for `tone-guide.md` and `reference-videos.md`.

**Transcript Scraping** (if reference videos exist):
1. Collect ★-marked URLs from `reference-videos.md` + any `reference_urls` from user input (max 5)
2. For each URL, run: `yt-dlp -o "OUTPUT_DIR/00-reference-transcripts/%(title)s.%(ext)s" "URL"`
   - Default config (`~/.config/yt-dlp/config`) already sets: `--skip-download --write-auto-sub --sub-lang ko,en --sub-format srt/best`
   - No additional flags needed
3. Read scraped `.srt` files, strip SRT timestamps (keep text only), pass to Success Analyst in Phase 1
4. If yt-dlp fails for a URL (no subtitles, private, etc.), log warning and continue
5. Token budget: truncate each transcript to first 3,000 chars (~10min of speech) if longer

### Phase 1: Research (3 agents, parallel, single message)

| Agent | Prompt | Type | Model | Output |
|-------|--------|------|-------|--------|
| Success Analyst | `references/agent-success-analyzer.md` | `oh-my-claudecode:researcher` | sonnet | Patterns, hooks, differentiation |
| Fact Checker | `references/agent-fact-checker.md` | `oh-my-claudecode:researcher` | sonnet | Verified facts with confidence grades |
| Info Researcher | general-purpose | sonnet | Background, cases, expert opinions, trends |

Save each result to Obsidian.

### Phase 2: Script Writing

Read `references/agent-script-writer.md`. Use `oh-my-claudecode:executor` with **opus**. Input: topic + all Phase 1 results + tone guide + target duration. Save to Obsidian.

### Phase 3: Review Loop (2 agents parallel, max 3 iterations)

Read `references/agent-script-reviewer.md`. Use `oh-my-claudecode:critic` with **opus**.

- **Reviewer A**: Viewer perspective (engagement, clarity, emotion)
- **Reviewer B**: Producer perspective (accuracy, structure, SEO)

Each scores 10 criteria x 10 points = 100. If average >= 90: PASS. If < 90: apply fixes, re-review. After 3 failures: ask user whether to proceed. Append all reviews to `05-review-log.md`.

### Phase 3.5: Human Review Gate

AI 리뷰를 통과한 대본을 사용자에게 제시하고 검토를 요청한다. **이 단계는 사용자 응답 없이 건너뛸 수 없다.**

**제시 형식:**

```
---
## Human Review: 대본 검토

AI 리뷰 점수: A={score_a}/100, B={score_b}/100 (avg {avg})

대본 파일: `{output_dir}/04-script.md`

아래에서 선택해주세요:

1. **승인** — 이대로 진행 (스토리보드 + 업로드 준비)
2. **직접 수정** — 대본 파일을 직접 수정 후 "수정 완료" 입력
3. **수정 요청** — 수정 사항을 텍스트로 전달 (AI가 반영 후 재검토)
---
```

**각 선택지 처리:**

1. **승인 (approve)**: Phase 4로 즉시 진행.

2. **직접 수정 (edit inline)**: 사용자가 `04-script.md`를 에디터에서 직접 수정. "수정 완료" 또는 "done"을 입력하면 수정된 파일을 읽어서 Phase 4로 진행. `05-review-log.md`에 "Human edit applied" 기록.

3. **수정 요청 (request AI revision)**: 사용자의 피드백을 Script Writer(opus)에 전달하여 대본 수정. 수정 후 **Phase 3 Review Loop를 1회 재실행** (avg >= 85면 PASS, 기존보다 낮은 기준). 재실행 후 다시 Human Review Gate로 돌아옴. 최대 2회 반복 후 강제 진행 여부를 사용자에게 확인.

**기록**: 모든 Human Review 선택과 피드백을 `05-review-log.md` 하단에 추가:

```markdown
## Human Review
- Decision: {approve|edit|revision}
- Feedback: {user's feedback if any}
- Timestamp: {ISO timestamp}
```

### Phase 4: Storyboard

Read `references/agent-storyboard.md`. Use `oh-my-claudecode:executor` with **sonnet**. Save to Obsidian.

### Phase 5: Upload Prep

Read `references/agent-upload-prep.md`. Use `oh-my-claudecode:executor` with **sonnet**. Save to Obsidian.

### Phase 6: Briefing

Summarize all phases to user. Save `00-briefing.md` with: research highlights, script stats, review scores, storyboard summary, upload recommendations, file paths, next-step checklist.

### Phase 7: Upload (optional)

Phase 6 (Briefing) 완료 후 사용자에게 업로드 여부를 확인한다.

```
영상 파일과 썸네일이 준비되면 업로드를 진행할까요?
1. 네 — youtube-uploader 스킬 실행
2. 아니오 — 업로드 체크리스트만 제공하고 종료
```

승인 시: `/youtube-uploader {OUTPUT_DIR}` 실행 (youtube-uploader 스킬의 Step 2부터).
미준비 시: `07-upload-package.md`의 Upload Checklist를 제시하고 종료.

## Model Selection

| Agent | Model | Rationale |
|-------|-------|-----------|
| Research (3) | sonnet | Web search + analysis, speed priority |
| Script Writer | opus | Creative writing, quality critical |
| Reviewers (2) | opus | Critical judgment required |
| Storyboard | sonnet | Structural transformation |
| Upload Prep | sonnet | SEO/metadata optimization |

## Extension Points

- `references/tone-guide.md` — Channel tone/style guide (user creates)
- `references/reference-videos.md` — Fixed reference video list by genre (user creates)
