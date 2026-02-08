# 2025년 전체 Daily Work Logger 배치 실행 + 주/월 요약 계획

## 개요

2025년 365일에 대해 `/daily-work-logger` 스킬을 tmux-orchestrator로 실행하고,
결과를 주간/월간 요약 문서로 정리합니다.

## 현재 상태

- 기존 daily notes: 191개 (2025-02-17 ~ 2025-12-31), `notes/dailies/2025/`
- 1월 daily notes: 없음 (활동 데이터도 거의 없을 것)
- 주간/월간 요약 파일: 없음
- orchestrate.py: daily-logger 지원 있으나 rate limit/resume 미구현

## 수정 대상 파일 (3개)

| 파일 | 변경 내용 |
|------|----------|
| `orchestrate.py` | timeout 24h, progress tracking, resume, staggered deploy, summary 메서드 |
| `templates/daily-logger/agent_template.py` | rate limit 대응, inter-date delay, progress 기록 |
| `templates/daily-logger/config.yaml` | agent 수, timeout, rate limit 설정 |

---

## Phase 1: orchestrate.py 수정

### 1-1. Config 기본값 변경 (Line 66-71)

```python
'daily-logger': {
    'path': '.../templates/daily-logger',
    'default_agent_count': 4,       # 유지 (staggered deploy로 rate limit 대응)
    'dates_per_agent': 92,          # 365/4
    'skill_name': 'daily-work-logger',
    'inter_date_delay_seconds': 10  # 신규
}
```

### 1-2. Timeout 변경 (Line 653-654)

```python
if self.task_type == 'daily-logger':
    max_time = 86400  # 14400 -> 86400 (24시간)
```

### 1-3. Progress tracking 추가

- `_init_progress_file()`: agent별 `agent_{id}_progress.json` 초기화
- `_merge_progress()`: 완료 후 agent별 progress를 `progress.json`으로 병합
- `_customize_template()`에 `{work_dir}` replacement 추가

### 1-4. Staggered deploy (Line 555-591)

```python
# deploy_agents() 수정
# Agent 시작 간격: 120초 (2분)
# 4개 agent가 2분 간격으로 시작 → 동시 rate limit 압력 분산
```

### 1-5. Resume 기능

- CLI에 `--resume {work_dir}` 플래그 추가
- resume 시 기존 progress.json에서 pending/failed 날짜만 agent에 재할당

### 1-6. Summary 배포 메서드

- `generate_summaries()`: daily 처리 완료 후 summary agent 2개 배포
  - Agent A: 52개 주간 요약 생성
  - Agent B: 12개 월간 요약 생성

---

## Phase 2: Agent Template 수정

### 핵심 추가: Rate Limit 대응 규칙

```
1차 rate limit → 60초 대기 후 재시도
2차 연속       → 120초 대기
3차 연속       → 300초(5분) 대기
4차 연속       → 600초(10분) 대기
5회 실패       → "failed" 기록, 다음 날짜로 진행

감지 키워드: "rate limit", "too many requests", "429", "overloaded", "capacity"
```

### Inter-date delay

각 날짜 처리 완료 후 **10초 대기** (rate limit 선제 예방)

### Progress 기록

각 날짜 처리 직후 python3 one-liner로 `agent_{id}_progress.json` 업데이트:
- success / failed / skipped 상태 기록
- 에러 시 에러 메시지도 기록

---

## Phase 3: config.yaml 업데이트

```yaml
processing:
  default_agent_count: 4
  dates_per_agent: 92
  inter_date_delay_seconds: 10
  stagger_deploy_seconds: 120
  max_timeout_hours: 24

rate_limit:
  initial_wait_seconds: 60
  max_retries_per_date: 5
  backoff_sequence: [60, 120, 300, 600]
```

---

## Phase 4: Summary 생성

Daily 처리 완료 후 실행. tmux session 내 새 window에 Claude agent 배포.

### Weekly Summary (2025-W01.md ~ 2025-W52.md)

```markdown
---
tags: [type/weekly-summary]
period: "2025-W{nn}"
date_range: "YYYY-MM-DD ~ YYYY-MM-DD"
---
# 2025년 W{nn} 주간 요약
## 주요 작업 내역
## 프로젝트별 진행
## 주간 학습
## 주간 미팅
```

### Monthly Summary (2025-01-monthly.md ~ 2025-12-monthly.md)

```markdown
---
tags: [type/monthly-summary]
period: "2025-{MM}"
---
# 2025년 {M}월 월간 요약
## 요약 통계
## 월간 주요 성과
## 프로젝트별 진행
## 월간 학습 하이라이트
```

저장 위치: `~/DocumentsLocal/msbaek_vault/notes/dailies/2025/`

---

## 실행 순서

```
1. 코드 수정 (Phase 1-3)
2. 소규모 테스트: python3 orchestrate.py daily-logger --date-range 2025-03-01:2025-03-07 --keep-session
3. 테스트 결과 확인 후 전체 실행:
   python3 orchestrate.py daily-logger --date-range 2025-01-01:2025-12-31 --keep-session
4. 실패 날짜 재처리 (필요 시): --resume {work_dir}
5. Summary 생성 (daily 완료 후 자동 또는 수동)
```

---

## 검증 방법

1. **소규모 테스트 (1주일분)**
   - 7일 처리 후 progress.json에 상태 기록 확인
   - rate limit 대기 로그 확인
   - daily note에 "## 작업 내역" 섹션 추가 확인

2. **전체 실행 후**
   - `progress.json`: 365개 날짜 상태 (success/skipped/failed 분포)
   - daily notes: "## 작업 내역" 섹션 존재 여부
   - 주간 요약 52개, 월간 요약 12개 파일 존재 확인

---

## 리스크 및 대응

| 리스크 | 대응 |
|--------|------|
| Rate limit 빈번 | 4 agents 120초 간격 staggered deploy + 10초 inter-date delay + exponential backoff |
| Agent context 소진 (91일 연속) | Claude Code 자동 context compaction 의존 + resume 기능으로 중단 시 재개 |
| Progress 파일 충돌 | Agent별 별도 progress 파일 → 완료 후 merge |
| 24시간 초과 | resume 기능으로 이어서 처리 |
