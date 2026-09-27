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
- 일시: 2026-09-27
- 브랜치: `feature/relay-traffic-longpoll` (develop에서 분기)
- 목적: 릴레이 서버 트래픽 절감 — (1) /api/poll 옵트인 롱폴, (2) PC 세션 대기 connect 지수 백오프, (4) 중복 PC heartbeat 제거 (유휴 세션 요청 ~6,700/h → ~290/h 목표)
- 완료/변경 파일:
  - 계획 문서: `docs/superpowers/plans/2026-09-27-relay-traffic-optimization.md` (재개 가이드 포함)
  - `codex-relay-server/api/poll.ts` — 롱폴 wait 파라미터(기본 0, 상한 25초, 1초 간격 재확인, clientGone close 감시) 커밋 `a47b3cf`
- 검증:
  - `cd codex-relay-server && npm run type-check` 통과
  - diff 검증 완료 (계획 스니펫과 일치)
- 미완료(다음 세션): Task 2 익스텐션(`relay-client.ts` 롱폴+백오프+heartbeat 제거, **151행 clearHeartbeat 삭제 필수**), Task 3 모바일(`main.dart` 롱폴+6초 커맨드메타 타이머), Task 4 `test-relay-longpoll.js` 스모크, 게이트(`build:extension`, `flutter analyze/test`, streaming merge 테스트)
- 남은 리스크:
  - 서버 리배포 전까지 `wait`는 무시됨(구버전 서버) → 즉시응답 동작(기능 저하 없음). 리버티스: 배포는 사용자 승인 필요.
  - 클라이언트 전환(익스텐션/앱 배포)은 서버 리배포 이후 권장(옵트인 설계로 순서 자유).
  - opt 5~7(승인 piggyback, 백그라운드 폴링, 메시지 이중저장·trace 중복) 별도 과제로 미적용.
