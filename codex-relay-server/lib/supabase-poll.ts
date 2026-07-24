import type {
  DeviceType,
  PollMessagesResult,
  RelayMessage,
} from "./types.js";

export interface SupabasePollClient {
  rpc(
    name: string,
    args: Record<string, unknown>
  ): Promise<{ data: unknown; error: null | { message: string } }>;
}

export interface SupabasePollInput {
  sessionId: string;
  deviceType: DeviceType;
  deviceId?: string;
  limit: number;
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
    throw new Error(`pollMessages: ${error.message}`);
  }

  const payload = normalizeRpcPayload(data);
  return {
    sessionFound: payload.sessionFound === true,
    messages: Array.isArray(payload.messages)
      ? (payload.messages as RelayMessage[])
      : [],
  };
}
