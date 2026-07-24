# Relay and Model Latency Implementation Plan

> **For agentic workers:** REQUIRED: Execute this plan in the current session without subagents because the user explicitly disabled multi-agent work. Track each task with the active plan.

**Goal:** Reduce relay database round trips and make model selection resilient to stale or unsupported model names.

**Architecture:** Supabase polling moves to one atomic `relay_poll_messages` RPC that validates the session, refreshes the PC heartbeat, dequeues messages, and returns them in one database call. Relay trace persistence runs as durable background work instead of extending request latency. The Extension owns authoritative runtime-model validation and coalesces concurrent capability requests; the mobile app sends `auto` until a live or cached catalog validates a concrete selection.

**Tech Stack:** TypeScript, Vercel Functions, Supabase/PostgreSQL, VS Code Extension TypeScript, Flutter/Dart.

---

## Chunk 1: Relay database path

### Task 1: Atomic Supabase poll RPC

**Files:**
- Create: `codex-relay-server/supabase/migrations/20260724_relay_poll_messages.sql`
- Modify: `codex-relay-server/supabase/schema.sql`
- Modify: `codex-relay-server/lib/supabase-store.ts`
- Modify: `codex-relay-server/lib/redis.ts`
- Modify: `codex-relay-server/lib/store.ts`
- Modify: `codex-relay-server/api/poll.ts`
- Create: `codex-relay-server/scripts/test-supabase-poll.ts`
- Modify: `codex-relay-server/package.json`

- [ ] Write a failing fake-client test proving Supabase polling performs exactly one `rpc("relay_poll_messages")` call and normalizes its JSON result.
- [ ] Run `npm run test:supabase-poll` and confirm it fails because the poll function does not exist.
- [ ] Add the service-role-only PostgreSQL function using `FOR UPDATE SKIP LOCKED` and `DELETE ... RETURNING` for atomic dequeue.
- [ ] Add `pollMessages` to both store implementations and route `/api/poll` through it.
- [ ] Run the target test and relay type-check.

### Task 2: Remove repeated session reads

**Files:**
- Modify: `codex-relay-server/lib/supabase-store.ts`
- Modify: `codex-relay-server/lib/redis.ts`
- Modify: `codex-relay-server/api/connect.ts`
- Modify: `codex-relay-server/api/send.ts`
- Create: `codex-relay-server/scripts/test-store-query-shape.ts`

- [ ] Write failing tests for passing an already-loaded session into `joinSession` and mobile device IDs into `sendMessage`.
- [ ] Make the optional context parameters compatible in Supabase and Redis stores.
- [ ] Replace discovery N+1 reads with one `relay_sessions` select.
- [ ] Make `getSession` distinguish a missing row from a transient Supabase error.
- [ ] Run target tests and type-check.

### Task 3: Durable background trace writes

**Files:**
- Create: `codex-relay-server/lib/background-work.ts`
- Create: `codex-relay-server/scripts/test-background-work.ts`
- Modify: `codex-relay-server/api/send.ts`
- Modify: `codex-relay-server/api/poll.ts`
- Modify: `codex-relay-server/package.json`

- [ ] Write a failing test proving scheduling returns before the trace promise settles.
- [ ] Implement a Vercel `waitUntil` scheduler with a safe local fallback.
- [ ] Schedule send/poll trace persistence without awaiting it in the user-facing response path.
- [ ] Run target tests and the relay regression suite.

## Chunk 2: Extension model authority

### Task 4: Capability single-flight and dynamic model resolution

**Files:**
- Create: `codex-extension/src/runtime_capability_policy.ts`
- Create: `codex-extension/src/runtime_capability_policy.test.ts`
- Modify: `codex-extension/src/codex-handler.ts`
- Modify: `codex-extension/package.json`

- [ ] Write failing pure TypeScript tests showing concurrent loads share one promise and a short TTL cache.
- [ ] Write failing tests showing unsupported, empty, `auto`, or unavailable-catalog model requests resolve to no explicit model, while a supported explicit model is preserved.
- [ ] Add the single-flight cache and use it in `getRuntimeCapabilities`.
- [ ] Validate every prompt model immediately before `turn/start`; omit invalid models so Codex selects its current account default.
- [ ] Log requested/effective models and fallback reasons without exposing prompt content.
- [ ] Compile and run the new Extension tests.

## Chunk 3: Mobile request policy

### Task 5: Remove fixed fallback model and retry amplification

**Files:**
- Create: `mobile-app/lib/services/runtime_capability_policy.dart`
- Create: `mobile-app/test/services/runtime_capability_policy_test.dart`
- Modify: `mobile-app/lib/main.dart`

- [ ] Write failing Flutter tests showing no catalog means only `auto`, stale selections normalize to `auto`, and concurrent capability-load calls coalesce.
- [ ] Replace the hard-coded `gpt-5`/`gpt-5-mini` fallback catalog with `auto` behavior.
- [ ] Add an in-flight guard around `_loadRuntimeCapabilities`.
- [ ] Remove the three timer-driven duplicate capability commands; retain one user-visible delayed state and one explicit/manual reload path.
- [ ] Run the target Flutter test and the full `flutter test` gate.

## Chunk 4: Production verification

### Task 6: Apply, deploy, and measure

**Files:**
- Update only if validation reveals defects in the files above.

- [ ] Apply the SQL migration to Supabase and verify the RPC using a temporary session.
- [ ] Run all relay, Extension, and Flutter tests.
- [ ] Build and deploy the single-function Vercel production artifact.
- [ ] Confirm the custom domain is healthy and the function remains in `icn1`.
- [ ] Run the same eight-cycle relay benchmark and compare it with the 500 ms median baseline.
- [ ] Commit in small Git Flow-compatible increments, leaving unrelated untracked files untouched.
