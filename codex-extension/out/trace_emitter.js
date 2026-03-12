"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TraceEmitter = void 0;
class TraceEmitter {
    constructor(sender, maxBatchSize = 20) {
        this.queue = [];
        this.sender = sender;
        this.maxBatchSize = Math.max(1, maxBatchSize);
    }
    emitTraceHop(input) {
        const traceId = (input.traceId ?? "").trim();
        const sessionId = (input.sessionId ?? "").trim().toUpperCase();
        if (!traceId || !sessionId || !input.hop?.trim()) {
            return false;
        }
        const payload = {
            event_id: `tev_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
            trace_id: traceId,
            session_id: sessionId,
            hop: input.hop.trim(),
            status: input.status ?? "ok",
            server_ts: Date.now(),
            source_ts: input.sourceTs,
            command_id: input.commandId ?? null,
            relay_message_id: input.relayMessageId ?? null,
            sender_device_id: input.senderDeviceId ?? null,
            target_device_id: input.targetDeviceId ?? null,
            client_id: input.clientId ?? null,
            meta: input.meta ?? {},
        };
        this.queue.push(payload);
        return true;
    }
    async flushNow() {
        if (this.queue.length === 0)
            return 0;
        const batch = this.queue.splice(0, this.maxBatchSize);
        try {
            await this.sender(batch);
            return batch.length;
        }
        catch {
            this.queue = [...batch, ...this.queue];
            return 0;
        }
    }
    queuedCount() {
        return this.queue.length;
    }
}
exports.TraceEmitter = TraceEmitter;
//# sourceMappingURL=trace_emitter.js.map