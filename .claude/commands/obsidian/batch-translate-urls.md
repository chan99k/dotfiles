---
argument-hint: "[url1 url2 url3 ...] 또는 [계획파일경로.md]"
description: "URL 목록을 받아 각 URL에 대해 서브 에이전트를 병렬로 실행하여 전문 번역 obsidian 문서 생성 (세션 연속성 지원)"
---

# Batch Translate URLs - $ARGUMENTS

여러 URL을 병렬로 처리하여 각각 **전문 번역** Obsidian 문서를 생성합니다.
**세션이 고갈되어도 다음 세션에서 이어서 진행할 수 있습니다.**

> `batch-summarize-urls`와의 차이: summarize는 4000자 요약을 생성하고, translate는 **원문 전체의 빠짐없는 한국어 번역**을 생성합니다. 번역은 토큰 소모가 크므로 배치 크기가 2개입니다.

## 입력 형식

$ARGUMENTS로 전달되는 값:

- **URL 목록**: 공백 또는 줄바꿈으로 구분된 URL들 → 새 계획 파일 생성
- **계획 파일 경로**: `.md`로 끝나는 파일 경로 → 이전 작업 재개

## 처리 프로세스

### Step 1: 인자 분석

$ARGUMENTS 분석:

- `.md`로 끝나면 → **계획 파일 재개 모드**
- 그 외 → **새 작업 모드** (URL 목록 파싱)

### Step 2: 계획 파일 처리

#### 새 작업 모드

1. `.claude/batch-progress/` 디렉토리 확인 (없으면 생성)
2. `batch-translate-YYYYMMDD-HHMMSS.md` 파일 생성
3. 다음 형식으로 계획 파일 작성:

```markdown
# Batch Translate Progress

생성 시간: YYYY-MM-DD HH:MM:SS
총 URL 수: N개

## 처리 목록

- [ ] https://example.com/article1
- [ ] https://example.com/article2
- [ ] https://example.com/article3

## 실패 항목

(실패 시 추가)
```

4. **중요: 계획 파일 경로를 사용자에게 출력**

```
계획 파일 생성: .claude/batch-progress/batch-translate-20260310-143022.md
세션이 중단되면 다음 명령으로 재개하세요:
/obsidian:batch-translate-urls .claude/batch-progress/batch-translate-20260310-143022.md
```

#### 재개 모드

1. 전달받은 계획 파일 읽기
2. `- [ ]`로 시작하는 미완료 항목 추출
3. 이어서 처리 진행

### Step 3: 2개씩 배치 병렬 처리

**핵심 규칙: 한 번에 최대 2개 URL을 병렬로 처리하고, 완료 후 다음 2개 처리**

> 번역은 요약 대비 토큰 소모가 3~5배 크므로 배치 크기를 2개로 제한한다.

```
미완료 URL 목록에서 최대 2개 선택

단일 메시지에서 2개의 Agent tool 동시 호출:
- subagent_type: "general-purpose"
- description: "Translate: [URL 도메인/경로 일부]"
- prompt: |
    다음 URL에 대해 Skill tool을 사용하여 /obsidian:translate-article 스킬을 실행해주세요.

    URL: [해당 URL]

    Skill tool 호출:
    - skill: "obsidian:translate-article"
    - args: "[해당 URL]"

    완료 후 생성된 문서 경로를 알려주세요.

결과 수집
```

### Step 4: 계획 파일 업데이트

각 배치(2개) 처리 완료 후 **즉시** 계획 파일 업데이트:

성공한 항목:

```
- [x] https://example.com/article1 → 00-Inbox/문서제목.md
```

실패한 항목:

```
## 실패 항목

- https://example.com/failed → 에러: 접근 불가
```

### Step 5: 반복 및 완료

1. 미완료 항목이 있으면 Step 3로 돌아가서 다음 2개 처리
2. 모든 항목 완료 시 결과 요약 출력

## 결과 요약 형식

```
## 처리 완료

- 총 URL: N개
- 성공: M개
- 실패: K개

### 생성된 문서
1. 00-Inbox/제목1.md
2. 00-Inbox/제목2.md
...

### 실패 목록 (있는 경우)
- https://failed-url.com → 사유
```

## 사용 예시

### 새 작업 시작

```
/obsidian:batch-translate-urls https://docs.spring.io/page1 https://docs.spring.io/page2 https://vladmihalcea.com/article1
```

### 세션 재개

```
/obsidian:batch-translate-urls .claude/batch-progress/batch-translate-20260310-143022.md
```

## 주의사항

1. **2개씩 병렬 처리**: 번역은 토큰 소모가 크므로 한 번에 2개 이상 동시 처리 금지
2. **즉시 업데이트**: 배치 완료 시마다 계획 파일 업데이트 필수
3. **경로 안내**: 계획 파일 생성 시 반드시 경로와 재개 명령 출력
4. **에러 기록**: 실패 시 사유를 계획 파일에 기록

## 관련 스킬

- `/obsidian:translate-article`: 단일 URL에 대한 전문 번역 (내부적으로 호출)
- `/obsidian:batch-summarize-urls`: URL 배치 요약 (번역이 아닌 요약 버전)
