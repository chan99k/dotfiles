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

여기에 로컬 실행에서는 **클라우드 소스(Calendar·Gmail·Linear·GitHub)** 까지 얹어
"모닝 브리프"로 확장한다(3.5단계, 커넥터 있을 때만·읽기 전용). 클라우드 소스는
프로젝트 횡단 정보라 **허브 섹션·허브 채널에만** 담는다.

> **왜 활성 프로젝트까지 보나**: remember는 세션이 실행된 디렉터리의 `.remember/`에
> 기록된다. 허브(`chan99k-workspace/`)에서 연 세션은 허브 `.remember`만 보지만,
> 실제 코드 작업은 각 `projects/{name}/.remember/`에 흩어진다. 허브만 읽으면
> 프로젝트 작업이 통째로 누락된다.

> 출력 = (1) **리멤버에 상세 브리핑 원문 저장** (허브 `now.md` 상단) + (2)
> **대화창에 `Daily Check-in` 슬랙 메시지** (원문에서 파생) + (3) Hermes 봇 토큰이
> 있으면 **개인 슬랙 워크스페이스로 자동 전송**(주제별 전용 채널, 매일 새 스레드). 상세 분석은
> 리멤버에 보존하고, 팀에 붙여넣을 짧은 체크인만 대화창에 띄우며, 같은 체크인을
> 본인 슬랙으로도 보낸다.

## Slack 전송 설정 (Hermes 봇 토큰 재활용)

체크인은 **기존 Hermes 슬랙 봇 토큰을 재활용**해 전송한다. Hermes는 이미 개인
워크스페이스(`chan99k's personal`)에 봇(maia)으로 연결돼 있으므로, **새 슬랙 앱이나
webhook을 만들 필요가 없다**. 봇 토큰은 `chat.postMessage` API로 봇이 들어가 있는
어느 채널에든 보낼 수 있어 webhook보다 유연하다.

- **토큰 출처**: `~/.hermes/.env`의 `SLACK_BOT_TOKEN`(xoxb) — 변수로만 읽고 **절대
  로그·대화창·커밋에 노출하지 않는다**. 보여줄 땐 끝 4자리만.
- **채널 라우팅 (주제별 전용 채널)**: 소스(주제)마다 **전용 채널**로 보낸다. 매핑은
  `~/.config/daily-work-logger/channels/{key}` 파일에 채널 ID를 한 줄로 둔다.
  `{key}` = 소스 식별자(허브=`hub`, 프로젝트=`.remember` 상위 디렉터리명).
  - **폴백**: `{key}` 매핑 파일이 없으면 **기본 채널**로 보낸다. 기본 채널은
    `~/.config/daily-work-logger/slack-channel`(있으면) → `~/.hermes/.env`의
    `SLACK_HOME_CHANNEL` → `#hermes`(`C0B83FWAC13`) 순으로 해석한다.
  - **봇 초대 필수**: 봇(maia)은 자신이 멤버인 채널에만 쓸 수 있다. 새 전용 채널마다
    `/invite @maia` 하지 않으면 `not_in_channel`로 실패한다(전송 실패는 graceful, 대화창 출력은 정상).
- **워크스페이스 보장**: Hermes 봇은 개인 워크스페이스에만 설치돼 있어 회사로 갈 수
  없다 — 이것이 "회사 말고 개인" 보장 메커니즘이다(필요 시 `auth.test`로 team 확인).

> **매일 새 스레드 (영속 스레드 재사용 안 함)**: 각 소스는 매일 그 소스의 전용 채널에
> **top-level 메시지 1개**를 새로 올린다(하루 1개). 이 메시지 자체가 그날의 새 스레드
> root가 되며, 필요하면 거기에 reply로 토의할 수 있다. **어제 메시지에 이어 붙이지
> 않는다** — `threads/{key}` ts 재사용 로직은 쓰지 않는다(채널 타임라인이 날짜순으로
> 자연 정렬된다).

> **봇 토큰은 비밀이다.** Hermes의 자격증명을 재활용하므로 토큰 회전·재설치 시
> 끊길 수 있다 — 전송 실패는 graceful하게 처리하고(대화창 출력은 정상), 토큰 전문은
> 어떤 경우에도 출력하지 않는다.

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
| 일일 로그 (소스별) | `{RD}/today-YYYY-MM-DD-sN.done.md` (세션별 분리, N=1,2,3...) |
| 현재 버퍼 (소스별) | `{RD}/now.md` |
| 7일 맥락 (소스별) | `{RD}/recent.md` |
| 자동 메모리 인덱스 | `$MEM` (1회만) |

> **윈도우 조정**: 잠깐 들른 프로젝트가 끌려오면 `-mtime -5`를 `-3`으로 좁힌다.
> 반대로 며칠 쉰 프로젝트도 보려면 넓힌다. manifest 파일은 두지 않는다(유지보수 부담).

## Procedure

### 1. 소스별 "어제" 파일 결정 (가장 최근 기록된 날, 세션별 복수 파일)

허브 + 활성 프로젝트 **각 소스마다** 따로 어제 파일을 고른다. 오늘 날짜를 제외하고,
파일명에서 날짜를 추출해 가장 최근 날짜의 **모든 세션 파일**을 수집한다.
소스마다 진척 날짜가 다를 수 있으므로 소스별로 계산해야 한다.

```bash
TODAY=$(date +%Y-%m-%d)
for RD in "$HUB_RD" $ACTIVE_RDS; do
  # 가장 최근 날짜 추출 (오늘 제외). 레거시(접미사 없음) + 세션별(-sN) 모두 매칭
  YDAY_DATE=$(ls "$RD"/today-*.done.md 2>/dev/null \
    | sed 's/.*today-\([0-9-]*\).*/\1/' | sort -u | grep -v "$TODAY" | tail -1)
  # 해당 날짜의 모든 세션 파일 수집
  YDAY_FILES=$(ls "$RD"/today-${YDAY_DATE}*.done.md 2>/dev/null | sort)
  echo "[$RD] 어제($YDAY_DATE): $(echo "$YDAY_FILES" | wc -l | tr -d ' ')개 세션"
done
```

> **하위 호환**: `today-YYYY-MM-DD.done.md` (접미사 없음, 레거시)도 glob에 포함된다.
> 패턴 `today-{DATE}*.done.md`로 양쪽 모두 매칭.

소스에 `.done.md`가 하나도 없으면 그 소스는 `now.md`만으로 진행한다.

### 2. 소스 읽기 (Read 도구)

각 소스(`$HUB_RD` + `$ACTIVE_RDS`)에서 아래 3종을 읽는다. **소스별로 어느 프로젝트
것인지 라벨을 유지**한다(브리핑에서 그룹핑에 사용).

- `{RD}/today-{DATE}-s*.done.md` (= 그 소스의 `$YDAY_FILES`, 복수) — 어제 작업 타임라인 (핵심, **세션별로 전부 읽는다**)
- `{RD}/now.md` — 직전 세션 버퍼 (마무리 안 된 흐름 / `Pending` 마커)
- `{RD}/recent.md` — 7일 연속성 맥락

그리고 `$MEM`을 **1회만** 읽는다 — `**NEXT 진입점**` / `**NEXT 세션 단일 entry-point**`
마커가 붙은 프로젝트 라인 = 오늘 할일 1순위 후보.

> 소스가 1(허브)+활성 N개라 파일 수가 늘어도 모두 다이제스트된 짧은 md다.
> **직접 Read로 충분**하며 병렬 서브에이전트는 여전히 불필요하다.

### 3. ZenNotes task (있으면 사용)

ToolSearch로 `mcp__zennotes__list_tasks`를 로드한다. 실패하면 **조용히 건너뛴다**.
성공 시 `status:"open"`으로 열린 task를 가져와 스케줄된 할일을 추천에 합친다.
마감 임박만 보려면 `dueBefore`(오늘+3일)로 좁힌다.

> **stale 가드**: `due`(마감)가 오늘보다 한참 과거인 항목은 오늘 할일로 추천하지 말고
> 브리핑에 "⚠️ 지난 task" 로만 플래그한다. `@waiting` 태그가 붙은 task는 외부 대기
> 항목이므로 6단계 체크인의 **Blocker** 후보로 분류한다.

### 3.5 클라우드 소스 수집 (모닝 브리프 확장, 커넥터 있으면)

로컬 실행에서는 클라우드 커넥터로 **오늘의 외부 일정·마감·리뷰**까지 끌어와 브리프를
넓힌다. 각 소스는 ToolSearch로 도구를 로드하고, **로드 실패 시 조용히 건너뛴다**
(Things 가드와 동일 — 커넥터 미연결/미인증이면 그 섹션만 비우고 진행). **모두 읽기
전용** — 메일 전송, 일정·이슈 생성/수정은 절대 하지 않는다.

이 소스들은 **프로젝트 횡단(cross-cutting)** 정보이므로 **허브(hub) 섹션에만** 담는다
(프로젝트별 섹션에 중복하지 않는다).

- **Google Calendar** (`mcp__claude_ai_Google_Calendar__list_events`): 오늘(로컬 기준)
  이벤트를 시간순으로. 앞으로 3일 내 "마감/제출/데드라인/지원" 성격 이벤트는 마감 후보로.
- **Gmail** (`mcp__claude_ai_Gmail__search_threads` → `get_message`): 최근 24~48h 중
  **채용·면접·과제 제출·프로젝트** 관련 액션/마감만. 홍보·뉴스레터는 제외. 본문 전체를
  덤프하지 말고 "무엇을/언제까지" 한 줄로 요약.
- **Linear** (`mcp__plugin_linear_linear__*` 또는 `mcp__claude_ai_Linear__*`, 인증되면):
  오늘 나에게 할당됐거나 마감 임박한 이슈.
- **GitHub** (`gh` CLI가 있으면 `Bash`로): 내 리뷰 대기 PR과 내가 연 PR의 상태
  (변경 요청·CI 실패). 예: `gh search prs --review-requested=@me --state=open`,
  `gh search prs --author=@me --state=open`.

> **개인정보/스코프**: 위 소스에서 얻은 내용은 브리프에만 쓴다. Gmail 원문·URL을
> 그대로 옮기지 말고 요약한다. 접근 불가한 소스는 지어내지 말고 비운다.

### 4. 상세 브리핑 작성 (내부 원문)

먼저 아래 상세 형식으로 브리핑을 **작성한다** — 이것이 리멤버에 저장될 **원문**이다
(대화창에 그대로 띄우지 않는다; 6단계 체크인의 근거 자료). 추측 금지 — 소스에 있는
내용만 요약한다. **"어제 한 일"은 소스(프로젝트)별로 그룹핑**한다 — 허브와 활성
프로젝트가 섞이지 않게.

```markdown
## Daily Briefing — {오늘}

### 어제 한 일
**{프로젝트명 / 허브}** (어제: {그 소스의 YDAY_DATE}, {N}개 세션)
- {브랜치/이슈}: {1줄 요약} (s1에서)
- {다른 작업}: {1줄 요약} (s2에서)
- ...

**{다른 프로젝트}** (어제: {YDAY_DATE}, {N}개 세션)
- ...

### 진행 중 · 미완료 흐름
- {소스}: {now.md / "Pending" 마커에서 발견된, 끝나지 않은 작업}

### 맥락 (연속성)
- {recent.md에서 오늘과 이어지는 흐름 1~2줄}

### 오늘 일정·마감·리뷰 (허브 · 클라우드 소스, 3.5단계)
- **오늘 일정**: {Calendar 오늘 이벤트, 시간순} _(없으면 생략)_
- **마감 임박**: {채용 지원·과제 제출·프로젝트 마감, "무엇/언제까지"} _(없으면 생략)_
- **이메일 액션**: {Gmail 채용·프로젝트 액션 아이템 요약} _(없으면 생략)_
- **Linear**: {오늘 할당/마감 이슈} _(없으면 생략)_
- **GitHub**: {리뷰 대기 PR / 내 PR 상태} _(없으면 생략)_

### 오늘 추천 할일
1. {미완료 흐름 마무리} — 근거: {소스/어제 로그}
2. {오늘 마감·일정} — 근거: {Calendar/Gmail} (마감 임박 최우선)
3. {MEMORY.md NEXT 진입점} — 근거: {프로젝트명}
4. {ZenNotes task 스케줄 / 선택}
```

추천은 **오늘 마감 → 미완료 흐름 → MEMORY.md NEXT 진입점 → ZenNotes task** 순으로 우선순위를 둔다.
사용자가 특정 프로젝트만 요청하면(예: "ops-console만") 해당 소스로 범위를 좁힌다.

### 5. 원문을 리멤버에 저장 (now.md)

4단계 상세 브리핑 **원문 전체**를 기본적으로 **허브 `$HUB_RD/now.md` 상단에** 아래
블록으로 prepend한다 (기존 타임스탬프 엔트리는 보존). 이미 같은 날짜의 `DAILY BRIEFING`
블록이 있으면 교체한다. 단, 특정 프로젝트로 범위를 좁혔으면 그 프로젝트의 `{RD}/now.md`에 기록한다.

```markdown
## DAILY BRIEFING (원문) ({오늘})
{4단계 상세 브리핑 전문 — 어제 한 일(프로젝트별)/미완료/맥락/추천 할일}
```

> 리멤버 파이프라인이 이 블록을 그대로 다이제스트하므로 상세 분석이 보존된다.
> 대화창에는 띄우지 않는다.

### 6. 대화창에 Daily Check-in 출력 (슬랙 형식)

대화창에는 4단계 원문에서 **파생한 짧은 체크인 메시지**를 출력한다. 팀 슬랙에
그대로 붙여넣는 용도이자 7단계 자동 전송의 본문이다.

> **소스별 체크인 (프로젝트별 채널 라우팅)**: 활성 소스가 여럿이면(허브 + 프로젝트
> N개) **소스(프로젝트)마다 별도 체크인을 1건씩** 생성한다 — 각 메시지는 그 소스의
> 항목만 담는다(`[오늘 집중]`/`[Blocker]`/`[팀 공유]`를 해당 소스로 스코프). 7단계가
> 이 메시지들을 **각 프로젝트 채널로 따로** 보내기 때문이다. `[컨디션]`은
> 개인 단일 값이므로 각 메시지에 동일하게 포함하되 placeholder로 둔다(채널마다 청중이
> 다르므로 반복은 자연스럽다). 메시지 제목에 `— {프로젝트명}`을 붙여 어느 소스인지 표시한다.
>
> 단일 소스이거나 사용자가 특정 프로젝트로 범위를 좁혔으면 그 소스 1건만 만든다.
> 대화창에는 생성한 소스별 체크인을 모두 보여줘 사용자가 무엇이 전송되는지 확인하게 한다.

> **개인 식별자 금지 (outward 산출물 규칙)**: 체크인은 팀 슬랙으로 나가는 outward
> 산출물이다. 개인 트래커(Linear) 식별자와 개인 메모/핸드오프 참조를 **넣지 않는다**.
>
> **판별은 URL 도메인으로 한다 — 접두사가 아니라.** 소스에 식별자가 어떤 URL로
> 링크돼 있는지 보고 분류한다:
> - `*.atlassian.net` (Jira) → **팀 SSOT, 허용**. 그대로 쓴다.
> - `*.linear.app` (Linear) → **개인 트래커, 제거**. outward 텍스트에서 뺀다.
> - 도메인 단서가 없으면 접두사를 **보조 힌트**로만 쓴다(`KAN-` 계열 = Jira 추정,
>   `99K-`/기타 워크스페이스 prefix = Linear 추정). 확신이 없으면 **번호 없이 설명만** 쓴다.
>
> 4단계 원문에서 항목을 파생할 때 붙어 있던 Linear 식별자는 **반드시 제거**한다.
> Jira 매핑을 알면 `KAN-N`(필요 시 `(Linear-id)` 괄호 보조)을, 모르면 번호 없이 설명만.
> 원문(`now.md`)에는 추적용으로 Linear 식별자를 남겨도 된다 — 제거는 대화창 체크인에만 적용.

매핑 규칙 (이모지 없음 / 헤더 = 블록쿼트 볼드이탤릭, 풀 텍스트):

- `오늘 집중할 업무` ← 4단계 **오늘 추천 할일** 상위 항목
- `업무에 Blocker가 되는 것 / 도움이 필요한 부분` ← **진행 중·미완료 흐름** 중 **외부
  대기·논의 필요·정보 부족** 항목 (본인 통제 밖 블로커). 없으면 "현재 없음"
- `팀에 공유할 내용` ← 소스에 있는 **배포 예정·스키마 변경·일정** 등 팀 영향 사항.
  소스에 근거 없으면 항목을 비우고 `_(공유할 내용 입력)_` placeholder
- `오늘의 컨디션 (1~10)` ← **소스로 알 수 없음 → 추측 금지**, `_(직접 입력)_`로 남김

> **서식 규칙 (이모지 금지, Block Kit 구분선)**: 사용자는 이모지를 선호하지 않는다.
> 어디에도 `:emoji:`/유니코드 이모지를 쓰지 않는다. 섹션 사이는 **Block Kit divider
> 블록(진짜 가로선)** 으로 나눈다 — 슬랙 일반 텍스트엔 구분선 문법이 없어 7단계에서
> `blocks` 배열로 전송한다.
> - **제목**: 부분마다 인라인 코드 칩 + ` : ` 구분 — `` `Daily Check-in` : `{오늘}` : `{프로젝트명/허브}` ``
> - **섹션 헤더**: 블록쿼트 + 볼드이탤릭 — `> *_헤더 문구_*` (왼쪽 회색 바 + 강조). 풀 텍스트
> - **본문**: 일반 불릿 `•`
> - **섹션 구분**: 체크인 본문은 섹션마다 한 줄 `===` 구분자로 작성한다(아래). 7단계가
>   이 `===`로 split해 각 조각을 section 블록으로, 사이마다 divider 블록을 넣는다.
>
> **예외 — `ops-console` 소스는 팀 표준 템플릿을 따른다** (아래 "ops-console 전용
> 형식" 참조). 이 회사 프로젝트는 팀 데일리 체크인 워크플로우 형식이 별도로 정해져
> 있어, 위의 "이모지 금지·블록쿼트 헤더·불릿" 규칙 **대신** 이모지 헤더 + 평문 줄바꿈을
> 쓴다. 다른 소스(`hub`/`affinix`/`chan99k-blog` 등)는 위 표준 규칙 그대로.

체크인 본문은 아래처럼 **`===` 로 섹션을 구분**해 임시 파일에 저장한다(수동 구분선
`──────` 는 넣지 않는다 — divider가 대신한다):

```text
`Daily Check-in` : `{오늘}` : `{프로젝트명/허브}`
===
> *_오늘의 컨디션 (1~10)_*
_(직접 입력)_
===
> *_오늘 집중할 업무_*
• {이 소스의 추천 할일 1}
• {이 소스의 추천 할일 2}
===
> *_업무에 Blocker가 되는 것 / 도움이 필요한 부분_*
• {이 소스의 외부 대기·정보 부족 항목} _(없으면 "현재 없음")_
===
> *_팀에 공유할 내용_*
• {이 소스의 배포 예정·일정·스키마 변경 등 근거 있는 것} _(없으면 "직접 입력")_
```

#### ops-console 전용 형식 (팀 표준 템플릿)

`ops-console` 소스는 위 표준 대신 **팀 데일리 체크인 템플릿**으로 만든다. 섹션 헤더는
**이모지 shortcode + 헤더 문구**, 본문은 **불릿 없는 평문 줄바꿈**이다(마크다운 서식은
사용자가 붙여넣은 뒤 직접 처리하므로 스킬은 순수 텍스트만 낸다). 내부 `===` 구분자는
그대로 유지한다 — 7단계 Block Kit 전송(기록용)이 이 `===`로 섹션을 나누기 때문이다.
대화창에는 `===`를 **빈 줄**로 바꿔 팀 슬랙에 곧바로 붙여넣을 수 있는 평문으로 보여준다
(`──────` 가로선을 넣지 않는다).

```text
:date: Daily Check-in
===
:grinning: 오늘의 컨디션 (1~10)
(직접 입력)
===
:dart: 오늘 집중할 업무
{이 소스의 오늘 할일 1 — PR/이슈 번호는 GitHub #N 그대로}
{이 소스의 오늘 할일 2}
===
:construction: 업무에 Blocker가 되는 것 / 도움이 필요한 부분
{외부 대기·논의 필요 항목 / 없으면 "특이사항 없음"}
===
:loudspeaker: 팀에 공유할 내용
{배포 예정·일정·충돌 상태 등 팀 영향 사항 / 없으면 "특이사항 없음"}
```

> - **이모지 헤더는 5개 고정**(`:date:` 제목 + `:grinning:`/`:dart:`/`:construction:`/`:loudspeaker:`),
>   문구도 위와 정확히 동일하게 쓴다(팀 워크플로우와 일치해야 편집이 0에 수렴).
> - **오늘 집중할 업무** ← ops-console의 미완료 흐름·PR/이슈 상태·NEXT 마커에서 파생.
>   각 항목을 **한 줄씩** 나열한다. 세부 사유·중첩은 사용자가 직접 덧붙일 자리이므로
>   스킬은 소스 근거가 있는 상위 항목만 평문 줄로 낸다(지어내지 않는다).
> - **빈 섹션**은 `특이사항 없음`으로 채운다(placeholder `_(...)_` 쓰지 않는다 —
>   팀 템플릿은 그렇게 안 쓴다). 컨디션만 `(직접 입력)`.
> - GitHub `#N`은 팀 SSOT라 그대로 쓴다. Linear 식별자는 outward 규칙대로 제거.

> **허브 체크인 = 클라우드 섹션 추가 (모닝 브리프)**: `hub` 소스의 체크인에는 위 4개
> 섹션 뒤에 3.5단계에서 수집한 **클라우드 섹션**을 `===`로 이어 붙인다(내용 있는 것만,
> 빈 섹션은 생략). 프로젝트 소스 체크인에는 붙이지 않는다.
>
> ```text
> ===
> > *_오늘 일정_*
> • {Calendar 오늘 이벤트, 시간순}
> ===
> > *_마감 임박_*
> • {채용 지원·과제·프로젝트 마감 — 무엇/언제까지}
> ===
> > *_이메일 액션_*
> • {Gmail 채용·프로젝트 액션 아이템}
> ===
> > *_Linear / GitHub_*
> • {오늘 할당·마감 이슈 / 리뷰 대기 PR·내 PR 상태}
> ```

> 대화창 출력 시에는 `===`를 `──────` 가로선으로 바꿔 보여줘 사용자가 최종 모양을
> 가늠하게 한다(슬랙 전송본은 7단계에서 divider로 렌더). 단일 소스(또는 범위 좁힘)
> 모드에서는 제목의 세 번째 칩 `` `{프로젝트명/허브}` `` 을 생략해도 된다.
>
> **단, `ops-console`는 예외**: 대화창에도 `===`를 **빈 줄**로만 바꿔 (가로선 없이)
> 팀 슬랙 붙여넣기용 평문으로 그대로 보여준다. 전송본(7단계)만 Block Kit divider로 렌더.

> 컨디션·개인 일정 등 **소스에 없는 칸은 지어내지 말고 placeholder로 비운다** —
> 사용자가 채울 자리다.

### 7. 개인 슬랙으로 자동 전송 — Hermes 봇 + 주제별 채널, 매일 새 스레드 (토큰 있으면)

6단계에서 만든 **소스별 체크인**(`===` 구분)을 Hermes 봇 토큰으로 **그 소스의 전용
채널**에 자동 전송한다(전송 게이트: 자동, 확인 없이 보냄). 개인 식별자 금지 규칙(Linear
제거)은 6단계에서 **이미 적용된** 텍스트를 보낸다. 섹션 사이 구분선을 위해 `text`가
아니라 **Block Kit `blocks`(section + divider)** 로 전송한다.

토큰이 없거나(`~/.hermes/.env` 부재) `jq` 미설치면 **조용히 건너뛰고** 대화창 출력만
한다(Things 가드와 동일 — 에러·토큰 노출 금지).

소스마다: (1) 6단계 체크인(`===` 구분)을 임시 파일에 쓰고 (2) `{key}` → 전용 채널 해석
(매핑 없으면 기본 채널) (3) 본문을 `===`로 split → section 블록 + 사이 divider 블록으로
빌드 (4) 그 채널에 **top-level 메시지 1개**로 전송한다(매일 새 스레드 — thread_ts 없음,
어제 메시지에 이어 붙이지 않는다).

```bash
HERMES_ENV="$HOME/.hermes/.env"
[ -f "$HERMES_ENV" ] || { echo "(Hermes 미설치 — 슬랙 전송 건너뜀, 대화창 출력은 정상)"; return 2>/dev/null; }
set -a; . "$HERMES_ENV"; set +a            # SLACK_BOT_TOKEN, SLACK_HOME_CHANNEL 로드

CFG="$HOME/.config/daily-work-logger"
CHANNELS="$CFG/channels"                    # channels/{key} = 그 소스 전용 채널 ID (한 줄)
DEFAULT_CHANNEL=$([ -s "$CFG/slack-channel" ] && head -1 "$CFG/slack-channel" || echo "${SLACK_HOME_CHANNEL:-C0B83FWAC13}")
API="https://slack.com/api/chat.postMessage"

resolve_channel() {  # $1=key → 전용 채널 ID. 매핑 파일 없으면 기본 채널로 폴백
  local f="$CHANNELS/$1"
  [ -s "$f" ] && head -1 "$f" || printf '%s' "$DEFAULT_CHANNEL"
}

post() {  # $1=JSON payload(file) → 응답 JSON(stdout). 토큰은 헤더로만, echo 금지
  curl -s -X POST "$API" \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    -H 'Content-type: application/json; charset=utf-8' \
    --data @"$1"
}

# 체크인 본문(=== 구분) → Block Kit blocks 배열(section + 사이 divider)
# - 불릿(`• `) 줄은 NBSP 4칸 들여쓰기(슬랙은 일반 선행 공백을 줄임 → NBSP 사용)
# - 각 섹션 끝(마지막 제외)에 NBSP 빈 줄 1개 → divider 앞 여백
build_blocks() {  # stdin = 체크인 본문 → blocks JSON(stdout)
  jq -Rs '
    def indent: split("\n")
      | map(if startswith("• ") then "    " + . else . end)
      | join("\n");
    split("\n===\n")
    | map(gsub("^[\\s]+|[\\s]+$";"") | indent)
    | . as $s
    | [ range(0; ($s|length)) as $i
        | $s[$i] + (if $i < ($s|length-1) then "\n " else "" end) ]
    | map({type:"section", text:{type:"mrkdwn", text:.}})
    | reduce .[1:][] as $b ([.[0]]; . + [{type:"divider"}, $b])'
}

send_checkin() {  # $1=key(hub|프로젝트명)  $2=CHECKIN_FILE(=== 구분)  $3=표시명
  local channel payload resp blocks
  channel=$(resolve_channel "$1")          # 매일 새 top-level 메시지 (thread_ts 없음)
  blocks=$(build_blocks < "$2")
  payload=/tmp/dwl-msg-$1.json
  jq -n --arg ch "$channel" --arg fb "Daily Check-in $3" --argjson bl "$blocks" \
    '{channel:$ch, text:$fb, blocks:$bl}' > "$payload"
  resp=$(post "$payload")
  if [ "$(printf '%s' "$resp" | jq -r '.ok')" = "true" ]; then
    echo "[$1] $channel 전송됨 (새 스레드)"
  else
    echo "[$1] 전송 실패: $(printf '%s' "$resp" | jq -r '.error // "unknown"') (대화창 출력은 정상)"
  fi
  rm -f "$2" "$payload"
}

# 소스별로 반복 (예시)
# send_checkin hub         /tmp/checkin-hub.txt         "허브"
# send_checkin ops-console /tmp/checkin-ops-console.txt "ops-console"
```

> **blocks 빌드**: 체크인은 `===` 로 섹션을 나눠 저장하고 `build_blocks`가 section+divider로
> 변환한다. `text` 필드는 알림(notification) fallback용으로 짧게 넣는다(렌더는 blocks가 담당).
> **토큰**: `SLACK_BOT_TOKEN`은 `Authorization` 헤더로만, 어떤 경우에도 출력 금지.
> **독립성**: 한 소스 실패가 나머지를 막지 않는다 — 소스별 호출, 결과만 모은다.
> **채널 라우팅**: `channels/{key}` 있으면 그 채널로, 없으면 `DEFAULT_CHANNEL`로. 봇이
> 그 채널 멤버가 아니면 `not_in_channel` — graceful 처리하고 `/invite @maia` 안내.
> **매일 새 스레드**: `thread_ts`를 붙이지 않으므로 매 실행이 채널에 새 top-level
> 메시지를 만든다. `threads/{key}` ts 저장·재사용은 하지 않는다.

## Common Mistakes

| 실수 | 교정 |
|------|------|
| `date -v-1d`로 엄격히 어제만 봄 | 주말·공백일에 빈 브리핑. **가장 최근 로그된 날** 사용 |
| 5개 병렬 에이전트로 raw 파일 스캔 | 리멤버는 이미 다이제스트됨. 직접 Read로 충분 |
| 소스에 없는 할일 지어냄 | 미완료 흐름·NEXT 마커·ZenNotes task 등 **출처 있는 항목만** 추천 |
| now.md 전체를 덮어씀 | 상단 prepend만. 기존 타임스탬프 엔트리 보존 |
| 상세 브리핑을 대화창에 그대로 띄움 | 대화창=Daily Check-in 짧은 형식. 상세 원문은 리멤버(now.md)에만 |
| 체크인 원문을 리멤버에 저장 안 함 | 4단계 원문을 `DAILY BRIEFING (원문)` 블록으로 반드시 저장 |
| 컨디션·개인 일정을 지어냄 | 소스에 없는 칸은 `_(직접 입력)_` placeholder로 비움 |
| Blocker 칸에 본인이 풀 수 있는 일 넣음 | 외부 대기·논의 필요·정보 부족 등 **본인 통제 밖**만 |
| ZenNotes task 조회 실패 시 에러 노출 | ToolSearch/`list_tasks` 실패 시 조용히 건너뜀 |
| 지난 task 항목을 오늘 할일로 추천 | `due` 과거 항목은 플래그만, 추천 제외. `@waiting`은 Blocker 후보 |
| 허브 `.remember`만 읽고 프로젝트 작업 누락 | 코드 작업은 `projects/{name}/.remember`에 쌓임. 활성 프로젝트도 소스로 포함 |
| `projects/*/.remember` 전체 스캔 (30+ stale 폴더) | `now.md` mtime 최근 5일 필터로 활성만 채택 |
| 어제 파일을 소스 전체에서 1개만 고름 | 소스마다 진척 날짜가 다름. **소스별로** `$YDAY_FILES` 계산 |
| 같은 날짜의 세션 파일 중 마지막만 읽음 | 해당 날짜의 **모든** 세션 파일(`-s1`, `-s2`, ...)을 읽어야 전체 맥락 확보 |
| 레거시 파일(접미사 없음) 무시 | `today-{DATE}*.done.md` 패턴으로 레거시도 포함 |
| 체크인에 개인 Linear 식별자 노출 | outward엔 개인 트래커 금지. 판별은 URL 도메인으로(`atlassian.net`=Jira 허용 / `linear.app`=Linear 제거), 접두사는 보조 힌트. 모르면 설명만. 원문엔 남겨도 됨 |
| 봇 토큰을 로그·대화창·커밋에 노출 | 비밀이다. `Authorization` 헤더로만 전달, 출력 금지. `~/.hermes/.env`에서 변수로만 로드 |
| 새 슬랙 앱/webhook을 만들려 함 | 불필요 — Hermes 봇 토큰 재활용. `chat.postMessage`로 전송 |
| 토큰 없는데 에러 노출 | Things 가드와 동일 — 조용히 건너뛰고 대화창 출력은 정상 진행 |
| 체크인을 셸 문자열로 직접 JSON 조립 | 줄바꿈·백틱 깨짐. `jq`로 이스케이프 + `build_blocks`로 blocks 생성 |
| 구분선을 `text`에 `---`로 넣음 | 슬랙 텍스트엔 hr 없음. Block Kit `divider` 블록 사용(`blocks` 전송) |
| 멀티소스인데 합친 1건만 전송 | 소스별 체크인 1건씩 → 그 소스 전용 채널로. key=`hub`/디렉터리명 |
| 한 소스 전송 실패가 나머지를 막음 | 소스별 독립 전송 — 실패해도 다음 소스 계속, `.error`만 보고 |
| 어제 스레드에 이어 붙임 | 매일 새 top-level 메시지. `thread_ts` 안 붙임, `threads/{key}` ts 저장·재사용 안 함 |
| 전용 채널에 봇 미초대 상태로 전송 | `not_in_channel` 실패. graceful 처리 + `/invite @maia` 안내 |
| 체크인·헤더에 이모지 사용 | 사용자는 이모지 비선호. 제목=코드 칩 ` : ` 구분, 헤더=`> *_풀 텍스트_*`, 제목 아래 `─` 구분선. **단 ops-console는 예외** |
| ops-console에 표준 형식(블록쿼트·불릿·코드칩) 적용 | ops-console은 팀 표준: 이모지 헤더(`:date:`/`:grinning:`/`:dart:`/`:construction:`/`:loudspeaker:`) + 불릿 없는 평문 줄바꿈. 빈 섹션=`특이사항 없음`. 대화창도 `──────` 없이 평문 |
