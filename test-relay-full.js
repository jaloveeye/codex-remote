/**
 * 릴레이 서버 전체 플로우 테스트 (현재 정책: PC first)
 * 사용법: node test-relay-full.js [RELAY_URL]
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
  console.log("\n🧪 Relay Server 전체 테스트 (PC first)");
  console.log(`   URL: ${RELAY_SERVER_URL}\n`);

  let sessionId;
  const mobileDeviceId = `mobile-${Date.now()}`;
  const pcDeviceId = `pc-${Date.now()}`;

  await test("GET /api/health", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/health`);
    const data = await res.json();
    if (!res.ok || !data.success) throw new Error(data.error || res.statusText);
    return data;
  });

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

  await test("POST /api/connect (PC first)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/connect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId, deviceId: pcDeviceId, deviceType: "pc" }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "PC connect failed");
    return data;
  });

  await test("POST /api/connect (모바일)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/connect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId, deviceId: mobileDeviceId, deviceType: "mobile" }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "Mobile connect failed");
    return data;
  });

  await test("POST /api/send (모바일→insert_text)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/send`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sessionId,
        deviceId: mobileDeviceId,
        deviceType: "mobile",
        type: "insert_text",
        data: {
          type: "insert_text",
          id: String(Date.now()),
          text: "안녕?",
          prompt: true,
          execute: true,
          agentMode: "agent",
        },
      }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "Send failed");
    return data;
  });

  const pcMessages = await test("GET /api/poll (PC)", async () => {
    const res = await fetch(
      `${RELAY_SERVER_URL}/api/poll?sessionId=${sessionId}&deviceType=pc&deviceId=${encodeURIComponent(pcDeviceId)}`
    );
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "Poll failed");
    const messages = data.data?.messages ?? data.messages ?? [];
    if (messages.length === 0) {
      throw new Error("PC 폴에 메시지 없음 (모바일→PC 큐 비어있음)");
    }
    return messages;
  });
  console.log(`   PC 수신 메시지 수: ${pcMessages.length}`);

  await test("POST /api/send (PC→chat_response)", async () => {
    const res = await fetch(`${RELAY_SERVER_URL}/api/send`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sessionId,
        deviceId: pcDeviceId,
        deviceType: "pc",
        type: "chat_response",
        data: {
          type: "chat_response",
          text: "테스트 응답입니다.",
          timestamp: new Date().toISOString(),
          source: "relay-test",
          clientId: "relay-client",
        },
      }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "Send failed");
    return data;
  });

  const mobileMessages = await test("GET /api/poll (모바일)", async () => {
    const res = await fetch(
      `${RELAY_SERVER_URL}/api/poll?sessionId=${sessionId}&deviceType=mobile&deviceId=${encodeURIComponent(mobileDeviceId)}`
    );
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "Poll failed");
    const messages = data.data?.messages ?? data.messages ?? [];
    if (messages.length === 0) {
      throw new Error("모바일 폴에 메시지 없음 (PC→모바일 큐 비어있음)");
    }
    return messages;
  });
  console.log(`   모바일 수신 메시지 수: ${mobileMessages.length}`);

  console.log("\n✅ 전체 테스트 통과\n");
}

main().catch((e) => {
  console.error("\n❌ 테스트 실패:", e.message || e);
  process.exit(1);
});
