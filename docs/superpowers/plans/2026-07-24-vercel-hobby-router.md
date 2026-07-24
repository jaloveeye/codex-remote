# Vercel Hobby Relay Router Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package all Codex relay API handlers behind one Vercel function while preserving every deployed client URL and request/response contract.

**Architecture:** A testable dependency-injected router module resolves a rewrite-injected path against typed handler keys and delegates the untouched Vercel request/response objects. One `api/router.ts` entry point supplies the explicit 23-handler production registry and a 30-second duration, and `vercel.json` allowlists only that entry point while rewriting public API paths to it.

**Tech Stack:** TypeScript, `@vercel/node`, Vercel rewrites/builders, Node type-stripping test scripts

---

## Chunk 1: Router behavior

### Task 1: Add failing route and adapter tests

**Files:**
- Create: `codex-relay-server/scripts/test-relay-router.ts`
- Modify: `codex-relay-server/package.json`
- Test: `codex-relay-server/scripts/test-relay-router.ts`

- [ ] **Step 1: Register a router test script**

Add:

```json
"test:relay-router": "node --experimental-strip-types scripts/test-relay-router.ts"
```

- [ ] **Step 2: Write the failing route inventory test**

Import the not-yet-created dependency-injected router factory and pure route
resolver. Assert that all 23 direct routes and the four friendly trace aliases
resolve to the expected typed handler keys, while an unknown route does not
resolve. Do not import production handlers in this script: existing production
modules use `.js` specifiers that Node's type-stripping runner does not remap to
`.ts`.

- [ ] **Step 3: Write failing adapter preservation tests**

Use fake handlers and lightweight Vercel request/response doubles to assert:

- method, body, headers, and ordinary query parameters keep object identity
- the synthetic `__relay_internal_path` query key is removed before delegation
- a rewrite-provided path wins when a spoofed client value is also present
- dynamic trace routes inject the URL trace ID and override query `traceId`
- an unknown path returns JSON `404`
- delegated `write` and `end` calls pass through the original response object

- [ ] **Step 4: Run the test and verify RED**

Run:

```bash
cd codex-relay-server
npm run test:relay-router
```

Expected: FAIL with module-not-found because `../lib/relay-router.ts` does not
exist.

- [ ] **Step 5: Commit the failing test**

```bash
cd ..
git add codex-relay-server/package.json \
  codex-relay-server/scripts/test-relay-router.ts
git commit -m "test: define relay router compatibility"
cd codex-relay-server
```

### Task 2: Implement the route resolver and adapter

**Files:**
- Create: `codex-relay-server/lib/relay-router.ts`
- Test: `codex-relay-server/scripts/test-relay-router.ts`

- [ ] **Step 1: Define handler and route types**

Use the existing Vercel types:

```ts
export type RelayHandler = (
  req: VercelRequest,
  res: VercelResponse
) => unknown | Promise<unknown>;

export type RelayRouteMatch = {
  handler: RelayHandler;
  traceId?: string;
};
```

- [ ] **Step 2: Build the explicit production registry**

Define all 23 handler keys and map the supported direct route names. Add
explicit alias resolution for:

```text
trace-events/batch
trace/recent
trace/:traceId/timeline
trace/:traceId/summary
```

- [ ] **Step 3: Implement trusted path extraction**

Read `req.query.__relay_internal_path`. When Vercel supplies an array because a
client spoofed the same query key, select the last element (the rewrite
destination value), then delete the synthetic key. Do not derive handler
selection from any other client query value. This ordering is provisional
until it passes the real `vercel dev` and preview-deployment collision tests in
Task 3.

- [ ] **Step 4: Implement delegation**

Resolve the trusted path, inject a dynamic URL `traceId` when present, and call
the selected handler with the original request and response objects. Return:

```ts
res.status(404).json({
  success: false,
  error: "API route not found",
  timestamp: Date.now(),
});
```

for unknown paths.

- [ ] **Step 5: Run the router test and verify GREEN**

Run:

```bash
npm run test:relay-router
```

Expected: all inventory, preservation, spoofing, trace, 404, and response
pass-through assertions report `[OK]`.

- [ ] **Step 6: Run type checking and existing tests**

Run:

```bash
npm run type-check
npm run test:trace-api-shape
npm run test:trace-timeline
npm run validate:command-event
npm run test:command-policy
```

Expected: all commands exit `0`.

- [ ] **Step 7: Commit the implementation**

```bash
cd ..
git add codex-relay-server/lib/relay-router.ts
git commit -m "feat: add single-function relay router"
cd codex-relay-server
```

## Chunk 2: Vercel packaging and deployment

### Task 3: Package exactly one Vercel function

**Files:**
- Create: `codex-relay-server/api/router.ts`
- Modify: `codex-relay-server/vercel.json`
- Create: `codex-relay-server/scripts/check-vercel-function-count.mjs`
- Create: `codex-relay-server/scripts/test-deployed-route-matrix.mjs`
- Modify: `codex-relay-server/package.json`
- Test: `codex-relay-server/scripts/check-vercel-function-count.mjs`

- [ ] **Step 1: Write the failing function-count check**

Add `check:vercel-functions` to run a script that scans
`.vercel/output/functions` for `.func` directories and requires exactly one.
Run it against the current failed/absent build output and verify it fails.

- [ ] **Step 2: Add the single function entry**

Import every existing handler in `api/router.ts`, construct a typed registry
covering every handler key, and create the production router:

```ts
import { createRelayRouter } from "../lib/relay-router.js";
// ...23 existing default-handler imports...

export const config = { maxDuration: 30 };
export default createRelayRouter(handlerRegistry);
```

- [ ] **Step 3: Replace broad Vercel build globs**

Configure `vercel.json` to build only `api/router.ts`. Replace the current
specific trace rewrites and broad API rewrite with:

```json
{
  "source": "/api/:path*",
  "destination": "/api/router.ts?__relay_internal_path=:path*"
}
```

Keep the existing CORS headers. The `.ts` destination is intentional for the
legacy `builds` configuration and must be verified through `vercel dev`.

- [ ] **Step 4: Build locally**

Run:

```bash
vercel build --prod --yes
npm run check:vercel-functions
```

Expected: Vercel build succeeds and exactly one `.func` directory exists,
regardless of whether the builder names it `api/router.func` or
`api/router.ts.func`.

- [ ] **Step 5: Verify local HTTP routing and collision behavior**

Run `vercel dev` in the background, wait for readiness, assert both responses,
and always stop it:

```bash
vercel dev --listen 127.0.0.1:3000 > /tmp/codex-relay-vercel-dev.log 2>&1 &
VERCEL_DEV_PID=$!
trap 'kill "$VERCEL_DEV_PID" 2>/dev/null || true' EXIT

READY=false
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:3000/api/health > /tmp/codex-relay-health.json; then
    READY=true
    break
  fi
  sleep 1
done
test "$READY" = true
jq -e '.success == true and .data.status == "healthy"' \
  /tmp/codex-relay-health.json

curl -fsS \
  'http://127.0.0.1:3000/api/version?__relay_internal_path=health' \
  > /tmp/codex-relay-spoof.json
jq -e '.success == true and .data.version == "0.2.0" and (.data.status == null)' \
  /tmp/codex-relay-spoof.json

kill "$VERCEL_DEV_PID"
wait "$VERCEL_DEV_PID" 2>/dev/null || true
trap - EXIT
```

Expected: the first response is the health handler, while the spoofing request
still reaches the version handler. Stop the local server afterward. If this
fails, inspect the actual rewrite query representation and adjust trusted path
extraction before proceeding.

- [ ] **Step 6: Add and run the deployed-route matrix**

Create a script accepting a relay base URL. Request all 23 direct paths and
four aliases with safe missing-input requests, and fail only when any response
is the router's `"API route not found"` sentinel (or transport failure).

- [ ] **Step 7: Run the complete regression suite**

Run the router test, type check, and all existing relay scripts again.

- [ ] **Step 8: Commit packaging**

```bash
cd ..
git add codex-relay-server/api/router.ts codex-relay-server/vercel.json \
  codex-relay-server/package.json \
  codex-relay-server/scripts/check-vercel-function-count.mjs \
  codex-relay-server/scripts/test-deployed-route-matrix.mjs
git commit -m "fix: package relay as one Vercel function"
cd codex-relay-server
```

### Task 4: Deploy and restore the production domain

**Files:**
- No tracked source changes

- [ ] **Step 1: Deploy the production build**

Capture the URL from the CLI output:

```bash
vercel --prod --yes 2>&1 | tee /tmp/codex-relay-deploy.log
DEPLOYMENT_URL=$(grep -Eo 'https://codex-relay-server-[^ ]+\\.vercel\\.app' \
  /tmp/codex-relay-deploy.log | tail -1)
test -n "$DEPLOYMENT_URL"
vercel inspect "$DEPLOYMENT_URL"
```

Expected: deployment reaches `Ready` without the Hobby function-count error.

- [ ] **Step 2: Attach the custom domain**

Run:

```bash
vercel domains add codex-relay.jaloveeye.com codex-relay-server
vercel alias set "$DEPLOYMENT_URL" codex-relay.jaloveeye.com
```

Confirm the domain appears on `codex-relay-server`, while
`relay.jaloveeye.com` remains untouched.

- [ ] **Step 3: Verify health**

Run:

```bash
curl -fsS https://codex-relay.jaloveeye.com/api/health
```

Expected: HTTP `200`, `status: healthy`, version `0.2.0`, store `supabase`, and
the Supabase key present.

- [ ] **Step 4: Verify API compatibility**

From the repository root, run:

```bash
cd ..
node test-relay-full.js https://codex-relay.jaloveeye.com
node test-relay-trace-smoke.js \
  --relay https://codex-relay.jaloveeye.com
cd codex-relay-server
node scripts/test-deployed-route-matrix.mjs \
  https://codex-relay.jaloveeye.com
```

Expected: the full relay lifecycle, trace smoke test, and all 27 direct/alias
route checks pass.

- [ ] **Step 5: Verify sustained SSE**

Create a temporary session, then connect PC before mobile:

```bash
BASE=https://codex-relay.jaloveeye.com
SESSION_JSON=$(curl -fsS -X POST "$BASE/api/session")
SESSION_ID=$(printf '%s' "$SESSION_JSON" | jq -r '.data.sessionId')
PC_DEVICE="deploy-sse-pc-$(date +%s)"
MOBILE_DEVICE="deploy-sse-mobile-$(date +%s)"
curl -fsS -X POST "$BASE/api/connect" -H 'Content-Type: application/json' \
  -d "{\"sessionId\":\"$SESSION_ID\",\"deviceId\":\"$PC_DEVICE\",\"deviceType\":\"pc\"}"
curl -fsS -X POST "$BASE/api/connect" -H 'Content-Type: application/json' \
  -d "{\"sessionId\":\"$SESSION_ID\",\"deviceId\":\"$MOBILE_DEVICE\",\"deviceType\":\"mobile\"}"
curl -sN --max-time 35 \
  "$BASE/api/stream?sessionId=$SESSION_ID&deviceId=$MOBILE_DEVICE&deviceType=mobile" \
  > /tmp/codex-relay-sse.out
grep -q '^event: reconnect$' /tmp/codex-relay-sse.out
curl -fsS -X POST "$BASE/api/session-clear" \
  -H 'Content-Type: application/json' \
  -d "{\"sessionId\":\"$SESSION_ID\",\"deviceId\":\"$PC_DEVICE\",\"keepPc\":false}"
```

Expected: PC and mobile connect successfully, the stream emits
`event: reconnect` after approximately 25 seconds, and cleanup deletes the
temporary session.

- [ ] **Step 6: Record final state**

Report the production deployment URL, custom-domain response, test evidence,
feature branch, commits, and any remaining Cursor relay outage separately.
