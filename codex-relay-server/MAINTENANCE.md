# 릴레이 서버 정기 점검

독립 배포한 Codex Relay Server의 수동 점검 체크리스트입니다.

## 1. 점검 전제

```bash
export RELAY_URL=https://relay.example.com
```

로컬 개발 중이면 `http://localhost:3000` 으로 바꿔 사용합니다.

## 2. 기본 점검

### 2.1 Health

```bash
curl -s "$RELAY_URL/api/health" | jq .
```

기대 결과:

- `success: true`
- `data.status: "healthy"`

### 2.2 Session / Debug 상태

```bash
curl -s "$RELAY_URL/api/debug-sessions" | jq .
```

기대 결과:

- `success: true`
- `data.totalSessions`, `data.waitingForPc`, `data.sessionsWithPc` 확인 가능

### 2.3 저장소 종류 확인

```bash
curl -s "$RELAY_URL/api/store" | jq .
```

기대 결과:

- `success: true`
- `data.storeLabel` 이 `Supabase` 또는 `Upstash Redis`

## 3. 연결 확인

```bash
curl -X POST "$RELAY_URL/api/connect"   -H "Content-Type: application/json"   -d '{"sessionId":"CHECK1","deviceId":"maintenance-check","deviceType":"pc"}'   -w "
HTTP_CODE:%{http_code}
" -s
```

- HTTP 200 + `success: true` → 정상
- 4xx/5xx → 응답 본문과 배포 로그 확인

## 4. 장애 시 확인할 것

- Vercel 프로젝트 로그 / Functions 로그
- Supabase 또는 Upstash 상태
- 최근 환경변수 변경 여부
- app / extension 이 같은 relay URL을 쓰는지

## 5. 운영 원칙

- 이 프로젝트용 relay는 **기존 공유 relay와 분리**해서 운영
- 가능하면 storage도 분리
- 수동 점검 또는 외부 모니터링으로 health/debug API 감시
- 자동화가 필요하면 이 저장소에 맞는 별도 CI/monitor를 추가

## 6. 관련 문서

- [README.md](./README.md)
- [TEST_PLAN.md](./TEST_PLAN.md)

## Vercel link note

If `codex-relay-server/.vercel/project.json` still points to an older Vercel project, run `vercel link` before the first deploy for the new relay server.
