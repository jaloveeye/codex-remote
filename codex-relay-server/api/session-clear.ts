import type { VercelRequest, VercelResponse } from "@vercel/node";
import {
  createSession,
  deleteSession,
  getSession,
  joinSession,
  setSessionPinHash,
} from "../lib/store.js";
import type { ApiResponse } from "../lib/types.js";

interface SessionClearRequest {
  sessionId?: string;
  deviceId?: string;
  keepPc?: boolean;
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
    let body = req.body as SessionClearRequest | string | undefined;
    if (typeof body === "string") {
      body = JSON.parse(body) as SessionClearRequest;
    }

    const rawSessionId = body?.sessionId;
    const rawDeviceId = body?.deviceId;
    const keepPc = body?.keepPc !== false;

    const sessionId = rawSessionId?.trim().toUpperCase();
    const deviceId = rawDeviceId?.trim();

    if (!sessionId || !deviceId) {
      return res.status(400).json({
        success: false,
        error: "sessionId and deviceId are required",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    const existingSession = await getSession(sessionId);
    if (!existingSession) {
      return res.status(404).json({
        success: false,
        error: "Session not found",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    if (!existingSession.pcDeviceId || existingSession.pcDeviceId !== deviceId) {
      return res.status(403).json({
        success: false,
        error: "Only the connected PC device can clear this session",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    const clearedMobileCount = existingSession.mobileDeviceIds?.length ?? 0;
    const hadPin = !!existingSession.pcPinHash;

    await deleteSession(sessionId);

    let recreated = false;
    if (keepPc) {
      await createSession(sessionId);
      await joinSession(sessionId, deviceId, "pc");
      if (existingSession.pcPinHash) {
        await setSessionPinHash(sessionId, existingSession.pcPinHash);
      }
      recreated = true;
    }

    return res.status(200).json({
      success: true,
      data: {
        sessionId,
        keepPc,
        recreated,
        cleared: {
          mobileDeviceCount: clearedMobileCount,
          hadPin,
        },
      },
      timestamp: Date.now(),
    } satisfies ApiResponse<{
      sessionId: string;
      keepPc: boolean;
      recreated: boolean;
      cleared: {
        mobileDeviceCount: number;
        hadPin: boolean;
      };
    }>);
  } catch (error) {
    const response: ApiResponse = {
      success: false,
      error: error instanceof Error ? error.message : "Internal server error",
      timestamp: Date.now(),
    };
    return res.status(500).json(response);
  }
}
