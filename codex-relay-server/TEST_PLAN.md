# Relay Server Test Plan

## English

Validation guide for the standalone relay server deployment.
The default target is the **local relay** at `http://localhost:3000`, but you can pass a deployed URL explicitly.

## 1. Preparation

```bash
cd codex-relay-server
cp .env.example .env.local
npm install
npm run dev
```

Run the test scripts from the repository root in another terminal.

## 2. Automated tests

### Full flow

```bash
node test-relay-full.js
node test-relay-full.js https://codex-relay.jaloveeye.com
```

### sessions-waiting-for-pc / stale PC

```bash
node test-relay-sessions-waiting.js
node test-relay-sessions-waiting.js https://codex-relay.jaloveeye.com
```

### PIN setup and verification

```bash
node test-relay-pin.js
node test-relay-pin.js https://codex-relay.jaloveeye.com
```

### Inspect a specific session queue

```bash
node test-relay-message.js ABC123
node test-relay-message.js ABC123 https://codex-relay.jaloveeye.com
```

## 3. Manual tests

Prerequisites:

- mobile app and VS Code extension use the same relay URL
- extension setting: `codexRemote.relayServerUrl`
- mobile/web runtime flag: `--dart-define=RELAY_SERVER_URL=...`

### A. Mobile discovers PC

1. Create and connect a session from the mobile client
2. Connect the VS Code extension to the same session ID
3. Check relay connection logs in the extension output
4. Verify session status via `/api/debug-sessions`

### B. PC disconnect and reconnect

1. Connect mobile and PC to the same session
2. Close VS Code
3. Wait at least 2 minutes
4. Reopen VS Code and connect with the same session ID
5. Confirm that the stale session appears again in `sessions-waiting-for-pc`

### C. PIN verification

1. Set a 4-6 digit PIN when the PC connects
2. Try to connect from mobile without a PIN → should fail
3. Enter the wrong PIN → should fail
4. Enter the correct PIN → should succeed

## 4. Quick API checks

```bash
RELAY_URL=${RELAY_URL:-http://localhost:3000}

curl -s "$RELAY_URL/api/health" | jq .
curl -s "$RELAY_URL/api/sessions-waiting-for-pc" | jq .
curl -s "$RELAY_URL/api/debug-sessions" | jq .
```

### Call the connect API directly

```bash
RELAY_URL=${RELAY_URL:-http://localhost:3000}

curl -X POST "$RELAY_URL/api/connect"   -H "Content-Type: application/json"   -d '{"sessionId":"CHECK1","deviceId":"maintenance-check","deviceType":"pc"}'   -w "
HTTP_CODE:%{http_code}
" -s
```

## 5. Expected results

- `health` returns `success: true`
- session creation, connect, and polling all succeed
- PIN policy behaves as expected
- stale PC sessions reappear in the waiting list after 2 minutes

---

## 한국어

독립 배포한 릴레이 서버를 검증하는 절차입니다.
기본 대상은 `http://localhost:3000`의 **로컬 릴레이**이며, 배포 서버 URL을 명시적으로 넘길 수도 있습니다.

## 1. 준비

```bash
cd codex-relay-server
cp .env.example .env.local
npm install
npm run dev
```

다른 터미널에서 저장소 루트 기준으로 테스트 스크립트를 실행하세요.

## 2. 자동 테스트

### 전체 플로우

```bash
node test-relay-full.js
node test-relay-full.js https://codex-relay.jaloveeye.com
```

### sessions-waiting-for-pc / stale PC

```bash
node test-relay-sessions-waiting.js
node test-relay-sessions-waiting.js https://codex-relay.jaloveeye.com
```

### PIN 설정 및 검증

```bash
node test-relay-pin.js
node test-relay-pin.js https://codex-relay.jaloveeye.com
```

### 특정 세션 큐 확인

```bash
node test-relay-message.js ABC123
node test-relay-message.js ABC123 https://codex-relay.jaloveeye.com
```

## 3. 수동 테스트

전제:

- 모바일 앱과 VS Code 확장이 같은 relay URL을 사용
- 확장 설정: `codexRemote.relayServerUrl`
- 모바일/웹 실행 플래그: `--dart-define=RELAY_SERVER_URL=...`

### A. 모바일에서 PC 발견

1. 모바일 클라이언트에서 세션을 만들고 연결합니다
2. VS Code 확장을 같은 세션 ID로 연결합니다
3. 확장 출력에서 relay 연결 로그를 확인합니다
4. `/api/debug-sessions`로 세션 상태를 확인합니다

### B. PC 끊김 후 재접속

1. 모바일과 PC를 같은 세션으로 연결합니다
2. VS Code를 종료합니다
3. 최소 2분 기다립니다
4. VS Code를 다시 열고 같은 세션 ID로 연결합니다
5. stale 세션이 `sessions-waiting-for-pc`에 다시 나타나는지 확인합니다

### C. PIN 검증

1. PC 연결 시 4-6자리 PIN을 설정합니다
2. 모바일에서 PIN 없이 접속하면 실패해야 합니다
3. 잘못된 PIN을 입력하면 실패해야 합니다
4. 올바른 PIN을 입력하면 성공해야 합니다

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

- `health`가 `success: true`를 반환
- 세션 생성, 연결, 폴링이 모두 성공
- PIN 정책이 예상대로 동작
- stale PC 세션이 2분 후 대기 목록에 다시 나타남
