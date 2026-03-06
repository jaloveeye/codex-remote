# Skill: fragment-writer (파편 저장 작가)

## 목표
- 기억을 1~3문장, 300자 이하 “원자 단위”로 저장합니다.
- **한 파편에는 한 개념만** 담습니다.

## 언제 remember()를 호출?
- **fact**: 변하지 않는 사실(스택/환경/인프라/계정 구조)
- **decision**: 결정 + 이유(왜 그랬는지)
- **error**: 실패 패턴(증상/로그 키워드/원인/해결)
- **preference**: 스타일/취향/금기(주석 언어, 포맷, 선호 라이브러리)
- **procedure**: 반복되는 루틴(배포 순서, 장애 대응 순서)
- **relation**: 모듈 의존/원인-결과 연결

## 작성 규칙
- content: 300자 이하, 1~3문장, 재현 가능한 단서(키워드/에러코드/환경변수명) 포함
- topic: 반드시 부여(예: auth, database, deployment, infra, coding-style)
- keywords: 자동 추출이 가능해도, 검색 키워드가 명확하면 2~5개 직접 지정
- importance/isAnchor: “절대 잊으면 안 됨”이면 isAnchor 고려
- scope:
  - permanent: 기본(장기 지식)
  - session: 세션 한정 임시 메모(일회성)

## 보안
- 비번/키/메일/전화번호 등 민감정보는 content에 넣지 마세요(마스킹되더라도 복구 불가).
