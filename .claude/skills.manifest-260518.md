# Skill Manifest — Zero-Base Reset 2026-05-18

본 manifest 는 zero-base 초기화 시점 `~/.claude/skills/` 인벤토리.
복원 시 어떤 스킬을 어느 출처에서 가져올지 참고용.

- 원본 스킬 총 수: 73 (~/.claude/skills/ 디렉토리 기준)
- 백업본 위치: `dotfiles/.claude/skills-backup/260518/` (71 개)
- 백업 미포함 3 개: 아래 별도 표 참조
- 사용 빈도(30d) / Ecosystem 분류: 워크스루 문서 `00-Inbox/260518-SKILLS-01-claude-code-skill-audit.md` §3.2, §5.2 참조

## 백업본 인벤토리 (71 개)

| 스킬명 | 출처 | 30d 사용 | description |
|---|---|---|---|
| autoplan | gstack | 0 | Auto-review pipeline — reads the full CEO, design, eng, and DX review skills from disk and runs them sequentially with a |
| backlog-md | external | 0 | Expert guidance for Backlog.md CLI project management tool including task creation, editing, status management, acceptan |
| benchmark-models | gstack | 0 | Cross-model benchmark for gstack skills. Runs the same prompt through Claude, GPT (via Codex CLI), and Gemini side-by-si |
| benchmark | gstack | 0 | Performance regression detection using the browse daemon. Establishes baselines for page load times, Core Web Vitals, an |
| browse | gstack | 7 | Fast headless browser for QA testing and site dogfooding. Navigate any URL, interact with elements, verify page state, d |
| brunch-writer | custom(KR) | 0 | 브런치 블로그 글 작성을 도와주는 Skill. 사용자가 초안 파일(.md)을 @멘션하면서 "브런치", "글 작성", "블로그 글" 등을 언급하면 활성화. vault-intelligence 시스템으로 관련 자료를 검색 |
| canary | gstack | 0 | Post-deploy canary monitoring. Watches the live app for console errors, performance regressions, and page failures using |
| careful | gstack | 0 | Safety guardrails for destructive commands. Warns before rm -rf, DROP TABLE, force-push, git reset --hard, kubectl delet |
| codebase-verify | custom(KR) | 0 | 설계 문서, 로드맵, 구현 계획 등의 각 항목을 실제 코드베이스와 대조 검증하는 스킬. |
| codex | gstack | 0 | OpenAI Codex CLI wrapper — three modes. Code review: independent diff review via codex review with pass/fail gate. Chall |
| connect-chrome | gstack | 0 | Launch GStack Browser — AI-controlled Chromium with the sidebar extension baked in. Opens a visible browser window where |
| context-restore | gstack | 0 | Restore working context saved earlier by /context-save. Loads the most recent saved state (across all branches by defaul |
| context-save | gstack | 0 | Save working context. Captures git state, decisions made, and remaining work so any future session can pick up without l |
| cover-letter | custom(KR) | 10 | 신입 공채 자기소개서 작성 도우미. 5명의 전문가 피드백 루프를 통해 AI 탐지 회피/팩트 정확성/적절성 100점 달성까지 반복 개선. 공고 URL 또는 회사명+직군명 입력, 여러 항목 병렬 처리. "자기소개서",  |
| cso | gstack | 0 | Chief Security Officer mode. Infrastructure-first security audit: secrets archaeology, dependency supply chain, CI/CD pi |
| daily-work-logger | custom(KR) | 0 | 매일 아침 업무 시작 전 어제 작업 내역을 정리하여 Daily Note에 반영. 서브 에이전트 기반 병렬 처리로 메인 컨텍스트 절약. "어제 작업 정리해줘", "daily log", "업무 내역 정리" 등의 요청 시 |
| databricks-academy | external | 0 | Use this skill when users ask questions about Databricks courses, tutorials, documentation, or learning materials from D |
| deep-dive-doc | custom(KR) | 11 | "학부 후반 ~ 석사 수준의 시니어 백엔드/시스템 디자인 인터뷰 대비 심층 탐구 시리즈 문서를 작성하는 6단계 파이프라인 — MOC 설계 → 샘플 정립 → 작성 → 팩트체크 → 정정 → 아카이빙. 기본 순차 작성 + |
| design-consultation | gstack | 2 | Design consultation: understands your product, researches the landscape, proposes a complete design system (aesthetic, t |
| design-html | gstack | 1 | Design finalization: generates production-quality Pretext-native HTML/CSS. Works with approved mockups from /design-shot |
| design-review | gstack | 3 | Designer's eye QA: finds visual inconsistency, spacing issues, hierarchy problems, AI slop patterns, and slow interactio |
| design-shotgun | gstack | 0 | Design shotgun: generate multiple AI design variants, open a comparison board, collect structured feedback, and iterate. |
| devex-review | gstack | 0 | Live developer experience audit. Uses the browse tool to actually TEST the developer experience: navigates docs, tries t |
| document-release | gstack | 0 | Post-ship documentation update. Reads all project docs, cross-references the diff, updates README/ARCHITECTURE/CONTRIBUT |
| executing-plans | superpowers | 1 | Use when you have a written implementation plan to execute in a separate session with review checkpoints |
| finishing-a-development-branch | superpowers | 0 | Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completio |
| freeze | gstack | 0 | Restrict file edits to a specific directory for the session. Blocks Edit and Write outside the allowed path. Use when de |
| gh | external | 0 | This skill should be used when working with GitHub CLI (gh) for pull requests, issues, releases, and GitHub automation.  |
| git-worktree-summary | custom(KR) | 0 | Git 워크트리와 브랜치 현황을 종합 분석하여 요약 테이블로 출력. 로컬 브랜치의 커밋 수, GitHub PR 연동 여부, 푸시 상태, 워크트리 여부를 한눈에 파악. "워크트리 현황", "브랜치 현황", "branc |
| graphify | external | 3 | "any input (code, docs, papers, images) - knowledge graph - clustered communities - HTML + JSON + audit report" |
| gstack-upgrade | gstack | 0 | Upgrade gstack to the latest version. Detects global vs vendored install, runs the upgrade, and shows what's new. Use wh |
| guard | gstack | 0 | Full safety mode: destructive command warnings + directory-scoped edits. Combines /careful (warns before rm -rf, DROP TA |
| health | gstack | 0 | Code quality dashboard. Wraps existing project tools (type checker, linter, test runner, dead code detector, shell linte |
| inbox-triage | custom(KR) | 2 | Obsidian vault의 00-Inbox 문서들을 병렬 에이전트로 평가(기술적 깊이/재사용성/완성도/포트폴리오 가치)하고, |
| investigate | gstack | 0 | Systematic debugging with root cause investigation. Four phases: investigate, analyze, hypothesize, implement. Iron Law: |
| jira | external | 0 | Use jira CLI for Jira operations including issue management, project queries, transitions, and JQL search |
| land-and-deploy | gstack | 0 | Land and deploy workflow. Merges the PR, waits for CI and deploy, verifies production health via canary checks. Takes ov |
| landing-report | gstack | 0 | Read-only queue dashboard for workspace-aware ship. Shows which VERSION slots are currently claimed by open PRs, which s |
| learn | gstack | 0 | Manage project learnings. Review, search, prune, and export what gstack has learned across sessions. Use when asked to " |
| learning-tracker | custom(KR) | 0 | 세션에서 새로운 기술/라이브러리/개념 학습 내용을 추출하여 TIL(Today I Learned) 문서로 정리. 독립 실행 또는 daily-work-logger의 서브 에이전트로 호출 가능. "학습 정리", "TIL" |
| make-pdf | gstack | 0 | Turn any markdown file into a publication-quality PDF. Proper 1in margins, intelligent page breaks, page numbers, cover  |
| mastery-course | custom(KR) | 8 | 유료 인터넷 강의 정보(목차, 가격, 시간, 강사)를 입력받아 사용자 컨텍스트(직급/스택/취준 단계) 기준 수강 ROI를 판정하고, 가치가 부족하다고 판단되면 강의 목차의 학습 흐름을 보존한 채 공식 1차 레퍼런스  |
| obsidian-vault | custom(KR) | 0 | Obsidian vault 및 마크다운 문서 작업 시 사용. markdown-oxide LSP를 통한 효율적인 검색, 백링크 탐색, 태그 관리 지원. vault 경로, 태그 체계, vault-intelligence  |
| office-hours | gstack | 6 | YC Office Hours — two modes. Startup mode: six forcing questions that expose demand reality, status quo, desperate speci |
| open-gstack-browser | gstack | 0 | Launch GStack Browser — AI-controlled Chromium with the sidebar extension baked in. Opens a visible browser window where |
| pair-agent | gstack | 0 | Pair a remote AI agent with your browser. One command generates a setup key and prints instructions the other agent can  |
| pdf-processing-pro | external | 0 | Production-ready PDF processing with forms, tables, OCR, validation, and batch operations. Use when working with complex |
| plan-ceo-review | gstack | 1 | CEO/founder-mode plan review. Rethink the problem, find the 10-star product, challenge premises, expand scope when it cr |
| plan-design-review | gstack | 0 | Designer's eye plan review — interactive, like CEO and Eng review. Rates each design dimension 0-10, explains what would |
| plan-devex-review | gstack | 1 | Interactive developer experience plan review. Explores developer personas, benchmarks against competitors, designs magic |
| plan-eng-review | gstack | 14 | Eng manager-mode plan review. Lock in the execution plan — architecture, data flow, diagrams, edge cases, test coverage, |
| plan-tune | gstack | 0 | Self-tuning question sensitivity + developer psychographic for gstack (v1: observational). Review which AskUserQuestion  |
| project-status | custom(KR) | 1 | 프로젝트 루트 디렉토리나 심링크가 주어지면 Git/GitHub 현황을 종합 분석하여 레포트 출력. 서브 에이전트 기반 병렬 처리로 메인 컨텍스트 절약. "프로젝트 현황", "project status", "현황 파악 |
| qa-only | gstack | 0 | Report-only QA testing. Systematically tests a web application and produces a structured report with health score, scree |
| qa | gstack | 0 | Systematically QA test a web application and fix bugs found. Runs QA testing, then iteratively fixes bugs in source code |
| ralplan | external | 4 | Iterative planning with Planner, Architect, and Critic until consensus |
| react-best-practices | external | 0 | React and Next.js performance optimization guidelines from Vercel Engineering. This skill should be used when writing, r |
| retro | gstack | 0 | Weekly engineering retrospective. Analyzes commit history, work patterns, and code quality metrics with persistent histo |
| review | gstack | 0 | Pre-landing PR review. Analyzes diff against the base branch for SQL safety, LLM trust boundary violations, conditional  |
| setup-browser-cookies | gstack | 0 | Import cookies from your real Chromium browser into the headless browse session. Opens an interactive picker UI where yo |
| setup-deploy | gstack | 0 | Configure deployment settings for /land-and-deploy. Detects your deploy platform (Fly.io, Render, Vercel, Netlify, Herok |
| setup-gbrain | gstack | 0 | Set up gbrain for this coding agent: install the CLI, initialize a local PGLite or Supabase brain, register MCP, capture |
| ship | gstack | 0 | Ship workflow: detect + merge base branch, run tests, review diff, bump VERSION, update CHANGELOG, commit, push, create  |
| skill-creator | external | 0 | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an exist |
| unfreeze | gstack | 0 | Clear the freeze boundary set by /freeze, allowing edits to all directories again. Use when you want to widen edit scope |
| usage-pattern-analyzer | custom(KR) | 1 | Claude Code 도구 사용 패턴 및 생산성 트렌드 분석. 반복 작업 감지, 시간대별 생산성, 도구 사용 빈도 시각화. "패턴 분석", "사용 통계", "productivity" 등의 요청 시 자동 적용. |
| using-git-worktrees | superpowers | 0 | Use when starting feature work that needs isolation from current workspace or before executing implementation plans - cr |
| vis | custom(KR) | 0 | Vault Intelligence System (vis) CLI를 활용한 Obsidian vault 시맨틱 검색, 자동 태깅, MOC 생성, 관련 문서 연결, 주제별 문서 연결, 주제 수집, 태그 통계, 지식 공백  |
| work-tracker | unknown | 0 | Bidirectional task synchronization between local backlog (serena memories) and external systems (GitHub Issues, Things 3 |
| youtube-scriptwriter | custom(KR) | 0 | YouTube script pipeline orchestrator. Takes topic/keywords and optional reference video URLs, then runs success analysis |
| youtube-uploader | custom(KR) | 0 | YouTube 영상 업로드 자동화. upload-package.md를 파싱하여 메타데이터를 보강하고, |

## 백업 미포함 항목 (3 개)

| 스킬명 | 사유 | 복원 방법 |
|---|---|---|
| gstack | 외부 repo, node_modules 포함 2.27GB — 백업 비용 과다 | gstack 공식 install 스크립트 재실행 |
| .gstack-backup | gstack 자체의 보조 백업 디렉토리, 별도 skill 아님 | gstack 재설치 시 자동 생성 |
| checkpoint | 원본 ~/.claude/skills/checkpoint 가 깨진 symlink (gstack/checkpoint 미존재) | 원래부터 작동 안 했음, 복원 불요 |

## 비고

- 본 백업은 `cp -RL` 로 symlink dereference 하여 zero-base 후에도 무결.
- gstack 및 .gstack-backup 은 `rsync --exclude` 로 의도적 제외.
- node_modules, .git, .DS_Store 등 dependency 도 제외.
