import assert from "node:assert/strict";

let pollModule: Record<string, unknown> = {};
try {
  pollModule = await import("../lib/supabase-poll.ts");
} catch {
  // RED phase: the focused Supabase poll module does not exist yet.
}

const pollMessagesWithClient = (
  pollModule as {
    pollMessagesWithClient?: (
      client: {
        rpc: (
          name: string,
          args: Record<string, unknown>
        ) => Promise<{ data: unknown; error: null | { message: string } }>;
      },
      input: {
        sessionId: string;
        deviceType: "mobile" | "pc";
        deviceId?: string;
        limit: number;
      }
    ) => Promise<{
      sessionFound: boolean;
      messages: Array<Record<string, unknown>>;
    }>;
  }
).pollMessagesWithClient;
const createCompatiblePoller = (
  pollModule as {
    createCompatiblePoller?: (options: {
      pollRpc: (
        input: {
          sessionId: string;
          deviceType: "mobile" | "pc";
          deviceId?: string;
          limit: number;
        }
      ) => Promise<{
        sessionFound: boolean;
        messages: Array<Record<string, unknown>>;
      }>;
      pollLegacy: (
        input: {
          sessionId: string;
          deviceType: "mobile" | "pc";
          deviceId?: string;
          limit: number;
        }
      ) => Promise<{
        sessionFound: boolean;
        messages: Array<Record<string, unknown>>;
      }>;
      now?: () => number;
      unavailableTtlMs?: number;
    }) => (
      input: {
        sessionId: string;
        deviceType: "mobile" | "pc";
        deviceId?: string;
        limit: number;
      }
    ) => Promise<{
      sessionFound: boolean;
      messages: Array<Record<string, unknown>>;
    }>;
  }
).createCompatiblePoller;

assert.equal(
  typeof pollMessagesWithClient,
  "function",
  "Supabase store must expose one-call pollMessagesWithClient"
);
assert.equal(
  typeof createCompatiblePoller,
  "function",
  "Supabase poll must expose an RPC compatibility wrapper"
);

const calls: Array<{ name: string; args: Record<string, unknown> }> = [];
const expectedMessage = {
  id: "message-1",
  type: "insert_text",
  from: "mobile",
  to: "pc",
  data: { text: "hello" },
  timestamp: 1,
};
const client = {
  async rpc(name: string, args: Record<string, unknown>) {
    calls.push({ name, args });
    return {
      data: {
        sessionFound: true,
        messages: [expectedMessage],
      },
      error: null,
    };
  },
};

const result = await pollMessagesWithClient!(client, {
  sessionId: "ABC123",
  deviceType: "pc",
  deviceId: "pc-1",
  limit: 10,
});

assert.deepEqual(result, {
  sessionFound: true,
  messages: [expectedMessage],
});
assert.deepEqual(calls, [
  {
    name: "relay_poll_messages",
    args: {
      p_session_id: "ABC123",
      p_device_type: "pc",
      p_device_id: "pc-1",
      p_limit: 10,
    },
  },
]);

let rpcCalls = 0;
let legacyCalls = 0;
let now = 1_000;
const compatiblePoll = createCompatiblePoller!({
  pollRpc: async () => {
    rpcCalls += 1;
    const error = new Error(
      "Could not find the function public.relay_poll_messages in the schema cache"
    ) as Error & { code?: string };
    error.code = "PGRST202";
    throw error;
  },
  pollLegacy: async () => {
    legacyCalls += 1;
    return { sessionFound: true, messages: [expectedMessage] };
  },
  now: () => now,
  unavailableTtlMs: 60_000,
});

const compatibilityInput = {
  sessionId: "ABC123",
  deviceType: "pc" as const,
  deviceId: "pc-1",
  limit: 10,
};
assert.deepEqual(await compatiblePoll(compatibilityInput), {
  sessionFound: true,
  messages: [expectedMessage],
});
assert.deepEqual(await compatiblePoll(compatibilityInput), {
  sessionFound: true,
  messages: [expectedMessage],
});
assert.equal(rpcCalls, 1, "missing RPC must be cached during the fallback TTL");
assert.equal(legacyCalls, 2);

now += 60_001;
await compatiblePoll(compatibilityInput);
assert.equal(rpcCalls, 2, "RPC must be retried after the fallback TTL");
assert.equal(legacyCalls, 3);

let unexpectedLegacyCalls = 0;
const strictPoll = createCompatiblePoller!({
  pollRpc: async () => {
    const error = new Error("database connection failed") as Error & {
      code?: string;
    };
    error.code = "08006";
    throw error;
  },
  pollLegacy: async () => {
    unexpectedLegacyCalls += 1;
    return { sessionFound: true, messages: [] };
  },
});
await assert.rejects(
  () => strictPoll(compatibilityInput),
  /database connection failed/
);
assert.equal(
  unexpectedLegacyCalls,
  0,
  "real database failures must not be hidden by the compatibility fallback"
);

console.log("[OK] Supabase poll uses one atomic RPC call with safe legacy fallback");
