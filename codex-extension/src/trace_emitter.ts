export type TraceStatus = "ok" | "error" | "timeout" | "fail";

export interface TraceHopInput {
  traceId?: string | null;
  sessionId?: string | null;
  hop: string;
  status?: TraceStatus;
  commandId?: string | null;
  relayMessageId?: string | null;
  senderDeviceId?: string | null;
  targetDeviceId?: string | null;
  clientId?: string | null;
  sourceTs?: number;
  meta?: Record<string, unknown>;
}

export interface TraceEventPayload {
  event_id: string;
  trace_id: string;
  session_id: string;
  hop: string;
  status: TraceStatus;
  server_ts: number;
  source_ts?: number;
  command_id?: string | null;
  relay_message_id?: string | null;
  sender_device_id?: string | null;
  target_device_id?: string | null;
  client_id?: string | null;
  meta?: Record<string, unknown>;
}

export type TraceBatchSender = (events: TraceEventPayload[]) => Promise<void>;

export class TraceEmitter {
  private readonly sender: TraceBatchSender;
  private readonly maxBatchSize: number;
  private queue: TraceEventPayload[] = [];

  constructor(sender: TraceBatchSender, maxBatchSize: number = 20) {
    this.sender = sender;
    this.maxBatchSize = Math.max(1, maxBatchSize);
  }

  emitTraceHop(input: TraceHopInput): boolean {
    const traceId = (input.traceId ?? "").trim();
    const sessionId = (input.sessionId ?? "").trim().toUpperCase();
    if (!traceId || !sessionId || !input.hop?.trim()) {
      return false;
    }

    const payload: TraceEventPayload = {
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

  async flushNow(): Promise<number> {
    if (this.queue.length === 0) return 0;

    const batch = this.queue.splice(0, this.maxBatchSize);
    try {
      await this.sender(batch);
      return batch.length;
    } catch {
      this.queue = [...batch, ...this.queue];
      return 0;
    }
  }

  queuedCount(): number {
    return this.queue.length;
  }
}
