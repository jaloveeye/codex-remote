import type { VercelRequest, VercelResponse } from "@vercel/node";
import { listTraceEventsByTraceId } from "../lib/store.js";
import type { ApiResponse, TraceTimeline } from "../lib/types.js";
import { buildTraceTimeline } from "../lib/trace-timeline.js";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.setHeader("Access-Control-Max-Age", "86400");

  if (req.method === "OPTIONS") {
    return res.writeHead(200).end();
  }

  if (req.method !== "GET") {
    const response: ApiResponse = {
      success: false,
      error: "Method not allowed",
      timestamp: Date.now(),
    };
    return res.status(405).json(response);
  }

  try {
    const { traceId: rawTraceId, limit } = req.query;
    if (!rawTraceId || typeof rawTraceId !== "string") {
      return res.status(400).json({
        success: false,
        error: "traceId is required",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    const traceId = rawTraceId.trim();
    const parsedLimit = typeof limit === "string" ? parseInt(limit, 10) : 500;
    const events = await listTraceEventsByTraceId(
      traceId,
      Number.isFinite(parsedLimit) ? parsedLimit : 500
    );

    if (events.length === 0) {
      return res.status(404).json({
        success: false,
        error: "Trace not found",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    const timeline = buildTraceTimeline(events);

    const response: ApiResponse<TraceTimeline> = {
      success: true,
      data: timeline,
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
