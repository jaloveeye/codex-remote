#!/usr/bin/env node
/**
 * Relay Trace Smoke Test
 *
 * 목적:
 * - trace-events/batch -> trace timeline/summary/recent API를 단일 스크립트로 검증
 * - 모바일 UI(Approvals > Trace timeline)에 넣어볼 traceId를 생성
 *
 * 예시:
 *   node test-relay-trace-smoke.js --relay https://codex-relay.jaloveeye.com
 *   node test-relay-trace-smoke.js --relay http://localhost:3000 --session ABC123
 */

const DEFAULT_RELAY_URL =
  process.env.RELAY_SERVER_URL || "https://codex-relay.jaloveeye.com";

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (!token.startsWith("--")) continue;
    const key = token.slice(2);
    const value = argv[i + 1] && !argv[i + 1].startsWith("--") ? argv[++i] : "true";
    out[key] = value;
  }
  return out;
}

async function requestJson(url, init = {}) {
  const response = await fetch(url, init);
  let body = null;
  try {
    body = await response.json();
  } catch (_) {
    body = null;
  }
  return { response, body };
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function createSession(relayUrl) {
  const { response, body } = await requestJson(`${relayUrl}/api/session`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });

  if (!response.ok || !body?.success || !body?.data?.sessionId) {
    throw new Error(`세션 생성 실패: ${body?.error || response.statusText}`);
  }

  return String(body.data.sessionId).trim().toUpperCase();
}

async function ensureTraceApiAvailable(relayUrl) {
  const { response } = await requestJson(`${relayUrl}/api/trace-events/batch`, {
    method: "OPTIONS",
  });

  if (response.status !== 404) return;

  const { response: versionRes, body: versionBody } = await requestJson(
    `${relayUrl}/api/version`
  );
  const version =
    versionRes.ok && versionBody?.success ? versionBody?.data?.version : null;
  const versionSuffix = version ? ` (현재 /api/version=${version})` : "";
  throw new Error(
    `trace API가 배포되어 있지 않습니다. /api/trace-events/batch 가 404 입니다${versionSuffix}. 최신 릴레이 배포 후 다시 실행하세요.`
  );
}

function buildTraceEvents({ traceId, sessionId }) {
  const commandId = `cmd_${Date.now()}`;
  const baseTs = Date.now() - 1000;

  const hops = [
    "mobile.prompt.created",
    "mobile.send.to_relay",
    "relay.recv.from_mobile",
    "relay.enqueue.to_pc",
    "ext.poll.recv",
    "ext.dispatch.to_codex",
    "codex.turn.started",
    "codex.first_chunk",
    "codex.turn.completed",
    "ext.send.to_relay",
    "relay.recv.from_pc",
    "relay.enqueue.to_mobile",
    "mobile.poll.recv",
    "mobile.ui.rendered",
  ];

  return hops.map((hop, index) => ({
    traceId,
    sessionId,
    hop,
    status: "ok",
    commandId,
    senderDeviceId: index < 9 ? "mobile-smoke" : "pc-smoke",
    targetDeviceId: index < 9 ? "pc-smoke" : "mobile-smoke",
    serverTs: baseTs + index * 40,
    sourceTs: baseTs + index * 40,
    meta: {
      smoke: true,
      index,
      generatedBy: "test-relay-trace-smoke.js",
    },
  }));
}

async function ingestTrace(relayUrl, events) {
  const { response, body } = await requestJson(`${relayUrl}/api/trace-events/batch`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ events }),
  });

  if (!response.ok || !body?.success) {
    throw new Error(`trace ingest 실패: ${body?.error || response.statusText}`);
  }

  return body;
}

async function fetchTimeline(relayUrl, traceId) {
  const { response, body } = await requestJson(
    `${relayUrl}/api/trace/${encodeURIComponent(traceId)}/timeline`
  );

  if (!response.ok || !body?.success) {
    throw new Error(`trace timeline 조회 실패: ${body?.error || response.statusText}`);
  }

  return body.data;
}

async function fetchSummary(relayUrl, traceId) {
  const { response, body } = await requestJson(
    `${relayUrl}/api/trace/${encodeURIComponent(traceId)}/summary`
  );

  if (!response.ok || !body?.success) {
    throw new Error(`trace summary 조회 실패: ${body?.error || response.statusText}`);
  }

  return body.data;
}

async function fetchRecent(relayUrl, sessionId) {
  const { response, body } = await requestJson(
    `${relayUrl}/api/trace/recent?sessionId=${encodeURIComponent(sessionId)}&limit=10`
  );

  if (!response.ok || !body?.success) {
    throw new Error(`trace recent 조회 실패: ${body?.error || response.statusText}`);
  }

  return body.data;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const relayUrl = (args.relay || DEFAULT_RELAY_URL).replace(/\/+$/, "");

  await ensureTraceApiAvailable(relayUrl);

  let sessionId = String(args.session || "")
    .trim()
    .toUpperCase();
  if (!sessionId) {
    sessionId = await createSession(relayUrl);
  }

  const traceId = `trc_smoke_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
  const events = buildTraceEvents({ traceId, sessionId });

  console.log("\n🧪 Relay trace smoke test");
  console.log(`   relay: ${relayUrl}`);
  console.log(`   sessionId: ${sessionId}`);
  console.log(`   traceId: ${traceId}`);

  const ingestResult = await ingestTrace(relayUrl, events);
  console.log(`✅ ingest: count=${ingestResult?.data?.count || events.length}`);

  const timeline = await fetchTimeline(relayUrl, traceId);
  const summary = await fetchSummary(relayUrl, traceId);
  const recent = await fetchRecent(relayUrl, sessionId);

  assert(timeline.traceId === traceId, `timeline.traceId 불일치: ${timeline.traceId}`);
  assert(
    String(timeline.sessionId || "").toUpperCase() === sessionId,
    `timeline.sessionId 불일치: ${timeline.sessionId}`
  );
  assert(Array.isArray(timeline.hops) && timeline.hops.length >= events.length, "timeline.hops 누락");
  assert(Array.isArray(timeline.missingHops) && timeline.missingHops.length === 0, "missingHops 존재");
  assert(summary.traceId === traceId, `summary.traceId 불일치: ${summary.traceId}`);
  assert(summary.missingHopCount === 0, `summary.missingHopCount=${summary.missingHopCount}`);
  assert((recent.traceIds || []).includes(traceId), "recent traceIds에 traceId가 없음");

  console.log(`✅ timeline.totalMs=${timeline.totalMs}`);
  console.log(
    `✅ summary: totalMs=${summary.totalMs}, missing=${summary.missingHopCount}, errors=${summary.errorCount}`
  );
  console.log(`✅ recent contains traceId (${traceId})`);

  console.log("\n📱 모바일 UI 확인 가이드");
  console.log("   1) 앱 연결 후 Approvals 탭 이동");
  console.log("   2) Trace timeline 섹션에서 Trace ID 입력");
  console.log(`   3) traceId: ${traceId}`);
  console.log("   4) 조회 버튼 -> hops/missing/slowest 확인");

  console.log("\n🎉 trace smoke test PASS");
}

main().catch((error) => {
  console.error(`\n❌ trace smoke test FAIL: ${error?.message || error}`);
  process.exit(1);
});
