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
**오늘 할일을 추천**한다. 데이터는 허브와 **활성 프로젝트**의 리멤버 시스템
(`.remember/`) + 자동 메모리(`MEMORY.md`)에서 가져온다 — 이미 다이제스트된
마크다운이므로 **메인 에이전트가 직접 Read로 읽으면 되고(소스당 2~3개 파일),
병렬 서브에이전트는 불필요**하다.

> **왜 활성 프로젝트까지 보나**: remember는 세션이 실행된 디렉터리의 `.remember/`에
> 기록된다. 허브(`chan99k-workspace/`)에서 연 세션은 허브 `.remember`만 보지만,
> 실제 코드 작업은 각 `projects/{name}/.remember/`에 흩어진다. 허브만 읽으면
> 프로젝트 작업이 통째로 누락된다.

> 출력 = (1) **리멤버에 상세 브리핑 원문 저장** (허브 `now.md` 상단) + (2)
> **대화창에 `Daily Check-in` 슬랙 메시지** (원문에서 파생). 상세 분석은 리멤버에
> 보존하고, 팀에 붙여넣을 짧은 체크인만 대화창에 띄운다.

## Paths (variables)

먼저 아래 변수를 해석한다. `$WORKSPACE`가 미설정이면 `$HOME/chan99k-workspace`로
기본값 처리한다. 자동 메모리 경로는 Claude Code 인코딩(경로 `/`→`-`)으로 계산한다.

**소스 집합 = 허브 `.remember` + 활성 프로젝트 `.remember`.** 활성 프로젝트는
manifest를 손으로 관리하지 않고 **mtime으로 자동 판정**한다: `projects/*/.remember/now.md`가
**최근 5일 내 수정된** 프로젝트만 채택한다(나머지 수십 개 stale 폴더는 자동 배제).

```bash
WORKSPACE="${WORKSPACE:-$HOME/chan99k-workspace}"
HUB_RD="$WORKSPACE/.remember"
MEM="$HOME/.claude/projects/$(echo "$WORKSPACE" | sed 's#/#-#g')/memory/MEMORY.md"

# 활성 프로젝트 .remember = now.md 가 최근 5일 내 수정된 것
ACTIVE_RDS=$(find "$WORKSPACE/projects" -maxdepth 3 -path '*/.remember/now.md' -mtime -5 2>/dev/null \
  | xargs -n1 dirname 2>/dev/null | sort)

echo "허브: $HUB_RD"
echo "활성 프로젝트:"; echo "$ACTIVE_RDS"
```

| 항목 | 경로 |
|------|------|
| 허브 리멤버 | `$HUB_RD` (`$WORKSPACE/.remember/`) |
| 활성 프로젝트 리멤버 | `$ACTIVE_RDS` (각 `projects/{name}/.remember/`) |
| 일일 로그 (소스별) | `{RD}/today-YYYY-MM-DD.done.md` |
| 현재 버퍼 (소스별) | `{RD}/now.md` |
| 7일 맥락 (소스별) | `{RD}/recent.md` |
| 자동 메모리 인덱스 | `$MEM` (1회만) |

> **윈도우 조정**: 잠깐 들른 프로젝트가 끌려오면 `-mtime -5`를 `-3`으로 좁힌다.
> 반대로 며칠 쉰 프로젝트도 보려면 넓힌다. manifest 파일은 두지 않는다(유지보수 부담).

## Procedure

### 1. 소스별 "어제" 파일 결정 (가장 최근 기록된 날)

허브 + 활성 프로젝트 **각 소스마다** 따로 어제 파일을 고른다. 오늘 날짜를 제외하고,
파일명 날짜 기준 가장 최근 일일 로그를 고른다(파일명이 `today-YYYY-MM-DD`라 lexical
sort = date sort). 소스마다 진척 날짜가 다를 수 있으므로 소스별로 계산해야 한다.

```bash
TODAY=$(date +%Y-%m-%d)
for RD in "$HUB_RD" $ACTIVE_RDS; do
  YDAY_FILE=$(ls "$RD"/today-*.done.md 2>/dev/null | sort | grep -v "today-$TODAY" | tail -1)
  echo "[$RD] 어제 로그: ${YDAY_FILE:-(없음)}"
done
```

소스에 `.done.md`가 하나도 없으면 그 소스는 `now.md`만으로 진행한다.

### 2. 소스 읽기 (Read 도구)

각 소스(`$HUB_RD` + `$ACTIVE_RDS`)에서 아래 3종을 읽는다. **소스별로 어느 프로젝트
것인지 라벨을 유지**한다(브리핑에서 그룹핑에 사용).

- `{RD}/today-...done.md` (= 그 소스의 `$YDAY_FILE`) — 어제 작업 타임라인 (핵심)
- `{RD}/now.md` — 직전 세션 버퍼 (마무리 안 된 흐름 / `Pending` 마커)
- `{RD}/recent.md` — 7일 연속성 맥락

그리고 `$MEM`을 **1회만** 읽는다 — `**NEXT 진입점**` / `**NEXT 세션 단일 entry-point**`
마커가 붙은 프로젝트 라인 = 오늘 할일 1순위 후보.

> 소스가 1(허브)+활성 N개라 파일 수가 늘어도 모두 다이제스트된 짧은 md다.
> **직접 Read로 충분**하며 병렬 서브에이전트는 여전히 불필요하다.

### 3. Things MCP (있으면 사용)

ToolSearch로 `things`를 로드한다. 실패하면 **조용히 건너뛴다**.
성공 시 `get_today`, `get_upcoming`을 호출해 스케줄된 할일을 추천에 합친다.

> **stale 가드**: `deadline`/`start_date`가 오늘보다 한참 과거인 항목은
> 오늘 할일로 추천하지 말고 브리핑에 "⚠️ 지난 Things 항목"으로만 플래그한다.
> (Things에 오래된 미완료 항목이 쌓여 있는 경우가 많다.)

### 4. 상세 브리핑 작성 (내부 원문)

먼저 아래 상세 형식으로 브리핑을 **작성한다** — 이것이 리멤버에 저장될 **원문**이다
(대화창에 그대로 띄우지 않는다; 6단계 체크인의 근거 자료). 추측 금지 — 소스에 있는
내용만 요약한다. **"어제 한 일"은 소스(프로젝트)별로 그룹핑**한다 — 허브와 활성
프로젝트가 섞이지 않게.

```markdown
## 🌅 Daily Briefing — {오늘}

### 어제 한 일
**{프로젝트명 / 허브}** (어제: {그 소스의 YDAY_DATE})
- {브랜치/이슈}: {1줄 요약}
- ...

**{다른 프로젝트}** (어제: {YDAY_DATE})
- ...

### 진행 중 · 미완료 흐름
- {소스}: {now.md / "Pending" 마커에서 발견된, 끝나지 않은 작업}

### 맥락 (연속성)
- {recent.md에서 오늘과 이어지는 흐름 1~2줄}

### 오늘 추천 할일
1. {미완료 흐름 마무리} — 근거: {소스/어제 로그}
2. {MEMORY.md NEXT 진입점} — 근거: {프로젝트명}
3. {Things 스케줄 / 선택}
```

추천은 **미완료 흐름 → MEMORY.md NEXT 진입점 → Things** 순으로 우선순위를 둔다.
사용자가 특정 프로젝트만 요청하면(예: "ops-console만") 해당 소스로 범위를 좁힌다.

### 5. 원문을 리멤버에 저장 (now.md)

4단계 상세 브리핑 **원문 전체**를 기본적으로 **허브 `$HUB_RD/now.md` 상단에** 아래
블록으로 prepend한다 (기존 타임스탬프 엔트리는 보존). 이미 같은 날짜의 `DAILY BRIEFING`
블록이 있으면 교체한다. 단, 특정 프로젝트로 범위를 좁혔으면 그 프로젝트의 `{RD}/now.md`에 기록한다.

```markdown
## 🌅 DAILY BRIEFING (원문) ({오늘})
{4단계 상세 브리핑 전문 — 어제 한 일(프로젝트별)/미완료/맥락/추천 할일}
```

> 리멤버 파이프라인이 이 블록을 그대로 다이제스트하므로 상세 분석이 보존된다.
> 대화창에는 띄우지 않는다.

### 6. 대화창에 Daily Check-in 출력 (슬랙 형식)

대화창에는 4단계 원문에서 **파생한 짧은 체크인 메시지**만 출력한다. 팀 슬랙에
그대로 붙여넣는 용도다. 매핑 규칙:

- `:dart: 오늘 집중할 업무` ← 4단계 **오늘 추천 할일** 상위 항목
- `:construction: Blocker / 도움 필요` ← **진행 중·미완료 흐름** 중 **외부 대기·논의
  필요·정보 부족** 항목 (본인 통제 밖 블로커). 없으면 "현재 없음"
- `:loudspeaker: 팀에 공유할 내용` ← 소스에 있는 **배포 예정·스키마 변경·일정** 등
  팀 영향 사항. 소스에 근거 없으면 항목을 비우고 `_(공유할 내용 입력)_` placeholder
- `:grinning: 오늘의 컨디션 (1~10)` ← **소스로 알 수 없음 → 추측 금지**, `_(직접 입력)_`로 남김

```markdown
:date: *Daily Check-in — {오늘}*

:grinning: *오늘의 컨디션 (1~10)*
_(직접 입력)_

:dart: *오늘 집중할 업무*
• {추천 할일 1}
• {추천 할일 2}
• {추천 할일 3}

:construction: *업무에 Blocker가 되는 것 / 도움이 필요한 부분*
• {외부 대기·정보 부족 항목} _(없으면 "현재 없음")_

:loudspeaker: *팀에 공유할 내용*
• {배포 예정·일정·스키마 변경 등 소스 근거 있는 것} _(없으면 "직접 입력")_
```

> 컨디션·개인 일정 등 **소스에 없는 칸은 지어내지 말고 placeholder로 비운다** —
> 사용자가 채울 자리다.

## Common Mistakes

| 실수 | 교정 |
|------|------|
| `date -v-1d`로 엄격히 어제만 봄 | 주말·공백일에 빈 브리핑. **가장 최근 로그된 날** 사용 |
| 5개 병렬 에이전트로 raw 파일 스캔 | 리멤버는 이미 다이제스트됨. 직접 Read로 충분 |
| 소스에 없는 할일 지어냄 | 미완료 흐름·NEXT 마커·Things 등 **출처 있는 항목만** 추천 |
| now.md 전체를 덮어씀 | 상단 prepend만. 기존 타임스탬프 엔트리 보존 |
| 상세 브리핑을 대화창에 그대로 띄움 | 대화창=Daily Check-in 짧은 형식. 상세 원문은 리멤버(now.md)에만 |
| 체크인 원문을 리멤버에 저장 안 함 | 4단계 원문을 `DAILY BRIEFING (원문)` 블록으로 반드시 저장 |
| 컨디션·개인 일정을 지어냄 | 소스에 없는 칸은 `_(직접 입력)_` placeholder로 비움 |
| Blocker 칸에 본인이 풀 수 있는 일 넣음 | 외부 대기·논의 필요·정보 부족 등 **본인 통제 밖**만 |
| Things 미설정 시 에러 노출 | ToolSearch 실패 시 조용히 건너뜀 |
| 지난 Things 항목을 오늘 할일로 추천 | deadline/start 과거 항목은 플래그만, 추천 제외 |
| 허브 `.remember`만 읽고 프로젝트 작업 누락 | 코드 작업은 `projects/{name}/.remember`에 쌓임. 활성 프로젝트도 소스로 포함 |
| `projects/*/.remember` 전체 스캔 (30+ stale 폴더) | `now.md` mtime 최근 5일 필터로 활성만 채택 |
| 어제 파일을 소스 전체에서 1개만 고름 | 소스마다 진척 날짜가 다름. **소스별로** `$YDAY_FILE` 계산 |
