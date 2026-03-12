export const TRACE_HOP_ORDER = [
  "mobile.prompt.created",
  "mobile.send.to_relay",
  "relay.recv.from_mobile",
  "relay.enqueue.to_pc",
  "ext.poll.recv",
  "ext.dispatch.to_codex",
  "codex.turn.started",
  "codex.first_chunk",
  "codex.turn.completed",
  "ext.send.to_relay",
  "relay.recv.from_pc",
  "relay.enqueue.to_mobile",
  "mobile.poll.recv",
  "mobile.ui.rendered",
] as const;

export type TraceHop = (typeof TRACE_HOP_ORDER)[number] | (string & {});
export type TraceStatus = "ok" | "error" | "timeout" | "fail";

export interface TraceEventLike {
  event_id: string;
  trace_id: string;
  session_id?: string;
  hop: TraceHop;
  status: TraceStatus;
  server_ts: number;
  source_ts?: number;
  meta?: Record<string, unknown>;
}

export interface TraceTimelineHop {
  hop: string;
  ts: number;
  deltaFromPrevMs: number;
  status: TraceStatus;
}

export interface TraceTimeline {
  traceId: string;
  sessionId: string | null;
  startedAt: number;
  endedAt: number;
  totalMs: number;
  hops: TraceTimelineHop[];
  missingHops: string[];
  slowestSegment: {
    from: string;
    to: string;
    ms: number;
  } | null;
  errors: Array<{ hop: string; status: TraceStatus }>;
}

export function buildTraceTimeline(events: TraceEventLike[]): TraceTimeline {
  const sorted = [...events].sort((a, b) => a.server_ts - b.server_ts);
  if (sorted.length === 0) {
    return {
      traceId: "",
      sessionId: null,
      startedAt: 0,
      endedAt: 0,
      totalMs: 0,
      hops: [],
      missingHops: [...TRACE_HOP_ORDER],
      slowestSegment: null,
      errors: [],
    };
  }

  const startedAt = sorted[0].server_ts;
  const endedAt = sorted[sorted.length - 1].server_ts;

  const hops: TraceTimelineHop[] = [];
  let slowestSegment: TraceTimeline["slowestSegment"] = null;

  for (let i = 0; i < sorted.length; i++) {
    const event = sorted[i];
    const prev = sorted[i - 1];
    const delta = prev ? Math.max(0, event.server_ts - prev.server_ts) : 0;

    hops.push({
      hop: event.hop,
      ts: event.server_ts,
      deltaFromPrevMs: delta,
      status: event.status,
    });

    if (prev) {
      if (!slowestSegment || delta > slowestSegment.ms) {
        slowestSegment = {
          from: prev.hop,
          to: event.hop,
          ms: delta,
        };
      }
    }
  }

  const seen = new Set(sorted.map((item) => item.hop));
  const missingHops = TRACE_HOP_ORDER.filter((hop) => !seen.has(hop));

  return {
    traceId: sorted[0].trace_id,
    sessionId: sorted.find((event) => !!event.session_id)?.session_id ?? null,
    startedAt,
    endedAt,
    totalMs: Math.max(0, endedAt - startedAt),
    hops,
    missingHops,
    slowestSegment,
    errors: hops
      .filter((hop) => hop.status !== "ok")
      .map((hop) => ({ hop: hop.hop, status: hop.status })),
  };
}
