# Skill: error-forensics (에러 패턴 수집 & 재발 방지)

## 목표
- 에러를 “재현 가능”하게 기록하고, 다음 번엔 1분컷으로 끝냅니다.

## 발생 즉시(5줄 규칙)
`remember(type="error", topic=..., content=...)`
- 증상: 대표 에러 메시지/코드 한 줄
- 환경: 로컬/스테이징/프로덕션, OS/버전 한 줄
- 원인: 결정적 원인 한 줄
- 해결: 조치/명령/설정 한 줄
- 증거: 로그 키워드(예: NOAUTH), stacktrace 키워드 등

## 해결 후 정리
- 해결이 “절차”로 남을 만하면  
  - `remember(type="procedure", topic=..., content="에러 대응 절차 ...")`
- 기존 에러 파편이 이제 쓸모없게 되었으면 `forget()`로 정리(필요 시 force)

## 관계 연결
- 원인 파편이 따로 있으면  
  - `link(from=errorId, to=causeId, relationType="caused_by")`
- 해결 파편이 따로 있으면  
  - `link(from=errorId, to=fixId, relationType="resolved_by")`
