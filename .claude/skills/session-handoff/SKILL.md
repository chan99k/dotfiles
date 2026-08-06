---
name: session-handoff
description: |
  Use when wrapping up a work session and recording context for the next session.
  Triggers: "정리해줘", "마무리", "wrap up", "handoff", "세션 정리",
  "오늘 작업 정리", "remember에 저장".
---

# Session Handoff

## Overview

세션 종료 시 **어제-오늘-내일 3-block**으로 맥락을 정리하여 `.remember/`에 기록한다.
다음 세션이 cold start 없이 흐름을 이어받을 수 있게 하는 것이 목적이다.

## 각 블록의 목적

각 블록은 **왜 존재하는지**가 다르다. 목적을 벗어난 내용을 채우지 않는다.

| 블록 | 목적 | 핵심 질문 |
|------|------|-----------|
| Yesterday | 오늘 작업을 이해하기 위한 **최소 배경** | "이 맥락 없이 오늘 작업을 이해할 수 있나?" |
| Today | 이번 세션의 **성과와 판단** 기록 | "무엇을 했고, 왜 그렇게 결정했나?" |
| Tomorrow | 다음 세션의 **진입점** 제공 | "내일 시작할 때 뭘 먼저 해야 하나?" |

## Procedure

### 1. 소스 읽기

```
.remember/recent.md              → 7일 연속성 맥락
.remember/today-*-s*.done.md     → 세션별 완료 일지 (아래 우선순위로 선택)
.remember/now.md                 → 현재 버퍼
```

**읽기 우선순위:**
1. 오늘 이전 세션 파일 (`today-{TODAY}-s*.done.md`) — 같은 날 이전 세션의 맥락
2. 가장 최근 이전 날짜의 세션 파일들 (`today-{PREV_DATE}-s*.done.md`) — Yesterday 블록 소스
3. `now.md` — 현재 버퍼

> **하위 호환**: 기존 `today-YYYY-MM-DD.done.md` (접미사 없음) 파일도 glob에 포함한다.
> 패턴 `today-{DATE}*.done.md`로 양쪽 모두 매칭.

### 2. Tomorrow 소스 수집

```bash
gh pr list --state open --author @me   # PR 상태
```

세션 대화에서 추출:
- 명시적 TODO / defer 항목
- 새로 발견한 탐구 주제 (insight ideas)
- 블로커 / 외부 대기 항목

### 3. 3-block 작성

아래 형식 **그대로** 작성한다. H1 헤더, 메타 섹션("설명", "원칙 준수 확인" 등),
자기 평가 블록을 추가하지 않는다. **H2는 Yesterday / Today / Tomorrow / PR Status 4개만.**

```markdown
## Yesterday
- {이번 세션 이전 맥락 — 오늘 작업을 이해하기 위한 최소 배경}
- {불릿 리스트 3-5개. 밀집 단락이 아닌 한 줄 한 항목}

## Today
{이번 세션 작업 요약}
- {커밋/PR/논의 등}
- ...

### Decisions
- {이번 세션에서 명시적으로 내린 판단 + 근거}

### Insights
- {기술 인사이트, 발견, 블로그 글감 등}

## Tomorrow

### Actionable
- {즉시 실행 가능한 작업}

### Waiting
- {외부 대기 — PR 리뷰, 팀 응답 등}

### Ideas
- {탐구 주제, 아이디어, 조사할 것}

## PR Status
| PR | 상태 | 설명 |
|----|------|------|
| ... | ... | ... |
```

### 4. 출력 (확인 없이 즉시 실행)

1. **세션 번호 결정**: 오늘 날짜의 기존 세션 파일 수를 센다.
   ```bash
   TODAY=$(date +%Y-%m-%d)
   NEXT_N=$(( $(ls .remember/today-${TODAY}-s*.done.md 2>/dev/null | wc -l) + 1 ))
   # 기존 접미사 없는 파일(today-${TODAY}.done.md)이 있으면 그것도 s0으로 간주해 +1
   ```
2. `.remember/today-YYYY-MM-DD-sN.done.md`에 작성 (N = 다음 번호, **기존 파일을 덮어쓰지 않는다**)
3. `.remember/now.md` 버퍼 클리어

사용자에게 "이 내용으로 쓸까요?" 확인을 받지 않는다. 3-block 작성이 완료되면 바로 파일에 쓴다.

> **예시**: 오늘 3번째 세션이면 `today-2026-07-01-s3.done.md`가 생성된다.
> 기존 s1, s2는 그대로 보존된다.

## Rules

### Yesterday는 3-5개 불릿으로 압축한다

기존 기록의 재복사가 아니다. "이 배경 없이 Today를 이해할 수 있나?"에 No인 항목만.

**하드 리밋: 최대 5개 불릿.** 어제 10가지를 했어도 5개로 묶는다.
관련 작업은 하나의 불릿으로 합친다 (예: "PR #27, #28 머지 → 도메인 확정").
밀집 단락(줄바꿈 없는 긴 문장)도 금지 — 한 줄 한 항목.

```
# BAD: 어제 기록을 항목별로 나열 (11개)
## Yesterday
- PR #27 머지: TargetLanguage consts 이동, NovelTitle VO
- PR #28 머지: 리뷰 6건 반영, GcsUrl VO 통합
- 13개 stale 브랜치 정리
- PR #35 본문 6회 개선
- WorkJpaEntity 테스트 4개 추가
- Kotlin internal 인사이트
- PR #30 위자드 템플릿 5개
- 3-tier 전략 수립
- Code Reviewer APPROVE
- ObjectMapper 적용
- 테스트 전략 판단

# GOOD: 관련 작업을 묶어 3-5개로 (같은 어제)
## Yesterday
- PR #27(Novel AR), #28(Work 도메인) 머지 → 도메인 레이어 확정
- 3-tier 병렬 개발 착수: infra(PR #35) / UI(PR #30) / service(미착수)
- PR #35 Work 영속성 어댑터 draft, 본문 정제 + WorkJpaEntity 테스트 추가
- stale 브랜치 13개 정리, ObjectMapper companion object 적용
```

### 3-block 외 섹션을 만들지 않는다

H2 헤더는 `Yesterday`, `Today`, `Tomorrow`, `PR Status` 4개만 허용.
`# Session Handoff`, `## 설명`, `## 원칙 준수 확인`, `## 메모` 등 자의적 헤더 금지.
결정 사항은 Today > Decisions에, 메모성 항목은 Tomorrow > Ideas에 넣는다.

### Decisions와 Insights를 구분한다

| | Decisions | Insights |
|---|-----------|----------|
| 핵심 질문 | "왜 A를 선택하고 B를 버렸나?" | "무엇을 새로 알게 되었나?" |
| 예시 | `internal set` 채택 (protected set 대신) | Kotlin `internal`은 패키지가 아닌 모듈 단위 |
| 성격 | 선택 + 근거 (A vs B) | 발견 + 함의 (TIL) |

상태 업데이트("PR 코멘트 3개 확인")는 둘 다 아니다 — Today 본문에 넣는다.

### Tomorrow는 실행 가능성으로 분류한다

"~대기 중"인 항목을 Actionable에 넣지 않는다. 본인이 즉시 시작할 수 있는 것만 Actionable.

```
# BAD: 대기 항목이 Actionable에
### Actionable
- PR #35 리뷰 코멘트 반영
- Novel 목록 API 페이지네이션 결정 대기  ← Waiting이다

# GOOD
### Actionable
- PR #35 리뷰 코멘트 반영

### Waiting
- Novel 목록 API 페이지네이션 방식 — 다음 주 팀 회의에서 결정
```

### Insights를 매몰시키지 않는다

기술 인사이트는 Today 안에 별도 `### Insights` 서브섹션으로 분리한다.
"~을 구현했다" 사이에 묻히면 다음 세션에서 찾을 수 없다.

### PR Status는 3컬럼 테이블이다

컬럼은 **PR / 상태 / 설명** 3개만. Title, Branch, Next Action 등 추가 컬럼 금지.

```
# BAD: 불릿 리스트
- PR #35: Open, 리뷰 대기

# BAD: 컬럼 확대
| PR | Title | Status | Branch | Next Action |

# GOOD: 3컬럼
| PR | 상태 | 설명 |
|----|------|------|
| #35 | Ready for Review | Work 영속성 어댑터, 리뷰 대기 |
| #30 | Draft | 등록 마법사 UI, 템플릿 5개 완성 |
```

### 소스에 없는 판단을 지어내지 않는다

세션에서 명시적으로 논의/결정하지 않은 내용을 Decisions에 추가하지 않는다.
"~하는 것이 맞을 것이다", "~을 먼저 완료한 후"처럼 추론한 판단은 기록 대상이 아니다.

## Common Mistakes

| 실수 | 교정 |
|------|------|
| Yesterday를 항목별로 나열 (10개+) | 관련 작업을 묶어 최대 5개 불릿으로 압축 |
| Yesterday를 밀집 단락으로 작성 | 한 줄 한 항목 불릿 리스트 |
| PR Status에 컬럼 추가 | PR / 상태 / 설명 3컬럼만 |
| 3-block 외 섹션 추가 | H2는 Yesterday / Today / Tomorrow / PR Status 4개만 |
| H1 헤더 추가 (`# Session Handoff`) | 파일에 H1 없음. H2부터 시작 |
| 메타 섹션 추가 ("설명", "원칙 준수") | 자기 평가/설명 블록 금지 |
| Decisions와 Insights 혼동 | Decision=선택+근거, Insight=발견+함의 |
| 상태 업데이트를 Insights에 넣음 | Today 본문에 넣음 |
| Tomorrow Waiting 항목을 Actionable에 | 본인이 즉시 시작 가능한 것만 Actionable |
| PR Status를 불릿으로 작성 | 반드시 테이블 형식 |
| 소스에 없는 판단 추론 | 명시적으로 논의/결정한 것만 기록 |
| 인사이트가 작업 목록에 매몰 | Today > Insights 서브섹션으로 분리 |
| now.md 클리어 안 함 | 반드시 버퍼 비우기 |
| 사용자에게 "쓸까요?" 확인 요청 | 확인 없이 즉시 파일 쓰기 |
| 같은 날 기존 done 파일 덮어쓰기 | 세션별 `-sN` 접미사로 분리. 기존 파일 절대 교체 금지 |
| 접미사 없는 레거시 파일 무시 | `today-{DATE}*.done.md` 패턴으로 레거시 파일도 읽기 |
