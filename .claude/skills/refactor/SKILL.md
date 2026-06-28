---
name: refactor
description: >-
  보이스카웃 룰에 따라 구현 전 기존 코드를 점검하고 정리한다.
  네이밍, 아키텍처, DDD 컨벤션 위반을 수정하고 확장 가능한 구조를 마련한다.
  반드시 /inspect 실행 후에 사용한다.
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(./gradlew*)
  - Bash(git *)
---

# Refactor — 보이스카웃 룰

> "캠프장을 떠날 때는 도착했을 때보다 깨끗하게 남겨라."
> 구현을 시작하기 전에, 작업 영역의 기존 코드를 먼저 정리한다.

`$ARGUMENTS`가 주어지면 해당 영역을 리팩터링한다.
**전제: `/inspect`가 먼저 실행되어 Inspection Report가 존재해야 한다.**

## 실행 순서

### Phase 1: 컨벤션 점검

Inspection Report의 "변경 지점" 파일들을 대상으로:

#### Kotlin/Spring (`**/src/main/**`)
- [ ] 파일명: `PascalCase.kt` (클래스당 1파일)
- [ ] Extension 함수 모음: `{Type}Extensions.kt`
- [ ] Top-level 함수: 내용을 설명하는 이름 (예: `DateFormatters.kt`). `Utils` 지양
- [ ] 함수: `camelCase`
- [ ] 상수: `UPPER_SNAKE_CASE` 또는 `companion object` 내 `const val`
- [ ] nullable 최소화 — 불필요한 `?` 없음
- [ ] `!!` 금지 — `requireNotNull` 사용
- [ ] `val` 우선 (불변 선호)
- [ ] 생성자 주입만 사용
- [ ] `.claude/rules/` 하위 rule 파일이 있으면 해당 기준을 우선 적용한다
- [ ] rule 파일 없는 경우 — 의존성 방향: domain ← application ← ui/infrastructure (멀티모듈), 또는 domain/service/repository/controller 패키지 역할 원칙 (단일모듈)
- [ ] Controller에 비즈니스 로직 없음

#### DDD (`docs/domain/*/language.yaml`, 존재 시)
- [ ] 클래스/필드명이 유비쿼터스 언어와 일치
- [ ] 금지 동의어 미사용

### Phase 2: 구조 개선

Inspection Report의 "추천 작업 순서"를 기반으로:

1. **인터페이스 조정**: 구현할 기능이 기존 Port 인터페이스로 충분한가? 확장이 필요한가?
2. **추상화 수준**: 구체적 구현에 의존하는 코드를 추상화
3. **중복 제거**: 비슷한 로직이 여러 곳에 흩어져 있으면 통합
4. **불필요한 코드 제거**: 사용되지 않는 import, 변수, 함수

### Phase 3: 테스트 확인

**모든 리팩터링 후 반드시 테스트 실행** (프로젝트 빌드도구에 맞게):

```bash
./gradlew test      # Gradle
./mvnw test         # Maven
npm test            # Node
```

### Phase 4: 커밋

리팩터링은 기능 구현과 **별도 커밋**으로 분리한다:

```
refactor: repository 접근 로직을 별도 메서드로 추출
refactor: DTO 네이밍을 도메인 용어와 일치시킴
```

## 하지 말아야 할 것

- **기능 변경**: 리팩터링 중에 새 기능을 추가하지 않는다
- **과도한 리팩터링**: 작업 영역 밖의 코드는 건드리지 않는다
- **테스트 없는 리팩터링**: 테스트 실행 없이 커밋하지 않는다
