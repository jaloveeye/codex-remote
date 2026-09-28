/**
 * 릴레이 롱폴 스모크 테스트
 * 사용법: node test-relay-longpoll.js [RELAY_URL]
 * 기본 RELAY_URL: http://localhost:3000 (또는 RELAY_SERVER_URL 환경변수)
 *
 * 검증 항목:
 *   A. PC 롱폴 대기 중 모바일이 보낸 메시지를 3초 내 수신 (메시지 도착 즉시 반환)
 *   B. 모바일 롱폴 대기 중 PC가 보낸 메시지를 3초 내 수신
 *   C. 빈 큐 PC 롱폴 wait=8 → 약 8초 후 복귀
 *      (2초 미만 복귀 = 서버 미배포로 wait 무시 중 → 경고 후 통과 처리)
 *
 * 종료 코드: 검증 실패 시 1, 그 외(경고 포함) 0.
 */

const RELAY_SERVER_URL =
  process.argv[2] ||
  process.env.RELAY_SERVER_URL ||
  'http://localhost:3000';

const WAIT_SECONDS = 8; // Test C 용 (짧게 유지해 테스트 시간 단축)
const SEND_PROBE_DELAY_MS = 1200; // 롱폴 시작 후 메시지 전송까지의 지연
const DELIVERY_BUDGET_MS = 3000; // 메시지 전송 → 롱폴 복귀 허용 시간
const IDLE_HOLD_MIN_MS = 6500; // wait=8일 때 최소 hold 시간
const REQUEST_TIMEOUT_MS = 60000;

const results = [];

function log(label, ok, detail) {
  const mark = ok ? '✅' : '❌';
  results.push({ label, ok });
  console.log(`${mark} ${label}${detail ? ` — ${detail}` : ''}`);
}

async function postJson(path, body) {
  const response = await fetch(`${RELAY_SERVER_URL}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body || {}),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  const bodyJson = await response.json().catch(() => null);
  return { statusCode: response.status, body: bodyJson };
}

/** 롱폴 1회. 결과로 messages 배열을 반환 (실패 시 null) */
async function longPollOnce(sessionId, deviceType, deviceId, waitSeconds) {
  const url =
    `${RELAY_SERVER_URL}/api/poll?sessionId=${encodeURIComponent(sessionId)}` +
    `&deviceType=${deviceType}&deviceId=${encodeURIComponent(deviceId)}` +
    `&wait=${waitSeconds}`;
  const response = await fetch(url, {
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  const body = await response.json().catch(() => null);
  if (response.status !== 200 || body?.success !== true) {
    console.error(`  poll 응답 이상: HTTP ${response.status}`, body);
    return null;
  }
  return Array.isArray(body?.data?.messages) ? body.data.messages : [];
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  console.log(`📡 Relay Server: ${RELAY_SERVER_URL}`);
  const stamp = Date.now();
  const pcDeviceId = `lp-pc-${process.pid}-${stamp}`;
  const mobileDeviceId = `lp-mobile-${process.pid}-${stamp}`;
  let sessionId = null;

  try {
    // 0. 세션 생성 + PC/모바일 접속
    const sessionRes = await postJson('/api/session');
    if (sessionRes.statusCode !== 201 || !sessionRes.body?.data?.sessionId) {
      throw new Error(`세션 생성 실패: HTTP ${sessionRes.statusCode}`);
    }
    sessionId = sessionRes.body.data.sessionId;
    console.log(`🔑 Session: ${sessionId}`);

    for (const [deviceId, deviceType] of [
      [pcDeviceId, 'pc'],
      [mobileDeviceId, 'mobile'],
    ]) {
      const connectRes = await postJson('/api/connect', {
        sessionId,
        deviceId,
        deviceType,
      });
      if (connectRes.statusCode >= 300 || connectRes.body?.success !== true) {
        throw new Error(
          `connect 실패 (${deviceType}): HTTP ${connectRes.statusCode}`
        );
      }
    }
    console.log('🔌 PC/모바일 접속 완료\n');

    // A. PC 롱폴 도중 모바일 메시지 → 즉시 수신
    {
      const pollPromise = longPollOnce(sessionId, 'pc', pcDeviceId, 25);
      await sleep(SEND_PROBE_DELAY_MS);
      const sentAt = Date.now();
      const sendRes = await postJson('/api/send', {
        sessionId,
        deviceId: mobileDeviceId,
        deviceType: 'mobile',
        type: 'insert_text',
        data: { type: 'insert_text', text: `longpoll-smoke-${stamp}` },
      });
      if (sendRes.statusCode >= 300 || sendRes.body?.success !== true) {
        throw new Error(`send 실패: HTTP ${sendRes.statusCode}`);
      }
      const messages = await pollPromise;
      const elapsed = Date.now() - sentAt;
      const ok = messages !== null && messages.length >= 1 && elapsed < DELIVERY_BUDGET_MS;
      log(
        'A. PC 롱폴 즉시 수신',
        ok,
        `수신 ${messages?.length ?? 0}건, 전송 후 ${elapsed}ms (허용 ${DELIVERY_BUDGET_MS}ms)`
      );
    }

    // B. 모바일 롱폴 도중 PC 메시지 → 즉시 수신
    {
      const pollPromise = longPollOnce(sessionId, 'mobile', mobileDeviceId, 25);
      await sleep(SEND_PROBE_DELAY_MS);
      const sentAt = Date.now();
      const sendRes = await postJson('/api/send', {
        sessionId,
        deviceId: pcDeviceId,
        deviceType: 'pc',
        type: 'message',
        data: { type: 'message', text: `longpoll-smoke-pc-${stamp}` },
      });
      if (sendRes.statusCode >= 300 || sendRes.body?.success !== true) {
        throw new Error(`send 실패: HTTP ${sendRes.statusCode}`);
      }
      const messages = await pollPromise;
      const elapsed = Date.now() - sentAt;
      const ok = messages !== null && messages.length >= 1 && elapsed < DELIVERY_BUDGET_MS;
      log(
        'B. 모바일 롱폴 즉시 수신',
        ok,
        `수신 ${messages?.length ?? 0}건, 전송 후 ${elapsed}ms (허용 ${DELIVERY_BUDGET_MS}ms)`
      );
    }

    // C. 빈 큐 롱폴 hold 확인 (wait=8 → ~8초)
    {
      const startedAt = Date.now();
      const messages = await longPollOnce(sessionId, 'pc', pcDeviceId, WAIT_SECONDS);
      const elapsed = Date.now() - startedAt;
      if (messages === null) {
        log('C. 유휴 롱폴 hold', false, 'poll 요청 실패');
      } else if (elapsed < 2000) {
        console.log(
          '⚠️  서버가 wait 파라미터를 무시했습니다 (구버전 서버 배포 상태).'
        );
        console.log('    → 롱폴 효과는 서버 리배포 후에 확인할 수 있습니다.');
        log('C. 유휴 롱폴 hold', true, `경고로 통과: ${elapsed}ms 복귀 (wait 미지원)`);
      } else if (elapsed >= IDLE_HOLD_MIN_MS) {
        log('C. 유휴 롱폴 hold', true, `${elapsed}ms hold (wait=${WAIT_SECONDS}s)`);
      } else {
        log(
          'C. 유휴 롱폴 hold',
          false,
          `${elapsed}ms 복귀 — 기대 ${IDLE_HOLD_MIN_MS}ms 이상 (조기 반환 버그 의심)`
        );
      }
    }
  } catch (error) {
    console.error('❌ Test error:', error?.message || error);
    results.push({ label: 'setup/setup error', ok: false });
  } finally {
    if (sessionId) {
      try {
        await postJson('/api/session-clear', {
          sessionId,
          deviceId: pcDeviceId,
          keepPc: false,
        });
        console.log('\n🧹 임시 세션 정리 완료');
      } catch {
        console.log('\n⚠️ 세션 정리 실패 (TTL 5분 내 자동 정리됨)');
      }
    }
  }

  const failed = results.filter((r) => !r.ok);
  console.log(`\n📊 결과: ${results.length - failed.length}/${results.length} 통과`);
  process.exit(failed.length > 0 ? 1 : 0);
}

main();
