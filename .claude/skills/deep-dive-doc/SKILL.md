---
name: deep-dive-doc
description: "학부 후반 ~ 석사 수준의 시니어 백엔드/시스템 디자인 인터뷰 대비 심층 탐구 시리즈 문서를 작성하는 6단계 파이프라인 — MOC 설계 → 샘플 정립 → 작성 → 팩트체크 → 정정 → 아카이빙. 기본 순차 작성 + 사용자 지정 범위 병렬화 + 병렬 팩트체크."
trigger: /deep-dive-doc
---

# /deep-dive-doc

Obsidian 볼트에 학부~석사 수준의 한국어 기술 심층 탐구 시리즈를 일관된 품질로 작성하기 위한 워크플로우. 시니어 백엔드/시스템 디자인 인터뷰 대비 자료 수준을 목표로 한다.

## Usage

```
/deep-dive-doc                                          # 인터랙티브 — 주제 도메인을 묻는다
/deep-dive-doc <도메인>                                  # 예: backend, distributed-systems, security
/deep-dive-doc <도메인> --topics N                       # 주제 수 지정 (기본 30~40)
/deep-dive-doc continue <MOC 경로>                       # 기존 시리즈 이어서 작성
/deep-dive-doc factcheck <폴더 경로>                     # 작성 완료 후 팩트체크 단독 실행
/deep-dive-doc factcheck <폴더 경로> --groups 7          # 그룹 수 지정 (기본 4+3)
/deep-dive-doc parallel <범위>                           # 특정 범위 병렬 작성 (예: "#15-#20")
```

## What This Skill Is For

이 스킬은 다음 조건을 모두 만족하는 시리즈 문서를 양산하기 위한 것이다:

- **타깃 독자**: 학부 후반 ~ 석사. 시니어(5~15년차) 백엔드 인터뷰 준비자
- **분량**: 문서당 1,000~1,700 라인 (60~120 page screen)
- **인용 깊이**: RFC / 학술 논문 / 공식 docs / 권위 있는 엔지니어링 블로그. 2차 자료 단독 인용 금지
- **다이어그램**: Mermaid + ASCII (Obsidian 호환, 그림 파일 의존성 회피)
- **Q&A**: 문서당 12개 (시니어 인터뷰 평균 60분 기준)
- **언어**: 한국어 본문 + 영어 기술 용어 첫 등장
- **상호 참조**: `[[##]]` Obsidian 위키링크로 시리즈 내 그래프 형성

작성 기준이 다르다면 이 스킬을 호출하지 말 것.

## Critical Principle: 작성 동시성 정책

동시성에는 **두 차원**이 있다. 둘을 섞어서 해석하면 안 된다.

### 차원 1 — 편 단위 동시성 (inter-document)

**기본은 순차 작성. 거의 항상 순차가 옳다.**

| 작업 유형 | 기본 방식 | 병렬 허용 조건 |
|---|---|---|
| 시리즈 작성 (편 단위) | **순차 (default)** | 사용자가 `parallel <범위>` 명시 + 인접 주제만 |
| 팩트체크/검증 | **병렬** | (read-only, 항상 안전) |
| 정밀 수정 (Edit) | **병렬** | (독립 파일이면 안전) |

편 단위 병렬을 피하는 이유: 시리즈 작성은 앞 문서의 스타일·인용·표기 컨벤션이 뒷 문서에 영향을 준다. 인접 편이라도 prerequisite 의존이 흔하다. 무분별한 병렬은 일관성을 깨고, 같은 부분을 여러 번 다시 쓰는 비용으로 돌아온다.

팩트체크는 read-only 이고 문서 간 의존이 없으므로 항상 병렬.

### 차원 2 — 편 안 청크 단위 동시성 (intra-document chunks)

**한 편을 한 번에 작성하면 출력 토큰/컨텍스트 한계에 부딪친다 (~16k 출력 제한). 편 1개를 청크로 분할해서 여러 서브에이전트로 처리하는 것은 권장.**

청크 분할 = "한 편의 작은 작업으로 쪼개기" 이지 "여러 편 동시 작성" 이 아니다. 차원 1 의 편 단위 순차 정책과 충돌하지 않는다.

청크 분할 패턴:

| 청크 | 섹션 묶음 | 분량 |
|---|---|---|
| Chunk 1 (메인 세션, ground truth) | frontmatter + TL;DR + 학술/산업 배경 + 학술적 배경 + 핵심 메커니즘 | ~400~500 라인 |
| Chunk 2 (백그라운드 가능) | 다이어그램 + 다중 플랫폼 비교 + 트레이드오프 매트릭스 | ~400 라인 |
| Chunk 3 (백그라운드 가능) | 실무 시나리오 + 안티패턴 + Q&A 12개 | ~500 라인 |
| Chunk 4 (메인 또는 백그라운드) | 참고 자료 + 마커 + 인접 편 링크 정리 | ~100 라인 |

청크 분할 동시성 옵션:
- **순차 청크** (안전): 메인 세션이 chunk 1 작성 → 완료 후 chunk 2 백그라운드 spawn → 완료 통지 후 chunk 3 백그라운드 spawn → ... 청크 간 prerequisite 보장
- **병렬 청크** (추가 위험): chunk 2 / 3 / 4 가 chunk 1 의 메타데이터(섹션 번호/스타일)만 의존하면 동시 spawn 가능. 단 인접 청크가 같은 ASCII 다이어그램 / Q&A 를 다른 형식으로 쓸 위험. 메인이 chunk 1 작성 후, chunk 2-4 prompt 에 동일 ground truth (chunk 1 본문 포함) 명시 필수
- **단일 에이전트 멀티 청크** (가장 단순): 백그라운드 에이전트 1명에게 "chunk 1+2+3+4 순차 작성, Write → Edit append × N" 위임. 메인은 다른 작업 진행

청크 분할은 사용자가 "백그라운드에서" 또는 "청크별로 나눠서" 명시하면 활성. 또는 한 편 분량이 1,200 라인을 넘을 가능성이 명확하면 자동 적용.

### 두 차원의 의도 정리

| 사용자 의도 표현 | 해석 |
|---|---|
| "#15-#20 을 병렬로" | 차원 1 — 편 단위 병렬 (위험. 동의 후 진행) |
| "백그라운드에서 청크별로 나눠서" | 차원 2 — 편 안 청크 분할 (권장. 즉시 진행) |
| "방해되지 않게 백그라운드에서" | 차원 2 + run_in_background=true (메인 세션 다른 작업과 병행) |

판별 휴리스틱: "여러 편" 언급이면 차원 1. "한 편" 또는 "토큰/길이/한계" 언급이면 차원 2.

## What You Must Do When Invoked

순서대로 따른다. 단계 건너뛰기 금지.

### Phase 0 — 사전 정의 (5분)

사용자에게 다음을 확인하거나 합리적 디폴트를 제시하고 동의받는다:

| 항목 | 디폴트 |
|---|---|
| Obsidian 볼트 경로 | `/Users/chan99/chan99k-workspace/chan99k's vault/03-Resources/<series-name>/` |
| 시리즈 폴더명 | 도메인 기반 (`backend-interview-deep-dive` 등) |
| 분량 범위 | 1,000~1,700 라인 |
| Q&A 수 | 12개/문서 |
| 인용 정책 | 1차 자료 우선 (RFC/논문/JEP/CVE/공식 docs) |
| 첫 페이지 frontmatter | created, status, level, tags |

### Phase 1 — MOC 설계 및 주제 분해

1. `00-MOC-<series-name>.md` 생성
2. 주제 N개를 직교성(orthogonality) 기준으로 분해 — 중복 없이 합집합으로 도메인 커버
3. 주제 번호 = 작성 순서. 앞 주제가 뒷 주제의 prerequisite이 되도록 정렬
4. 인접 주제 간 내부 링크 의도 명시 (`[[15-msa]] ↔ [[16-hexagonal-ddd]]`)
5. 진척 체크리스트 `[ ]` 추가
6. frontmatter `status: in-progress` 시작

```markdown
---
created: YYYY-MM-DD
status: in-progress
level: undergraduate-to-master
tags: [moc, <domain>]
---

# <Series Title>

## 진척 체크리스트
- [ ] 01-<topic>
- [ ] 02-<topic>
...
```

### Phase 2 — 샘플 문서로 템플릿 정립

**1번 문서를 풀-뎁스로 작성하여 이후 문서들의 ground truth로 삼는다.** 이 단계는 절대 병렬화 금지.

표준 섹션 구조:

```markdown
---
created: YYYY-MM-DD
status: done
level: undergraduate-to-master
tags: [<domain>, <topic-tags>]
---

# <Topic Title>

## TL;DR (요약 2-3문단)

## 1. 학술·산업 배경 (인용 표 + 핵심 인용 4-6건)
## 2. 학술적 배경 (논문 deep-dive)
## 3. 핵심 개념 / 메커니즘
## 4. 다이어그램 (Mermaid + ASCII)
## 5. 다중 플랫폼 구현 비교 (Spring/Node/Go/Rust 등)
## 6. 트레이드오프 매트릭스
## 7. 실무 시나리오 (Discord/Stripe/Netflix 등 사례)
## 8. 안티패턴 / 함정
## 9. Q&A (12개)
## 10. 참고 자료 (학술 / 공식 docs / 엔지니어링 블로그)

===[TOPIC #N COMPLETE]===
```

마지막 줄에 truncation 검증용 마커 `===[TOPIC #N COMPLETE]===` 필수.

이 템플릿이 **10편 이상 일관되게 유지되어야** 시리즈 신뢰도 확보 가능.

### Phase 3 — 본격 작성 (#02 이후)

**기본 순차 실행.**

```
for 주제 in [#02..#N]:
    Read 직전 문서 (스타일 일관성 확인)
    Write 새 문서 (Phase 2 템플릿 따라)
    검증: 마커 존재 + 라인 수 1000+ 확인
    MOC 체크리스트 업데이트
```

**편 단위 병렬화 허용 조건 (차원 1)**: 사용자가 명시적으로 범위 지정 시에만.

```
/deep-dive-doc parallel "#15-#20"
→ 5개 백그라운드 에이전트 동시 spawn (technical-researcher 또는 content-writer)
```

편 단위 병렬 시 주의:
- 각 에이전트에 동일한 템플릿·스타일 가이드 전달 필수
- 인접 주제만 병렬화 (멀리 떨어진 주제는 prerequisite 위반 위험)
- 동시성 상한 4개 (rate limit 회피)
- MOC는 메인 세션에서만 일괄 업데이트 (race condition 회피)

**청크 분할 백그라운드 패턴 (차원 2 — 권장)**:

사용자가 "백그라운드에서" 또는 "청크별로 나눠서" 명시 시:

```
1. 메인 세션이 Phase 0 + Phase 1 (MOC) + Chunk 1 (ground truth) 작성
   - Chunk 1 = frontmatter + TL;DR + 학술 배경 + 핵심 메커니즘 (~400~500 라인)
2. Agent run_in_background=true 로 Chunk 2-4 위임
   - 단일 에이전트가 순차 Edit append 작성 (가장 안전)
   - 또는 Chunk 2 / 3 / 4 별도 에이전트 동시 spawn (속도 우선 시)
3. 메인 세션은 다른 작업 진행 (예: 진행 중이던 프로젝트 가이드)
4. 백그라운드 완료 통지 받으면 검증:
   - 라인 수 1,000+ 확인
   - ===[TOPIC #N COMPLETE]=== 마커 존재
   - 청크 경계가 자연스러운지 확인 (섹션 분리)
5. 다음 편(#02)을 동일 패턴으로 진행 (편 단위 순차 유지)
```

서브에이전트 호출 패턴:
```
Agent (subagent_type=technical-researcher 또는 content-writer)
  ├─ 자기 완결적 prompt (대화 컨텍스트 모름)
  ├─ Phase 2 템플릿 전체 + 직전 문서 1편 참조 명시
  ├─ 청크 작성 시: 메인 세션이 작성한 Chunk 1 본문 통째로 전달 (스타일 ground truth)
  ├─ 출력 파일 절대 경로 명시
  ├─ 청크 분량 제한 (~400~500 라인) 또는 전체 1,000~1,700 라인
  ├─ 마지막 청크에만 마커 추가 강제: ===[TOPIC #N COMPLETE]===
  ├─ MOC 수정 금지 명시
  └─ 작성 후 wc -l 으로 자체 검증 명령 실행 강제
```

작성 안티패턴:
- ❌ 백그라운드 에이전트가 21초만에 종료하며 "fake completion" 보고 → Write/Edit 도구 호출 강제 + 파일 크기 검증으로 회피
- ❌ 12개 동시 spawn → rate limit 초과. 4개 이하 유지
- ❌ 한 번 Write로 1,500+ 라인 → 16k 출력 제한 도달. ~600라인씩 Edit append (또는 청크 분할)
- ❌ 차원 1 (편 단위) 과 차원 2 (청크 단위) 를 혼동 → "병렬"이라는 단어로 둘을 같이 처리. 사용자 의도 판별 필수

### Phase 4 — 팩트체크 (병렬 검증)

**작성과 검증은 분리.** 모든 문서 작성 완료 후 별도 작업으로 수행.

#### 그룹핑 전략

주제 유사성 기준 5-7 그룹으로 분할 (각 그룹 4-6 문서). 그룹별 검증 우선순위 명시.

예시 (이번 backend 시리즈):

| 그룹 | 검증 우선순위 |
|---|---|
| SQL 최적화 | Selinger 1979, Use The Index Luke, Postgres docs |
| DB 아키텍처 | Berenson 1995, Cahill 2008, Helland 2007 |
| Cache/Concurrency | Redis docs, Mitzenmacher 2001, Karger 1997 |
| 분산/패턴 | Garcia-Molina 1987, DDIA, Microservices Patterns |
| 성능/배치 | Spring Batch docs, Lambda Architecture |
| 보안/인증/실시간 | RFC 6455/8446, OAuth BCP 9700, RFC 9449 |
| JVM/JPA/Infra | JEPs, GC Handbook, PCI-DSS, ImageTragick CVE |

#### 동시성 정책

기본 4+3 분할 (rate limit 안전).

```
Phase 1: 4개 에이전트 동시 spawn (G1, G2, G3, G4)
   → 모두 완료 대기
Phase 2: 3개 에이전트 동시 spawn (G5, G6, G7)
```

#### 보고 형식 표준화 (4-카테고리)

```markdown
# <Group> 팩트체크 결과

## <파일명>

### Confirmed (검증 완료)
- [인용] — [검증 출처/링크]

### Suspicious (의심, 추가 확인 필요)
- [인용] — [의심 사유]

### Likely Wrong (조작/오류 가능성 높음)
- [인용] — [실제 사실]

### Outdated (구식 정보)
- [정보] — [현재 상태/최신 버전]
```

#### 검증 도구 우선순위

1. **WebFetch** → 1차 자료 (datatracker.ietf.org, openjdk.org/jeps/N, cve.mitre.org, doi.org)
2. **WebSearch** → 1차 자료가 차단되거나 (403) 미발견 시 폴백
3. **engineering blog 직접 확인** → ACM DL, Springer DOI, Semantic Scholar

#### 메타-교훈

**에이전트 보고서 자체도 1차 자료 검증 대상이다.**

이번 backend 시리즈에서 9건 의심 항목 중 4건이 "문서에 해당 인용 자체가 없는" 오인이었음. 보고서를 받으면 반드시 `grep -nE "..."`로 실제 문서 매칭을 재확인한 뒤 수정 작업에 들어갈 것.

### Phase 5 — 정정 (정밀 수정)

```
1. Bash grep으로 정확한 라인 번호 식별 (Grep 도구가 rg 의존성 누락이면 폴백)
2. Read로 컨텍스트 확보 (Edit은 읽지 않은 파일 거부)
3. unique한 old_string 보장 (전후 컨텍스트 충분히 포함)
4. 병렬 Edit 호출로 일괄 처리 (한 메시지에 여러 Edit)
```

한국어/UTF-8 주의:
- 한국어 commit 메시지: Write 도구로 임시 파일 → `git commit -F`. heredoc 금지 (인코딩 깨짐)
- 본문 한글 그대로 Edit 가능 (UTF-8 안전)

수정 후 재검증:
- 수정한 라인 다시 grep으로 확인
- 마커 `===[TOPIC #N COMPLETE]===` 존재 재확인

### Phase 6 — 아카이빙

세션 종료 시:

1. **MOC frontmatter** `status: in-progress → done`
2. **MOC 체크리스트** 모두 `[x]` + 라인 수 + 핵심 인용 메모 추가
3. **완료 마커 검증**: `tail -3 *.md | grep -c "TOPIC.*COMPLETE"`로 누락 확인
4. **워크스루 문서** (선택): `YYMMDD-{scope}-{NN}-{description}.md` 형식, OBSIDIAN_INBOX 저장
5. **메모리 갱신** (선택): 시리즈 작성 패턴, 주의사항을 reference memory로 저장

## Tool Cheatsheet

| 작업 | 도구 |
|---|---|
| 파일 패턴 검색 | Glob (rg 의존성 없음) |
| 내용 검색 | Grep (rg 누락 시 Bash grep 폴백) |
| 정확한 인용 찾기 | `grep -nE "..." -C 2` |
| 1차 자료 검증 | WebFetch → WebSearch |
| 병렬 작성 | Agent (background, technical-researcher 또는 content-writer) |
| 1줄 정정 | Edit (replace_all 신중히) |
| 신규 문서 | Write (Read 후 사용 강제됨) |
| 시간 측정 | Bash `date` 또는 wall-clock 노트 |

## Time Budget Guide (참고용)

backend 시리즈 38편 실측치 기준:

| Phase | 소요 | 1편당 |
|---|---|---|
| MOC + 샘플 1편 | 30분 | 30분 |
| 본격 작성 #02-#27 (병렬 일부) | 6시간 | 14분 |
| 작성 #28-#38 (컨텍스트 압축 후 순차) | 4시간 | 22분 |
| 팩트체크 7그룹 4+3 분할 | 30분 | 0.8분 |
| 정밀 수정 9건 | 10분 | 1.1분 |
| **합계** | **~11시간** | **17분/편** |

## Anti-Pattern Checklist

작업 시작 전·중·후 점검:

1. ❌ **무분별 병렬 작성** → 기본 순차. 사용자 명시 범위에서만 병렬
2. ❌ **에이전트 보고 그대로 신뢰** → 1차 자료 또는 grep 재확인
3. ❌ **긴 본문을 한 Write로** → 16k 출력 제한, ~600라인씩 Edit append
4. ❌ **인용 없는 단정** → 모든 학술적 주장은 RFC/논문/공식 docs 인용 동반
5. ❌ **검증 누락된 outdated 정보** → 라이브러리 버전·CVE 신규 등은 늘 갱신 필요
6. ❌ **MOC 동시 수정** → 메인 세션에서만 일괄 업데이트
7. ❌ **마커 누락** → 모든 문서 끝에 `===[TOPIC #N COMPLETE]===` 강제
8. ❌ **frontmatter 누락** → created/status/level/tags 4종 필수

## Output

- 시리즈 폴더: `<Obsidian Vault>/03-Resources/<series-name>/`
- MOC: `00-MOC-<series-name>.md`
- 문서: `NN-<topic-slug>.md` (NN = 두자리 번호)
- (선택) 워크스루: `<OBSIDIAN_INBOX>/YYMMDD-{scope}-{NN}-{description}.md`

## Failure Modes & Recovery

| 증상 | 원인 | 복구 |
|---|---|---|
| 백그라운드 에이전트 21초 종료 | 도구 호출 누락한 fake completion | Write/Edit 도구 호출 강제 prompt + 파일 크기 검증 후 보고 |
| Rate limit 초과 | 동시 12+ 에이전트 | 4+3 분할 또는 3+3+3 분할로 재시도 |
| Edit replace_all 모호 매칭 | old_string 비유일 | 전후 컨텍스트 추가 |
| Grep 도구 ENOENT rg | ripgrep 미설치 | Bash `grep -nE` 폴백 |
| 컨텍스트 한계 도달 | 작성 중 누적 | 메인 세션 직접 Read+Edit append (~600라인 단위) |
| 한글 commit 메시지 깨짐 | heredoc 사용 | Write 임시파일 + `git commit -F` |

## Notes

- 모든 본문은 한국어. 코드 주석은 영어 (CLAUDE.md global rule)
- 1번 샘플 문서는 사용자 검토 받은 뒤 진행. 통과 못 하면 Phase 2부터 재시작
- 사용자가 "병렬로 진행"이라 말해도 작성은 기본 순차. 명확한 범위(`#15-#20`) 지정 시에만 병렬화
- 팩트체크는 이전 세션에서 발견된 4/9 오인 사례를 교훈으로, 항상 grep 재확인 절차 포함
