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
- 일시: 2026-09-27 (구현 완료) / 브랜치: `feature/relay-traffic-longpoll` (develop에서 분기)
- 목적: 릴레이 서버 트래픽 절감 — (1) /api/poll 옵트인 롱폴, (2) PC 세션 대기 connect 지수 백오프, (4) 중복 PC heartbeat 제거 (유휴 세션 요청 ~6,700/h → ~290/h 목표)
- 커밋: `a47b3cf` 서버 롱폴(wait 상한 25s, clientGone 감시) · `48d7fa8`+`fdbd483` 익스텐션(롱폴+백오프·heartbeat 제거) · `e231cab` 모바일(롱폴+커맨드메타 6초 타이머) · `657d48c` 스모크 스크립트 · `2e6a01a` 기록
- 검증(실실행): `npm run type-check` / `npm run build:extension` EXIT=0, `flutter analyze` 117건(기존 동일·신규 0), `flutter test` 42통과, `streaming_text_merge_test` 6통과. diff는 계획 스니펫과 일치 확인
- 다음 단계(배포 — 사용자 승인 필요): ① `cd codex-relay-server && npm run deploy` (vercel CLI 직접 배포 — git master 푸시·동기화 완료 `70a370d`, CLI 토큰 만료로 에이전트 실행 불가) ② `node test-relay-longpoll.js https://codex-relay.jaloveeye.com` (A/B 통과) + `node test-relay-full.js <RELAY_URL>` 회귀 ③ 클라이언트 배포는 순서 무관(옵트인)
- 릴리스 준비 완료(2026-09-28): 익스텐션 0.2.2(`d906d3f`, VSIX: `codex-extension/codex-remote-extension-0.2.2.vsix`, 내부 버전 확인), 모바일 0.2.2+10(`69b7d86`) — Android `build/app/outputs/bundle/release/app-release.aab`(45.4MB)+`flutter-apk/app-release.apk`(55.9MB, versionCode 10/0.2.2), iOS `build/ios/ipa/codex_remote.ipa`(22.8MB, 0.2.2/10). 스모크 스크립트 status 필드 수정 커밋 `8fa5a40`
- 남은 리스크:
  - 구버전 서버에서는 `wait` 무시 → 즉시응답 동작(기능 저하 없음). 배포 전 스모크 A/B 실패는 정상.
  - opt 5~7(승인 piggyback, 백그라운드 폴링, 메시지 이중저장·trace 중복) 별도 과제로 미적용.
