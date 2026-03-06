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

## 작업 중 기억으로 남길 것(추천)
- Git Flow 관련 규칙/예외가 생기면 `remember(type="preference" 또는 "procedure", topic="vcs", ...)`로 기록
  - 예: “릴리즈는 항상 release/* 브랜치에서만 수행”
  - 예: “PR 머지는 squash만 허용”

## 금지
- 브랜치 전략이 불명확한데 임의로 `develop`을 만들거나 기본 브랜치를 바꾸지 않는다.
