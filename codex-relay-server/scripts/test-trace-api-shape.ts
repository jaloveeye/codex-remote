import assert from "node:assert/strict";
import { buildTraceTimeline } from "../lib/trace-timeline.ts";

const events = [
  {
    event_id: "e1",
    trace_id: "trc_api_shape",
    session_id: "ABC123",
    hop: "mobile.send.to_relay",
    status: "ok",
    server_ts: 1000,
  },
  {
    event_id: "e2",
    trace_id: "trc_api_shape",
    session_id: "ABC123",
    hop: "relay.recv.from_mobile",
    status: "ok",
    server_ts: 1200,
  },
  {
    event_id: "e3",
    trace_id: "trc_api_shape",
    session_id: "ABC123",
    hop: "mobile.ui.rendered",
    status: "ok",
    server_ts: 2500,
  },
] as const;

const timeline = buildTraceTimeline(events as any);
assert.equal(timeline.traceId, "trc_api_shape");
assert.equal(typeof timeline.totalMs, "number");
assert.ok(Array.isArray(timeline.hops));
assert.ok(Array.isArray(timeline.missingHops));
assert.ok("slowestSegment" in timeline);

console.log("[OK] trace API shape helper validated");
