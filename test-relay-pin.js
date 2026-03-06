/**
 * PIN 설정·검증 API 테스트 (현재 정책: PC first)
 * 사용법: node test-relay-pin.js [RELAY_URL]
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
  console.log("\n🧪 PIN (connect API) 테스트 (PC first)");
  console.log(`   URL: ${RELAY_SERVER_URL}\n`);

  let sessionId;
  const pcDeviceId = `pc-${Date.now()}`;
  const mobile2 = `mobile-${Date.now()}-2`;
  const PIN = "1234";

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

  await test("POST /api/connect (PC + pin)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/connect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId, deviceId: pcDeviceId, deviceType: "pc", pin: PIN }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "Connect failed");
    return data;
  });

  await test("POST /api/connect (모바일2, pin 없음) → 403 PIN_REQUIRED", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/connect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId, deviceId: mobile2, deviceType: "mobile" }),
    });
    const data = await res.json();
    if (res.status !== 403 || data.errorCode !== "PIN_REQUIRED") {
      throw new Error(`Expected 403 PIN_REQUIRED, got ${res.status} ${data.errorCode}`);
    }
    return data;
  });

  await test("POST /api/connect (모바일2, wrong pin) → 403 INVALID_PIN", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/connect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId, deviceId: mobile2, deviceType: "mobile", pin: "0000" }),
    });
    const data = await res.json();
    if (res.status !== 403 || data.errorCode !== "INVALID_PIN") {
      throw new Error(`Expected 403 INVALID_PIN, got ${res.status} ${data.errorCode}`);
    }
    return data;
  });

  await test("POST /api/connect (모바일2, correct pin) → 200", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/connect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId, deviceId: mobile2, deviceType: "mobile", pin: PIN }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "Connect failed");
    return data;
  });

  console.log("\n✅ PIN 테스트 통과\n");
}

main().catch((e) => {
  console.error("\n❌ 테스트 실패:", e.message || e);
  process.exit(1);
});
