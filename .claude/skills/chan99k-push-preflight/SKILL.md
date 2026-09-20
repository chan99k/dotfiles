---
name: chan99k-push-preflight
description: push 전 안전 점검 10항목. 원격으로 나가기 전에 브랜치/발산/유출/게이트 실증을 확인하고, 하나라도 걸리면 push 하지 않고 보고한다. /chan99k-pr 이 PR 생성·갱신 전에 호출하며 단독 호출도 가능하다.
metadata:
  author: chan99k
  version: 1.0.0
---

# Push Preflight - push 전 안전 점검

원격으로 나가는 push 는 되돌리기가 비대칭이다. push 직전에 아래 10항목을 순서대로 확인하고,
**하나라도 걸리면 push 하지 않고 무엇이 걸렸는지 보고한다.** 통과 판정은 각 항목의 명령
출력을 근거로 하며, 요약하지 않고 걸린 항목의 출력 원문을 보고에 옮긴다.

승인 게이트는 이 스킬 밖이다 - push 실행 자체는 사용자 확인(GIT_PUSH_OK=1 관행)을 따른다.
이 스킬은 "확인을 요청해도 되는 상태인가" 를 판정한다.

## 점검 항목

### 1. 워크트리와 브랜치

```bash
pwd && git rev-parse --abbrev-ref HEAD
```

의도한 워크트리인가. push 금지 브랜치(main, 타인 소유 브랜치)가 아닌가.

### 2. 원격 최신 상태

```bash
git fetch <remote> <branch> && git rev-parse origin/<branch>
```

마지막으로 본 위치에서 원격이 움직였는가. 움직였으면 먼저 그 커밋을 읽는다.

### 3. fast-forward 판정 - 실패 시 자동 진행 금지

```bash
git merge-base --is-ancestor origin/<branch> HEAD && echo FF || echo DIVERGED
```

`DIVERGED` 면 force 가 필요한 상황이다. **여기서 멈추고 사람에게 묻는다.**
force 판단은 사람 영역이고, push guard 가 force 플래그를 막으므로 실행도 사람이 한다.

사람에게 명령을 줄 때 lease 문법에 주의한다 - 기대값 구분자는 콜론이다.

```bash
git push --force-with-lease=<branch>:<기대SHA> origin <branch>   # 콜론이다
# =<branch>=<SHA> 로 쓰면 "branch=SHA" 라는 ref 에 lease 가 걸려 매칭이 안 되고,
# lease 없는 일반 push 로 나가 non-fast-forward 거부가 난다 (2026-09-03 실사례)
```

### 4. 나갈 커밋과 파일

```bash
git log origin/<branch>..HEAD --oneline
git diff --numstat origin/<branch>..HEAD
```

의도한 커밋만 나가는가. 의도하지 않은 파일이 diff 에 섞여 있지 않은가.

### 5. 작업 트리 clean

```bash
git status --short
```

커밋 안 된 변경이 있으면 그것이 push 대상에서 빠진다는 것을 인지한 상태인가.

### 6. 개인 식별자 스캔

```bash
git log origin/<branch>..HEAD --format=%B | grep -n '99K-'
git diff origin/<branch>..HEAD | grep -n '99K-'
```

**0건이어야 통과.** 개인 트래커 식별자는 원격에 나가면 안 된다.
커밋 메시지에서 나오면 해당 커밋을 reword, diff 에서 나오면 파일을 고쳐 커밋을 정정한다.

### 7. 금지 기호 스캔

```bash
git log origin/<branch>..HEAD --format=%B | grep -nP '[·—]'
git diff origin/<branch>..HEAD -- '*.md' | grep -P '^\+' | grep -nP '[·—]'
```

가운뎃점과 em dash. 커밋 메시지와 문서 diff 가 대상이다.

### 8. 테스트 게이트 실증 - BUILD SUCCESSFUL 을 믿지 않는다

`./gradlew check` 가 성공해도 up-to-date 스킵이면 아무것도 실행되지 않은 것이다.
리베이스 직후 빈 게이트가 통과한 실사례가 있다. 판정은 결과 XML 로 한다.

```bash
RUN_START=$(date +%s)
./gradlew check
find . -path '*/build/test-results/*/*.xml' -newermt "@${RUN_START}" \
  | xargs grep -ho 'tests="[0-9]*"' | grep -o '[0-9]*' | paste -sd+ - | bc
```

실행 시작 이후 갱신된 결과 파일의 tests 합이 0 이거나 파일이 없으면 실행 안 된 것이다.
그때는 `--rerun-tasks` 로 다시 돌린다. failures/errors 도 같은 방식으로 0 을 확인한다.

### 9. 연결 PR 확인

```bash
gh pr list --head <branch> --state open
```

PR 이 이미 있으면 `gh pr create` 가 아니라 push 로 갱신한다. 본문을 고칠 때는
`gh pr edit` 전에 원격 본문을 다시 받아 남의 편집을 덮어쓰지 않는다.

### 10. push 후 검증

```bash
git fetch <remote> <branch> && \
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/<branch>)" ] && echo SYNCED
```

push 가 승인되어 실행된 뒤, 로컬과 원격 SHA 일치를 확인하고 나서야 완료를 보고한다.

## 보고 형식

```
## Push Preflight - <branch>

| # | 항목 | 판정 |
|---|------|------|
| 1 | 워크트리/브랜치 | PASS <경로, 브랜치> |
| 3 | fast-forward | PASS / DIVERGED (중단) |
| 6 | 개인 식별자 | PASS 0건 / FAIL <원문> |
| 8 | 게이트 실증 | PASS tests=<n> failures=0 / FAIL <사유> |
| ... |

걸린 항목: <없으면 "없음 - push 확인 요청 가능">
```

전부 PASS 일 때만 사용자에게 push 확인을 요청한다.
