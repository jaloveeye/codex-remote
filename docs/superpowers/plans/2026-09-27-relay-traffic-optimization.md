# Relay Traffic Optimization (1·2·4) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

## 📌 진행 상태 (2026-09-27 구현 완료 — 배포 대기)

| 항목 | 상태 |
|---|---|
| 브랜치 | `feature/relay-traffic-longpoll` (develop에서 분기) ✅ |
| Task 1 서버 롱폴 | **완료** — 커밋 `a47b3cf` |
| Task 2 익스텐션 | **완료** — 커밋 `48d7fa8` (소스) + `fdbd483` (out 산물). 롱폴 wait=25+35s 타임아웃, poll 에러 백오프 1s→15s, connect 백오프 1s→30s, heartbeat 완전 제거(4개 호출부 포함 151행) |
| Task 3 모바일 | **완료** — 커밋 `e231cab`. 롱폴 wait=25+35s 타임아웃, 에러 백오프(산술 cap), 커맨드메타 6초 타이머 분리, `_stopPolling` 정리 |
| Task 4 스모크 스크립트 | **완료** — 커밋 `657d48c` (`test-relay-longpoll.js`: A 즉시수신/B 즉시수신/C hold, C는 서버 미배포 시 경고 후 통과) |
| 게이트 (모두 실실행 검증) | `npm run type-check` EXIT=0 ✅ / `npm run build:extension` EXIT=0 ✅ / `flutter analyze` 117건(기존과 동일, 신규 0) ✅ / `flutter test` 42 통과 ✅ / `streaming_text_merge_test` 6 통과 ✅ |
| **남은 일: 배포** | ① 서버 리배포 (사용자 승인 필요): `cd codex-relay-server && vercel --prod` → ② `node test-relay-longpoll.js https://codex-relay.jaloveeye.com` (A/B 통과 확인) + `node test-relay-full.js <RELAY_URL>` 회귀 → ③ 익스텐션/앱 배포는 이후 자유 (옵트인 설계, 순서 무관) |
| 참고 | 구버전 서버에 신버전 클라이언트: `wait` 무시 → 즉시응답 동작(기존과 동일, 기능 저하 없음). 배포 전 스모크는 A/B 실패가 정상(wait 미지원), C만 경고 통과 |

**재개 절차:** 배포 승인 → 서버 `vercel --prod` → 스모크(A/B·회귀) → (선택) 클라이언트 배포. 병행 과제: opt 5~7(승인 piggyback, 백그라운드 폴링, 이중저장/트레이스 절감)은 별도 과제로 미적용.

---

## Chunk 1: Server — 롱폴 지원

### Task 1: `/api/poll` wait 파라미터 (opt 1 서버)

**Files:**
- Modify: `codex-relay-server/api/poll.ts` (lines 44-105 부근)
- Verify: `cd codex-relay-server && npm run type-check`

- [x] **Step 1: wait 파서와 폴링 루프 추가** ✅ 커밋 a47b3cf (+54/-5, helper는 13-18행)

`maxLimit` 계산(`api/poll.ts:89`) 뒤를 다음으로 교체:

```ts
    const maxLimit = Math.min(parseInt(limit as string) || 10, 50);

    // 롱폴(옵트인): wait 초 동안 메시지가 생길 때까지 1초 간격으로 재확인.
    // 기본 0 = 기존 즉시응답(구버전 클라이언트 하위호환). 상한 25초는
    // router.ts maxDuration: 30 내부 오버헤드 마련 + stream.ts 25초 전례.
    const waitSeconds = parseLongPollWait(req.query.wait);
    const deadlineMs = Date.now() + waitSeconds * 1000;
    // 클라이언트가 기다리지 않고 끊은 경우(타임아웃 등) 즉시 그만둔다
    let clientGone = false;
    req.on("close", () => {
      clientGone = true;
    });
    const pollInput = {
      sessionId: sessionId!,
      deviceType: deviceType as DeviceType,
      deviceId: deviceId as string | undefined,
      limit: maxLimit,
    };

    let pollResult = await pollMessages(
      pollInput.sessionId,
      pollInput.deviceType,
      pollInput.limit,
      pollInput.deviceId
    );

    // 세션이 없으면 기다리지 않고 즉시 404 (재연결 로직이 빨리 반응해야 함)
    while (
      pollResult.sessionFound &&
      !clientGone &&
      pollResult.messages.length === 0 &&
      Date.now() < deadlineMs
    ) {
      const sleepMs = Math.min(1000, deadlineMs - Date.now());
      await new Promise((resolve) => setTimeout(resolve, sleepMs));
      if (clientGone) break;
      try {
        pollResult = await pollMessages(
          pollInput.sessionId,
          pollInput.deviceType,
          pollInput.limit,
          pollInput.deviceId
        );
      } catch (error) {
        // 대기 중 일시적 오류: hold를 깨지 말고 다음 tick에서 재시도
        console.warn("Poll long-wait retry error:", error);
      }
    }

    if (!pollResult.sessionFound) {
```

파일 하단(handler 위)에 헬퍼 추가:

```ts
/** 롱폴 wait 파라미터 파싱(초). 유효하지 않으면 0 → 즉시응답. */
function parseLongPollWait(raw: unknown): number {
  const value = typeof raw === "string" ? Number(raw) : NaN;
  if (!Number.isFinite(value) || value <= 0) return 0;
  return Math.min(value, 25);
}
```

이후 `if (!pollResult.sessionFound) { ... 404 ... }` 블록과 trace/응답 부분은 **기존 코드 그대로 유지** (교체 범위는 89-96행: `maxLimit` 대입부터 `if (!pollResult.sessionFound) {` 오프너까지. 97행 이하는 무변경).

- [x] **Step 2: 타입 체크** ✅ exit 0

Run: `cd codex-relay-server && npm run type-check`
Expected: exit 0

- [x] **Step 3: Commit** ✅ a47b3cf "feat(relay-server): opt-in long-poll wait for /api/poll"

```bash
git add codex-relay-server/api/poll.ts
git commit -m "feat(relay-server): opt-in long-poll wait for /api/poll"
```

---

## Chunk 2: Extension 클라이언트

### Task 2: 롱폴 전환 + connect 백오프 + heartbeat 제거 (opt 1·2·4)

**Files:**
- Modify: `codex-extension/src/relay-client.ts`
- Verify: `npm run build:extension` (repo root)

- [ ] **Step 1: 필드 추가** (line 56 `POLL_ACTIVITY_WINDOW_MS` 아래)

```ts
  /** 롱폴: 서버가 새 메시지가 생길 때까지(최대 25초) 응답을 유지한다 */
  private readonly POLL_WAIT_SECONDS = 25;
  /** 롱폴 요청 타임아웃 (서버 wait + 마진) */
  private readonly POLL_HTTP_TIMEOUT_MS = 35_000;
  /** poll 실패 시 백오프 (1s → 15s cap, 성공 시 리셋) */
  private nextPollAllowedAtMs = 0;
  private pollErrorBackoffMs = 1000;
  /** 세션 대기 중 connect 재시도 백오프 (1s → 30s cap) */
  private nextConnectAttemptAtMs = 0;
  private connectRetryBackoffMs = 1000;
```

- [ ] **Step 2: heartbeat 제거 (opt 4)**

- 삭제: `heartbeatInterval` 필드(59행), `HEARTBEAT_INTERVAL_MS`(60행)
- 삭제: `clearHeartbeat()`(212-217행), `sendHeartbeat()`(219-228행), `startHeartbeat()`(230-238행)
- 크리티컬(리뷰 발견): `connectToSessionById`의 `this.clearHeartbeat();`(151행)도 삭제 — 누락 시 빌드 실패. 그 자리의 `sessionId = null; isConnected = false;`는 유지
- `stop()`에서 `this.clearHeartbeat();` 삭제
- `connectToSession` 성공 브랜치의 `this.startHeartbeat();`(596행) 삭제 — 폴링(RPC `relay_poll_messages`)이 이미 `pc_last_seen_at`을 갱신함을 주석으로 남긴다:
  ```ts
  // heartbeat 제거: /api/poll(RPC relay_poll_messages)이 접속마다
  // pc_last_seen_at을 갱신하므로 별도 heartbeat가 불필요하다.
  ```
- `clearRelaySession` keepPc 브랜치의 `this.startHeartbeat();`(826행) 삭제

- [ ] **Step 3: poll 스케줄러에 백오프 게이트 추가** (`startPolling` interval 콜백, 249-264행)

`if (this.pollInFlight) return;` 앞에 추가:

```ts
      if (now < this.nextPollAllowedAtMs) return;
```

로그 문구 변경: `"⏱️ Long-poll loop started (wait 25s, immediate on message)"`

- [ ] **Step 4: 세션 폴링 → 롱폴 + 에러 백오프** (`pollMessages` 세션 분기, 329행~)

```ts
      const pollUrl = `${this.relayServerUrl}/api/poll?sessionId=${
        this.sessionId
      }&deviceType=pc&deviceId=${encodeURIComponent(
        this.deviceId
      )}&wait=${this.POLL_WAIT_SECONDS}`;
      const data = await this.httpRequest(
        pollUrl,
        "GET",
        undefined,
        this.POLL_HTTP_TIMEOUT_MS
      );

      if (!data) {
        // 요청 실패/타임아웃: 즉시 재시도 폭탄 방지
        this.nextPollAllowedAtMs =
          Date.now() + this.pollErrorBackoffMs;
        this.pollErrorBackoffMs = Math.min(
          this.pollErrorBackoffMs * 2,
          15_000
        );
        this.logError("⚠️ Poll failed - backing off before retry");
        return;
      }
      this.nextPollAllowedAtMs = 0;
      this.pollErrorBackoffMs = 1000;
```

(기존 `if (!data)` 블록은 위 블록으로 대체)

- [ ] **Step 5: 세션 대기 connect 백오프 (opt 2)** (`pollMessages` !sessionId 분기, 284-297행)

```ts
      if (this.targetSessionId) {
        const now = Date.now();
        if (now < this.nextConnectAttemptAtMs) return;
        if (
          now - this.lastNoSessionHeartbeatTime >=
          this.POLL_HEARTBEAT_INTERVAL
        ) {
          this.lastNoSessionHeartbeatTime = now;
          this.log(
            `⏳ 세션 ${this.targetSessionId} 대기 중 (모바일에서 해당 세션 생성·연결 후 자동 연결, 백오프 ${Math.round((this.nextConnectAttemptAtMs - now) / 1000)}s)`
          );
        }
        await this.connectToSession(this.targetSessionId, this.targetPin ?? undefined);
        if (this.sessionId) {
          this.nextConnectAttemptAtMs = 0;
          this.connectRetryBackoffMs = 1000;
        } else {
          this.nextConnectAttemptAtMs =
            Date.now() + this.connectRetryBackoffMs;
          this.connectRetryBackoffMs = Math.min(
            this.connectRetryBackoffMs * 2,
            30_000
          );
        }
        return;
      }
```

`start()` 메서드에 `targetSessionId` 설정부 뒤에 리셋 추가:

```ts
    this.nextConnectAttemptAtMs = 0;
    this.connectRetryBackoffMs = 1000;
```

- [ ] **Step 6: httpRequest 타임아웃 지원** (`httpRequest`, 956행~)

시그니처를 `body?: any` 뒤에 `timeoutMs?: number` 추가, `req.end()` 직전에:

```ts
      if (timeoutMs && timeoutMs > 0) {
        req.setTimeout(timeoutMs, () => {
          req.destroy(new Error(`Request timed out after ${timeoutMs}ms`));
        });
      }
```

(`req.destroy(err)` → `req.on('error')` → resolve(null) 경로로 정상 흡수됨)

- [ ] **Step 7: 빌드 검증**

Run: `npm run build:extension`
Expected: exit 0, 컴파일 에러 없음

- [ ] **Step 8: Commit**

```bash
git add codex-extension/src/relay-client.ts
git commit -m "feat(extension): relay long-poll + connect backoff, drop redundant heartbeat"
```

---

## Chunk 3: Mobile 클라이언트

### Task 3: 롱폴 루프 + 커맨드 메타 타이머 (opt 1)

**Files:**
- Modify: `mobile-app/lib/main.dart` (poll fields 848-854, `_startPolling` 2103, `_pollRelayMessagesOnce` 2117-2174, `_stopPolling` 2176)
- Verify: `cd mobile-app && flutter analyze && flutter test`

- [ ] **Step 1: 필드 추가** (854행 `_pollSchedulerTick` 아래)

```dart
  static const int _relayLongPollWaitSeconds = 25;
  static const Duration _relayLongPollHttpTimeout = Duration(seconds: 35);
  int _relayPollErrorBackoffMs = 1000;
  static const int _relayPollMaxErrorBackoffMs = 15000;
  Timer? _commandMetaTimer;
```

- [ ] **Step 2: `_startPolling`에 메타 타이머 병행 시작**

폴링 타이머 뒤에 추가 (승인/이벤트 메타 6초 갱신 보장 — 롱폴이 25초 막혀도 승인 UX 유지):

```dart
    _commandMetaTimer?.cancel();
    _commandMetaTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      unawaited(_refreshCommandMetaIfStale());
    });
```

- [ ] **Step 3: `_pollRelayMessagesOnce` 롱폴화**

- 요청에 wait 추가 + 타임아웃:

```dart
      final response = await http
          .get(
            _relayUri('/api/poll', {
              'sessionId': _sessionId!,
              'deviceType': 'mobile',
              'deviceId': _deviceId,
              'wait': '$_relayLongPollWaitSeconds',
            }),
          )
          .timeout(_relayLongPollHttpTimeout);
```

- 성공 경로( statusCode 200 블록 앞)에 백오프 리셋: `_relayPollErrorBackoffMs = 1000;`
- catch 블록에 실패 백오프 (main.dart에 `dart:math` 미임포트가 확인됨 → 산술로 cap):

```dart
    } catch (e) {
      // 폴링 에러는 조용히 무시하되, 즉시 재시도 폭탄은 막는다
      _lastRelayPollStartedAtMs =
          DateTime.now().millisecondsSinceEpoch + _relayPollErrorBackoffMs;
      final doubled = _relayPollErrorBackoffMs * 2;
      _relayPollErrorBackoffMs =
          doubled > _relayPollMaxErrorBackoffMs ? _relayPollMaxErrorBackoffMs : doubled;
    }
```

- [ ] **Step 4: `_stopPolling` 메타 타이머 정리**

```dart
    _commandMetaTimer?.cancel();
    _commandMetaTimer = null;
```

- [ ] **Step 5: 검증**

Run:
```bash
cd mobile-app && flutter analyze
cd mobile-app && flutter test
```
Expected: analyze — 기존 경고 수준 동일, 신규 error 없음 / test — 전부 통과
(스트리밍 병합 로직 불변이지만 게이트로 병행 실행: `flutter test test/services/streaming_text_merge_test.dart`)

- [ ] **Step 6: Commit**

```bash
git add mobile-app/lib/main.dart
git commit -m "feat(mobile): relay long-poll loop with command-meta timer"
```

---

## Chunk 4: 스모크 테스트 + 마무리

### Task 4: 롱폴 스모크 스크립트

**Files:**
- Create: `test-relay-longpoll.js` (기존 test-relay-message.js 스타일)
- Verify: 배포 후 `node test-relay-longpoll.js https://codex-relay.jaloveeye.com`

- [ ] **Step 1: 스크립트 작성**

절차:
1. `POST /api/session` → session 생성
2. PC·mobile `POST /api/connect`
3. **Test A (PC 수신 지연)**: PC 롱폴(wait=25) 백그라운드 시작 → 1.2s 후 모바일 `/api/send` → 폴링이 메시지와 함께 **3초 내** 복귀 assert
4. **Test B (모바일 수신 지연)**: 모바일 롱폴(wait=25) 백그라운드 → 1.2s 후 PC `/api/send` → 3초 내 복귀 assert
5. **Test C (유휴 hold)**: 비어있는 큐로 PC 롱폼 `wait=8` → 경과시간 ≥ 6.5s assert. 단 **2초 미만 복귀 시** `⚠️ wait 미지원(서버 미배포)` 경고 후 통과 처리(배포 전 게이트용)
6. `POST /api/session-clear {keepPc:false}` 정리
7. device id는 `lp-test-<위도>-<stamp>`로 충돌 회피

- [ ] **Step 2: 구문 점검**

Run: `node --check test-relay-longpoll.js`
Expected: no output, exit 0

- [ ] **Step 3: Commit**

```bash
git add test-relay-longpoll.js
git commit -m "test: add relay long-poll smoke script"
```

---

## 검증 요약 (Feature 게이트)

| 게이트 | 명령 |
|---|---|
| 서버 타입 | `cd codex-relay-server && npm run type-check` |
| 익스텐션 빌드 | `npm run build:extension` |
| 모바일 | `cd mobile-app && flutter analyze && flutter test` (+ streaming merge 테스트) |
| 스모크(배포 후) | `node test-relay-longpoll.js <RELAY_URL>`, `node test-relay-full.js <RELAY_URL>` |

## 범위 밖 (명시적 제외)
- 서버 배포 (`vercel --prod`) — 사용자 승인 후 별도 수행. **클라이언트(익스텐션/앱 배포)는 서버 리배포 이후**에 배포해야 한다 (구버전 서버는 `wait`를 무시 → 즉시응답으로 동작, 기능 저하 없음 — 배포 순서 자유로움이 옵트인 설계의 이점)
- opt 5(승인 piggyback), opt 6(백그라운드 폴링), opt 7(이중저장/트레이스 절감)
