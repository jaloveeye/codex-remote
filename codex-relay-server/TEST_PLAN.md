# 릴레이 서버 테스트 가이드

독립 배포한 릴레이 서버를 검증하는 절차입니다.
기본 테스트 대상은 **로컬 relay(`http://localhost:3000`)** 이며, 배포 서버는 명시적으로 URL을 넘겨 테스트합니다.

## 1. 준비

```bash
cd codex-relay-server
cp .env.example .env.local
npm install
npm run dev
```

다른 터미널에서 저장소 루트 기준으로 테스트 스크립트를 실행합니다.

## 2. 자동 테스트

### 전체 플로우

```bash
node test-relay-full.js
node test-relay-full.js https://relay.example.com
```

### sessions-waiting-for-pc / stale PC

```bash
node test-relay-sessions-waiting.js
node test-relay-sessions-waiting.js https://relay.example.com
```

### PIN 설정·검증

```bash
node test-relay-pin.js
node test-relay-pin.js https://relay.example.com
```

### 특정 세션 큐 확인

```bash
node test-relay-message.js ABC123
node test-relay-message.js ABC123 https://relay.example.com
```

## 3. 수동 테스트

전제:

- 모바일 앱과 VS Code extension이 같은 relay URL을 사용
- extension 설정: `codexRemote.relayServerUrl`
- mobile/web 실행 시: `--dart-define=RELAY_SERVER_URL=...`

### A. 모바일 → PC 발견

1. 모바일에서 세션 생성 후 연결
2. VS Code extension에서 같은 세션 ID로 연결
3. Output에서 relay 연결 로그 확인
4. `/api/debug-sessions` 로 세션 상태 확인

### B. PC 끊김 후 재접속

1. 모바일·PC를 같은 세션으로 연결
2. VS Code를 종료
3. 2분 이상 대기
4. 다시 VS Code를 열고 같은 세션 ID로 접속
5. `sessions-waiting-for-pc` 에서 stale 세션이 재노출되는지 확인

### C. PIN 설정 검증

1. PC 연결 시 4~6자리 PIN 설정
2. 모바일에서 PIN 없이 접속 → 실패
3. 잘못된 PIN 입력 → 실패
4. 올바른 PIN 입력 → 성공

## 4. 빠른 API 확인

```bash
RELAY_URL=${RELAY_URL:-http://localhost:3000}

curl -s "$RELAY_URL/api/health" | jq .
curl -s "$RELAY_URL/api/sessions-waiting-for-pc" | jq .
curl -s "$RELAY_URL/api/debug-sessions" | jq .
```

### Connect API 직접 호출

```bash
RELAY_URL=${RELAY_URL:-http://localhost:3000}

curl -X POST "$RELAY_URL/api/connect"   -H "Content-Type: application/json"   -d '{"sessionId":"CHECK1","deviceId":"maintenance-check","deviceType":"pc"}'   -w "

HTTP_CODE:%{http_code}
" -s
```

## 5. 기대 결과

- `health` 가 `success: true`
- 세션 생성/연결/폴링이 모두 성공
- PIN 정책이 예상대로 동작
- stale PC 세션이 2분 후 다시 대기 목록에 나타남
