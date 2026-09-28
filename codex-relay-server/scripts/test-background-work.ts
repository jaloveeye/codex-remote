import assert from "node:assert/strict";

let backgroundModule: Record<string, unknown> = {};
try {
  backgroundModule = await import("../lib/background-work.ts");
} catch {
  // RED phase: the background scheduler does not exist yet.
}

const scheduleBackground = backgroundModule.scheduleBackground as
  | undefined
  | ((
      task: () => Promise<void>,
      scheduler: (promise: Promise<unknown>) => void
    ) => void);

assert.equal(
  typeof scheduleBackground,
  "function",
  "relay must expose a background work scheduler"
);

let releaseTask: (() => void) | undefined;
let taskFinished = false;
let scheduledPromise: Promise<unknown> | undefined;
const deferred = new Promise<void>((resolve) => {
  releaseTask = resolve;
});

const result = scheduleBackground!(
  async () => {
    await deferred;
    taskFinished = true;
  },
  (promise) => {
    scheduledPromise = promise;
  }
);

assert.equal(result, undefined);
assert.equal(taskFinished, false);
assert.ok(scheduledPromise, "scheduler must receive the background promise");

releaseTask!();
await scheduledPromise;
assert.equal(taskFinished, true);

console.log("[OK] trace work is scheduled without blocking the response path");
