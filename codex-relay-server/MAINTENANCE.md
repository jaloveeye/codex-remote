# Relay Server Maintenance

## English

Manual maintenance checklist for the standalone Codex Relay Server deployment.

## 1. Setup

```bash
export RELAY_URL=https://relay.example.com
```

For local development, replace it with `http://localhost:3000`.

## 2. Basic checks

### 2.1 Health

```bash
curl -s "$RELAY_URL/api/health" | jq .
```

Expected result:

- `success: true`
- `data.status: "healthy"`

### 2.2 Session / debug status

```bash
curl -s "$RELAY_URL/api/debug-sessions" | jq .
```

Expected result:

- `success: true`
- visible `data.totalSessions`, `data.waitingForPc`, and `data.sessionsWithPc`

### 2.3 Store type

```bash
curl -s "$RELAY_URL/api/store" | jq .
```

Expected result:

- `success: true`
- `data.storeLabel` is `Supabase` or `Upstash Redis`

## 3. Connection check

```bash
curl -X POST "$RELAY_URL/api/connect"   -H "Content-Type: application/json"   -d '{"sessionId":"CHECK1","deviceId":"maintenance-check","deviceType":"pc"}'   -w "
HTTP_CODE:%{http_code}
" -s
```

- HTTP 200 + `success: true` → healthy
- 4xx/5xx → inspect the response body and deployment logs

## 4. What to check during incidents

- Vercel project logs / Functions logs
- Supabase or Upstash status
- Recent environment-variable changes
- Whether app and extension use the same relay URL

## 5. Operating principles

- Keep this relay deployment separate from any shared legacy relay
- Prefer separate storage for this project
- Monitor health/debug APIs manually or with external monitoring
- Add dedicated CI or monitoring if you need more automation

## 6. Related docs

- [README.md](./README.md)
- [TEST_PLAN.md](./TEST_PLAN.md)

---

## 한국어

독립 배포한 Codex Relay Server의 수동 점검 체크리스트입니다.

## 1. 준비

```bash
export RELAY_URL=https://relay.example.com
```

로컬 개발 중이면 `http://localhost:3000`으로 바꿔 사용하세요.

## 2. 기본 점검

### 2.1 Health

```bash
curl -s "$RELAY_URL/api/health" | jq .
```

기대 결과:

- `success: true`
- `data.status: "healthy"`

### 2.2 Session / debug 상태

```bash
curl -s "$RELAY_URL/api/debug-sessions" | jq .
```

기대 결과:

- `success: true`
- `data.totalSessions`, `data.waitingForPc`, `data.sessionsWithPc` 확인 가능

### 2.3 저장소 종류

```bash
curl -s "$RELAY_URL/api/store" | jq .
```

기대 결과:

- `success: true`
- `data.storeLabel`이 `Supabase` 또는 `Upstash Redis`

## 3. 연결 확인

```bash
curl -X POST "$RELAY_URL/api/connect"   -H "Content-Type: application/json"   -d '{"sessionId":"CHECK1","deviceId":"maintenance-check","deviceType":"pc"}'   -w "
HTTP_CODE:%{http_code}
" -s
```

- HTTP 200 + `success: true` → 정상
- 4xx/5xx → 응답 본문과 배포 로그 확인

## 4. 장애 시 확인할 항목

- Vercel 프로젝트 로그 / Functions 로그
- Supabase 또는 Upstash 상태
- 최근 환경변수 변경 여부
- 앱과 확장이 같은 relay URL을 쓰는지 여부

## 5. 운영 원칙

- 이 릴레이 배포는 기존 공유 레거시 릴레이와 분리해서 운영합니다
- 가능하면 이 프로젝트 전용 저장소를 사용합니다
- health/debug API를 수동 또는 외부 모니터링으로 감시합니다
- 자동화가 더 필요하면 전용 CI 또는 모니터링을 추가합니다

## 6. 관련 문서

- [README.md](./README.md)
- [TEST_PLAN.md](./TEST_PLAN.md)
