---
name: mastery-course
description: |
  유료 인터넷 강의 정보(목차, 가격, 시간, 강사)를 입력받아 사용자 컨텍스트(직급/스택/취준 단계) 기준 수강 ROI를 판정하고, 가치가 부족하다고 판단되면 강의 목차의 학습 흐름을 보존한 채 공식 1차 레퍼런스 기반의 Obsidian 학습 가이드 + Advanced Slides + 다중 전문가 교차 팩트체크를 자동 스캐폴딩한다. 모든 산출물에 출처 URL을 인라인으로 명시한다.
trigger: /mastery-course
---

# /mastery-course

유료 강의를 무료/저비용 1차 출처 학습 자료로 대체하는 워크플로우. PostgreSQL/Redis/MSA Mastery 시리즈 패턴을 일반화한 skill.

## When To Invoke

- 인터넷 강의 (인프런/패스트캠퍼스/Udemy/Coursera 등) 구매 전 ROI 판정이 필요할 때
- 강의 목차는 좋은데 (1) 가격이 부담되거나 (2) 강사 신뢰도가 모호하거나 (3) 사용자 직급에 비해 깊이가 얕거나 (4) 더 깊은 학습이 필요할 때
- "이 강의 살까요?" / "이 강의 ROI 어때요?" / "공식 자료로 대체 가능?" 류 요청

## When NOT To Invoke

- 강의 목차 정보 없이 "Redis 공부할래" 같은 일반 학습 시작 → `/deep-dive-doc` 사용
- 이미 강의를 구매·수강 중이고 보충 자료만 필요한 경우 → 일반 노트 작성
- 한 강의 한 챕터의 단편 설명 요청 → 직접 답변

## Inputs

필수:
- **강의 정보**: 제목, 강사, 가격, 시간(시/분), 섹션/강의 목차 전문
- **플랫폼**: 인프런/패스트캠퍼스/Udemy/Coursera/Boostcourse 등

선택 (없으면 사용자 메모리 + AskUserQuestion):
- **사용자 직급/단계**: 신입/주니어/시니어, 취준/재직, 부캠/4년제
- **스택**: 주력 언어·프레임워크
- **학습 목표**: 면접 대비/포트폴리오/실무 투입

## Output Path

```
{OBSIDIAN_VAULT}/03-Resources/{domain}/{topic}-mastery/
├── 00-overview.md                   # MOC, Phase 정의, 시간 예산
├── 01-section-mapping.md            # 강의 목차 → Phase 매핑 매트릭스
├── 02-expert-critique-path.md       # 면접 질문, 안티패턴, 자가진단 체크리스트
├── phase-0-*.md                     # Obsidian Advanced Slides (theme: black)
├── phase-1-*.md
├── phase-N-*.md
├── _fact-check/
│   ├── expert1-{lens-A}.md          # 예: docs-accuracy
│   ├── expert2-{lens-B}.md          # 예: production-patterns
│   └── (선택) expert3-{lens-C}.md    # 예: spring-integration
└── (선택) _strategic/
    └── roi-verdict.md               # ROI 판정 근거
```

`{domain}` 예: `databases/`, `architecture/`, `kotlin/`, `spring/`. 새 도메인이면 사용자 확인.

## Pipeline

### Phase A — ROI Verdict (필수, 학습 자료 생성 전)

평가 매트릭스 (5개 차원, 각 1~5점):

| 차원 | 5점 | 1점 |
|---|---|---|
| 사용자 직급 적합도 | 신입에 신입 강의 / 시니어에 시니어 강의 | mismatched |
| 면접 커버리지 | 한국 백엔드 면접 빈출 ≥80% | 빈출 미커버 |
| 포트폴리오 차별화 | 신입 시장 흔하지 않은 깊이 | 부캠 baseline 수준 |
| 강사 신뢰도 | 검증된 산업 경력·저서·CFP | 모호함 |
| 가격 vs 시간 | <5,000원/시간 | >10,000원/시간 |

판정 규칙:
- **합계 ≥ 20**: 수강 권장. 필요 시 보충 노트만 생성하고 종료.
- **합계 15~19**: 사용자에게 옵션 제시 (수강 / 자료 제작 / 자료 제작 후 수강).
- **합계 < 15**: **자동으로 Phase B 진입** (단, 사용자에게 한 번 확인).

신입 백엔드 사용자 (메모리 `user_career_stage.md`)는 다음을 가산점:
- 한국 시장 표준 스택 (Spring/Kotlin) 강의 = +1
- 자기학습 자료(F-lab/인프런 등)와 중복도 낮음 = +1

판정 결과는 `_strategic/roi-verdict.md`에 저장 (선택). 사용자 응답에 인라인 표시는 필수.

### Phase B — Canonical Phase 정의 (00-overview)

**가장 중요한 단계.** 후속 문서들이 모두 이 정의를 인용하므로 drift 방지를 위해 먼저 확정.

00-overview.md 필수 섹션:
1. **TL;DR**: 강의 정보, ROI 판정, 대체 경로 한 줄 요약
2. **Phase 정의 (canonical)**: Phase 0 ~ Phase N, 각 Phase별 (이름, 학습 목표, 시간 예산, 핵심 출처 3~5개)
3. **시간 예산 합계**: 강의 시간 vs 대체 경로 시간 비교
4. **파일 트리**: 후속 작성될 모든 파일 명시 (파일명 drift 방지)
5. **1차 출처 인덱스**: 공식 docs / RFC / 학술 논문 / 검증된 한국 실무 블로그 (우아한형제들·카카오·토스·당근 등)

⚠ **drift 방지 필수 규칙**: Phase 개수, Phase 이름, 시간 예산, 파일명 — 이 4개는 00-overview에 확정한 뒤 다른 문서/슬라이드 모두 동일하게 인용. 후속 에이전트 prompt에 canonical 정의를 인라인으로 embed.

### Phase C — Section Mapping (01-section-mapping)

강의 목차 N개 강의를 Phase 0~N에 매핑하는 매트릭스. 형태:

```markdown
| 강의 # | 강의 제목 | 매핑 Phase | 대체 자료 (URL) | 예상 시간 |
|---|---|---|---|---|
| 1 | Redis 소개 | Phase 0 | https://redis.io/docs/about/ | 30m |
| 2 | String 자료형 | Phase 1 | https://redis.io/docs/data-types/strings/ | 45m |
```

목적: 강의 학습 흐름을 잃지 않으면서 출처를 무료 자료로 치환. 수강과 자료 학습 어느 쪽으로 가도 매핑이 일치.

### Phase D — Expert Critique Path (02-expert-critique-path)

면접 대비 보강. 필수 항목:
- **면접 질문 N개** (Phase별 분류, Tier 1/2/3 난이도)
- **안티패턴 표** (10개 이상, 한국 실무에서 흔한 실수)
- **자가진단 체크리스트** (학습 완료 확인용)
- **이력서·포트폴리오 적용 기준** (이 강의 주제를 이력서에 쓰려면 어디까지 알아야 하나)

### Phase E — Slide Decks (phase-N-*.md)

Obsidian Advanced Slides 형식:

```yaml
---
theme: black
transition: slide
---

# Phase N: 제목

---

## 슬라이드 본문
- 핵심 포인트
- 출처: https://...
```

규칙:
- 슬라이드 1개 분량: 1편당 17~50 슬라이드
- 모든 코드/개념에 출처 URL 인라인 (Obsidian 링크 + 외부 URL 둘 다)
- **토큰 오버플로우 방어**: 한 Phase가 16k 출력 한계 위험 시 자동 split (예: phase-3 → phase-3a + phase-3b). 출력 토큰 추정 > 12,000이면 사전 split.
- 작성 동시성: Phase 간 독립이면 병렬 spawn 허용. 단 모든 prompt에 canonical Phase 정의 (Phase B 산출물) embed.

### Phase F — Cross Fact-Check (_fact-check/)

최소 2명, 권장 3명. **렌즈 분리 필수** (같은 렌즈 중복 금지).

표준 렌즈 매트릭스:

| 렌즈 | 검증 대상 | 사용 도구 |
|---|---|---|
| `docs-accuracy` | 공식 docs와 syntax/option/version 일치 | WebFetch + technical-researcher |
| `production-patterns` | 실무 안티패턴, 라이브러리 API breaking change | technical-researcher + WebSearch |
| `spring-integration` (선택) | Spring Boot 통합 패턴 정확성 | Java/Kotlin 생태계 검증 |
| `learning-path` (선택) | 학습 순서 인지부하 적절성 | 교육공학 관점 |

각 expert 출력 형식:
```markdown
## Verdict: {정확도 %} / Critical {N} / Major {N} / Minor {N}

### Critical Issues
- [ ] {파일}:{줄} — {문제} → {수정 제안}

### Major Issues
...

### Minor / Style
...
```

병렬 spawn (read-only이므로 안전). 결과 종합 후 사용자에게 fix 적용 옵션 제시.

## Execution Flow

```
1. 입력 수집 (강의 정보, 사용자 컨텍스트)
   ↓
2. Phase A: ROI 판정 → 사용자 확인
   ├─ 수강 권장 → 종료 (보충 노트만 생성 옵션)
   └─ 대체 경로 진입 → 계속
   ↓
3. Phase B: 00-overview 작성 (canonical Phase 정의 확정)
   ↓ [사용자 확인 — Phase 정의 OK?]
   ↓
4. Phase C+D 병렬: 01-section-mapping + 02-expert-critique-path
   (둘 다 00-overview만 의존)
   ↓
5. Phase E: 슬라이드 작성
   ├─ 사용자 옵션: 순차 / 병렬 (default 병렬)
   ├─ Phase별 백그라운드 에이전트 spawn (canonical 정의 embed)
   └─ 토큰 오버플로우 위험 → 자동 split
   ↓
6. Phase F: 팩트체크 병렬 spawn (≥2 expert lens)
   ↓
7. 사용자에게 fix 옵션 제시 (Critical 강제, Major 권장, Minor 선택)
   ↓
8. 적용 후 종료
```

## Drift Prevention Rules

PostgreSQL/Redis/MSA 시리즈 운영 중 발견한 실패 모드 → 사전 차단:

1. **Phase 정의 drift**: 후속 문서가 00과 다른 Phase 개수/이름 사용 → 모든 후속 prompt에 00의 canonical 정의 인라인 embed.
2. **시간 예산 합계 mismatch**: 00은 25h, 01은 24h → 00 작성 시 산수 검증 후 잠금.
3. **파일명 drift**: split 결정 후 00의 파일 트리 미갱신 → split 즉시 00 파일 트리 업데이트.
4. **출처 URL 누락**: 슬라이드에 코드만 있고 출처 없음 → 슬라이드 작성 prompt에 "모든 코드/개념에 출처 URL 인라인 필수" 명시.
5. **사용자 직급 오인**: 시니어 강의 → 신입 사용자에게 추천 → Phase A 판정 시 사용자 메모리(`user_career_stage.md`) 필수 확인.
6. **팩트체크 렌즈 중복**: 두 expert가 같은 docs-accuracy 시각 → 렌즈 매트릭스에서 강제 분리.

## 1차 출처 우선순위

학습 자료 작성 시 출처 인용 우선순위:

1. **공식 docs** (해당 도구의 공식 문서)
2. **RFC / 표준 명세** (네트워크/프로토콜)
3. **학술 논문** (Google Scholar, ACM, USENIX, VLDB)
4. **검증된 산업 블로그**: 우아한형제들, 카카오, 토스, 당근, 라인, 네이버 D2, AWS 공식 블로그, GCP 공식 블로그, Azure Architecture Center
5. **권위 있는 저자 책/사이트**: Martin Fowler, microservices.io, highscalability.com, Sam Newman
6. **GitHub 공식 라이브러리 README/wiki** (특정 라이브러리 통합 시)

❌ **금지**: 익명 블로그, 한 개인의 단발성 포스트, 출처 불명 코드 스니펫.

## Path Constants

- `OBSIDIAN_VAULT`: `/Users/chan99/chan99k-workspace/chan99k's vault`
- 학습 자료 경로: `{OBSIDIAN_VAULT}/03-Resources/{domain}/{topic}-mastery/`
- 사용자 메모리: `/Users/chan99/.claude/projects/-Users-chan99-chan99k-workspace/memory/`

## Reference Implementations

성공 사례 (이 패턴이 산출한 결과물):

| 시리즈 | 강의 | 산출물 |
|---|---|---|
| postgresql-mastery | (강의 미상) | 00-07 docs + slides/ + 3-expert fact-check |
| redis-mastery | 인프런 코딩하는기술사 (60,000원, 12h) | 00-02 docs + 7 slide decks (295 슬라이드) + 2-expert fact-check |
| MSA self-study guide | 인프런 Hong+Choi (60,000원, 6h27m) | 자기학습 가이드 + presentation |

새 시리즈 시작 시 이 셋 중 하나를 참조 템플릿으로 사용자에게 제시.

## 관련 Skill

- `/deep-dive-doc`: 학부~석사 수준 심층 탐구 시리즈 작성 (강의 input 없이 도메인 입력)
- `/usage-pattern-analyzer`: 패턴 분석 (이 skill의 메타 사용 패턴 추적)
- `/graphify`: 작성 완료 후 지식 그래프 빌드

## 사용자 보고 형식

skill 종료 시 다음을 한 화면 안에 표시:

```
## Mastery Course 결과 — {topic}

**ROI 판정**: {점수}/25 — {수강 권장 / 자료 제작 / 사용자 선택}

**산출물**:
- {OBSIDIAN_VAULT}/03-Resources/{domain}/{topic}-mastery/
- 00-overview, 01-section-mapping, 02-expert-critique-path
- N개 슬라이드 ({총 슬라이드 수})
- 2~3 expert fact-check (Critical {N}/Major {N}/Minor {N})

**시간 예산**:
- 원 강의: {X}시간 / {가격}원
- 대체 경로: {Y}시간 / 0원 (또는 권장 도서 1권 ~{Z}원)

**다음 단계**:
1. Phase 0 학습 시작
2. 팩트체크 fix 적용
3. (선택) 학습 후 강의 보충 수강 결정
```
