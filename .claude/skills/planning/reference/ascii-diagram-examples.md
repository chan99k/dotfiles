# ASCII Diagram Examples

House-style reference. Use these as templates when generating diagrams in PRDs and specs.
Labels inside the diagrams are Korean because that is the output language of the documents.

## 1. Value Chain (Executive Summary)

```
핵심 가치 사슬:
  스크리닝 → 워치리스트 → 목표가 알림 → 매매 기록 → 복리 추적
   (발견)    (관심 등록)    (실행 시점)    (사후 기록)   (장기 성과)
```

## 2. UX Flow (User Experience)

```
       ┌─────────────────────────────────────────────────┐
       │       요청 승인 워크플로우                          │
       └─────────────────────────────────────────────────┘

  [접수]              [검토]              [처리]
 ┌────────┐         ┌────────┐         ┌────────┐
 │요청 목록│ ──────→ │요청 상세│ ──────→ │승인/반려│
 │조회     │         │확인     │         │사유 입력│
 └────────┘         └────────┘         └───┬────┘
      ▲                                    │
      │                                    ▼
      │                             ┌────────┐
      └──── 목록 복귀 ──────────────│처리 완료│
                                    │이력 기록│
                                    └────────┘
```

## 3. Comparison Table (as-is vs to-be)

```
┌──────────────┬──────────────────┬───────────────────┐
│ 항목         │ As-Is            │ To-Be             │
├──────────────┼──────────────────┼───────────────────┤
│ 접수         │ 슬랙/메일 분산   │ 어드민 통합 접수  │
│ 상태 관리    │ 스프레드시트     │ 시스템 상태값     │
│ 이력         │ 추적 불가        │ 자동 이력 기록    │
│ 권한         │ 구분 없음        │ 역할별 접근 제어  │
└──────────────┴──────────────────┴───────────────────┘
```

## 4. Timeline / Roadmap

```
┌──────────────────────────────────────────────────┐
│  Week 1 (2026.06.16~06.22)                        │
│  ─────────────────────────                        │
│  □ 도메인 모델 정의 + Flyway 마이그레이션          │
│  □ 요청 CRUD API                                  │
│                                                   │
│  Week 2 (2026.06.23~06.29)                        │
│  ─────────────────────────                        │
│  □ 승인/반려 상태 전이 로직                        │
│  □ 이력 기록 이벤트                                │
└──────────────────────────────────────────────────┘
```

## 5. State Machine

```
         ┌─────┐
         │ 대기 │
         └──┬──┘
       ┌────┴────┐
       ▼         ▼
   ┌─────┐   ┌─────┐
   │ 승인 │   │ 반려 │
   └─────┘   └─────┘
   (final)   (final)
```

## Rules

- Use box-drawing characters: `┌ ┐ └ ┘ ─ │ ┬ ┴ ├ ┤ ┼`
- Arrows: `→ ← ▲ ▼ ──────→`
- Keep the width under 70 characters for readability.
- Korean labels inside boxes.
- Annotate roles or actions below in parentheses.
