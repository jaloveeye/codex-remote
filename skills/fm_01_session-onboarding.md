# Skill: session-onboarding (세션 시작 기억 복원)

## 목표
- 세션 시작에 “핵심 기억”을 짧게 주입해 맥락 재구축 비용/토큰을 줄입니다.

## 트리거
- 새 세션 시작
- 사용자가 “이전 맥락부터”, “우리 프로젝트 규칙”, “내 스타일”을 언급

## 프로토콜
1) `context()`를 먼저 호출합니다.  
   - `tokenBudget`은 2000에서 시작(짧게: 1200~1600).  
   - 기본 `types`(preference/error/procedure)를 우선 로드합니다.

2) `context()` 결과에 “미반영(아직 reflect 안 된) 세션 힌트”가 있으면,  
   - 사용자에게 알리고 가능하면 `reflect()`를 실행합니다(자동 실행이 있어도 명시 실행 권장).

3) 주입 우선순위(읽는 순서)  
   - preference → error → procedure → decision

## 금지
- `context()` 없이 규칙/스택/취향을 단정하지 마세요.
