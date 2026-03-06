# Skill: recall-master (토큰 절약 회상 전문가)

## 목표
- 매번 비싼 검색을 하지 말고, **필요할 때만 깊게** 들어갑니다.

## 전략
1) 키워드/주제/타입이 명확하면  
   - `recall(keywords=[...], topic=..., type=..., tokenBudget=...)`

2) 표현이 다를 수 있거나(동의어/이음동의어), 기억이 안 잡히면  
   - `recall(text="자연어 질의", topic=..., tokenBudget=..., threshold=...)`  
   - (의미 검색을 통해 “인증 실패”와 “NOAUTH” 같은 표현 차이를 흡수)

## 파라미터 팁
- tokenBudget: 기본 1000, “짧게 힌트만”이면 400~700
- includeLinks: 원인/해결까지 따라가야 하면 true, 단답이면 false
- asOf: 특정 시점 기준으로 회상해야 하면 사용

## 결과 처리
- isAnchor 파편이 섞여 있으면 최우선 준수
- 링크 이웃(원인/해결)이 붙어오면 인과체인으로 먼저 정리한 뒤 답변
