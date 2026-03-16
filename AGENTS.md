# AGENTS.md

이 레포는 `skills/fm_*.md` 기반의 파편 기억 워크플로우를 사용합니다.

## 기본 진입점
- 인덱스: `skills/fm_00_INDEX.md`
- 빠른 가이드: `skills/fm_USAGE.md`

## 작업 루틴(기본)
1. **시작 전 목표 정합성 확인**
   - 요청/목표를 한 줄로 정리하고, 범위/제외사항을 먼저 합의한다.
   - (Superpowers의 `brainstorm`/`write-plan` 흐름 반영)
1. **작업 시작 전 Preflight**
   - `skills/fm_10_preflight-review.md`
   - 아래 4가지를 짧게 점검/보고:
     - 버그/확장성
     - 컨벤션/일반성
     - 보안/리스크
     - 모호함/누락
2. **작업 분해 및 실행 계획**
   - 기능 단위가 아닌 파일 단위로 2~3분 내 완료 가능한 태스크로 분해해 진행한다.
   - 각 태스크는 “변경 파일 + 검증 방법”을 명시한다.
   - (Superpowers의 `writing-plans` / `execute-plan` 흐름 반영)
3. **코드 변경 시 브랜치 규칙**
   - `skills/fm_15_git-flow.md`
   - Feature/Release/Hotfix 흐름 준수
   - **Git Flow 테스트 게이트 상시 적용**
     - feature: 변경 모듈 테스트 + (mobile 변경 시) `cd mobile-app && flutter test`
     - release: `npm run build:extension` → `cd mobile-app && flutter test` → `node test-relay-full.js <RELAY_URL>` → `npm run test:relay:live -- --relay <RELAY_URL>`
     - hotfix: 타깃 테스트 + 영향 모듈 회귀 테스트
4. **세션 시작/중간/종료**
   - 시작: `skills/fm_01_session-onboarding.md`
   - 중요 결정/에러/절차는 즉시 기록: `skills/fm_02_fragment-writer.md`
   - 막히면 회상: `skills/fm_03_recall-master.md`
   - 종료: `skills/fm_08_reflect-closer.md`

5. **변경 후 즉시 검증**
   - Superpowers의 `red-green` 취지에 맞춰 변경 직후 최소 1개 자동검증을 실행한다.
   - (예: `npm run compile`, `flutter test` 등 해당 모듈의 표준 점검)
   - 스트리밍/응답 병합 로직 변경 시 추가로 아래를 반드시 실행:
     - `cd mobile-app && flutter test test/services/streaming_text_merge_test.dart`

## 권장 참조
- 에러 대응: `skills/fm_04_error-forensics.md`
- 결정 로그: `skills/fm_05_decision-log.md`
- 절차 정리: `skills/fm_06_procedure-playbook.md`
- 인과 분석: `skills/fm_07_graph-rca.md`
- 유지보수: `skills/fm_09_hygiene-maint.md`

## 최근 작업 기록 (요약)
- 일시: 2026-03-11
- 브랜치: `feature/bilingual-web-extension`
- 목적: 모바일 앱 다국어(i18n) 반영 검증 및 테스트 정합성 맞춤
- 변경 파일: `mobile-app/lib/main.dart`, `mobile-app/lib/screens/settings_page.dart`, `mobile-app/lib/services/app_settings.dart`, `mobile-app/lib/services/app_i18n.dart`, `mobile-app/lib/widgets/*.dart`, `mobile-app/test/*.dart`, `mobile-app/pubspec.yaml`, `mobile-app/pubspec.lock`
- 검증:
  - `flutter analyze` (mobile-app): 통과(문법/타입 오류 없음, 100+ 기존/정보성 경고 존재)
  - `flutter test` (mobile-app): 통과
- 남은 리스크:
  - 다수의 `withOpacity`, `deprecated` 경고 및 기존 코드 정리가 미적용(기능 동작에는 영향 없음).
  - `AppI18n` 추가로 텍스트 키 누락/문구 품질 변경 시 테스트 문자열 동기화가 다시 필요.
