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

assert.equal(
  typeof pollMessagesWithClient,
  "function",
  "Supabase store must expose one-call pollMessagesWithClient"
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

console.log("[OK] Supabase poll uses one atomic RPC call");
