# AGENTS.md

이 레포는 `skills/fm_*.md` 기반의 파편 기억 워크플로우를 사용합니다.

## 기본 진입점
- 인덱스: `skills/fm_00_INDEX.md`
- 빠른 가이드: `skills/fm_USAGE.md`

## 작업 루틴(기본)
1. **작업 시작 전 Preflight**
   - `skills/fm_10_preflight-review.md`
   - 아래 4가지를 짧게 점검/보고:
     - 버그/확장성
     - 컨벤션/일반성
     - 보안/리스크
     - 모호함/누락
2. **코드 변경 시 브랜치 규칙**
   - `skills/fm_15_git-flow.md`
   - Feature/Release/Hotfix 흐름 준수
3. **세션 시작/중간/종료**
   - 시작: `skills/fm_01_session-onboarding.md`
   - 중요 결정/에러/절차는 즉시 기록: `skills/fm_02_fragment-writer.md`
   - 막히면 회상: `skills/fm_03_recall-master.md`
   - 종료: `skills/fm_08_reflect-closer.md`

## 권장 참조
- 에러 대응: `skills/fm_04_error-forensics.md`
- 결정 로그: `skills/fm_05_decision-log.md`
- 절차 정리: `skills/fm_06_procedure-playbook.md`
- 인과 분석: `skills/fm_07_graph-rca.md`
- 유지보수: `skills/fm_09_hygiene-maint.md`
