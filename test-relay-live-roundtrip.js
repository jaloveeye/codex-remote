#!/usr/bin/env node
/**
 * 릴레이 + 실제 익스텐션 라운드트립 검증 스크립트
 *
 * 목적:
 * - 모바일 클라이언트처럼 릴레이에 직접 접속
 * - 실제 PC(익스텐션) 연결 세션으로 프롬프트 전송
 * - 스트리밍/최종 응답을 수신해 중복 누적 여부를 분석
 *
 * 사용 예:
 *   node test-relay-live-roundtrip.js --relay https://codex-relay.jaloveeye.com
 *   node test-relay-live-roundtrip.js --relay http://localhost:3000 --session ABC123
 */

const DEFAULT_RELAY_URL =
  process.env.RELAY_SERVER_URL || "https://codex-relay.jaloveeye.com";
const DEFAULT_PROMPT = process.env.E2E_PROMPT || "hello";
const DEFAULT_WAIT_PC_MS = Number(process.env.E2E_WAIT_PC_MS || 120000);
const DEFAULT_TIMEOUT_MS = Number(process.env.E2E_TIMEOUT_MS || 120000);
const DEFAULT_POLL_INTERVAL_MS = Number(process.env.E2E_POLL_INTERVAL_MS || 1000);

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

function nowIso() {
  return new Date().toISOString();
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function requestJson(url, init = {}) {
  const res = await fetch(url, init);
  let body = null;
  try {
    body = await res.json();
  } catch (_) {
    body = null;
  }
  return { res, body };
}

function suffixPrefixOverlapLength(base, suffixCandidate) {
  const max = Math.min(base.length, suffixCandidate.length);
  for (let i = max; i > 0; i--) {
    if (base.slice(base.length - i) === suffixCandidate.slice(0, i)) {
      return i;
    }
  }
  return 0;
}

function mergeStreamingText({ current, chunkText, fullText, isReplace }) {
  if (isReplace) {
    if (fullText) return fullText;
    if (chunkText) return chunkText;
    return current;
  }

  if (fullText) {
    if (!current) return fullText;
    if (fullText === current) return current;
    if (fullText.length >= current.length && fullText.startsWith(current)) {
      return fullText;
    }
  }

  if (!chunkText) return current;
  if (current.endsWith(chunkText)) return current;
  const overlap = suffixPrefixOverlapLength(current, chunkText);
  return current + chunkText.slice(overlap);
}

function detectSuspiciousRepetition(text) {
  if (!text || text.length < 8) return null;

  // 동일 단어 3회 이상 연속 반복 감지
  const tokenRepeat = text.match(/(\b[\p{L}\p{N}_-]+\b)(?:\s+\1){2,}/iu);
  if (tokenRepeat) {
    return `repeated token pattern: "${tokenRepeat[0]}"`;
  }

  // 3~12자 단위 문자열의 3회 이상 반복 감지 (공백 포함)
  const blockRepeat = text.match(/(.{3,12}?)(?:\1){2,}/u);
  if (blockRepeat) {
    return `repeated block pattern: "${blockRepeat[0]}"`;
  }
  return null;
}

async function createSession(relayUrl) {
  const { res, body } = await requestJson(`${relayUrl}/api/session`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });
  if (!res.ok || !body?.success || !body?.data?.sessionId) {
    throw new Error(`세션 생성 실패: ${body?.error || res.statusText}`);
  }
  return body.data.sessionId;
}

async function getSession(relayUrl, sessionId) {
  const { res, body } = await requestJson(
    `${relayUrl}/api/session?sessionId=${encodeURIComponent(sessionId)}`
  );
  if (!res.ok || !body?.success) {
    throw new Error(`세션 조회 실패(${sessionId}): ${body?.error || res.statusText}`);
  }
  return body.data;
}

async function waitForPcConnection(relayUrl, sessionId, waitMs) {
  const started = Date.now();
  while (Date.now() - started < waitMs) {
    const session = await getSession(relayUrl, sessionId);
    if (session?.pcDeviceId) return session;
    await sleep(1000);
  }
  throw new Error(
    `PC(익스텐션) 연결 대기 타임아웃(${waitMs}ms). 세션 ${sessionId} 에 익스텐션을 먼저 연결해 주세요.`
  );
}

async function connectMobile(relayUrl, sessionId, mobileDeviceId) {
  const { res, body } = await requestJson(`${relayUrl}/api/connect`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      sessionId,
      deviceId: mobileDeviceId,
      deviceType: "mobile",
    }),
  });
  if (!res.ok || !body?.success) {
    throw new Error(
      `모바일 연결 실패: ${body?.error || res.statusText} (${body?.errorCode || "no-code"})`
    );
  }
}

async function sendPrompt(relayUrl, sessionId, mobileDeviceId, prompt) {
  const { res, body } = await requestJson(`${relayUrl}/api/send`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      sessionId,
      deviceId: mobileDeviceId,
      deviceType: "mobile",
      type: "insert_text",
      data: {
        type: "insert_text",
        id: `e2e-${Date.now()}`,
        senderDeviceId: mobileDeviceId,
        text: prompt,
        prompt: true,
        execute: true,
        agentMode: "auto",
      },
    }),
  });

  if (!res.ok || !body?.success) {
    const policy = body?.data?.policyDecision;
    if (policy === "approval_required") {
      throw new Error(
        `승인 필요 상태로 차단됨(approval_required). 현재 스크립트는 승인 자동처리를 수행하지 않습니다. approvalId=${body?.data?.approvalId || "unknown"}`
      );
    }
    throw new Error(`프롬프트 전송 실패: ${body?.error || res.statusText}`);
  }
}

async function pollMessages(relayUrl, sessionId, mobileDeviceId) {
  const { res, body } = await requestJson(
    `${relayUrl}/api/poll?sessionId=${encodeURIComponent(
      sessionId
    )}&deviceType=mobile&deviceId=${encodeURIComponent(mobileDeviceId)}`
  );
  if (!res.ok || !body?.success) {
    throw new Error(`poll 실패: ${body?.error || res.statusText}`);
  }
  return body?.data?.messages || [];
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  const relayUrl = (args.relay || DEFAULT_RELAY_URL).replace(/\/+$/, "");
  const prompt = args.prompt || DEFAULT_PROMPT;
  const waitPcMs = Number(args.waitPcMs || DEFAULT_WAIT_PC_MS);
  const timeoutMs = Number(args.timeoutMs || DEFAULT_TIMEOUT_MS);
  const pollIntervalMs = Number(args.pollIntervalMs || DEFAULT_POLL_INTERVAL_MS);
  let sessionId = (args.session || process.env.E2E_SESSION_ID || "").trim().toUpperCase();
  const mobileDeviceId = args.mobileDeviceId || `mobile-e2e-${Date.now()}`;

  console.log(`\n🧪 Relay+Extension live roundtrip test`);
  console.log(`   relay: ${relayUrl}`);
  console.log(`   prompt: ${JSON.stringify(prompt)}`);
  console.log(`   startedAt: ${nowIso()}`);

  if (!sessionId) {
    sessionId = await createSession(relayUrl);
    console.log(`\n📌 새 세션 생성됨: ${sessionId}`);
    console.log(`   VS Code 익스텐션을 같은 세션 ID로 연결합니다...`);
  } else {
    console.log(`\n📌 기존 세션 사용: ${sessionId}`);
  }

  const session = await waitForPcConnection(relayUrl, sessionId, waitPcMs);
  console.log(`✅ PC 연결 확인: ${session.pcDeviceId}`);

  await connectMobile(relayUrl, sessionId, mobileDeviceId);
  console.log(`✅ 모바일 연결 확인: ${mobileDeviceId}`);

  await sendPrompt(relayUrl, sessionId, mobileDeviceId, prompt);
  console.log(`✅ 프롬프트 전송 완료`);

  const startedAt = Date.now();
  const typeCounts = new Map();
  let streamingText = "";
  let finalText = "";
  let completeSeen = false;

  while (Date.now() - startedAt < timeoutMs) {
    const messages = await pollMessages(relayUrl, sessionId, mobileDeviceId);
    for (const msg of messages) {
      const type = msg?.type || msg?.data?.type || "unknown";
      const data = msg?.data || msg || {};
      typeCounts.set(type, (typeCounts.get(type) || 0) + 1);

      if (type === "chat_response_chunk") {
        const chunkText = String(data?.text || "");
        const fullText = String(data?.fullText || chunkText);
        const isReplace = data?.isReplace === true;
        streamingText = mergeStreamingText({
          current: streamingText,
          chunkText,
          fullText,
          isReplace,
        });
      } else if (type === "chat_response") {
        finalText = String(data?.text || "");
      } else if (type === "chat_response_complete") {
        completeSeen = true;
      } else if (type === "error") {
        throw new Error(`error message 수신: ${data?.message || "unknown"}`);
      }
    }

    if (!finalText && completeSeen && streamingText) {
      finalText = streamingText;
    }

    if (finalText && (completeSeen || (typeCounts.get("chat_response_chunk") || 0) === 0)) {
      break;
    }
    await sleep(pollIntervalMs);
  }

  if (!finalText) {
    const stats = Object.fromEntries(typeCounts.entries());
    throw new Error(
      `응답 타임아웃(${timeoutMs}ms). 수신 타입 통계=${JSON.stringify(stats)}`
    );
  }

  const suspicious = detectSuspiciousRepetition(finalText);
  const stats = Object.fromEntries(typeCounts.entries());

  console.log(`\n📊 수신 타입 통계: ${JSON.stringify(stats)}`);
  console.log(`📝 최종 응답 길이: ${finalText.length}`);
  console.log(`📝 최종 응답 미리보기: ${JSON.stringify(finalText.slice(0, 160))}`);

  if (suspicious) {
    throw new Error(`반복 패턴 감지됨: ${suspicious}`);
  }

  console.log(`\n✅ live roundtrip 테스트 통과`);
}

main().catch((error) => {
  console.error(`\n❌ live roundtrip 테스트 실패: ${error.message || error}`);
  process.exit(1);
});
