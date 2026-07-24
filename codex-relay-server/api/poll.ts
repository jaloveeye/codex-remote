import type { VercelRequest, VercelResponse } from "@vercel/node";
import {
  getDeviceSession,
  pollMessages,
} from "../lib/store.js";
import { ApiResponse, RelayMessage, DeviceType } from "../lib/types.js";
import {
  appendTraceHopsBestEffort,
  resolveTraceIdentity,
} from "../lib/trace-ingest.js";
import { scheduleBackground } from "../lib/background-work.js";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS 헤더 설정
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization, X-Device-Id, X-Device-Type"
  );
  res.setHeader("Access-Control-Max-Age", "86400"); // 24시간

  // CORS preflight - OPTIONS 요청 처리
  if (req.method === "OPTIONS") {
    res.writeHead(200, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers":
        "Content-Type, Authorization, X-Device-Id, X-Device-Type",
      "Access-Control-Max-Age": "86400",
    });
    return res.end();
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
    const {
      sessionId: querySessionId,
      deviceId,
      deviceType,
      limit,
    } = req.query;

    // 입력 검증
    if (!deviceType || typeof deviceType !== "string") {
      const response: ApiResponse = {
        success: false,
        error: "deviceType is required",
        timestamp: Date.now(),
      };
      return res.status(400).json(response);
    }

    if (deviceType !== "mobile" && deviceType !== "pc") {
      const response: ApiResponse = {
        success: false,
        error: 'deviceType must be "mobile" or "pc"',
        timestamp: Date.now(),
      };
      return res.status(400).json(response);
    }

    // 세션 ID 결정 (connect와 동일하게 대문자 정규화 — PC/모바일 동일 키 매칭)
    let sessionId = querySessionId as string | undefined;
    if (sessionId && typeof sessionId === "string") {
      sessionId = sessionId.trim().toUpperCase();
    }
    if (!sessionId && deviceId && typeof deviceId === "string") {
      sessionId = (await getDeviceSession(deviceId)) || undefined;
    }

    if (!sessionId) {
      const response: ApiResponse = {
        success: false,
        error: "sessionId or deviceId is required",
        timestamp: Date.now(),
      };
      return res.status(400).json(response);
    }

    const maxLimit = Math.min(parseInt(limit as string) || 10, 50);
    const pollResult = await pollMessages(
      sessionId,
      deviceType as DeviceType,
      maxLimit,
      deviceId as string | undefined
    );
    if (!pollResult.sessionFound) {
      const response: ApiResponse = {
        success: false,
        error: "Session not found",
        timestamp: Date.now(),
      };
      return res.status(404).json(response);
    }

    const messages = pollResult.messages;

    if (messages.length > 0) {
      const hop = deviceType === "pc" ? "ext.poll.recv" : "mobile.poll.recv";
      // Trace persistence must never delay polling. A slow trace insert can
      // otherwise hold the user-facing poll open until Vercel times it out.
      scheduleBackground(() =>
        appendTraceHopsBestEffort(
          messages.map((message) => {
            const payload =
              message.data && typeof message.data === "object"
                ? (message.data as Record<string, unknown>)
                : null;
            const traceIdentity = resolveTraceIdentity(payload);
            return {
              sessionId,
              hop,
              traceId: traceIdentity.traceId,
              commandId: traceIdentity.commandId,
              relayMessageId: message.id,
              senderDeviceId:
                typeof message.senderDeviceId === "string"
                  ? message.senderDeviceId
                  : null,
              targetDeviceId:
                typeof message.targetDeviceId === "string"
                  ? message.targetDeviceId
                  : null,
              clientId:
                payload && typeof payload.clientId === "string"
                  ? payload.clientId
                  : null,
              meta: {
                polledByDeviceType: deviceType,
              },
            };
          })
        )
      );
    }

    const response: ApiResponse<{ messages: RelayMessage[]; count: number }> = {
      success: true,
      data: {
        messages,
        count: messages.length,
      },
      timestamp: Date.now(),
    };

    return res.status(200).json(response);
  } catch (error) {
    console.error("Poll API error:", error);
    const response: ApiResponse = {
      success: false,
      error: error instanceof Error ? error.message : "Internal server error",
      timestamp: Date.now(),
    };
    return res.status(500).json(response);
  }
}
