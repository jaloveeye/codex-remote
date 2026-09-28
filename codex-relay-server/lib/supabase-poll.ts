import type {
  DeviceType,
  PollMessagesResult,
  RelayMessage,
} from "./types.js";

export interface SupabasePollClient {
  rpc(
    name: string,
    args: Record<string, unknown>
  ): Promise<{
    data: unknown;
    error: null | { message: string; code?: string };
  }>;
}

export interface SupabasePollInput {
  sessionId: string;
  deviceType: DeviceType;
  deviceId?: string;
  limit: number;
}

interface PollError extends Error {
  code?: string;
}

export interface CompatiblePollerOptions {
  pollRpc: (input: SupabasePollInput) => Promise<PollMessagesResult>;
  pollLegacy: (input: SupabasePollInput) => Promise<PollMessagesResult>;
  now?: () => number;
  unavailableTtlMs?: number;
  onRpcUnavailable?: (error: unknown) => void;
}

function normalizeRpcPayload(data: unknown): Record<string, unknown> {
  if (Array.isArray(data)) {
    const first = data[0];
    return first && typeof first === "object"
      ? (first as Record<string, unknown>)
      : {};
  }
  return data && typeof data === "object"
    ? (data as Record<string, unknown>)
    : {};
}

export async function pollMessagesWithClient(
  client: SupabasePollClient,
  input: SupabasePollInput
): Promise<PollMessagesResult> {
  const { data, error } = await client.rpc("relay_poll_messages", {
    p_session_id: input.sessionId,
    p_device_type: input.deviceType,
    p_device_id: input.deviceId ?? null,
    p_limit: input.limit,
  });
  if (error) {
    const rpcError = new Error(`pollMessages: ${error.message}`) as PollError;
    rpcError.code = error.code;
    throw rpcError;
  }

  const payload = normalizeRpcPayload(data);
  return {
    sessionFound: payload.sessionFound === true,
    messages: Array.isArray(payload.messages)
      ? (payload.messages as RelayMessage[])
      : [],
  };
}

function isPollRpcUnavailable(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const code =
    "code" in error && typeof error.code === "string" ? error.code : "";
  const message = error.message.toLowerCase();
  const namesPollRpc = message.includes("relay_poll_messages");
  return (
    namesPollRpc &&
    (code === "PGRST202" ||
      code === "42883" ||
      message.includes("could not find the function") ||
      message.includes("does not exist"))
  );
}

export function createCompatiblePoller(
  options: CompatiblePollerOptions
): (input: SupabasePollInput) => Promise<PollMessagesResult> {
  const now = options.now ?? Date.now;
  const unavailableTtlMs = options.unavailableTtlMs ?? 60_000;
  let rpcUnavailableUntil = 0;

  return async (input: SupabasePollInput): Promise<PollMessagesResult> => {
    if (now() < rpcUnavailableUntil) {
      return options.pollLegacy(input);
    }

    try {
      return await options.pollRpc(input);
    } catch (error) {
      if (!isPollRpcUnavailable(error)) throw error;
      rpcUnavailableUntil = now() + unavailableTtlMs;
      options.onRpcUnavailable?.(error);
      return options.pollLegacy(input);
    }
  };
}
