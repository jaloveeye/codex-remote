import assert from "node:assert/strict";
import {
  createRelayRouter,
  resolveRelayRoute,
  type RelayHandler,
} from "../lib/relay-router.ts";

const directRouteCases = [
  ["command-approvals", "command-approvals"],
  ["command-events", "command-events"],
  ["command-timeline-summary", "command-timeline-summary"],
  ["connect", "connect"],
  ["debug-sessions", "debug-sessions"],
  ["disconnect", "disconnect"],
  ["health", "health"],
  ["heartbeat", "heartbeat"],
  ["poll", "poll"],
  ["resolve-command-approval", "resolve-command-approval"],
  ["send", "send"],
  ["session-clear", "session-clear"],
  ["session", "session"],
  ["sessions-waiting-for-pc", "sessions-waiting-for-pc"],
  ["sessions-with-mobile", "sessions-with-mobile"],
  ["store", "store"],
  ["stream", "stream"],
  ["trace-event", "trace-event"],
  ["trace-events-batch", "trace-events-batch"],
  ["trace-recent", "trace-recent"],
  ["trace-summary", "trace-summary"],
  ["trace-timeline", "trace-timeline"],
  ["version", "version"],
] as const;

type HandlerKey = (typeof directRouteCases)[number][1];
type HandlerRegistry = Record<HandlerKey, RelayHandler>;

const aliasRouteCases = [
  ["trace-events/batch", "trace-events-batch", undefined],
  ["trace/recent", "trace-recent", undefined],
  ["trace/trc_timeline/timeline", "trace-timeline", "trc_timeline"],
  ["trace/trc_summary/summary", "trace-summary", "trc_summary"],
] as const;

const INTERNAL_PATH_QUERY_KEY = "__relay_internal_path";

function makeHandlerRegistry(
  overrides: Partial<HandlerRegistry> = {}
): HandlerRegistry {
  return Object.fromEntries(
    directRouteCases.map(([, handlerKey]) => [
      handlerKey,
      overrides[handlerKey] ?? (() => handlerKey),
    ])
  ) as HandlerRegistry;
}

type FakeRequest = {
  method?: string;
  body?: unknown;
  headers: Record<string, unknown>;
  query: Record<string, unknown>;
};

type FakeResponse = {
  statusCode: number;
  jsonBody?: unknown;
  writes: unknown[];
  endArguments: unknown[];
  status(code: number): FakeResponse;
  json(body: unknown): FakeResponse;
  write(chunk: unknown): boolean;
  end(chunk?: unknown): FakeResponse;
};

function makeResponse(): FakeResponse {
  return {
    statusCode: 200,
    writes: [],
    endArguments: [],
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.jsonBody = body;
      return this;
    },
    write(chunk) {
      this.writes.push(chunk);
      return true;
    },
    end(chunk) {
      this.endArguments.push(chunk);
      return this;
    },
  };
}

function asRouterRequest(request: FakeRequest): never {
  return request as never;
}

function asRouterResponse(response: FakeResponse): never {
  return response as never;
}

{
  const handlers = makeHandlerRegistry();

  for (const [path, handlerKey] of directRouteCases) {
    const match = resolveRelayRoute(path, handlers);
    assert.ok(match, `expected direct route ${path} to resolve`);
    assert.equal(match.handler, handlers[handlerKey], path);
    assert.equal(match.traceId, undefined, path);
  }

  for (const [path, handlerKey, traceId] of aliasRouteCases) {
    const match = resolveRelayRoute(path, handlers);
    assert.ok(match, `expected alias route ${path} to resolve`);
    assert.equal(match.handler, handlers[handlerKey], path);
    assert.equal(match.traceId, traceId, path);
  }

  assert.equal(resolveRelayRoute("not-a-relay-route", handlers), undefined);
  console.log("[OK] direct routes, aliases, and unknown route resolution");
}

{
  const body = { message: "preserve me" };
  const headers = { authorization: "Bearer test", "x-test": "identity" };
  const ordinaryQueryArray = ["first", "second"];
  const query = {
    sessionId: "ABC123",
    ordinary: ordinaryQueryArray,
    [INTERNAL_PATH_QUERY_KEY]: "send",
  };
  const request: FakeRequest = {
    method: "POST",
    body,
    headers,
    query,
  };
  const response = makeResponse();
  const delegatedResult = Symbol("delegated result");

  const handlers = makeHandlerRegistry({
    send: (delegatedRequest, delegatedResponse) => {
      assert.equal(delegatedRequest, request);
      assert.equal(delegatedResponse, response);
      assert.equal(delegatedRequest.method, "POST");
      assert.equal(delegatedRequest.body, body);
      assert.equal(delegatedRequest.headers, headers);
      assert.equal(delegatedRequest.query, query);
      assert.equal(delegatedRequest.query.ordinary, ordinaryQueryArray);
      assert.equal(
        Object.hasOwn(delegatedRequest.query, INTERNAL_PATH_QUERY_KEY),
        false
      );
      return delegatedResult;
    },
  });

  const result = await createRelayRouter(handlers)(
    asRouterRequest(request),
    asRouterResponse(response)
  );
  assert.equal(result, delegatedResult);
  console.log("[OK] request identity and ordinary request data preserved");
}

{
  let selectedHandler = "";
  const query = {
    keep: "ordinary",
    [INTERNAL_PATH_QUERY_KEY]: ["health", "send"],
  };
  const request: FakeRequest = {
    method: "POST",
    body: {},
    headers: {},
    query,
  };
  const response = makeResponse();
  const handlers = makeHandlerRegistry({
    health: () => {
      selectedHandler = "spoofed";
    },
    send: (delegatedRequest) => {
      selectedHandler = "rewrite";
      assert.equal(delegatedRequest.query.keep, "ordinary");
      assert.equal(
        Object.hasOwn(delegatedRequest.query, INTERNAL_PATH_QUERY_KEY),
        false
      );
    },
  });

  await createRelayRouter(handlers)(
    asRouterRequest(request),
    asRouterResponse(response)
  );
  assert.equal(selectedHandler, "rewrite");
  console.log("[OK] rewrite path wins over a spoofed internal path value");
}

for (const [path, handlerKey, urlTraceId] of [
  ["trace/url_timeline/timeline", "trace-timeline", "url_timeline"],
  ["trace/url_summary/summary", "trace-summary", "url_summary"],
] as const) {
  let delegated = false;
  const query = {
    traceId: "client_supplied",
    keep: "ordinary",
    [INTERNAL_PATH_QUERY_KEY]: path,
  };
  const request: FakeRequest = {
    method: "GET",
    headers: {},
    query,
  };
  const response = makeResponse();
  const handlers = makeHandlerRegistry({
    [handlerKey]: (delegatedRequest) => {
      delegated = true;
      assert.equal(delegatedRequest.query, query);
      assert.equal(delegatedRequest.query.traceId, urlTraceId);
      assert.equal(delegatedRequest.query.keep, "ordinary");
      assert.equal(
        Object.hasOwn(delegatedRequest.query, INTERNAL_PATH_QUERY_KEY),
        false
      );
    },
  });

  await createRelayRouter(handlers)(
    asRouterRequest(request),
    asRouterResponse(response)
  );
  assert.equal(delegated, true, `${handlerKey} was not delegated`);
}
console.log("[OK] dynamic trace aliases override client trace IDs");

{
  const request: FakeRequest = {
    method: "GET",
    headers: {},
    query: {
      [INTERNAL_PATH_QUERY_KEY]: "unknown",
    },
  };
  const response = makeResponse();

  const result = await createRelayRouter(makeHandlerRegistry())(
    asRouterRequest(request),
    asRouterResponse(response)
  );

  assert.equal(result, response);
  assert.equal(response.statusCode, 404);
  assert.equal(
    typeof (response.jsonBody as { timestamp?: unknown }).timestamp,
    "number"
  );
  assert.deepEqual(
    {
      ...(response.jsonBody as Record<string, unknown>),
      timestamp: "<timestamp>",
    },
    {
      success: false,
      error: "API route not found",
      timestamp: "<timestamp>",
    }
  );
  console.log("[OK] unknown route returns the JSON 404 sentinel");
}

{
  const request: FakeRequest = {
    method: "GET",
    headers: {},
    query: {
      [INTERNAL_PATH_QUERY_KEY]: "stream",
    },
  };
  const response = makeResponse();
  let delegatedResponse: unknown;
  const handlers = makeHandlerRegistry({
    stream: (_delegatedRequest, receivedResponse) => {
      delegatedResponse = receivedResponse;
      assert.equal(receivedResponse.write("chunk"), true);
      return receivedResponse.end("complete");
    },
  });

  const result = await createRelayRouter(handlers)(
    asRouterRequest(request),
    asRouterResponse(response)
  );

  assert.equal(delegatedResponse, response);
  assert.equal(result, response);
  assert.deepEqual(response.writes, ["chunk"]);
  assert.deepEqual(response.endArguments, ["complete"]);
  console.log("[OK] response write and end calls pass through");
}
