# Skill: topics-taxonomy (topic/keyword 표준)

## 목표
- 기억 품질은 “내용”만큼 **분류(topic/keywords)** 에 좌우됩니다.
- topic이 제각각이면 recall이 흔들리므로, 최소한의 표준을 둡니다.

## 권장 topic 목록(예시)
프로젝트에 맞게 줄이거나 늘리되, **표기 흔들림을 최소화**하세요.

- `infra` : 인프라/네트워크/서버/클라우드/런타임
- `deployment` : 배포/릴리즈/롤백/마이그레이션
- `database` : DB 스키마/쿼리/성능/트랜잭션
- `cache` : Redis/캐시 전략/TTL/무효화
- `auth` : 인증/인가/세션/토큰
- `api` : HTTP/gRPC 계약, 엔드포인트, DTO
- `backend` : 서비스 레이어, 도메인 로직
- `frontend` : UI/상태/빌드
- `testing` : 테스트 전략/도구/테스트 픽스처
- `vcs` : Git/브랜치 전략(Git Flow), PR 규칙, 릴리즈 태그
- `observability` : 로그/메트릭/트레이싱/알림
- `security` : 권한/비밀값/취약점 대응
- `coding-style` : 코드 컨벤션/포맷/주석 언어(선호)
- `ops` : 운영 절차, 온콜, 장애 대응

## 표기 규칙
- topic은 **소문자 + 하이픈/언더스코어 최소화** (예: `coding-style` 권장)
- 같은 개념은 같은 topic으로(예: `db` vs `database` 혼용 금지)
- 하나의 파편은 topic을 **1개만**(정말 필요할 때만 2개)

## keywords 규칙(검색 안정성)
- “에러 코드/로그 키워드/환경변수명/파일명/모듈명” 위주로 2~5개
- 너무 일반어는 피하기(예: error, failed 같은 단어만 넣지 말기)
- 예: `["NOAUTH","REDIS_PASSWORD","sentinel","auth"]`