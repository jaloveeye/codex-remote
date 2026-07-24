import assert from "node:assert/strict";

let policy = {};
try {
  policy = await import("../out/runtime_capability_policy.js");
} catch {
  // RED phase: runtime capability policy has not been compiled yet.
}

assert.equal(
  typeof policy.AsyncSingleFlightCache,
  "function",
  "Extension must expose a capability single-flight cache"
);
assert.equal(
  typeof policy.resolveRequestedModel,
  "function",
  "Extension must expose dynamic model resolution"
);

let now = 1000;
let loads = 0;
let releaseLoad;
const cache = new policy.AsyncSingleFlightCache(100, () => now);
const loader = async () => {
  loads += 1;
  await new Promise((resolve) => {
    releaseLoad = resolve;
  });
  return { ready: true, value: loads };
};

const first = cache.get(loader, (value) => value.ready);
const second = cache.get(loader, (value) => value.ready);
assert.equal(loads, 1);
assert.equal(first, second);
releaseLoad();
assert.deepEqual(await first, { ready: true, value: 1 });
assert.deepEqual(await cache.get(loader, (value) => value.ready), {
  ready: true,
  value: 1,
});
assert.equal(loads, 1);

now += 101;
const expired = cache.get(async () => {
  loads += 1;
  return { ready: true, value: loads };
});
assert.deepEqual(await expired, { ready: true, value: 2 });

const catalog = {
  ready: true,
  models: [
    { model: "gpt-current", isDefault: true },
    { model: "gpt-other", isDefault: false },
  ],
  defaultModel: "gpt-current",
};

assert.deepEqual(policy.resolveRequestedModel("gpt-other", catalog), {
  requestedModel: "gpt-other",
  selectedModel: "gpt-other",
  effectiveModel: "gpt-other",
  fallbackReason: null,
});
assert.deepEqual(policy.resolveRequestedModel("gpt-stale", catalog), {
  requestedModel: "gpt-stale",
  selectedModel: undefined,
  effectiveModel: "gpt-current",
  fallbackReason: "unsupported_model",
});
assert.deepEqual(policy.resolveRequestedModel("auto", catalog), {
  requestedModel: "auto",
  selectedModel: undefined,
  effectiveModel: "gpt-current",
  fallbackReason: "auto_requested",
});
assert.deepEqual(
  policy.resolveRequestedModel("gpt-other", {
    ready: false,
    models: [],
    defaultModel: "auto",
  }),
  {
    requestedModel: "gpt-other",
    selectedModel: undefined,
    effectiveModel: "auto",
    fallbackReason: "catalog_unavailable",
  }
);

console.log("[OK] capability requests coalesce and model fallback is dynamic");
