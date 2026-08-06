---
name: commit-blueprint
description: Use when about to run git commit, or any state-mutating git command (switch / checkout -b / branch / checkout <ref> -- / reset / rm) — especially under time pressure, in a shared or active working tree, or when acting on a remembered/stale git state.
---

# Commit Blueprint

## Overview

커밋하기 전 — 또는 git 상태를 바꾸기 전 — **항상 라이브 상태를 먼저 확인하고(Preflight), 그 사실이 어느 정도의 청사진을 만들지 결정한다.** 이 절차가 막는 사고(잘못된 브랜치에 커밋, 남의 작업 삭제 staging, stale한 가정에서 분기)는 되돌리는 데 수 분~수 시간이 든다.

**기억 속 git 상태는 현재 git 상태가 아니다. 매번 라이브로 검증한다.**

## The Iron Rule — 항상 Preflight (Tier 0, 비협상)

`git commit`, 또는 상태를 바꾸는 git 명령 전에 **멈추고 Preflight를 실행한다.** 기억으로 대체하지 않는다. Preflight는 read-only 명령 3~4개뿐이다.

**"빨리 해달라"는 Preflight를 면제하지 않는다.** Preflight가 빠른 길이고, 사고가 느린 길이다.

```
git rev-parse --abbrev-ref HEAD      # 실제 현재 브랜치
git rev-parse --show-toplevel        # 지금 어느 트리에 있나
git status --short --branch          # clean? 무엇이 staged? 미추적?
ls .git/MERGE_HEAD .git/REVERT_HEAD .git/rebase-* 2>/dev/null  # 진행 중 작업?
```

**Preflight의 출력이 티어를 결정한다.** "이건 위험한가?"를 주관으로 판단하지 않는다 — 아래 5신호를 git 사실로 채점하면 티어가 기계적으로 정해진다.

## Routing — 사실이 티어를 정한다

아래 신호 중 **하나라도 true → Tier 2** (전체 청사진 + 명시 확인).
**전부 false → Tier 1** (경량).

| 신호 | 조건 (Preflight 출력으로 판정) |
|------|------|
| **S1 행위** | plain commit이 아닌 **상태변경 명령** (switch / checkout -b / branch / checkout `<ref>` -- / reset / rm) |
| **S2 진행중** | MERGE_HEAD / REVERT_HEAD / rebase / cherry-pick 진행 중 |
| **S3 보호** | 대상이 `main` 또는 보호 브랜치 |
| **S4 공유트리** | `show-toplevel`이 `~/.claude/worktrees/*` 아래가 **아님** (= repo 루트/공유 트리) |
| **S5 dirty** | 이번 턴에 내가 stage한 것 **외**의 변경·미추적·삭제·리네임이 staged/worktree에 포함 |

> S4 때문에 **Tier 1(경량)은 전용 worktree 안에서만 열린다.** repo 루트의 커밋은 항상 Tier 2다. 이것은 의도된 설계다 — "경량을 쓰려면 격리하라"가 되어, 티어링이 곧 격리를 유도한다. 약한 S5를 S4가 이중으로 받쳐 오라우팅을 막는다.

## Tier 1 — 경량 (5신호 전부 false)

전용 worktree · clean · feature 브랜치 · plain commit인 일상 케이스. 멈추지 않고 짧게 노출 후 커밋:

1. 대상 브랜치
2. `git diff --cached --stat`
3. 커밋 메시지 초안

→ 보여주고 그대로 커밋. stop-and-wait 없음.

## Tier 2 — 전체 청사진 (신호 ≥1)

상태변경 명령이거나 · 진행중 작업이 있거나 · 보호 브랜치거나 · 공유 트리거나 · dirty. 사고가 나는 조건이다. 다음을 **순서대로 산출하고 `git commit`/상태변경 전에 사용자에게 보여준 뒤, 확인받고 진행한다.**

1. **라이브 상태**: Preflight 출력 그대로 (브랜치 · 트리 위치 · clean 여부 · 진행중 작업)
2. **격리 판단**: 공유/활성 트리(S4)면 **`git worktree`로 격리.** 공유 트리에서 `git switch`/`checkout -b` 금지.
3. **무엇이 커밋되나**: 대상 브랜치 + `git diff --cached --stat`. 의도치 않은 경로(빌드 산출물, 인프라 디렉터리, 남의 파일) 스캔.
4. **메시지 초안**.
5. **1~4를 보여주고, 의도와 일치할 때만 진행.**

## Postflight — 커밋이 실제로 생겼는지 확인 (Tier 무관, 항상)

**Preflight 는 커밋 직전의 사실이다. 커밋 결과는 아니다.** 인덱스는 Preflight 와 `git commit` 사이에도 바뀔 수 있다 — 같은 레포에서 다른 세션·에이전트·에디터가 동시에 `git add` 를 하면 내가 stage 한 것이 사라진다. 5신호는 이 창을 잡지 못한다.

커밋 명령마다 결과를 **한 줄로 확인한다.**

```
git log -1 --format='%h %s'
```

**판정은 이 출력의 subject 가 내가 쓴 메시지인가 하나로만 한다.**

| 관측 | 판정 |
|---|---|
| subject 가 내 메시지 | 커밋 성공 |
| subject 가 남의 메시지 | **내 커밋은 생기지 않았다.** 인덱스를 누가 가져갔다 |
| exit code, ahead 카운트 증가, 스테이징이 비었음 | **근거가 아니다.** 동시 커밋이 전부 똑같이 만든다 |

`ahead` 가 12 에서 13 이 된 것은 내 커밋의 증거가 아니다. 남이 커밋해도 13 이 된다.

### 내 커밋이 없을 때의 복구

원인을 추측하기 전에 `git log -1` 의 커밋이 누구 것인지 본다. **남의 커밋이면 HEAD 를 건드리지 않는다.**

```
git add <내가 의도한 경로만 명시>     # 원래 목록 그대로. 새로 고르지 않는다
git log -1 --format='%h %s'          # 다시 확인
```

**금지 — HEAD 가 남의 커밋일 수 있다:**

- `git reset --soft HEAD~1` / `git reset --hard` — 다른 세션의 커밋을 지운다
- `git stash` / `git stash -u` — 다른 세션의 작업 파일까지 쓸어담는다
- `git commit --amend` — 남의 커밋에 내 변경을 얹는다
- `git commit --no-verify` — hook 은 원인이 아니었다. 진단 없이 가드만 끈다
- `git add -A` / `git add .` — 인덱스가 밀린 상황에서 남의 변경까지 커밋한다

재스테이징 경로는 **처음 청사진에 적은 목록 그대로**다. 커밋 실패 후 status 에 새로 보이는 파일을 목록에 추가하지 않는다 — 그것은 내 변경이 아닐 수 있다.

## Red Flags — STOP, Preflight부터

- "빨리 해줘 / 사용자 바쁨" → Preflight는 싸다, 한다
- "저위험이야, 파일 하나 복사인데 / 새 브랜치인데"
- 이전 스냅샷의 브랜치/커밋을 라이브 재확인 없이 사용
- worktree 안이니까 당연히 경량이겠지 → **dirty(S5)·상태변경(S1)이면 worktree라도 Tier 2**
- 변경 명령을 직전 명령 성공 확인 없이 이어 실행
- 커밋 후 `git log -1` 없이 다음 단계로 넘어감
- 커밋이 안 생긴 원인을 hook 이라 단정 (동시 writer 를 먼저 배제했나?)
- 복구에 `reset` / `stash` / `--amend` / `--no-verify` / `add -A` 가 등장

## Rationalizations

| 변명 | 현실 |
|---|---|
| "빨리라니까 Preflight 끊지 말자" | Preflight는 read-only 4줄. 잘못된 커밋 되돌리기는 안 빠르다 |
| "저위험, 파일 하나" | 이 스킬을 만든 사고가 "파일 하나 복사"였고, 사용자 작업 삭제를 staging했다 |
| "스냅샷이 브랜치는 X라던데" | 브랜치 ref는 움직인다. 기억된 ref는 추측. HEAD를 라이브 재확인 |
| "worktree 안이니 경량이지" | 경량은 5신호 **전부** false일 때만. dirty·상태변경 명령이면 worktree라도 Tier 2 |
| "이 정도면 저위험으로 경량 가도 돼" | 위험도를 *주관 판단*하지 않는다. 5신호를 git 사실로 채점해 티어가 정해진다 |
| "청사진 보여주는 건 관료적" | 허락 요청이 아니라 상태 노출이다. 짧은 블록 하나 |
| "ahead 가 늘었으니 커밋됐다" | 남이 커밋해도 늘어난다. `git log -1` 의 subject 만이 근거다 |
| "스테이징이 비었으니 커밋에 들어갔다" | 남이 인덱스를 가져가도 비워진다. 같은 관측, 반대 결론 |
| "hook 이 파일 고치고 실패했겠지" | 흔한 오진. 동시 writer 를 먼저 배제하기 전엔 단정 금물 |
| "reset --soft 로 되돌리고 다시 하자" | HEAD 가 남의 커밋이면 그걸 지운다. 되돌릴 내 커밋은 애초에 없다 |
| "일단 stash 해서 안전하게" | `-u` 는 다른 세션의 미추적 작업까지 가져간다. 안전하지 않다 |
| "status 에 뜬 파일 다 넣고 다시 커밋" | 그중 상당수는 내 변경이 아니다. 원래 목록만 재스테이징 |

## Common Mistakes

- **Preflight 생략**: 기억으로 티어를 정함 → stale 사고. 항상 라이브 4줄 먼저.
- **오라우팅**: 위험 케이스를 "저위험"이라 경량으로 흘림. 티어는 *주관*이 아니라 *5신호 채점*으로 정한다.
- **격리 생략**: 공유 트리(S4)에서 브랜치 전환 → 충돌·남의 작업 staging. `git worktree add`로 격리.
- **실패 무시 연쇄**: `cannot switch branch` 같은 실패는 다음 명령을 멈추지 않는다. exit status 확인.
- **메시지 미리보기로 축소**: Tier 2에서 상태검증 + 격리 판단이 진짜 사고를 막는 부분. 메시지만 보여주는 건 청사진이 아니다.
