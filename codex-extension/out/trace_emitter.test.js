"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const node_test_1 = __importDefault(require("node:test"));
const strict_1 = __importDefault(require("node:assert/strict"));
const trace_emitter_1 = require("./trace_emitter");
(0, node_test_1.default)("emitTraceHop ignores payload without trace/session", () => {
    const emitter = new trace_emitter_1.TraceEmitter(async () => undefined, 10);
    strict_1.default.equal(emitter.emitTraceHop({
        hop: "ext.poll.recv",
        traceId: "",
        sessionId: "ABC123",
    }), false);
    strict_1.default.equal(emitter.queuedCount(), 0);
});
(0, node_test_1.default)("flushNow sends up to maxBatchSize", async () => {
    const sent = [];
    const emitter = new trace_emitter_1.TraceEmitter(async (events) => {
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
    strict_1.default.equal(flushed1, 2);
    strict_1.default.equal(emitter.queuedCount(), 1);
    const flushed2 = await emitter.flushNow();
    strict_1.default.equal(flushed2, 1);
    strict_1.default.equal(emitter.queuedCount(), 0);
    strict_1.default.deepEqual(sent, [2, 1]);
});
(0, node_test_1.default)("flushNow restores queue when sender fails", async () => {
    const emitter = new trace_emitter_1.TraceEmitter(async () => {
        throw new Error("network");
    }, 10);
    emitter.emitTraceHop({
        traceId: "trc-2",
        sessionId: "ZZ9999",
        hop: "ext.poll.recv",
    });
    const flushed = await emitter.flushNow();
    strict_1.default.equal(flushed, 0);
    strict_1.default.equal(emitter.queuedCount(), 1);
});
//# sourceMappingURL=trace_emitter.test.js.map