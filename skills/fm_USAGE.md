# 사용 방법 (Quick Guide)

## 0) 작업 전 점검(추천)
작업을 시작하기 전에 아래 4가지를 **짧게 점검하고 요약 보고**하면, 버그/보안/확장 문제를 초기에 줄일 수 있습니다.

- 버그 가능/확장 문제
- 컨벤션/일반성(팀 표준 위배 가능성 포함)
- 보안/리스크(비밀값/권한/데이터 파괴 등)
- 모호함/누락(가정/성공 기준/범위)

이 규칙은 `skills/fm_10_preflight-review.md`에 정리되어 있습니다.

## 0.5) 코드 변경 시 브랜치 규칙(항상)
코드를 수정/추가하는 작업이라면 **Git Flow 규칙을 우선 적용**합니다.

- Feature: `develop`에서 `feature/*`로 분기 → PR로 `develop` 병합
- Release: `release/*`로 릴리즈 준비 → `main/master` 병합 + 태그 → `develop`에도 반영
- Hotfix: `hotfix/*`로 긴급 수정 → `main/master` 병합 + 태그 → `develop`에도 반영

자세한 규칙은 `skills/fm_15_git-flow.md`를 참고하세요.

이 문서는 **파편(≤300자) 기반 기억 운용**을 “습관”으로 만들기 위한 최소 가이드입니다.

## 1) 세션 시작 (30초)
1. `context()`를 호출해 핵심 기억을 불러옵니다.
2. 로드된 기억을 5~10줄로 요약해 “오늘의 작업 목표”와 함께 시작합니다.

예시(개념):
- context(tokenBudget=1600, types=["preference","error","procedure"])

## 2) 작업 중 (중요 이벤트마다 10초)
아래 중 하나라도 해당하면 **바로 `remember()`**:
- 결정을 내렸다(값/정책/아키텍처 선택)
- 에러가 났고, 원인/해결을 알았다
- 다음에도 반복될 절차를 정리했다
- 취향/금기/스타일이 명확해졌다
- 모듈 간 의존/원인-결과 관계를 발견했다

### 파편 예시 템플릿(에러)
- 증상: ...
- 환경: ...
- 원인: ...
- 해결: ...
- 증거: ...

## 3) 막혔을 때 (필요할 때만)
- 키워드가 명확하면: `recall(keywords=[...])`
- 표현이 다를 수 있으면: `recall(text="자연어 질의")`
- 원인→해결까지 따라가려면: `includeLinks=true`

## 4) 세션 종료 (1~2분)
- `reflect()`를 호출해서 오늘의 결과를 파편으로 “응고”합니다.
  - decisions / errors_resolved / new_procedures / open_questions를 리스트로 정리해 넣으면 다음 세션이 빨라집니다.

## 5) 주기적 정리 (주 1회 추천)
- `memory_stats()`로 분포 확인
- `memory_consolidate()`로 감쇠/중복/모순 탐지 정리
- `tool_feedback()`으로 검색 품질 개선

## 파일 설명
- `skills/fm_00_INDEX.md` : 어떤 스킬을 언제 쓰는지
- `skills/fm_01_session-onboarding.md` : 세션 시작 루틴
- `skills/fm_02_fragment-writer.md` : 파편 저장 규칙
- `skills/fm_03_recall-master.md` : 회상 전략(토큰 절약)
- `skills/fm_04_error-forensics.md` : 에러 기록/재발 방지
- `skills/fm_05_decision-log.md` : 결정 기록/변경(amend)
- `skills/fm_06_procedure-playbook.md` : 반복 절차 저장
- `skills/fm_07_graph-rca.md` : 인과 체인(RCA) 탐색
- `skills/fm_08_reflect-closer.md` : 세션 종료 정리
- `skills/fm_09_hygiene-maint.md` : 유지보수/정리
- `skills/fm_10_preflight-review.md` : 작업 전 점검/개선 제안
- `skills/fm_11_topics-taxonomy.md` : topic/keywords 표준
- `skills/fm_12_call-templates.md` : 복붙 템플릿
- `skills/fm_13_forget-amend-policy.md` : 삭제/수정/추가 운영 기준
- `skills/fm_14_link-conventions.md` : relationType 표준
