# USAGE — agentic-team 사용 안내

본 문서는 본인이 일상 작업 흐름에서 본 시스템을 *어떻게* 활용하는지에 대한
시각적 walkthrough. tmux 4-pane dashboard (PM | gemini · codex · auditor) 가
*각 단계에서 어떻게 보이는지* ASCII 그림으로 보여줌.

**관련 문서**:
- [SPEC.md](SPEC.md) — 본 시스템 설계 명세 (§1-§13 lock + §14 확장 청사진)
- [VERIFICATION.md](VERIFICATION.md) — Option C-2 정직성 검증 자료

---

## Dashboard 사용 시나리오 — 7단계 walkthrough

### 단계 0 — 사전 설정 (한 번만)

```bash
# ~/.tmux.conf 에 한 줄 추가
echo 'source-file ~/.claude/agentic-team/tmux/keybinding.conf' >> ~/.tmux.conf

# 적용
tmux source-file ~/.tmux.conf
```

이 시점부터 모든 tmux 세션에서 `prefix + R` 작동.

---

### 단계 1 — 작업 진입

```
[본인]
   │
   ├─ tmux 세션 시작 (예: tmux new -s giftify)
   ├─ 작업 디렉토리 진입: cd ~/IdeaProjects/grep/giftify-be
   └─ 본인이 사용하는 방식으로 Claude Code 시작
```

이 시점 — *단일 pane*. 화면 전체가 본인의 PM(Claude) 대화 공간.

```
┌──────────────────────────────────────────────────────────────────────────┐
│ giftify · main · 17:00                                                    │
│                                                                            │
│ chan99 ➜ giftify-be $ claude                                              │
│                                                                            │
│ Claude Code v? — 새 세션 시작                                              │
│                                                                            │
│ > _                                                                        │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘
                             ↑ 본인이 자연어 입력하는 자리
```

---

### 단계 2 — `prefix + R` 으로 dashboard 호출

본인이 tmux prefix(기본 `Ctrl-b`) 후 `R` 키 → `team-layout` 실행 → 4-pane
분할 (좌 60% PM / 우측 컬럼 40% 를 gemini · codex · auditor 1/3 균등 3분할).

```
┌────────────────────────────────────────────┬───────────────────────────────┐
│ giftify · main pane (PM)                    │ Gemini · researcher           │
│                                              │ Query:   (no activity)        │
│                                              │ Status:  —                    │
│ Claude Code v? — 새 세션 시작                │ Sources: 0                    │
│                                              │ ─                             │
│                                              │ gemini · 17:01:02 · q/space/l │
│                                              ├───────────────────────────────┤
│ > _                                          │ Codex · reviewer              │
│  ↑ 본인 입력은 여기                          │ Focus:    (no activity)       │
│                                              │ Verdict:  —                   │
│                                              │ Findings: 0 b / 0 M / 0 m     │
│                                              │ ─                             │
│                                              │ codex · 17:01:02 · q/space/l  │
│                                              ├───────────────────────────────┤
│                                              │ Auditor · idle                │
│                                              │ Focus:    (no activity)       │
│                                              │ Verdict:  —                   │
│                                              │ Findings: 0 b / 0 M / 0 m     │
│                                              │ ─                             │
│                                              │ audit · 17:01:02 · q/space/l  │
└────────────────────────────────────────────┴───────────────────────────────┘
                                              ↑ 세 watcher 모두 1초 폴링 시작
```

`team-name` 자동 감지 — tmux 세션 이름 `giftify` 가 곧 격리 키. 로그는
`<git-top>/.agentic-team/log/giftify/` 로 누적 (`codex-*.log`, `gemini-*.log`,
`audit-*.log` 3종 네임스페이스).

> Auditor pane 의 페르소나 색상은 호출 시점에 결정 — `ceo` 파랑 / `cto` 시안
> / `idle` 회색 (dim). 하단 walkthrough 는 ask-codex / ask-gemini 시나리오에
> 집중 — Auditor pane 은 *idle 상태로 우측 하단에 항상 존재* 한다는 사실만
> 기억. audit-codex 호출 흐름은 별도 시나리오로 추후 추가 예정.

---

### 단계 3 — 자연어 요청 → ask-codex 진행 중

본인이 좌측 pane 에서 자연어로 말함:

```
> 이 cart 패키지에서 cascade.ALL 변경 영향 한 번 리뷰 시켜줘
```

이때 *Claude PM* 이 라우팅 결정 → `ask-codex --focus "JpaCart cascade.ALL
변경 영향 리뷰"` 실행. 우하 pane 의 watcher 가 *1초 안에* log 변경 감지 →
redraw.

```
┌────────────────────────────────────────────┬───────────────────────────────┐
│ Claude PM                                    │ Gemini · researcher           │
│                                              │ Query:   (no activity)        │
│ > 이 cart 패키지에서 cascade.ALL 변경        │ Status:  —                    │
│   영향 한 번 리뷰 시켜줘                     │ Sources: 0                    │
│                                              │ ─                             │
│ Claude: ask-codex 호출합니다...              │ gemini · 17:02:15 · q/space/l │
│ (응답 대기 중...)                            ├───────────────────────────────┤
│                                              │ Codex · reviewer              │
│                                              │ Focus:    JpaCart cascade.AL… │
│                                              │ Verdict:  ⏳ running          │
│                                              │ Findings: 0 b / 0 M / 0 m     │
│                                              │ ─                             │
│                                              │ codex · 17:02:18 · q/space/l  │
└────────────────────────────────────────────┴───────────────────────────────┘
                                              ↑ Verdict 자리에 노란색 ⏳ running
                                                Focus 는 trunc 되어 ellipsis 처리
```

> 우측 하단 Auditor pane 은 idle 상태 — 본 walkthrough 에선 표시 생략.

좌측에서 *기다리는* 동안 우하 pane 으로 *진행 상황 실시간 확인*.

---

### 단계 4 — Codex 응답 도착, verdict 색 변화

Codex 가 응답 완료 → log 파일에 `--- END (rc=0) ---` 기록 → watcher 가 다음
1초 polling 에서 `_DRC_RUNNING=0` 감지 → 새 prompt 으로 redraw.

#### 4-A. NEEDS-FIX 케이스 (Blocker 발견)

```
┌────────────────────────────────────────────┬───────────────────────────────┐
│ Claude PM                                    │ Gemini · researcher           │
│                                              │ Query:   (no activity)        │
│ Claude: 리뷰 완료 — verdict NEEDS-FIX,       │ Status:  —                    │
│ blocker 2건. 핵심: cascade.ALL 제거 후       │ Sources: 0                    │
│ orphanRemoval 누락 → 메모리 누수 위험.       │ ─                             │
│ 전체 로그: <link>                            │ gemini · 17:02:15 · q/space/l │
│                                              ├───────────────────────────────┤
│ > _                                          │ Codex · reviewer              │
│                                              │ Focus:    JpaCart cascade.AL… │
│                                              │ Verdict:  NEEDS-FIX           │ ← 빨강
│                                              │           cascade.ALL 제거 시 │
│                                              │           detached entity 에… │
│                                              │ Findings: 2 b / 1 M / 1 m     │ ← 빨/노/회
│                                              │ ─                             │
│                                              │ codex · 17:03:42 · q/space/l  │
└────────────────────────────────────────────┴───────────────────────────────┘
```

> Auditor pane 은 우측 하단에 idle 로 유지 (생략).

색 의미: `NEEDS-FIX` 빨강 (보안·correctness 위험), Findings 의 `2 b` 빨강
(Blocker 카운트), `1 M` 노랑 (Major), `1 m` 회색 (Minor).


#### 4-B. `audit-codex` (전략 감사) 결과

본인이 CEO 또는 CTO 관점이 필요할 때:
`audit-codex --persona cto "Giftify"`

우하단 Auditor pane 이 활성화되며, 페르소나 색상(cto=시안)으로 시각화됩니다.

```
┌────────────────────────────────────────────┬───────────────────────────────┐
│ Claude PM                                    │ Gemini · researcher           │
│                                              │ Status:  —                    │
│ > Giftify 기술 부채 한 번 훑어봐줘           │ ─                             │
│ Claude: audit-codex (cto) 호출합니다...      │ gemini · 21:03:10 · q/space/l │
│ (응답 대기 중...)                            ├───────────────────────────────┤
│                                              │ Codex · reviewer              │
│                                              │ Verdict:  SHIP                │
│                                              │ ...                           │
│                                              ├───────────────────────────────┤
│                                              │ Auditor · cto                 │ ← 시안색
│                                              │ Focus:    Giftify             │
│                                              │ Verdict:  NEEDS-FIX           │ ← 빨강
│                                              │           Cart SQL amplifica… │
│                                              │ Findings: 0 b / 2 M / 1 m     │
│                                              │ ─                             │
│                                              │ audit · 21:04:55 · q/space/l  │
└────────────────────────────────────────────┴───────────────────────────────┘
```

**CTO 감사 결과 (Giftify smoke 실사례)**:
- **Verdict**: `NEEDS-FIX` — 장바구니 write path 성능 병목 확인.
- **Major**: `JpaCart.java:21` — `CascadeType.ALL` 로 인한 SQL 증폭(36회).
- **Major**: `application-prod.yml:11` — Hikari pool size 미설정(기본값 의존).

이처럼 `audit-codex` 는 코드의 문법적 오류가 아닌, **운영 리스크와 아키텍처 부채** 를 짚어줍니다.

#### 4-C. SHIP 케이스 (정상)

```
                                              │ Codex · reviewer              │
                                              │ Focus:    JpaCart cascade.AL… │
                                              │ Verdict:  SHIP                │ ← 초록
                                              │           working tree clean… │
                                              │ Findings: 0 b / 0 M / 0 m     │
```

색 의미: `SHIP` 초록 (안전).

---

### 단계 5 — NEED-RESEARCH 루프 (본 시스템의 핵심 흐름)

본 코덱스 응답 끝에 `## NEED RESEARCH` 블록이 있으면, Claude PM 이 본인에게
묻고 → `ask-gemini` 호출.

#### 5-A. 본인에게 확인

```
> 좌측 pane:
Claude: Codex 가 다음 사실을 모릅니다:
  · "Hibernate 6.x 의 cascade.ALL 의미가 5.x 와 어떻게 다른가?"
Gemini 호출해서 받아올까요? (Y/n)
> y
Claude: ask-gemini 호출합니다...
```

#### 5-B. Gemini 진행 (우상 pane 활성화)

```
┌────────────────────────────────────────────┬───────────────────────────────┐
│ Claude PM                                    │ Gemini · researcher           │
│                                              │ Query:   Hibernate 6.x 의 ca… │
│ Claude: ask-gemini 호출 중...                │ Status:  ⏳ running           │ ← 노랑
│                                              │ Sources: 0                    │
│                                              │ ─                             │
│                                              │ gemini · 17:04:12 · q/space/l │
│                                              ├───────────────────────────────┤
│                                              │ Codex · reviewer              │ ← 4-A 의 NEEDS-FIX
│                                              │ Focus:    JpaCart cascade.AL… │   상태 그대로 유지
│                                              │ Verdict:  NEEDS-FIX           │
│                                              │ ...                           │
└────────────────────────────────────────────┴───────────────────────────────┘
```

> Auditor pane 은 우측 하단에 idle 로 유지 (생략).

#### 5-C. Gemini 완료, 본인에게 요약 보고

```
                                              │ Gemini · researcher           │
                                              │ Query:   Hibernate 6.x 의 ca… │
                                              │ Status:  ✓ done               │ ← 초록
                                              │ Lead:    Hibernate 6.x 에서 c…│
                                              │ Sources: 2                    │
```

좌측에 요약:

```
Claude: Gemini 답변:
  · cascade.ALL 정의는 5.x 와 동일, but 내부 SQM 엔진 도입으로 ...
  · MutationExecutor 도입으로 REMOVE/PERSIST 가 벌크 연산과 일관성 향상
  · Source: https://docs.jboss.org/hibernate/orm/6.0/migration-guide/...
전체: <log path>
이제 ask-codex 재호출 (--with-research) 진행할까요? (Y/n)
> y
```

#### 5-D. Codex 재호출 → 최종 verdict

```
                                              │ Codex · reviewer              │
                                              │ Focus:    JpaCart cascade.AL… │
                                              │ Verdict:  ⏳ running          │ ← 다시 노랑
                                              │ ...                           │
                                              │ codex · 17:04:55 · q/space/l  │
```

→ 1분 후

```
                                              │ Codex · reviewer              │
                                              │ Focus:    JpaCart cascade.AL… │
                                              │ Verdict:  NEEDS-FIX           │
                                              │           orphanRemoval 누락 │
                                              │ Findings: 1 b / 0 M / 0 m     │ ← Major 1건은
                                              │ ─                             │   리서치로 해소됨
                                              │ codex · 17:05:30 · q/space/l  │
```

좌측에 최종 보고:

```
Claude: 재리뷰 완료. Major 1건은 Hibernate 6.x 의미 변화가 영향 X
로 판명되어 해소. Blocker 1건만 남음 — orphanRemoval 추가 필요.
diff 생성할까요? (Y/n)
```

본인이 *NEED-RESEARCH 루프의 모든 단계* 를 *우측 pane* 에서 시각적으로
따라갈 수 있음 — 좌측은 의미 정리만 하고, 우측이 실시간 진행 추적.

---

### 단계 6 — pane 안 단축키 (각 dashboard pane 에 focus 둔 후)

| 키 | 동작 |
|---|---|
| `q` | 해당 watcher 만 종료. pane 닫힘. |
| `space` | pause/resume 토글. paused 동안 `[paused]` 표시, 마지막 frame 유지. |
| `l` | 해당 pane 의 raw 로그 (`latest-codex.log` / `latest-gemini.log` / `latest-audit.log` 중 1종) 를 `less` 로 *전체* 보기. ESC 로 복귀 — watcher 재개. |

```
                                              │ Codex · reviewer              │
                                              │ Focus:    JpaCart cascade.AL… │
                                              │ Verdict:  NEEDS-FIX           │
                                              │ Findings: 1 b / 0 M / 0 m     │
                                              │ ─                             │
                                              │ [paused — space to resume]    │ ← space 누름
```

---

### 단계 7 — 작업 종료

본인이 작업 끝 → tmux 그대로 두면 watcher 도 계속 돔 (1초마다 폴링, 변경
없으면 redraw 안 함 — CPU 무시 가능). 또는 각 pane 에서 `q` 로 watcher 종료.
tmux 세션 종료 시(`exit` 또는 `prefix + &`) 모든 watcher 자동 종료
(`trap INT TERM EXIT` 작동).

다음 작업 시작 → `prefix + R` 으로 다시 4-pane. 본인의 *작업 흐름과 한 몸*.

---

## 본 시스템 핵심 구조 다이어그램

```
                              [본인]
                                 │
                        자연어 입력 (좌측 pane)
                                 ▼
                          ┌──────────────┐
                          │  Claude PM   │ ← 본 Claude 세션
                          └──┬───┬───┬───┘
              ask-codex      │   │   │   ask-gemini
            audit-codex ─────┘   │   └────────┐
                   ┌─────────────┘            │
                   ▼             ▼            ▼
            ┌─────────┐    ┌─────────┐  ┌─────────┐
            │  Codex  │    │  Codex  │  │ Gemini  │ ← 외부 CLI 자체 실행
            │ (review)│    │ (audit) │  │  CLI    │
            └────┬────┘    └────┬────┘  └────┬────┘
                 │              │             │
                 └─── log 파일 쓰기 ──────────┘
                            │
                            ▼
   <git-top>/.agentic-team/log/<team>/latest-{codex,audit,gemini}.log
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
   [우중 pane]         [우하 pane]          [우상 pane]
   codex watcher       audit watcher        gemini watcher
   (1초 폴링)           (persona 색상)        (1초 폴링)
        │                   │                    │
        ▼                   ▼                    ▼
   verdict color bar   ceo=파랑/cto=시안     status + lead + sources
```

---

## 자주 묻는 질문 (예상)

### 본인이 dashboard 안 띄우고 wrapper 만 바로 쓰면?

가능. `prefix + R` 은 *시각화* 만 위함. dashboard 없어도:

```bash
ask-codex "리뷰 포커스"
ask-gemini --query "사실 질문" --max-words 200
```

는 항상 동작. 응답은 stdout 으로, 로그는 동일 위치에 누적.

### log 파일이 너무 쌓이면?

`<git-top>/.agentic-team/log/<team>/` 안 누적. 본인이 주기적으로 정리 권장.
또는 git hook 으로 자동 prune. 본 시스템은 *자동 정리 안 함* — log 자체가
*audit trail* 가치를 가지므로 본인 정책에 맡김.

### 같은 시점에 여러 작업(Giftify + AIDEX) 동시 진행?

`team_name()` 가 *tmux 세션 이름* 으로 격리. tmux 세션 두 개 띄우고 각각
`tmux new -s giftify`, `tmux new -s aidex` 로 시작하면 로그 디렉토리도
`giftify/`, `aidex/` 로 분리됨. dashboard 도 각 세션의 prefix+R 로 독립
띄움.

### codex/gemini quota 한도에 가깝거나 도달하면?

본 wrapper 는 quota 는 추적 안 함. 한도 도달 시 codex/gemini CLI 자체가
에러 응답 → wrapper rc != 0 으로 전달 → log 의 `--- END (rc=N) ---` 에
기록. dashboard 에선 verdict 가 `—` (회색) 으로 표시.

### graphify 그래프 빌드 안 했으면?

stderr 로 `[ask-codex] no graph for this project ...` 알림 후 *그대로 진행*.
빌드는 본인 정책 — `/graphify .` 로 첫 빌드 후 `graphify hook install` 로
자동 갱신 권장 (CLAUDE.md 의 graphify 운영 정책 참조).
