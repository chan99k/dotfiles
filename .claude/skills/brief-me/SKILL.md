---
name: brief-me
description: Use when the user asks to brief, summarize, or explain what files changed on the current branch, OR before implementation to show ASIS-TOBE design plan. Triggers on "브리핑", "변경사항 설명", "뭐가 바뀌었", "어떤 파일", "asis-tobe", "구현 전 브리핑", "change briefing", "diff summary".
---

# Change Briefing

두 가지 모드로 동작한다:

| 모드 | 인자 | 데이터 소스 | 사용 시점 |
|------|------|------------|----------|
| **구현 후** | (없음) / `last` / `working` / `<range>` | `git diff` | 구현 완료 후 변경사항 설명 |
| **ASIS-TOBE** | `plan <작업 설명>` | 코드베이스 탐색 | 구현 전, `/inspect`와 짝궁으로 설계 브리핑 |

---

## 모드 A: 구현 후 브리핑 (diff 기반)

### 실행 순서

1. **범위 결정**:
   | 인자 | 범위 |
   |------|------|
   | (없음) | `git diff main...HEAD` — 브랜치 전체 |
   | `last` | `git diff HEAD~1...HEAD` — 마지막 커밋 |
   | `working` | `git diff` + `git diff --staged` — 미커밋 변경 |
   | `<commit-range>` | 그대로 사용 |

2. **diff 수집**:
   - `git diff <range> --stat` — 변경 파일 목록과 줄수
   - `git diff <range>` — 실제 변경 내용
   - `git log --oneline <range>` — 커밋 히스토리

3. **출력 생성** — 섹션별 포함 범위:
   - **섹션 1-3**: diff 파일만. 추측 금지
   - **섹션 4-5**: diff 파일 + 직간접 상호작용하는 기존 파일 포함 가능 (경계·흐름 맥락 완성용)

**절대 규칙(섹션 1-3): diff에 없는 파일명이나 변경 내용을 추측하지 않는다.**

### 출력 구조 (모드 A)

반드시 아래 5개 섹션을 이 순서로 출력한다. 섹션을 생략하거나 순서를 바꾸지 않는다.

### 섹션 1: 모듈 변경 맵

프로젝트 모듈/레이어별로 변경된 파일을 트리로 시각화한다.
**변경된 파일만** 표시하며, 각 파일 옆에 `[+신규]`, `[~수정]`, `[→이동]`, `[-삭제]` 마커를 붙인다.

```
Module Change Map
=================
domain/novel/
  ├─ Work.kt                    [~수정] originalPublisher 제거
  └─ vo/WorkMetadata.kt         [~수정] originalPublisher 추가

ui/novel/
  ├─ controller/
  │   ├─ api/NovelApiController.kt    [+신규] 벌크 Work 등록 API
  │   └─ view/WorkViewController.kt   [+신규] Work 폼/완료 뷰
  ├─ dto/
  │   ├─ CreateNovelRequest.kt        [→이동] dto 패키지로
  │   └─ CreateWorkRequest.kt         [+신규] Work 생성 DTO
  └─ NovelViewController.kt          [~수정] Novel 생성 기능 추가

infrastructure/novel/persistence/
  ├─ WorkJpaEntity.kt           [~수정] 컬럼 제거 + JSONB
  └─ WorkMapper.kt              [~수정] 매핑 조정
```

규칙:
- 패키지 공통 접두사(`com.infiniction.ops.`)는 생략
- 모듈명은 Gradle 모듈(domain/ui/infrastructure/boot) 기준
- 한줄 설명은 10자 이내, 핵심 변경만

### 섹션 2: 변경 흐름도

변경의 **인과관계**를 화살표로 시각화한다.
"A가 바뀌어서 B도 바뀌었다"는 관계를 보여준다.

```
Change Flow
===========
[도메인 결정]
  originalPublisher: Work 필수 → WorkMetadata 선택

  Work.kt ─제거─→ WorkMetadata.kt ─추가
      │                  │
      ▼                  ▼
  WorkJpaEntity.kt    WorkMapper.kt
  (컬럼 제거+JSONB)    (매핑 조정)
      │                  │
      ▼                  ▼
  V2.0 DDL            WorkMapperTest.kt
  (스키마 반영)         (테스트 수정)

[신규 기능]
  NovelApiController ──→ CreateWorkRequest
  (벌크 등록 API)         (요청 DTO)

  WorkViewController ──→ work-create.html
  (폼/완료 뷰)           (템플릿)
```

규칙:
- 변경을 촉발한 **근본 원인**(도메인 결정, 신규 요구사항)을 `[대괄호]`로 먼저 명시
- 화살표 방향 = 변경이 전파된 방향 (원인 → 결과)
- 독립적인 변경 묶음은 별도 블록으로 분리
- 단순 리팩터링(이동/리네임)은 흐름도에서 제외하거나 별도 `[리팩터링]` 블록

### 섹션 3: 파일별 상세

변경된 파일 각각을 1-2줄로 설명한다. 테이블 형식:

```
File Details
============
| 파일 | 유형 | 줄수 | 설명 |
|------|------|------|------|
| Work.kt | ~수정 | -3 | originalPublisher 필드/검증 제거 |
| WorkMetadata.kt | ~수정 | +1 | originalPublisher 필드 추가 |
| NovelApiController.kt | +신규 | +80 | POST /api/novels/{id}/works 벌크 등록 |
| ... | ... | ... | ... |
```

규칙:
- 줄수는 `+N` / `-N` / `±N` 형식
- 설명은 **무엇이 왜** 바뀌었는지 — "수정"만 쓰지 않는다
- 테스트 파일은 별도 그룹으로 묶는다

### 섹션 4: 도메인 경계 다이어그램

변경된 파일들이 **Gradle 모듈 / Bounded Context 경계상 어디에 위치하는지**, 그리고 모듈 간 의존 방향을 ASCII 박스로 시각화한다.

```
Domain Boundary
===============
┌─────────────────────────────────────────────┐
│  domain/                                    │
│  ┌──────────────────┐  ┌─────────────────┐  │
│  │  novel BC        │  │  storage BC     │  │
│  │ [+] NovelArtifact│  │  ObjectStorage  │  │
│  │     Storage.kt   │  │  (기존, 참조만) │  │
│  └──────────────────┘  └────────┬────────┘  │
└─────────────────────────────────┼───────────┘
         ▲ application→domain     │ infra→domain
┌────────┴────────────────────────┼───────────┐
│  application/novel/             │           │
│ [+] RegisterNovelBundleUseCase  │           │
│ [+] SourceConverter             │           │
└─────────────────────────────────┼───────────┘
         ▲ ui→application         │
┌────────┴───────┐  ┌─────────────┴──────────┐
│  ui/novel/     │  │  infrastructure/novel/ │
│ [~] NovelView  │  │ [+] GcsNovelArtifact   │
│     Controller │  │     Storage.kt         │
│ [+] Register   │  └────────────────────────┘
│     Request    │
└────────────────┘
```

규칙:
- 변경된 파일은 박스 안에 `[+]/[~]/[-]` 마커와 함께 표시한다
- 변경되지 않았지만 상호작용하는 기존 파일은 마커 없이 표기 — 경계·의존 관계 이해에 필요한 경우만
- 박스 레이블은 Gradle 모듈명 기준 (`domain/`, `application/`, `ui/`, `infrastructure/`)
- BC(Bounded Context) 경계가 있으면 모듈 박스 안에 중첩 박스로 구분
- 의존 방향 화살표: `▲` (위 방향), `→` (오른쪽) — 항상 outer→inner 방향
- `[+]` 신규 / `[~]` 수정 / `[-]` 삭제 마커 유지

### 섹션 5: 동작 흐름도

변경된 컴포넌트들이 **런타임에 어떻게 협력하는지** 호출 흐름으로 시각화한다. 새로 추가되거나 수정된 경로만 그린다.

```
Operation Flow
==============
[주요 진입점 — e.g. POST /novels]

  HTTP Request
      │
      ▼
  NovelViewController.register()    [~수정]
      │  @Valid 검증 → toUseCaseRequest()
      ▼
  RegisterNovelBundleUseCase.execute()   [+신규]  @Transactional
      │
      ├─① novelRepository.save(Novel)
      │
      └─② works.forEach {
              │
              ├─ sourceConverter.convert(bytes)   [+신규 포트]
              │       └─→ TikaSourceConverter (PR #55)
              │
              └─ novelArtifactStorage.store(txt, novelId)   [+신규 포트]
                      └─→ GcsNovelArtifactStorage   [+신규]
                              │ ObjectStorage.upload()
                              ▼
                            GCS
                              └─→ StorageKey → ArtifactKey   ← BC 경계 변환
          }
      └─→ novelId: Long → redirect:/novels/{novelId}
```

규칙:
- 변경된 컴포넌트는 `[+신규]` / `[~수정]` 마커를 옆에 표기
- 변경되지 않았지만 흐름 이해에 필요한 기존 컴포넌트는 마커 없이 포함 가능 — 과도한 포함 금지, 흐름 맥락 완성에 필요한 것만
- BC 경계 변환이 일어나는 지점은 `← BC 경계 변환` 주석으로 명시
- 복수의 독립적인 흐름(GET/POST/event 등)은 각각 별도 블록으로 분리

---

## 모드 B: ASIS-TOBE 브리핑 (구현 전, 설계 브리핑)

`/inspect` 결과 또는 작업 설명을 바탕으로 현재 상태(ASIS)와 구현 후 목표 상태(TOBE)를 나란히 시각화한다.

### 실행 순서

1. **작업 설명 파악** — 인자에서 구현할 기능·변경의 범위를 파악한다
2. **코드베이스 탐색** — 관련 파일을 직접 읽는다 (diff 없음):
   - 변경될 도메인 파일, 포트 인터페이스, 컨트롤러, 리포지터리
   - 의존 방향·BC 경계 파악
3. **ASIS 스냅샷 확정** — 현재 코드를 읽은 사실 기반으로만 기술. 추측 금지
4. **TOBE 설계** — 작업 설명 + 코드베이스 컨벤션 기반으로 추가·변경·삭제될 파일 도출

### 출력 구조 (모드 B)

반드시 아래 4개 섹션을 이 순서로 출력한다.

#### 섹션 B1: ASIS — 현재 상태

관련 파일들이 지금 어디에 있고, 어떤 역할을 하는지 도메인 경계 박스로 표현한다.

```
ASIS — Current State
=====================
┌──────────────────────────────────────────────┐
│  domain/novel/                               │
│    Work.kt  (sourceKey: ArtifactKey? 없음)   │
│    WorkMetadata.kt  (coverImageKey 없음)     │
└──────────────────────────────────────────────┘
         ▲
┌────────┴─────────────────────────────────────┐
│  application/novel/                          │
│    GetWorkUseCase  — 조회만 존재             │
│    (다운로드 유스케이스 없음)                │
└──────────────────────────────────────────────┘
         ▲
┌────────┴─────────────────────────────────────┐
│  ui/novel/                                   │
│    WorkViewController  — 상세 뷰만 존재      │
│    work-detail.html: th:href="${work.sourceUrl}" │
│      → 현재 StorageKey.key 직접 노출 (broken) │
└──────────────────────────────────────────────┘
```

규칙:
- **읽은 파일에서 확인된 사실만** 기술. 코드베이스를 먼저 읽고 작성한다
- 현재 문제점·갭을 `(문제: ...)` 또는 주석으로 명시
- 변경 대상이 아닌 파일은 포함하지 않는다

#### 섹션 B2: TOBE — 목표 상태

구현 완료 후 예상되는 파일 구조를 같은 형식으로 표현한다. 신규·수정·삭제 마커 포함.

```
TOBE — Target State
====================
┌──────────────────────────────────────────────┐
│  domain/novel/                               │
│    Work.kt  (sourceKey: ArtifactKey?)        │  ← 기존 유지
│  domain/storage/                             │
│    ObjectStorage  (download(key): ByteArray) │  ← 기존 유지
└──────────────────────────────────────────────┘
         ▲
┌────────┴─────────────────────────────────────┐
│  application/novel/                          │
│  [+] DownloadArtifactUseCase                 │
│        execute(workId, type): ByteArray      │
└──────────────────────────────────────────────┘
         ▲
┌────────┴─────────────────────────────────────┐
│  ui/novel/                                   │
│  [+] WorkArtifactController                  │
│        GET /novels/{nId}/works/{wId}/artifact │
│        GET /novels/{nId}/works/{wId}/image   │
│  [~] WorkDetailView  sourceUrl → endpoint URL │
│  [~] work-detail.html  href → 엔드포인트 URL │
└──────────────────────────────────────────────┘
```

규칙:
- `[+신규]` / `[~수정]` / `[-삭제]` 마커 사용
- 기존 유지 파일은 마커 없이, `← 기존 유지` 주석으로 표기
- 컨벤션에서 벗어나는 설계 선택은 `(주의: ...)` 주석으로 명시

#### 섹션 B3: Delta Plan — 변경 계획 테이블

구현에 필요한 파일 액션을 테이블로 정리한다.

```
Delta Plan
==========
| 파일 | 액션 | 레이어 | 설명 |
|------|------|--------|------|
| DownloadArtifactUseCase.kt | +신규 | application | ArtifactKey→ObjectStorage.download |
| WorkArtifactController.kt  | +신규 | ui | artifact/image 두 엔드포인트 |
| WorkDetailView.kt          | ~수정 | ui | sourceUrl → /works/{id}/artifact |
| WorkRowView.kt             | ~수정 | ui | coverImageUrl → /works/{id}/image |
| work-detail.html           | ~수정 | ui/template | href/src → 엔드포인트 URL |
```

규칙:
- 테스트 파일은 별도 그룹으로 묶는다
- 추정 줄수가 있으면 기재, 없으면 생략

#### 섹션 B4: TOBE Operation Flow — 목표 동작 흐름도

구현 완료 후 예상 런타임 흐름을 그린다. 신규 컴포넌트는 `[+신규]` 마커.

```
TOBE Operation Flow
====================
[GET /novels/{nId}/works/{wId}/artifact]

  HTTP GET
      │
      ▼
  WorkArtifactController   [+신규]
      │  workId, type(SOURCE/IMAGE) 추출
      ▼
  DownloadArtifactUseCase.execute()   [+신규]
      │
      ├─ workRepository.findById(workId)
      │      └─→ null → 404
      ├─ work.sourceKey (ArtifactKey)
      │      └─→ null → 404 ("업로드 없음")
      └─ objectStorage.download(StorageKey(key))
             └─→ ByteArray
      │
      ▼
  ResponseEntity<ByteArrayResource>
    Content-Disposition: attachment
    Content-Type: text/plain
```

규칙:
- 기존 컴포넌트는 마커 없이 포함 가능
- BC 경계 변환 지점은 `← BC 경계 변환` 주석 명시
- 엔드포인트가 여럿이면 각각 별도 블록

---

## 공통 금지사항

- 전체 코드를 인용하지 않는다 (diff/파일 본문 복사 금지)
- 변경 대상이 아닌 기존 컴포넌트를 다이어그램 주인공으로 그리지 않는다
- 커밋 메시지 / 작업 설명을 단순 나열하지 않는다 — 다이어그램이 맥락을 대체한다
- 장황한 산문체 설명을 쓰지 않는다 — 다이어그램과 테이블이 주력
- **모드 B**: 코드베이스를 읽기 전에 ASIS를 작성하지 않는다. 읽은 사실만 기술한다

## 스타일

- 한국어 본문, 기술 용어 영어
- 다이어그램은 ASCII 전용 (유니코드 박스 문자 허용: ─│├└┌┐┘┤▼▶)
- 모드 A: 5개 섹션 합쳐서 120줄 이내 목표 (대규모 변경은 초과 가능)
- 모드 B: 4개 섹션 합쳐서 100줄 이내 목표
