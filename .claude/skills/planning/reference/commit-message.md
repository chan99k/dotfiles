# Commit Message Reference

Minimal commit message guide. 2-5 lines body, `-` bullet for readability.

## Subject Line

Format: `{type}: {한 줄 설명}`

- Conventional Commits type prefix (English)
- Korean subject, 기술 용어는 영문 그대로
- No parenthetical scope (per feedback_no_scope_in_commit)
- Max ~72 characters
- Issue reference `(#N)`: 대응되는 이슈가 있을 때만. `closes`는 커밋이 아닌 PR에서 처리

Examples:
```
feat: JWT 검증에 leeway 추가 및 strict 모드 전환
fix: saved_payment가 비정상 step에서 덮어쓰이는 버그 수정
refactor: MSW handlers 도메인별 9개 파일로 분리
chore: 테스트 파일 더미 credential을 placeholder로 교체
feat: position 모듈 + 테이블명 컨벤션 통일 (#22)
```

## Body

2-5줄. `-` bullet list. 해당 없으면 body 생략 (trivial chore, single-line fix).

```
- auth.py: JWT leeway=5 추가 (Supabase clock skew 대응)
- coordinator에 env_file 추가, mock-target strict 모드 전환
- deploy 스크립트에 Supabase 환경변수 주입 + 검증 로직
```

Rules:
- 기술 용어 영문 그대로, 설명은 한국어
- `—` dash로 인라인 근거 연결 가능
- 파일 단위 나열 금지 — 도메인/기능 단위로 요약
- 5줄 초과 시 subject가 너무 넓은 것 — 커밋을 쪼개야 하는 신호

## Issue Reference

- 대응 이슈가 있으면 subject 끝에 `(#N)` 또는 body에 `relates to #N`
- `closes #N`은 커밋이 아닌 **PR 본문에서만** 사용

## Anti-patterns

- **No giftify-be 스타일 장문**: Summary/What's Changed/Decisions 같은 PR 수준 구조를 커밋에 넣지 않음
- **No diff narration**: 모든 파일 나열 금지
- **No future tense**: 커밋은 현재 상태를 기록
- **No "~을 위한 작업"**: WHAT을 직접 서술
