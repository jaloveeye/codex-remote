# Skill: link-conventions (관계 그래프 규칙)

## 목표
- 관계(edge)가 제각각이면 graph 탐색이 약해집니다.
- 최소한의 relationType 표준을 둡니다.

## 권장 relationType(예시)
- `caused_by` : 원인
- `resolved_by` : 해결
- `part_of` : 구성 요소(절차/시스템 분해)
- `related` : 유사/연관(느슨한 연결)
- `superseded_by` : 최신 파편이 이전 파편을 대체(계보)

## 작성 규칙
- “원인/해결”은 가능하면 직접 연결(에러 → 원인, 에러 → 해결)
- 큰 절차는 part_of로 쪼개되, 1-hop 탐색이 기본인 점을 고려해 너무 잘게 쪼개지 않기
- related는 남발하지 말고, 검색 품질에 도움이 되는 경우만
