import { appendTraceEvents } from "./store.js";
import type { TraceEvent, TraceHop, TraceStatus } from "./types.js";

interface BuildTraceEventInput {
  sessionId: string;
  hop: TraceHop;
  status?: TraceStatus;
  traceId?: string | null;
  commandId?: string | null;
  relayMessageId?: string | null;
  senderDeviceId?: string | null;
  targetDeviceId?: string | null;
  clientId?: string | null;
  sourceTs?: number;
  meta?: Record<string, unknown>;
}

export function resolveTraceIdentity(payload: Record<string, unknown> | null): {
  traceId: string | null;
  commandId: string | null;
} {
  if (!payload) return { traceId: null, commandId: null };

  const rawTraceId =
    (typeof payload.traceId === "string" && payload.traceId.trim()) ||
    (typeof payload.trace_id === "string" && payload.trace_id.trim()) ||
    null;

  const rawCommandId =
    (typeof payload.commandId === "string" && payload.commandId.trim()) ||
    (typeof payload.command_id === "string" && payload.command_id.trim()) ||
    (typeof payload.id === "string" && payload.id.trim()) ||
    null;

  const traceId = rawTraceId ?? rawCommandId;
  return {
    traceId,
    commandId: rawCommandId,
  };
}

function buildTraceEvent(input: BuildTraceEventInput): TraceEvent | null {
  const traceId = input.traceId?.trim();
  if (!traceId) return null;

  return {
    event_id: `tev_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    trace_id: traceId,
    session_id: input.sessionId,
    hop: input.hop,
    status: input.status ?? "ok",
    server_ts: Date.now(),
    source_ts: input.sourceTs,
    command_id: input.commandId ?? null,
    relay_message_id: input.relayMessageId ?? null,
    client_id: input.clientId ?? null,
    sender_device_id: input.senderDeviceId ?? null,
    target_device_id: input.targetDeviceId ?? null,
    meta: input.meta ?? {},
  };
}

export async function appendTraceHopBestEffort(
  input: BuildTraceEventInput
): Promise<void> {
  try {
    const event = buildTraceEvent(input);
    if (!event) return;
    await appendTraceEvents([event]);
  } catch (error) {
    console.warn("[trace] appendTraceHopBestEffort failed:", error);
  }
}

export async function appendTraceHopsBestEffort(
  inputs: BuildTraceEventInput[]
): Promise<void> {
  try {
    const events = inputs
      .map((input) => buildTraceEvent(input))
      .filter((event): event is TraceEvent => !!event);
    if (events.length === 0) return;
    await appendTraceEvents(events);
  } catch (error) {
    console.warn("[trace] appendTraceHopsBestEffort failed:", error);
  }
}
