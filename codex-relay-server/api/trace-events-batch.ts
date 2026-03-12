import type { VercelRequest, VercelResponse } from "@vercel/node";
import { appendTraceEvents } from "../lib/store.js";
import type { ApiResponse, TraceEvent, TraceStatus } from "../lib/types.js";

function normalizeStatus(value: unknown): TraceStatus {
  const normalized = String(value ?? "ok").trim().toLowerCase();
  if (normalized === "error") return "error";
  if (normalized === "timeout") return "timeout";
  if (normalized === "fail") return "fail";
  return "ok";
}

function normalizeTraceEvent(input: Record<string, unknown>): TraceEvent | null {
  const traceId = String(input.traceId ?? input.trace_id ?? "").trim();
  const sessionId = String(input.sessionId ?? input.session_id ?? "").trim().toUpperCase();
  const hop = String(input.hop ?? "").trim();
  if (!traceId || !sessionId || !hop) return null;

  const now = Date.now();
  const eventId =
    String(input.eventId ?? input.event_id ?? "").trim() ||
    `tev_${now}_${Math.random().toString(36).slice(2, 8)}`;

  const serverTsRaw = input.serverTs ?? input.server_ts;
  const sourceTsRaw = input.sourceTs ?? input.source_ts;
  const serverTs =
    typeof serverTsRaw === "number" && Number.isFinite(serverTsRaw)
      ? serverTsRaw
      : now;
  const sourceTs =
    typeof sourceTsRaw === "number" && Number.isFinite(sourceTsRaw)
      ? sourceTsRaw
      : undefined;

  return {
    event_id: eventId,
    trace_id: traceId,
    session_id: sessionId,
    hop,
    status: normalizeStatus(input.status),
    server_ts: serverTs,
    source_ts: sourceTs,
    command_id:
      typeof (input.commandId ?? input.command_id) === "string"
        ? String(input.commandId ?? input.command_id)
        : null,
    relay_message_id:
      typeof (input.relayMessageId ?? input.relay_message_id) === "string"
        ? String(input.relayMessageId ?? input.relay_message_id)
        : null,
    client_id:
      typeof (input.clientId ?? input.client_id) === "string"
        ? String(input.clientId ?? input.client_id)
        : null,
    sender_device_id:
      typeof (input.senderDeviceId ?? input.sender_device_id) === "string"
        ? String(input.senderDeviceId ?? input.sender_device_id)
        : null,
    target_device_id:
      typeof (input.targetDeviceId ?? input.target_device_id) === "string"
        ? String(input.targetDeviceId ?? input.target_device_id)
        : null,
    meta:
      input.meta && typeof input.meta === "object" && !Array.isArray(input.meta)
        ? (input.meta as Record<string, unknown>)
        : {},
  };
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.setHeader("Access-Control-Max-Age", "86400");

  if (req.method === "OPTIONS") {
    return res.writeHead(200).end();
  }

  if (req.method !== "POST") {
    const response: ApiResponse = {
      success: false,
      error: "Method not allowed",
      timestamp: Date.now(),
    };
    return res.status(405).json(response);
  }

  try {
    let body = req.body as unknown;
    if (typeof body === "string") {
      body = JSON.parse(body) as unknown;
    }

    const payload =
      Array.isArray(body)
        ? body
        : body && typeof body === "object" && Array.isArray((body as { events?: unknown[] }).events)
        ? (body as { events: unknown[] }).events
        : null;

    if (!payload) {
      return res.status(400).json({
        success: false,
        error: "events array is required",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    const normalized = payload
      .filter((item): item is Record<string, unknown> =>
        !!item && typeof item === "object" && !Array.isArray(item)
      )
      .map((item) => normalizeTraceEvent(item))
      .filter((item): item is TraceEvent => !!item);

    if (normalized.length === 0) {
      return res.status(400).json({
        success: false,
        error: "No valid trace events",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    await appendTraceEvents(normalized);

    const response: ApiResponse<{ count: number; traceIds: string[] }> = {
      success: true,
      data: {
        count: normalized.length,
        traceIds: [...new Set(normalized.map((item) => item.trace_id))],
      },
      timestamp: Date.now(),
    };
    return res.status(200).json(response);
  } catch (error) {
    const response: ApiResponse = {
      success: false,
      error: error instanceof Error ? error.message : "Internal server error",
      timestamp: Date.now(),
    };
    return res.status(500).json(response);
  }
}
