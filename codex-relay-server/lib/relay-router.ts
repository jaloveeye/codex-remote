import type { VercelRequest, VercelResponse } from "@vercel/node";

export const INTERNAL_PATH_QUERY_KEY = "__relay_internal_path";

export const RELAY_HANDLER_KEYS = [
  "command-approvals",
  "command-events",
  "command-timeline-summary",
  "connect",
  "debug-sessions",
  "disconnect",
  "health",
  "heartbeat",
  "poll",
  "resolve-command-approval",
  "send",
  "session-clear",
  "session",
  "sessions-waiting-for-pc",
  "sessions-with-mobile",
  "store",
  "stream",
  "trace-event",
  "trace-events-batch",
  "trace-recent",
  "trace-summary",
  "trace-timeline",
  "version",
] as const;

export type RelayHandlerKey = (typeof RELAY_HANDLER_KEYS)[number];

export type RelayHandler = (
  req: VercelRequest,
  res: VercelResponse
) => unknown | Promise<unknown>;

export type RelayHandlerRegistry = Record<RelayHandlerKey, RelayHandler>;

export type RelayRouteMatch = {
  handler: RelayHandler;
  traceId?: string;
};

const directHandlerKeys = new Set<string>(RELAY_HANDLER_KEYS);

const aliasHandlerKeys: Readonly<Record<string, RelayHandlerKey>> = {
  "trace-events/batch": "trace-events-batch",
  "trace/recent": "trace-recent",
};

function normalizePath(path: string): string {
  return path.replace(/^\/+|\/+$/g, "");
}

function decodePathSegment(segment: string): string | undefined {
  try {
    return decodeURIComponent(segment);
  } catch {
    return undefined;
  }
}

export function resolveRelayRoute(
  rawPath: string,
  handlers: RelayHandlerRegistry
): RelayRouteMatch | undefined {
  const path = normalizePath(rawPath);

  if (directHandlerKeys.has(path)) {
    const handlerKey = path as RelayHandlerKey;
    return { handler: handlers[handlerKey] };
  }

  const aliasHandlerKey = aliasHandlerKeys[path];
  if (aliasHandlerKey) {
    return { handler: handlers[aliasHandlerKey] };
  }

  const dynamicTraceMatch = /^trace\/([^/]+)\/(timeline|summary)$/.exec(path);
  if (!dynamicTraceMatch) {
    return undefined;
  }

  const traceId = decodePathSegment(dynamicTraceMatch[1]);
  if (!traceId) {
    return undefined;
  }

  const handlerKey: RelayHandlerKey =
    dynamicTraceMatch[2] === "timeline" ? "trace-timeline" : "trace-summary";
  return {
    handler: handlers[handlerKey],
    traceId,
  };
}

function takeTrustedPath(req: VercelRequest): string | undefined {
  const rawPath = req.query[INTERNAL_PATH_QUERY_KEY];
  delete req.query[INTERNAL_PATH_QUERY_KEY];

  const trustedPath = Array.isArray(rawPath) ? rawPath.at(-1) : rawPath;
  return typeof trustedPath === "string" ? trustedPath : undefined;
}

export function createRelayRouter(handlers: RelayHandlerRegistry): RelayHandler {
  return async (req, res) => {
    const trustedPath = takeTrustedPath(req);
    const match = trustedPath
      ? resolveRelayRoute(trustedPath, handlers)
      : undefined;

    if (!match) {
      return res.status(404).json({
        success: false,
        error: "API route not found",
        timestamp: Date.now(),
      });
    }

    if (match.traceId) {
      req.query.traceId = match.traceId;
    }

    return match.handler(req, res);
  };
}
