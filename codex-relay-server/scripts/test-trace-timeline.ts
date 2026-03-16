import assert from "node:assert/strict";
import { buildTraceTimeline } from "../lib/trace-timeline.ts";

const base = 1_700_000_000_000;

const events = [
  {
    event_id: "e1",
    trace_id: "trc_1",
    session_id: "ABC123",
    hop: "mobile.send.to_relay",
    status: "ok",
    server_ts: base + 0,
    meta: {},
  },
  {
    event_id: "e2",
    trace_id: "trc_1",
    session_id: "ABC123",
    hop: "relay.recv.from_mobile",
    status: "ok",
    server_ts: base + 80,
    meta: {},
  },
  {
    event_id: "e3",
    trace_id: "trc_1",
    session_id: "ABC123",
    hop: "ext.dispatch.to_codex",
    status: "ok",
    server_ts: base + 150,
    meta: {},
  },
  {
    event_id: "e4",
    trace_id: "trc_1",
    session_id: "ABC123",
    hop: "codex.first_chunk",
    status: "ok",
    server_ts: base + 1400,
    meta: {},
  },
  {
    event_id: "e5",
    trace_id: "trc_1",
    session_id: "ABC123",
    hop: "mobile.ui.rendered",
    status: "ok",
    server_ts: base + 1880,
    meta: {},
  },
] as const;

const timeline = buildTraceTimeline(events as any);

assert.equal(timeline.traceId, "trc_1");
assert.equal(timeline.sessionId, "ABC123");
assert.equal(timeline.totalMs, 1880);
assert.equal(timeline.hops.length, 5);
assert.equal(timeline.hops[0].deltaFromPrevMs, 0);
assert.equal(timeline.hops[1].deltaFromPrevMs, 80);
assert.deepEqual(timeline.slowestSegment, {
  from: "ext.dispatch.to_codex",
  to: "codex.first_chunk",
  ms: 1250,
});
assert.ok(timeline.missingHops.includes("relay.enqueue.to_pc"));
assert.ok(timeline.missingHops.includes("mobile.poll.recv"));

console.log("[OK] trace timeline calculation");
