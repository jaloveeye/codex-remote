import test from "node:test";
import assert from "node:assert/strict";

import { TraceEmitter } from "./trace_emitter";

test("emitTraceHop ignores payload without trace/session", () => {
  const emitter = new TraceEmitter(async () => undefined, 10);

  assert.equal(
    emitter.emitTraceHop({
      hop: "ext.poll.recv",
      traceId: "",
      sessionId: "ABC123",
    }),
    false
  );
  assert.equal(emitter.queuedCount(), 0);
});

test("flushNow sends up to maxBatchSize", async () => {
  const sent: number[] = [];
  const emitter = new TraceEmitter(async (events) => {
    sent.push(events.length);
  }, 2);

  emitter.emitTraceHop({
    traceId: "trc-1",
    sessionId: "abc123",
    hop: "ext.poll.recv",
  });
  emitter.emitTraceHop({
    traceId: "trc-1",
    sessionId: "abc123",
    hop: "ext.dispatch.to_codex",
  });
  emitter.emitTraceHop({
    traceId: "trc-1",
    sessionId: "abc123",
    hop: "ext.send.to_relay",
  });

  const flushed1 = await emitter.flushNow();
  assert.equal(flushed1, 2);
  assert.equal(emitter.queuedCount(), 1);

  const flushed2 = await emitter.flushNow();
  assert.equal(flushed2, 1);
  assert.equal(emitter.queuedCount(), 0);
  assert.deepEqual(sent, [2, 1]);
});

test("flushNow restores queue when sender fails", async () => {
  const emitter = new TraceEmitter(async () => {
    throw new Error("network");
  }, 10);

  emitter.emitTraceHop({
    traceId: "trc-2",
    sessionId: "ZZ9999",
    hop: "ext.poll.recv",
  });

  const flushed = await emitter.flushNow();
  assert.equal(flushed, 0);
  assert.equal(emitter.queuedCount(), 1);
});
