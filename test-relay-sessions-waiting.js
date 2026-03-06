/**
 * sessions-waiting-for-pc API와 PC first 정책 검증
 * 사용법: node test-relay-sessions-waiting.js [RELAY_URL]
 */

const RELAY_SERVER_URL =
  process.argv[2] ||
  process.env.RELAY_SERVER_URL ||
  "http://localhost:3000";

async function test(name, fn) {
  process.stdout.write(`${name}... `);
  try {
    const result = await fn();
    console.log("✅");
    return result;
  } catch (e) {
    console.log("❌", e.message || e);
    throw e;
  }
}

async function main() {
  console.log("\n🧪 sessions-waiting-for-pc / PC first 정책 테스트");
  console.log(`   URL: ${RELAY_SERVER_URL}\n`);

  let sessionId;
  const mobileDeviceId = `mobile-${Date.now()}`;
  const pcDeviceId = `pc-${Date.now()}`;

  sessionId = await test("POST /api/session (세션 생성)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/session`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });
    const data = await res.json();
    if (!data.success || !data.data?.sessionId) {
      throw new Error(data.error || "No sessionId");
    }
    return data.data.sessionId;
  });
  console.log(`   sessionId: ${sessionId}`);

  const waitingBeforePc = await test("GET /api/sessions-waiting-for-pc (PC 연결 전)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/sessions-waiting-for-pc`);
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "API failed");
    const sessions = data.data?.sessions ?? [];
    const found = sessions.some((s) => s.sessionId === sessionId);
    if (!found) throw new Error("세션이 대기 목록에 없음");
    return sessions;
  });
  console.log(`   PC 연결 전 대기 목록 세션 수: ${waitingBeforePc.length}`);

  await test("POST /api/connect (모바일 선연결 시도) → 403 PC_MUST_CONNECT_FIRST", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/connect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId, deviceId: mobileDeviceId, deviceType: "mobile" }),
    });
    const data = await res.json();
    if (res.status !== 403 || data.errorCode !== "PC_MUST_CONNECT_FIRST") {
      throw new Error(`Expected 403 PC_MUST_CONNECT_FIRST, got ${res.status} ${data.errorCode}`);
    }
    return data;
  });

  await test("POST /api/connect (PC)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/connect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId, deviceId: pcDeviceId, deviceType: "pc" }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "PC connect failed");
    return data;
  });

  const waitingAfterPc = await test("GET /api/sessions-waiting-for-pc (PC 연결 후)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/sessions-waiting-for-pc`);
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "API failed");
    const sessions = data.data?.sessions ?? [];
    const found = sessions.some((s) => s.sessionId === sessionId);
    if (found) throw new Error("PC 연결 후에도 세션이 대기 목록에 있음");
    return sessions;
  });
  console.log(`   PC 연결 후 대기 목록 세션 수: ${waitingAfterPc.length}`);

  console.log("\n✅ sessions-waiting-for-pc 테스트 통과\n");
}

main().catch((e) => {
  console.error("\n❌ 테스트 실패:", e.message || e);
  process.exit(1);
});
