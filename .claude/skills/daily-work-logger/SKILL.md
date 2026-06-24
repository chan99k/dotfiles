---
name: daily-work-logger
description: |
  Use when starting the day or a work session and you want a briefing of
  recent work plus recommended tasks for today. Reads the .remember system
  (today-*.done.md / now.md / recent.md) and MEMORY.md NEXT entry-points.
  Triggers: "어제 작업 브리핑", "오늘 할일 추천", "데일리 로그", "morning briefing",
  "daily standup", running /daily-work-logger.
---

# Daily Work Logger

## Overview

세션/업무 시작 시 **어제(가장 최근 기록된 날) 작업을 요약·맥락 브리핑**하고
**오늘 할일을 추천**한다. 데이터는 리멤버 시스템(`.remember/`)과 자동 메모리
(`MEMORY.md`)에서 가져온다 — 이미 다이제스트된 마크다운이므로 **메인 에이전트가
직접 2~3개 파일만 읽으면 되고, 병렬 서브에이전트는 불필요**하다.

> 출력 = (1) 대화창 브리핑 + (2) `now.md` 상단에 `TODAY PLAN` 블록 기록.

## Paths (variables)

먼저 아래 변수를 해석한다. `$WORKSPACE`가 미설정이면 `$HOME/chan99k-workspace`로
기본값 처리한다. 자동 메모리 경로는 Claude Code 인코딩(경로 `/`→`-`)으로 계산한다.

```bash
WORKSPACE="${WORKSPACE:-$HOME/chan99k-workspace}"
RD="$WORKSPACE/.remember"
MEM="$HOME/.claude/projects/$(echo "$WORKSPACE" | sed 's#/#-#g')/memory/MEMORY.md"
```

| 항목 | 경로 |
|------|------|
| 리멤버 디렉터리 | `$RD` (`$WORKSPACE/.remember/`) |
| 일일 로그 | `$RD/today-YYYY-MM-DD.done.md` |
| 현재 버퍼 | `$RD/now.md` |
| 7일 맥락 | `$RD/recent.md` |
| 자동 메모리 인덱스 | `$MEM` |

## Procedure

### 1. "어제" 파일 결정 (가장 최근 기록된 날)

오늘 날짜를 제외하고, 파일명 날짜 기준 가장 최근 일일 로그를 고른다.
파일명이 `today-YYYY-MM-DD`라 lexical sort = date sort이므로 한 줄로 해결된다.

```bash
WORKSPACE="${WORKSPACE:-$HOME/chan99k-workspace}"
RD="$WORKSPACE/.remember"
TODAY=$(date +%Y-%m-%d)
YDAY_FILE=$(ls "$RD"/today-*.done.md 2>/dev/null | sort | grep -v "today-$TODAY" | tail -1)
echo "어제 로그: $YDAY_FILE"
```

로그가 하나도 없으면 `now.md`만으로 진행하고, 브리핑에 "이전 일일 로그 없음"을 명시한다.

### 2. 소스 읽기 (Read 도구)

- `$YDAY_FILE` — 어제 작업 타임라인 (핵심)
- `$RD/now.md` — 직전 세션 버퍼 (마무리 안 된 흐름 / `Pending` 마커)
- `$RD/recent.md` — 7일 연속성 맥락
- `$MEM` — `**NEXT 진입점**` / `**NEXT 세션 단일 entry-point**` 마커가 붙은
  프로젝트 라인 = 오늘 할일 1순위 후보

### 3. Things MCP (있으면 사용)

ToolSearch로 `things`를 로드한다. 실패하면 **조용히 건너뛴다**.
성공 시 `get_today`, `get_upcoming`을 호출해 스케줄된 할일을 추천에 합친다.

> **stale 가드**: `deadline`/`start_date`가 오늘보다 한참 과거인 항목은
> 오늘 할일로 추천하지 말고 브리핑에 "⚠️ 지난 Things 항목"으로만 플래그한다.
> (Things에 오래된 미완료 항목이 쌓여 있는 경우가 많다.)

### 4. 브리핑 작성 (대화창)

아래 형식으로 출력한다. 추측 금지 — 소스에 있는 내용만 요약한다.

```markdown
## 🌅 Daily Briefing — {오늘} (어제: {YDAY_DATE})

### 어제 한 일
- {프로젝트/브랜치}: {1줄 요약}
- ...

### 진행 중 · 미완료 흐름
- {now.md / "Pending" 마커에서 발견된, 끝나지 않은 작업}

### 맥락 (연속성)
- {recent.md에서 오늘과 이어지는 흐름 1~2줄}

### 오늘 추천 할일
1. {미완료 흐름 마무리} — 근거: {어제 로그}
2. {MEMORY.md NEXT 진입점} — 근거: {프로젝트명}
3. {Things 스케줄 / 선택}
```

추천은 **미완료 흐름 → MEMORY.md NEXT 진입점 → Things** 순으로 우선순위를 둔다.

### 5. now.md에 TODAY PLAN 기록

`now.md` **상단에** 다음 블록을 prepend한다 (기존 타임스탬프 엔트리는 보존).
이미 같은 날짜의 `TODAY PLAN` 블록이 있으면 교체한다.

```markdown
## 🌅 TODAY PLAN ({오늘})
- [ ] {추천 할일 1}
- [ ] {추천 할일 2}
- [ ] {추천 할일 3}

```

## Common Mistakes

| 실수 | 교정 |
|------|------|
| `date -v-1d`로 엄격히 어제만 봄 | 주말·공백일에 빈 브리핑. **가장 최근 로그된 날** 사용 |
| 5개 병렬 에이전트로 raw 파일 스캔 | 리멤버는 이미 다이제스트됨. 직접 Read로 충분 |
| 소스에 없는 할일 지어냄 | 미완료 흐름·NEXT 마커·Things 등 **출처 있는 항목만** 추천 |
| now.md 전체를 덮어씀 | 상단 prepend만. 기존 타임스탬프 엔트리 보존 |
| Things 미설정 시 에러 노출 | ToolSearch 실패 시 조용히 건너뜀 |
| 지난 Things 항목을 오늘 할일로 추천 | deadline/start 과거 항목은 플래그만, 추천 제외 |
