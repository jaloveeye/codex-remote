import type { VercelRequest, VercelResponse } from "@vercel/node";
import { getSession, leaveSession } from "../lib/store.js";
import { ApiResponse, DeviceType, Session } from "../lib/types.js";

type PublicSession = Omit<Session, "pcPinHash">;

function toPublicSession(session: Session): PublicSession {
  const { pcPinHash: _pcPinHash, ...safe } = session;
  return safe;
}

interface DisconnectRequest {
  sessionId?: string;
  deviceId?: string;
  deviceType?: DeviceType;
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
    let body = req.body as DisconnectRequest | string | undefined;
    if (typeof body === "string") {
      body = JSON.parse(body) as DisconnectRequest;
    }

    const rawSessionId = body?.sessionId;
    const rawDeviceId = body?.deviceId;
    const rawDeviceType = body?.deviceType;

    const sessionId = rawSessionId?.trim().toUpperCase();
    const deviceId = rawDeviceId?.trim();
    const deviceType = rawDeviceType?.trim() as DeviceType | undefined;

    if (!sessionId || !deviceId || !deviceType) {
      return res.status(400).json({
        success: false,
        error: "sessionId, deviceId, deviceType are required",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    if (deviceType !== "mobile" && deviceType !== "pc") {
      return res.status(400).json({
        success: false,
        error: 'deviceType must be "mobile" or "pc"',
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    const existing = await getSession(sessionId);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: "Session not found",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    if (deviceType === "pc") {
      if (existing.pcDeviceId && existing.pcDeviceId !== deviceId) {
        return res.status(403).json({
          success: false,
          error: "Only the connected PC device can disconnect this session",
          timestamp: Date.now(),
        } satisfies ApiResponse);
      }
    } else {
      const mobileIds = existing.mobileDeviceIds ?? [];
      if (!mobileIds.includes(deviceId)) {
        return res.status(403).json({
          success: false,
          error: "Only connected mobile device can disconnect this session",
          timestamp: Date.now(),
        } satisfies ApiResponse);
      }
    }

    const updated = await leaveSession(sessionId, deviceId, deviceType);
    if (!updated) {
      return res.status(404).json({
        success: false,
        error: "Session not found",
        timestamp: Date.now(),
      } satisfies ApiResponse);
    }

    return res.status(200).json({
      success: true,
      data: {
        session: toPublicSession(updated),
      },
      timestamp: Date.now(),
    } satisfies ApiResponse<{ session: PublicSession }>);
  } catch (error) {
    const response: ApiResponse = {
      success: false,
      error: error instanceof Error ? error.message : "Internal server error",
      timestamp: Date.now(),
    };
    return res.status(500).json(response);
  }
}
