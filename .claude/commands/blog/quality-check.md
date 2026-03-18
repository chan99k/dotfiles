---
argument-hint: "[all|파일명1 파일명2 ...] [--threshold 95]"
description: "블로그 게시글을 5명의 전문가(콘텐츠/SEO/메타데이터/AI탐지/팩트체크)가 병렬 리뷰하여 기준 점수 미달 시 게시 철회(draft: true) 및 개선 방향 리포트 생성"
---

# Blog Quality Check - $ARGUMENTS

블로그 게시글을 5명의 전문가가 병렬로 리뷰하여, 기준 점수 미달 포스트를 게시 철회하고 개선 방향을 리포트합니다.

## 입력 형식

$ARGUMENTS로 전달되는 값:

- **`all`**: 모든 공개 포스트(draft: false) 전수 검사
- **`all --include-drafts`**: draft 포함 전체 검사
- **파일명 목록**: 특정 파일만 검사 (공백 구분, 예: `builder-pattern.md act-local-ci-runner.md`). draft 포스트도 지정 가능
- **`--threshold N`**: 통과 기준 점수 (기본값: 95). Expert 1~3, 5는 이 점수 이상이어야 PASS

## 경로 정보

| 항목 | 경로 |
|------|------|
| 블로그 프로젝트 | `~/WebstormProjects/chan99k's blog/chan99k.github.io` |
| 포스트 디렉토리 | `{프로젝트}/src/content/blog/` |
| 콘텐츠 스키마 | `{프로젝트}/src/content/config.ts` |
| 태그 분류 체계 | `{프로젝트}/src/data/tag-taxonomy.ts` |
| 리포트 출력 | `{OBSIDIAN_VAULT}/02-Areas/blog-analytics/` |

## 통과 규칙 요약

| 전문가 | 기준 | 비고 |
|--------|------|------|
| Expert 1: 콘텐츠 품질 | threshold 이상 | 기본 95 |
| Expert 2: SEO | threshold 이상 | 기본 95 |
| Expert 3: 메타데이터 | threshold 이상 | 기본 95 |
| Expert 4: AI 탐지 | contentSource별 차등 | 아래 참조 |
| Expert 5: 팩트 체크 | threshold 이상 | 기본 95 |

### Expert 4 차등 기준 (contentSource별)

| contentSource | AI 탐지 통과 기준 | 의미 |
|---------------|:-----------------:|------|
| `original` | **100점** | 인간이 직접 작성한 것으로 판별되어야 함. AI 흔적 0% |
| `ai-assisted` | **75점 이상** | 인간의 사고와 경험이 주도, AI는 보조 역할. 일부 AI 흔적 허용 |
| `ai-generated` | **면제** | 이미 AI 작성임을 명시. 탐지 불필요 |

> 종합 판정: 5명 중 **한 명이라도 기준 미달이면 FAIL**.

## 처리 프로세스

### Step 1: 인자 파싱

$ARGUMENTS 분석:

1. `--threshold N` 옵션 추출 (없으면 기본값 95)
2. `--include-drafts` 플래그 추출 (있으면 draft 포스트도 포함)
3. 나머지 인자가 `all`이면 전수 검사 모드
4. 그 외는 파일명 목록으로 파싱 (draft 포스트도 지정 가능)

### Step 2: 대상 포스트 수집

#### 전수 검사 모드 (`all`)

```
블로그 디렉토리에서 모든 .md 파일을 Glob으로 찾기
각 파일의 frontmatter 읽기
--include-drafts 없으면: draft: true인 파일 제외 (공개 포스트만)
--include-drafts 있으면: 모든 포스트 포함 (draft 포함 전수 검사)
대상 포스트 목록 생성
```

#### 특정 파일 모드

```
지정된 파일명을 블로그 디렉토리 경로와 결합
파일 존재 여부 확인
(draft 여부 무관 — 명시적으로 지정된 파일은 항상 검사)
```

### Step 3: 사전 정보 수집

리뷰 시작 전 다음 정보를 읽어서 프롬프트에 포함:

1. `src/content/config.ts` — frontmatter 스키마 (필수/선택 필드, contentSource enum)
2. `src/data/tag-taxonomy.ts` — PARA 기반 태그 분류 체계 (유효한 1tier/2tier 목록)

### Step 4: 5명 전문가 병렬 디스패치

**핵심 규칙: 5명의 전문가를 동시에 백그라운드로 실행한다.**

단일 메시지에서 5개의 Agent tool 동시 호출:

```
- subagent_type: "oh-my-claudecode:code-reviewer"
- run_in_background: true
```

---

#### Expert 1: 콘텐츠 품질 전문가

평가 기준 (각 포스트 0-100):
- **정확성** (30점): 기술적 사실 정확? 코드 예제 동작? 오해 유발 없음?
- **완성도** (30점): 주제 완전 커버? 갑작스러운 종료 없음? 결론 존재? 서론 적절?
- **가독성** (20점): 구조화? 헤딩 계층? 문단 길이? 코드 설명?
- **고유성/깊이** (20점): 일반적 설명 이상의 가치? 개인 인사이트? 실전 경험? 문서 재탕 아닌가?

> 엄격 기준: AI-generated 콘텐츠가 개인 인사이트 없이 교과서적이면 고유성/깊이 저점수.
> 실제 디버깅/설계 경험이 있는 포스트는 가산점.

---

#### Expert 2: SEO 전문가

평가 기준 (각 포스트 0-100):
- **Description 품질** (25점): 150-160자 이내? 키워드 포함? 클릭 유도?
- **태그 적절성** (25점): PARA taxonomy 준수? 적절한 수? 계층 깊이?
- **구조화** (25점): H1→H2→H3 계층? 스캔 가능? 코드 블록 언어 지정?
- **SEO 기본** (25점): 제목 길이? URL slug 깔끔(한글/특수문자 금지)? 이미지 alt?

> 엄격 기준: 한글/특수문자 slug는 CRITICAL. 빈 태그 배열은 0점. description 23자 이하는 최하점.

---

#### Expert 3: 메타데이터 일관성 전문가

평가 기준 (각 포스트 0-100):
- **메타데이터 일관성** (25점): 필수 필드 존재? 날짜 유효? 스키마 위반 없음?
- **contentSource 정확성** (25점): 라벨이 실제 콘텐츠 스타일과 일치?
- **태그 체계 준수** (25점): PARA taxonomy 올바르게 적용? 포스트 간 일관성?
- **출판 품질** (25점): placeholder 없음? TODO 없음? 링크/이미지 깨짐 없음?

---

#### Expert 4: AI 작성 탐지 전문가

**목적**: 포스트의 `contentSource` 라벨이 실제 작성 방식과 일치하는지, 그리고 해당 라벨 기준에 부합하는 독창성을 갖추었는지 평가.

평가 기준 (각 포스트 0-100, **독창성 점수**):
- **문체 자연성** (25점): 저자 고유의 목소리/어투가 있는가? 기계적으로 균일한 톤이 아닌가?
- **경험 기반 서술** (25점): 실제 프로젝트/디버깅/의사결정 경험이 녹아있는가? "나는 X를 시도했고 Y가 발생했다" 같은 서술?
- **비정형적 구조** (25점): 교과서적 나열이 아닌 고유한 사고 흐름이 있는가? 예상치 못한 통찰이나 독자적 관점?
- **구체적 맥락** (25점): 특정 프로젝트명, 팀원, 날짜, 환경, 에러 메시지 등 실제 맥락이 포함되어 있는가?

> AI 작성 탐지 신호 (감점 요인):
> - 모든 섹션이 균일한 깊이와 분량 → 인간은 관심 영역에 편향됨
> - "~입니다", "~됩니다" 경어체가 일관되게 유지 → 인간은 문체가 흔들림
> - 코드 예제가 illustrative(교과서용)이지 실제 프로젝트 코드가 아님
> - 토픽 커버리지가 완벽하게 균등 → 인간은 아는 부분을 더 깊게 씀
> - "이 글에서는 ~를 살펴보겠습니다" 같은 정형화된 도입부

> 독창성 신호 (가점 요인):
> - 실제 에러 메시지, 스택 트레이스 인용
> - "처음에 X라고 생각했는데 알고 보니 Y였다" 같은 사고 전환
> - 코드에 실제 클래스명/메서드명 (FriendshipV2ApiSpec, SettlementExecutionWriter 등)
> - 감정 표현 ("삽질", "구원자", "당황")
> - 불완전하거나 비대칭적인 구조 (인간의 자연스러운 흔적)

**통과 기준 (contentSource별)**:
- `original`: **100점** (AI 흔적 없어야 함)
- `ai-assisted`: **75점 이상** (인간 주도 + AI 보조 허용)
- `ai-generated`: **면제** (점수는 매기되 판정에서 제외)

---

#### Expert 5: 기술 팩트 체크 전문가

**목적**: 포스트에 포함된 기술적 주장, 코드 예제, API 사용법, 프레임워크 동작 설명 등이 사실에 부합하는지 검증.

평가 기준 (각 포스트 0-100):
- **코드 정확성** (25점): 코드 예제가 실제로 컴파일/실행 가능? import문 정확? API 시그니처 일치? deprecated API 사용 없음?
- **개념 정확성** (25점): 기술 개념 설명이 공식 문서와 일치? 잘못된 비유나 오해 유발 표현 없음? 용어 사용이 정확?
- **버전/호환성** (25점): 언급된 라이브러리/프레임워크 버전이 정확? 버전별 차이가 올바르게 설명? 더 이상 유효하지 않은 정보 없음?
- **참조 무결성** (25점): 인용된 출처가 실재? 링크가 유효? 공식 문서 참조가 정확? 다른 포스트/외부 자료와의 상호 참조가 올바름?

> 검증 방법:
> - 코드 블록의 Java/TypeScript/Bash 문법 검사
> - Spring Framework, JPA, Hibernate 등 공식 동작과 대조
> - Azure Architecture Center 번역문의 원문 정확성
> - 에러 코드(HV000151 등)와 공식 문서 대조
> - 링크 유효성 (실제 접근 가능 여부는 제외, URL 형식만 검증)

> 엄격 기준:
> - 잘못된 기술 설명은 1건당 -10점
> - deprecated API를 최신인 것처럼 설명하면 -15점
> - 코드가 컴파일 불가능하면 -20점

---

### 각 전문가 출력 형식

```markdown
### [번호]. [파일명]
- 제목: [title]
- contentSource: [value]
- **항목1**: [점수]/[만점] — [1줄 근거]
- **항목2**: [점수]/[만점] — [1줄 근거]
- **항목3**: [점수]/[만점] — [1줄 근거]
- **항목4**: [점수]/[만점] — [1줄 근거]
- **총점**: [합계]/100
- **PASS/FAIL**: [기준 이상 PASS, 미만 FAIL]
- **개선 방향** (FAIL인 경우): [구체적 제안 2-3줄]

## Summary
| # | 파일명 | 총점 | 결과 |
|---|--------|------|------|
```

### Step 5: 결과 수집 및 종합 판정

5명의 전문가 결과가 모두 도착하면:

1. 각 포스트별로 5명의 점수 취합
2. **판정 규칙**:
   - Expert 1, 2, 3, 5: 모두 threshold 이상이어야 PASS
   - Expert 4 (AI 탐지): contentSource별 차등 기준 적용
     - `original`: 100점 필수
     - `ai-assisted` (또는 미설정=기본값): 75점 이상
     - `ai-generated`: 면제 (판정에서 제외)
   - **한 명이라도 기준 미달이면 FAIL**
3. FAIL 포스트를 Tier 분류:
   - **Tier A** (최저 90~threshold-1): 소폭 개선으로 통과 가능
   - **Tier B** (최저 70~89): 중간 수준 개선 필요
   - **Tier C** (최저 70 미만): 심각한 개선 필요

### Step 6: 게시 철회 실행

FAIL 판정된 포스트의 frontmatter에서 `draft: true`를 설정:

```
각 FAIL 포스트 파일을 Edit tool로 수정:
- draft 필드가 있으면: draft: false → draft: true
- draft 필드가 없으면: frontmatter에 draft: true 추가
```

> **주의**: 수정 전 사용자에게 철회 대상 목록을 보여주고 확인을 받는다.

### Step 7: 리포트 생성

Obsidian 문서로 리포트 저장:

파일명: `{OBSIDIAN_VAULT}/02-Areas/blog-analytics/quality-report-YYYY-MM-DD.md`

```markdown
---
id: "Blog Quality Report YYYY-MM-DD"
tags:
  - Areas/개발/blog-analytics
  - Areas/개발/quality-assurance
created_at: YYYY-MM-DD HH:MM
---

# Blog Quality Report - YYYY-MM-DD

## 요약

| 항목 | 값 |
|------|-----|
| 검사 대상 | N개 |
| PASS | M개 |
| FAIL (게시 철회) | K개 |
| 통과 기준 | E1-3,5: {threshold}점 / E4: contentSource별 차등 |

## 종합 판정표

| # | 포스트 | contentSource | E1 콘텐츠 | E2 SEO | E3 메타 | E4 AI탐지 | E5 팩트 | 판정 |
|---|--------|:------------:|:---------:|:------:|:-------:|:---------:|:-------:|:----:|
{각 포스트 행. E4는 "면제" 또는 점수/기준 표시}

## PASS (게시 유지)

{PASS 포스트 목록 + 간단한 코멘트}

## FAIL (게시 철회) — Tier별 분류

### Tier A: 소폭 개선 필요
{포스트별 문제점 + 구체적 개선 방향}

### Tier B: 중간 수준 개선 필요
{포스트별 문제점 + 구체적 개선 방향}

### Tier C: 심각한 개선 필요
{포스트별 문제점 + 구체적 개선 방향. CRITICAL 이슈 강조}

## 패턴 분석

{PASS/FAIL 포스트 간 공통 패턴 분석}

## 다음 단계 제안

{우선순위별 개선 작업 제안}
```

### Step 8: 결과 요약 출력

터미널에 최종 결과 요약:

```
## Quality Check 완료

- 검사 대상: N개
- PASS: M개
- FAIL (게시 철회): K개
- 리포트: 02-Areas/blog-analytics/quality-report-YYYY-MM-DD.md

### 철회된 포스트
1. [파일명] — [주요 이유] (감점 전문가: E#, 점수: X)
2. ...

### PASS 포스트
1. [파일명] (최저 점수: X)
2. ...
```

## 사용 예시

### 전체 검사 (기본 95점)

```
/blog:quality-check all
```

### 특정 파일 검사

```
/blog:quality-check builder-pattern.md circuit-breaker-pattern.md
```

### draft 포함 전수 검사

```
/blog:quality-check all --include-drafts
```

### 기준 점수 변경

```
/blog:quality-check all --threshold 90
```

### 개선 후 재검사

```
/blog:quality-check builder-pattern.md act-local-ci-runner.md --threshold 95
```

## 주의사항

1. **5명 병렬 실행**: 모든 전문가를 `run_in_background: true`로 동시 실행
2. **Expert 4 차등 기준**: original=100, ai-assisted=75, ai-generated=면제
3. **게시 철회 확인**: `draft: true` 변경 전 반드시 사용자 확인
4. **리포트 저장**: 매 실행마다 Obsidian에 리포트 보존 (이력 추적용)
5. **재검사 지원**: 개선 후 특정 파일만 재검사 가능
6. **태그 분류 체계**: 리뷰 시 항상 최신 `tag-taxonomy.ts`를 참조

## 관련 스킬

- `/obsidian:add-tag`: 태그 개선 시 참조
- `/tBlog2`: 통과한 workthrough를 블로그로 발행
- `/codebase-verify`: 코드베이스 대조 검증 (유사 패턴)
