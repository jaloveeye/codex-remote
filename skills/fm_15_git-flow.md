# Skill: git-flow (코드 변경은 Git Flow 규칙 준수)

## 목표
- 코드 변경이 있을 때 **항상 Git Flow 브랜치 전략을 따른다.**
- 작업 단위를 안전하게 격리하고(Feature), 릴리즈를 통제하고(Release), 긴급 수정은 빠르게 반영한다(Hotfix).

## Preflight (착수 전 확인)
- 이 레포가 Git Flow를 쓰는지 확인:
  - `main/master`(프로덕션)와 `develop`(통합) 브랜치가 존재하는가?
  - 브랜치 보호 규칙/PR 규칙이 있는가?
- 레포가 Git Flow가 아닌 다른 전략(trunk-based 등)이라면:
  - **그 사실을 먼저 보고**하고, 사용자가 “그래도 Git Flow로 갈지 / 레포 관례를 따를지” 선택하도록 한다.

## 기본 규칙
- `main/master`, `develop`에 **직접 커밋하지 않는다**(가능하면 PR만).
- 모든 변경은 목적에 맞는 브랜치에서 수행한다.
- PR은 작게 쪼개고(리뷰 가능 크기), 테스트/린트 통과를 전제로 한다.

## 브랜치 타입 & 흐름(표준 Git Flow)
- Feature
  - `feature/<slug>` : `develop`에서 분기 → 작업 → PR로 `develop`에 병합
- Release
  - `release/<version>` : `develop`에서 분기 → 릴리즈 준비(버전/체인지로그/QA) → `main/master`에 병합 + 태그
  - 이후 `develop`에도 병합(릴리즈 중 수정 반영)
- Hotfix
  - `hotfix/<slug>` : `main/master`에서 분기 → 긴급 수정 → `main/master`에 병합 + 태그
  - 이후 `develop`에도 병합(핫픽스 반영)

## 네이밍 권장(팀에 맞게 조정)
- `feature/1234-add-login-rate-limit`
- `hotfix/5678-fix-null-pointer`
- `release/1.8.0`

## 테스트 게이트 (이 레포 상시 규칙)
아래 게이트는 **Git Flow 단계마다** 적용한다.

### 1) Feature 브랜치 (`feature/*`)
- 목적: 빠른 피드백 + 회귀 방지
- 최소 게이트:
  - 변경 모듈 표준 테스트 1개 이상
  - `mobile-app` 변경 시: `cd mobile-app && flutter test`
  - 스트리밍/응답 조합 로직 변경 시:
    - `cd mobile-app && flutter test test/services/streaming_text_merge_test.dart`
- 병합 조건:
  - 게이트 통과 로그를 남긴 뒤 `develop`으로 병합(PR 또는 팀 규칙 방식)

### 2) Release 브랜치 (`release/*`)
- 목적: 배포 직전 안정성 확보
- 필수 게이트(순서 권장):
  1. `npm run build:extension`
  2. `cd mobile-app && flutter test`
  3. `node test-relay-full.js <RELAY_URL>` (릴레이 API 스모크)
  4. `npm run test:relay:live -- --relay <RELAY_URL> [--session <SESSION_ID>]`
     - 주의: PC 익스텐션 연결/인증이 필요한 실전형 테스트
- Finish 조건:
  - 위 1~4번이 모두 통과했을 때만 `release finish`
  - 실패 시 release 브랜치에서 수정 후 게이트 재실행

### 3) Hotfix 브랜치 (`hotfix/*`)
- 목적: 긴급 수정의 안전한 복구
- 필수 게이트:
  - 수정 영역 타깃 테스트 + 최소 전체 회귀 1개
  - 가능하면 `cd mobile-app && flutter test` 또는 영향 모듈 전체 테스트
- Finish 조건:
  - 테스트 통과 후 `main/master` 반영 + `develop` 역병합

## 자동화 운영 권장
- 항상 자동(빠른): 단위/통합 테스트 (`flutter test` 등)
- 스케줄 자동(Nightly): `test:relay:live` 실전 라운드트립
  - 워크플로우: `.github/workflows/nightly-live.yml`
  - 필요 설정:
    - `NIGHTLY_E2E_SESSION_ID` (필수 권장: 항상 연결된 익스텐션 세션 ID)
    - `NIGHTLY_RELAY_URL` (선택, 기본값 `https://codex-relay.jaloveeye.com`)
- 브랜치 푸시 자동(Git Flow 게이트): `.github/workflows/gitflow-gates.yml`
  - 트리거: `feature/*`, `release/*`, `hotfix/*` push
  - 선택/기본 시크릿:
    - `GATE_RELAY_URL` (없으면 `NIGHTLY_RELAY_URL` 또는 기본 relay URL)
    - `GATE_E2E_SESSION_ID` (release live 게이트용, 없으면 `NIGHTLY_E2E_SESSION_ID`)
- Git Flow 유지 원칙:
  - PR 중심으로 강제 전환할 필요 없음
  - `feature/release/hotfix` 브랜치 규칙 + 게이트 준수만 지키면 됨

## 작업 중 기억으로 남길 것(추천)
- Git Flow 관련 규칙/예외가 생기면 `remember(type="preference" 또는 "procedure", topic="vcs", ...)`로 기록
  - 예: “릴리즈는 항상 release/* 브랜치에서만 수행”
  - 예: “PR 머지는 squash만 허용”

## 금지
- 브랜치 전략이 불명확한데 임의로 `develop`을 만들거나 기본 브랜치를 바꾸지 않는다.
