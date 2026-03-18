---
name: inbox-triage
description: Obsidian vault의 00-Inbox 문서들을 병렬 에이전트로 평가(기술적 깊이/재사용성/완성도/포트폴리오 가치)하고,
  90점 이상은 프로젝트/리소스 폴더로 이동, 미만은 종합 브리핑 문서로 정리하여 아카이브로 이동하는 스킬.
  "인박스 정리", "inbox triage", "inbox cleanup", "옵시디언 정리" 등의 요청 시 자동 적용.
---

# Inbox Triage

Obsidian vault `00-Inbox/` 디렉터리의 문서들을 병렬 에이전트로 평가하고 PARA 구조에 맞게 분류/이동하는 자동화 워크플로우.

## Trigger

- "인박스 정리", "inbox triage", "inbox cleanup", "옵시디언 정리"

## Configuration

| 인수 | 설명 | 기본값 |
|------|------|--------|
| `--threshold` | 이동 기준 점수 | 90 |
| `--dry-run` | 평가만 하고 이동하지 않음 | false |

## Vault Path

```
VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/chan99k's vault/chan99k's vault
```

디렉터리 구조는 `references/vault-structure.md` 참조.

## Workflow

### Phase 1: Inventory

1. Inbox 전체 파일 목록 수집 (`00-Inbox.md` 인덱스 제외)
2. 파일 수에 따라 그룹 분할:
   - 20개 이하: 1개 에이전트
   - 21-50개: 2개 에이전트
   - 51개 이상: 3개 에이전트
3. 파일명 키워드 기반 그룹 분류:
   - 그룹 A: 프로젝트 관련 (GIFTIFY, BLOG, MDD 등)
   - 그룹 B: 블로그/포트폴리오/기타 프로젝트
   - 그룹 C: 기술 레퍼런스/셋업/기타

### Phase 2: Parallel Evaluation

각 그룹을 `oh-my-claudecode:explore-medium` 에이전트로 **병렬** 평가.

에이전트 프롬프트 템플릿:

```
Obsidian vault Inbox 문서들을 평가한다. 코드를 작성하지 않고 평가만 수행.

Vault 경로: {VAULT_PATH}

평가 대상: 00-Inbox/ 디렉터리의 아래 파일들
{FILE_LIST}

평가 기준 (100점):
- 기술적 깊이 (30점): 문제/해결 과정이 상세한가, 학습 가치가 높은가
- 재사용성 (30점): 나중에 다시 참고할 가치가 있는가
- 완성도 (20점): 문서가 완결된 형태인가 (미완성 메모가 아닌가)
- 포트폴리오 가치 (20점): 면접이나 팀 공유에 활용 가능한가

각 파일에 대해:
파일명: {filename}
점수: {score}/100
이동 대상: {folder_path | archive}
이유: {1줄 설명}
핵심 내용: {1줄 요약}
```

### Phase 3: User Confirmation

평가 결과를 요약 테이블로 제시하고 사용자 확인을 받은 후 진행.

사용자가 분류를 수정할 수 있음. 흔한 수정 사례:
- "그건 글 작성 초안이에요" → `01-Projects/blog/drafts/`로 변경
- "이 프로젝트는 archive가 맞아요" → 아카이브 유지
- 새 프로젝트 폴더 생성 요청

### Phase 4: Archive Briefing

threshold 미만 문서들을 하나의 브리핑 문서로 종합.

**파일명**: `04-Archive/YYMMDD-inbox-archive-briefing.md`

카테고리별 테이블로 구성:
- TODO/미완성 스켈레톤
- AI 생성 문헌 노트
- 완료/대체된 프로젝트 기록
- 일회성 셋업/가이드
- 기술 레퍼런스 (경계선)

각 항목에 점수, 핵심 내용 1줄 요약 포함.

### Phase 5: File Move

1. threshold 이상 문서를 평가된 폴더로 이동
2. 사용자 수정 사항 반영
3. 아카이브 대상 문서를 `04-Archive/`로 이동
4. Inbox 비워졌는지 확인 (`ls 00-Inbox/ | grep -v 00-Inbox.md | wc -l` = 0)

**이동 방법 (우선순위)**:
1. `obsidian move` CLI 사용 (vault 디렉토리에서 실행, 백링크 자동 업데이트)
   ```bash
   cd "$OBSIDIAN_VAULT" && obsidian move path="00-Inbox/파일명.md" to="03-Resources/topic/"
   ```
2. Obsidian 앱 미실행 시 fallback으로 `mv` 사용 (백링크 수동 확인 필요)

### Phase 6: Report

최종 결과 요약 테이블 출력.

## Important Rules

1. **이동 전 반드시 사용자 확인** 받기
2. **새 프로젝트 폴더 자동 생성**: 기존에 없으면 `mkdir -p`
3. **글 작성 초안 구분**: TODO 스켈레톤이라도 사용자가 "글 초안"이면 `blog/drafts/`
4. **00-Inbox.md 절대 보존**: 인덱스 파일 이동/삭제 금지
5. **JSON 파일도 평가 대상**: PRD 등 문서 역할
6. **대용량 파일**: 50KB 이상은 첫 200줄만 읽어서 평가
7. **이동 실패 시 재시도**: 파일명에 특수문자(공백, 괄호, 한글) 있으면 따옴표로 감싸기
8. **`obsidian move` 우선**: 백링크 자동 업데이트를 위해 Obsidian CLI를 우선 사용하고, 앱 미실행 시에만 `mv` fallback
