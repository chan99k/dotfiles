# Weekly Insights 기반 Claude Code 설정 개선

## Context

`003-RESOURCES/AI/best-practices/Claude-Code-Weekly-Insights-2026-02-13.md`에서 7일간 855메시지, 114세션의 사용 데이터를 분석한 결과, **Wrong Approach 11건(46%)**이 가장 큰 마찰 원인으로 확인됨. 주요 원인: 도구 선택 오류(Playwright 대신 fetch 사용), 언어 규칙 불일치, 불필요한 리팩토링.

이 계획은 데이터 기반으로 가장 높은 ROI 개선사항만 선별 적용함.

## 수정 대상 파일 (2개)

| 파일 | 변경 내용 |
|------|----------|
| `~/.claude/CLAUDE.md` | Communication 확장, Tool Preferences 확장, /commit 강제 규칙 추가 |
| `~/.zsh.after/msbaek.zsh` | Headless mode aliases 추가 |

**수정 불필요**: `/commit` 커맨드, `settings.json`

---

## Step 1: CLAUDE.md Communication 섹션 확장 (lines 131-140)

**현재**: "Answer in Korean" 한 줄만 존재
**변경**: Language Preferences + Approach Preferences 세분화

```markdown
### Communication

Korean by default. Respect user's tool choices.

<communication_style>

**Language:**
- 응답/설명: 한국어
- 커밋 메시지: 한국어 conventional commits (type/scope는 영어)
- 코드 주석: 영어
- 기술 용어: 첫 언급 시 영어 병기
- 사용자 프로필: ~/git/aboutme/AI-PROFILE.md 참조

**Approach:**
- 사용자가 도구를 지정하면 해당 도구만 사용 (대체 금지)
- 인프라 변경(git remote, 빌드 설정, 의존성) 전 반드시 확인
- 광범위한 리팩토링 대신 요청된 부분만 최소 변경

**Output:**
- 응답 끝에 "Uncertainty Map" 섹션 추가

</communication_style>
```

## Step 2: CLAUDE.md Tool Preferences 섹션 확장 (lines 216-226)

**현재**: rg, fd, sg 3개 도구만 명시
**변경**: Web content, 대용량 파일 처리 규칙 추가

```markdown
<tool_preferences>
| Task | Tool | Reason |
|------|------|--------|
| Syntax-aware search | `sg --lang <lang> -p '<pattern>'` | Optimized for structural matching |
| Text search | `rg` (ripgrep) | Faster than grep, respects .gitignore |
| File finding | `fd` | Faster and more intuitive than find |
| Web content | Playwright MCP 우선 | 동적/인증 콘텐츠 지원, Cloudflare 우회 |
| Large files (>500줄) | Serena/LSP symbolic tools | Read보다 효율적 |

**Web Content 규칙:**
- 1순위: Playwright MCP (browser_navigate → browser_snapshot)
- 2순위: WebFetch (정적 public 페이지만)
- 금지: fetch/bash curl/wget (렌더링 불가, 403 차단)

**File Reading 안전:**
- 1000줄 초과 파일: offset/limit 파라미터 사용
- Edit 전: old_string 고유성 확인
</tool_preferences>
```

## Step 3: CLAUDE.md Git Workflow 섹션에 /commit 강제 규칙 추가 (line 214 다음)

```markdown
<use_commit_skill>
커밋 생성 시 항상 /commit 스킬을 사용할 것.
- 자동 conventional commit 메시지 생성
- 내장 한글 인코딩 안전성 (Write tool 사용)
- `--push`: 커밋 후 자동 push
- `--amend`: 이전 커밋 수정
수동 git commit은 /commit이 불가능한 환경에서만 허용.
</use_commit_skill>
```

## Step 4: Shell aliases 추가 (msbaek.zsh line 222 다음)

```bash
# Headless mode aliases
alias cc-commit='claude -p "analyze staged changes, generate conventional commit message in Korean, commit and push" --allowedTools "Bash,Read,Grep"'
alias cc-dailylog='claude -p "run the daily-work-logger skill for today" --allowedTools "Bash,Read,Write,Glob,Grep"'
```

---

## 검증

1. **CLAUDE.md**: 새 세션 시작 → 웹 콘텐츠 요약 요청 → Playwright MCP 사용 여부 확인
2. **Aliases**: `source ~/.zshrc` 후 `cc-commit`, `cc-dailylog` 명령어 존재 확인

## 적용하지 않는 항목

| 항목 | 사유 |
|------|------|
| Session Continuity 규칙 (A4) | 이미 완벽 구현됨 |
| /commit 스킬 자체 수정 | 이미 인코딩 안전성 완비 |
| Java auto-test hook | 사용자 선택: 대규모 프로젝트 성능 우려로 제외 |
| Tool Error Prevention 상세 규칙 | noise_cancellation 원칙, 필요 시 추후 추가 |
| 미래 워크플로우 (Autonomous TDD 등) | 아이디어 단계, 별도 설계 필요 |
