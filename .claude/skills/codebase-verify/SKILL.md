---
name: codebase-verify
description: 설계 문서, 로드맵, 구현 계획 등의 각 항목을 실제 코드베이스와 대조 검증하는 스킬.
  deepsearch + research 에이전트를 병렬로 실행하여 사실 정확성, 현재 상태, 누락 항목을 평가하고 수정안을 제시.
  "코드베이스 검증", "대조", "verify", "적절성 평가" 등의 요청 시 자동 적용.
---

# Codebase Verify

문서(설계, 로드맵, 구현 계획 등)의 각 항목을 실제 코드베이스와 대조하여 사실 정확성을 검증하고, 점수와 수정안을 제시하는 복합 스킬.

## Trigger

- "코드베이스 기반으로 대조하여 적절성을 평가해주세요"
- "코드베이스 검증", "codebase verify"
- 설계/로드맵/계획 문서 작성 직후 자동 적용 권장

## Workflow

### 1. 입력 분석

대상 문서에서 검증 가능한 항목을 추출:
- 파일 경로, 클래스명, 메서드명 등 코드 참조
- 수치 (사용 횟수, 파일 수, 적용 비율 등)
- 기술 스택 현황 (의존성, 설정, 인프라)
- 구현 상태 주장 ("이미 구현됨", "미구현", "부분 구현")

### 2. 에이전트 병렬 실행

항목 유형에 따라 적절한 에이전트를 병렬로 실행:

**코드베이스 내부 검증 (deepsearch)**

```
/oh-my-claudecode:deepsearch
```

대상: 파일 존재 여부, 클래스/메서드 구현 현황, 설정값, 의존성, 패턴 사용 횟수 등

프롬프트 템플릿:
```
프로젝트 루트: {PROJECT_ROOT}

검증 대상 항목:
{ITEMS_TO_VERIFY}

각 항목에 대해:
1. 실제 파일 경로와 라인 번호
2. 현재 구현 상태 (구현됨/부분 구현/미구현)
3. 문서의 주장과 실제 코드의 차이점
4. 수치가 있으면 실제 카운트
```

**외부 기술 검증 (research)**

```
/oh-my-claudecode:research
```

대상: 도구 선택 타당성, 버전 호환성, 비용 추정, 벤치마크 주장 등

### 3. 결과 통합 및 평가

각 항목을 4가지 기준으로 평가 (각 25점, 총 100점):

| 기준 | 설명 |
|------|------|
| **사실 정확성** | 코드베이스 현황과 문서 내용이 일치하는가 |
| **완전성** | 누락된 사전 조건, 의존성, 엣지 케이스가 없는가 |
| **실행 가능성** | 개발자가 바로 작업할 수 있을 만큼 구체적인가 |
| **일관성** | 다른 섹션/항목과 모순이 없는가 |

### 4. 출력 포맷

```markdown
## 검증 결과 요약

| 섹션 | 점수 | 상태 |
|------|------|------|
| {section_name} | {score}/100 | PASS / NEEDS FIX |

## 상세 결과

### {section_name}
**점수**: {score}/100
**상태**: {PASS|NEEDS FIX}

**발견 사항:**
- {finding_1}
- {finding_2}

**수정안** (NEEDS FIX인 경우):
```
{exact_text_to_replace}
```
->
```
{corrected_text}
```
```

## Configuration

검증 범위를 인수로 조정 가능:

| 인수 | 설명 | 기본값 |
|------|------|--------|
| (positional) | 검증 대상 문서 경로 또는 현재 대화의 항목 | 현재 대화 컨텍스트 |
| `--threshold` | PASS 기준 점수 | 95 |
| `--fix` | 95점 미만 항목 자동 수정 적용 | false |
| `--parallel` | deepsearch + research 병렬 실행 | true |

## Examples

**기본 사용:**
```
/codebase-verify
```
현재 대화에서 마지막으로 제시된 설계/계획의 항목들을 코드베이스와 대조 검증.

**파일 지정:**
```
/codebase-verify docs/superpowers/specs/2026-03-15-post-deploy-roadmap-design.md
```
특정 문서의 모든 항목을 검증.

**자동 수정:**
```
/codebase-verify --fix
```
검증 후 95점 미만 항목을 자동으로 수정 적용.

## Agent Dispatch Strategy

항목 수에 따른 에이전트 전략:

- **5개 이하**: 단일 deepsearch 에이전트로 처리
- **6-15개**: deepsearch 1개 + research 1개 병렬
- **16개 이상**: 카테고리별로 분할하여 deepsearch N개 병렬 (카테고리당 1개)

에이전트 모델 선택:
- deepsearch: `oh-my-claudecode:explore-medium` (Sonnet, 코드 탐색 최적)
- research: `oh-my-claudecode:researcher` (Sonnet, 외부 문서 탐색)
- 최종 통합: 메인 에이전트가 결과를 수집하여 점수화
