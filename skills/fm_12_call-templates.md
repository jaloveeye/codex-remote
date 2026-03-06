# Skill: call-templates (빠른 복붙 템플릿)

이 문서는 “형식”을 보여주는 템플릿입니다. 실제 파라미터/스키마는 사용 중인 도구 정의에 맞추세요.

## 1) 세션 시작: context()
- 목표: 취향/에러패턴/절차만 짧게 로드

예시(개념):
- `context(tokenBudget=1600, types=["preference","error","procedure"])`

## 2) 에러 기록: remember(error)
템플릿:
- 증상: {에러 메시지/코드}
- 환경: {local|staging|prod}, {버전/OS}
- 원인: {단일 원인}
- 해결: {단일 조치}
- 증거: {로그 키워드/스택 키워드}

예시(개념):
- `remember(type="error", topic="cache", keywords=["NOAUTH","REDIS_PASSWORD"], content="증상: NOAUTH ...")`

## 3) 결정 기록: remember(decision)
템플릿:
- 결정: ...
- 이유: ...
- 대안: ...
- 되돌림 조건: ...

## 4) 회상: recall()
- 키워드가 확실할 때:
  - `recall(topic="auth", keywords=["NOAUTH","jwt"], tokenBudget=600)`
- 표현이 다를 수 있을 때(자연어):
  - `recall(text="로그인 토큰이 계속 거절되는 이유/해결", topic="auth", tokenBudget=900, includeLinks=true)`

## 5) 세션 종료: reflect()
템플릿:
- summary: 오늘 한 일(짧게)
- decisions: ["...", "..."]
- errors_resolved: ["...", "..."]
- new_procedures: ["...", "..."]
- open_questions: ["...", "..."]

## 6) 워크플로우/컨벤션 기록: remember(preference/procedure)
- 팀/프로젝트의 Git 규칙(예: Git Flow), PR 정책, 머지 방식(squash/rebase) 등을 잊지 않게 남깁니다.

예시(개념):
- `remember(type="preference", topic="vcs", keywords=["git-flow","branch"], content="코드 변경은 Git Flow 규칙 준수(Feature는 develop→feature/*→PR→develop, Hotfix는 main/master→hotfix/*→main/master+develop).")`
