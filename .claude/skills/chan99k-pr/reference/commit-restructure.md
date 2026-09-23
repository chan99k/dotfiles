# 커밋 히스토리 재구성 절차

`/chan99k-pr` Step 2에서 재구성이 필요하다고 판정되고 **사용자 승인을 받은 뒤에만** 실행한다.
`<base>`는 Step 1에서 탐지한 base branch다.

핵심 전제: 리뷰의 단위는 파일이나 시간이 아니라 **논리적 변경 단위**다. 작업 중 커밋은
"어떻게 디버깅했는가"의 기록이지만, PR 커밋은 "무엇을 만들었는가"를 리뷰어에게 설명하는
문서여야 한다.

## soft-reset vs rebase -i

| 도구 | 언제 |
|------|------|
| `git reset --soft` | 최종 스냅샷은 확정, 커밋 구조를 **백지에서 새로 설계**. 중간 커밋을 통째로 무시하고 새 논리 단위로 다시 담는다 |
| `git rebase -i` | 기존 커밋 대부분을 유지하며 일부만 squash/reword/reorder. "대체로 유지하되 다듬는다" |

"여러 개를 논리 단위 몇 개로 새로 쪼갠다"가 목적이면 soft-reset,
"대체로 유지"면 rebase -i.

## soft-reset 기본 절차

```bash
git branch backup/wip                            # 1. 안전망
git reset --soft $(git merge-base <base> HEAD)    # 2. 브랜치 전체를 인덱스로 되돌림
git reset                                         # 3. 인덱스를 워킹 디렉토리로 내림
# 4. git add -p 로 논리 단위씩 골라 담아 재커밋
```

- `merge-base`까지 푸는 이유: `HEAD~N`은 개수를 세야 하지만 merge-base는 브랜치가 갈라진
  지점을 정확히 잡아 "이 브랜치가 만든 변경 전부"를 대상으로 삼는다.
- **이중 안전망**: soft-reset은 원래 HEAD를 `ORIG_HEAD`에 자동 저장한다. 잘못되면
  `git reset --soft ORIG_HEAD` 한 줄로 되돌린다. `backup/wip` 브랜치와 함께 이중.

## 커밋 쌓는 순서 (의존성 = 아래에서 위로)

리뷰어는 위에서부터 읽으므로 먼저 읽혀야 할 것을 먼저 커밋한다:

1. 순수 리팩터링 / 이름 변경 (동작 변화 없음 - 빠르게 넘길 수 있는 것)
2. 도메인 모델, 값 객체, 엔티티
3. 인프라, 레포지토리 구현
4. 애플리케이션 서비스, API 계층
5. 테스트 (커밋마다 동봉하거나 마지막에 묶기)
6. 설정, 마이그레이션

## 절대 원칙

- **각 커밋은 독립적으로 빌드와 테스트를 통과해야 한다.** 유일한 절대 기준. bisect가 살아 있고,
  리뷰어가 중간 커밋을 체크아웃해 확인할 수 있다. (문서 전용 PR은 자동 충족)
- **이동/이름 변경과 로직 변경을 한 커밋에 섞지 않는다.** 섞이면 diff가 폭발한다.
- **포맷터 일괄 적용은 반드시 별도 커밋.** noise와 signal을 분리한다.
- untracked 파일은 reset 대상이 아니므로 매 단계 `git status`로 확인한다.

도구: `git add -p`(hunk 단위, `e`로 더 잘게), `git add -i`(대화식),
`git stash push -- <path>`(다음 커밋으로 미뤄두기), `git commit --amend`(직전 커밋에 누락분 추가).

## 검증 (재구성 후 필수)

재구성 후 `git diff <base>...HEAD`가 `backup/wip` 브랜치의 diff와 **완전히 일치**하는지 확인한다.
일치하면 히스토리만 바뀌고 결과물은 보존됐다는 증거다.

```bash
git diff <base>...HEAD > /tmp/after.diff
git diff <base>...backup/wip > /tmp/before.diff
diff /tmp/before.diff /tmp/after.diff && echo "일치 - 결과물 보존됨"
```

`backup/wip`은 PR이 머지될 때까지 남겨둔다. hunk를 흘렸는지 대조하는 근거가 된다.

## Push

- **재구성은 push 전에 끝내는 것이 원칙.** 아직 push 안 된 브랜치면 재구성 후 그냥 push한다.
- **이미 push된 브랜치는 기본적으로 재구성하지 않는다.** 공유된 히스토리 재작성은 팀원 로컬과
  충돌한다.
- 부득이 재구성해야 하면:
  - `--force-with-lease`만 쓴다. **본인 작업 브랜치에 한해서만** 허용한다. 다른 사람과
    공유 중인 브랜치엔 쓰지 않는다.
  - 순수 `--force`는 절대 금지 (남의 커밋을 덮어쓸 수 있다).
  - push는 **사용자 승인을 받은 뒤** `chan99k-push-preflight`를 거쳐 실행한다.

## PR 분할로 확장

변경이 자연스럽게 여러 관심사로 갈리면 커밋 정리에서 멈추지 않아도 된다. soft-reset으로 변경을
인덱스로 되돌린 뒤 새 브랜치를 파서 일부 변경만 담아 별도의 작은 PR로 내보낸다. 거대한 PR 하나보다
독립적인 작은 PR 여럿이 리뷰어에게 친절하다. 스택으로 이어지면 `stacked-worktrees` 스킬을 따른다.
