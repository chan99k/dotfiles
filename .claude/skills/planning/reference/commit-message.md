# Commit Message Reference

Minimal commit message guide. A 2 to 5 line body as a `-` bullet list for readability.

## Subject Line

Format: `{type}: {one-line description}`

- Conventional Commits type prefix, in English
- Korean subject; technical terms stay in English as they are
- No parenthetical scope (per `feedback_no_scope_in_commit`)
- At most about 72 characters
- Issue reference `(#N)` only when there is a matching issue. `closes` is handled in the PR, not the commit

Examples (Korean subjects as they would actually be written):
```
feat: JWT 검증에 leeway 추가 및 strict 모드 전환
fix: saved_payment가 비정상 step에서 덮어쓰이는 버그 수정
refactor: MSW handlers 도메인별 9개 파일로 분리
chore: 테스트 파일 더미 credential을 placeholder로 교체
feat: position 모듈 + 테이블명 컨벤션 통일 (#22)
```

## Body

2 to 5 lines as a `-` bullet list. Omit the body when nothing applies (trivial chore,
single-line fix).

```
- auth.py: JWT leeway=5 추가 (Supabase clock skew 대응)
- coordinator에 env_file 추가, mock-target strict 모드 전환
- deploy 스크립트에 Supabase 환경변수 주입 + 검증 로직
```

Rules:
- Technical terms stay in English; the explanation is Korean.
- An inline rationale goes in parentheses or after a hyphen (-). Never an em dash; it is a forbidden glyph in all outputs.
- Do not list file by file. Summarize by domain or feature.
- More than 5 lines means the subject is too broad: a signal to split the commit.

## Issue Reference

- If there is a matching issue, put `(#N)` at the end of the subject or `relates to #N` in the body.
- Use `closes #N` **only in the PR body**, never in a commit.

## Anti-patterns

- **No long-form giftify-be style**: PR-level structure such as Summary / What's Changed / Decisions does not belong in a commit.
- **No diff narration**: never enumerate every file.
- **No future tense**: a commit records the current state.
- **No "work for ..." phrasing**: state WHAT directly.
