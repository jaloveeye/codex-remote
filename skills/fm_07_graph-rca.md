# Skill: graph-rca (RCA: 인과 체인 탐색)

## 목표
- “증상 → 원인 → 해결”을 그래프로 따라가서 재발 방지까지 한 번에 합니다.

## 사용법
1) `recall()`로 대표 에러 파편을 찾습니다.
2) `graph_explore(startId=...)`로 연결된 인과를 1-hop로 탐색합니다.
3) `caused_by` / `resolved_by` 흐름으로 체인을 정리합니다.
4) 부족하면, 새 파편을 `remember()`하고 `link()`로 그래프를 보강합니다(다음에 더 잘 찾게).
