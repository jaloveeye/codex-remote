# Skill: procedure-playbook (반복 의식 저장)

## 목표
- 배포/운영/테스트/온콜 같은 “반복 루틴”을 최소 토큰으로 재사용합니다.

## 기록 규칙
`remember(type="procedure", topic=..., content=...)`
- 순서형(1→2→3)으로, 각 단계는 동사로 시작
- 실패 분기(실패하면 무엇을 확인?)가 있으면 포함
- 명령어/파일경로/설정키 등 “손이 가는 포인트”는 키워드로 남기기

## 구조화 팁
- 큰 절차는 `part_of` 링크로 쪼개기  
  - `link(from=parentProcId, to=subProcId, relationType="part_of")`

## 사용
- `recall(topic=..., type="procedure", tokenBudget=...)`로 필요한 절차만 로드합니다.
