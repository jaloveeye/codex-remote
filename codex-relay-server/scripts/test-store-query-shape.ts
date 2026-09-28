import assert from "node:assert/strict";
import type { Session } from "../lib/types.ts";

let queryShapeModule: Record<string, unknown> = {};
try {
  queryShapeModule = await import("../lib/store-query-shape.ts");
} catch {
  // RED phase: focused query-shape helpers do not exist yet.
}

const reuseOrLoadSession = queryShapeModule.reuseOrLoadSession as
  | undefined
  | ((
      existing: Session | undefined,
      loader: () => Promise<Session | null>
    ) => Promise<Session | null>);
const reuseOrLoadMobileDeviceIds =
  queryShapeModule.reuseOrLoadMobileDeviceIds as
    | undefined
    | ((
        existing: readonly string[] | undefined,
        loader: () => Promise<readonly string[]>
      ) => Promise<readonly string[]>);

assert.equal(
  typeof reuseOrLoadSession,
  "function",
  "store must support reusing an already-loaded session"
);
assert.equal(
  typeof reuseOrLoadMobileDeviceIds,
  "function",
  "store must support reusing already-loaded mobile device IDs"
);

const session: Session = {
  sessionId: "ABC123",
  mobileDeviceIds: ["mobile-1"],
  createdAt: 1,
  expiresAt: 2,
};
let sessionLoads = 0;
const reusedSession = await reuseOrLoadSession!(session, async () => {
  sessionLoads += 1;
  return null;
});
assert.equal(reusedSession, session);
assert.equal(sessionLoads, 0);

let mobileLoads = 0;
const reusedEmptyMobileIds = await reuseOrLoadMobileDeviceIds!(
  [],
  async () => {
    mobileLoads += 1;
    return ["unexpected"];
  }
);
assert.deepEqual(reusedEmptyMobileIds, []);
assert.equal(mobileLoads, 0);

console.log("[OK] preloaded store context avoids duplicate reads");
