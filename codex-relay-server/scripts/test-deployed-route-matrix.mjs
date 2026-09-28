const baseUrl = (process.argv[2] || process.env.RELAY_SERVER_URL || "").replace(
  /\/+$/,
  ""
);

if (!baseUrl) {
  console.error(
    "Usage: node scripts/test-deployed-route-matrix.mjs <relay-base-url>"
  );
  process.exit(2);
}

const routes = [
  "command-approvals",
  "command-events",
  "command-timeline-summary",
  "connect",
  "debug-sessions",
  "disconnect",
  "health",
  "heartbeat",
  "poll",
  "resolve-command-approval",
  "send",
  "session-clear",
  "session",
  "sessions-waiting-for-pc",
  "sessions-with-mobile",
  "store",
  "stream",
  "trace-event",
  "trace-events-batch",
  "trace-recent",
  "trace-summary",
  "trace-timeline",
  "version",
  "trace-events/batch",
  "trace/recent",
  "trace/route-matrix/timeline",
  "trace/route-matrix/summary",
];

let failed = false;
for (const route of routes) {
  const url = `${baseUrl}/api/${route}`;
  try {
    const response = await fetch(url, {
      headers: { "x-relay-route-matrix": "1" },
      signal: AbortSignal.timeout(15_000),
    });
    const body = await response.text();
    if (body.includes('"error":"API route not found"')) {
      failed = true;
      console.error(`[FAIL] ${route}: router 404`);
      continue;
    }
    console.log(`[OK] ${route}: HTTP ${response.status}`);
  } catch (error) {
    failed = true;
    console.error(
      `[FAIL] ${route}: ${error instanceof Error ? error.message : error}`
    );
  }
}

if (failed) {
  process.exit(1);
}

console.log(`[OK] all ${routes.length} relay routes reached a handler`);
