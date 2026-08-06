PR 본문 작성 — 변경 사항의 동기, 구현 핵심, 검증 방법을 구조화하여 리뷰어가 빠르게 승인할 수 있도록 합니다.

Create a PR message using the planning skill's pr-message guide.

Automatically gather context:
- Read the current branch diff (git diff main...HEAD or appropriate base)
- Check for related Linear issues or specs
- Determine PR scale (small/medium/large) from diff size

Follow the pr-message guide workflow:
- Step 1: Analyze (read diff, gather context)
- Step 2: Draft (apply template, select sections by scale)
- Step 3: Output (format for gh pr create or copy-paste)

Rules:
- Korean body, English type prefix for title (feat/fix/chore...)
- Remove sections that don't apply — no empty placeholders
- Motivation over metrics (qualitative first)
- No scope in title parentheses
