---
scope: personal              # personal | company | oss
disclosure: internal         # public | masked | internal
created: {{YYMMDD}}
project: {{project}}
last_adr_number: 0
tags: [adr, architecture-decision]
---
<!-- 신볼트 규약: `updated`/`last_updated` 필드는 두지 않는다 (mtime과 git이 SSOT). -->
<!-- 프로젝트 레포에 자체 ADR 파일이 있으면 이 템플릿 대신 그 파일을 쓴다. -->
<!-- 볼트에 둘 때 파일명은 `{project}-adr-log.md`, 위치는 raw/inbox/. -->


# {{프로젝트명}} ADR Log

> 아키텍처 결정 타임스탬프 로그. 모듈별 → 결정 유형별 그룹 정렬.
> 상세 내러티브는 각 워크스루 문서 참조.

---

<!-- 모듈별 섹션을 알파벳순으로 추가. -->
<!-- 각 모듈 안에서 결정 유형(통신 패턴, 도메인 설계, 스키마, ...) 서브섹션. -->
<!-- ADR 번호는 프로젝트 전역 순번 (모듈/유형 무관). -->

## {{module}}

### {{결정 유형}}

#### ADR-001: {{한 줄 제목}}
- **상태**: Accepted
- **일자**: {{YYYY-MM-DD}}
- **상황**: {{왜 이 결정이 필요했는가}}
- **결정**: {{무엇을 선택했는가}}
- **결과**: {{주요 영향 + 새로운 제약}}
- **상세**: [[{{워크스루 파일명}}]]
