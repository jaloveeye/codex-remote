import type { VercelRequest, VercelResponse } from "@vercel/node";
import { getSession, listRecentTraceIdsBySession } from "../lib/store.js";
import type { ApiResponse } from "../lib/types.js";

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
    const { sessionId: rawSessionId, limit } = req.query;
    if (!rawSessionId || typeof rawSessionId !== "string") {
      return res.status(400).json({
        success: false,
        error: "sessionId is required",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    const sessionId = rawSessionId.trim().toUpperCase();
    const session = await getSession(sessionId);
    if (!session) {
      return res.status(404).json({
        success: false,
        error: "Session not found",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    const parsedLimit = typeof limit === "string" ? parseInt(limit, 10) : 20;
    const traceIds = await listRecentTraceIdsBySession(
      sessionId,
      Number.isFinite(parsedLimit) ? parsedLimit : 20
    );

    return res.status(200).json({
      success: true,
      data: {
        sessionId,
        traceIds,
        count: traceIds.length,
      },
      timestamp: Date.now(),
    } satisfies ApiResponse<{ sessionId: string; traceIds: string[]; count: number }>);
  } catch (error) {
    const response: ApiResponse = {
      success: false,
      error: error instanceof Error ? error.message : "Internal server error",
      timestamp: Date.now(),
    };
    return res.status(500).json(response);
  }
}
