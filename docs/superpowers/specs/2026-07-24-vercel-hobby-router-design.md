# Vercel Hobby Single-Function Router Design

## Goal

Redeploy the Codex relay server on Vercel Hobby without changing the public
relay domain or any existing `/api/...` contract used by deployed clients.

## Context

The relay currently exposes 23 TypeScript files under `codex-relay-server/api`.
Vercel turns these files into separate Serverless Functions, while the Hobby
plan accepts at most 12 functions per deployment. The production deployment
therefore fails before it can replace the deleted relay project.

## Chosen Approach

Add one catch-all Vercel function that maps the incoming API path to the
existing handler modules. Update `vercel.json` so every supported public route
is rewritten to that catch-all function.

The existing handler files remain responsible for request validation, storage,
responses, streaming, and error handling. The router only normalizes the path,
selects a known handler, and returns JSON `404` for unknown paths.

## Public API Compatibility

The following contracts remain unchanged:

- Production origin: `https://codex-relay.jaloveeye.com`
- Existing routes such as `/api/session`, `/api/connect`, `/api/send`,
  `/api/poll`, and `/api/stream`
- Trace routes including `/api/trace/recent`,
  `/api/trace/:traceId/timeline`, and `/api/trace/:traceId/summary`
- HTTP methods, request bodies, query parameters, headers, and response shapes

Dynamic trace IDs continue to be copied into `req.query.traceId` before the
existing trace handler runs.

The compatibility route inventory is:

- `/api/command-approvals`
- `/api/command-events`
- `/api/command-timeline-summary`
- `/api/connect`
- `/api/debug-sessions`
- `/api/disconnect`
- `/api/health`
- `/api/heartbeat`
- `/api/poll`
- `/api/resolve-command-approval`
- `/api/send`
- `/api/session`
- `/api/session-clear`
- `/api/sessions-waiting-for-pc`
- `/api/sessions-with-mobile`
- `/api/store`
- `/api/stream`
- `/api/trace-event`
- `/api/trace-events-batch`
- `/api/trace-recent`
- `/api/trace-summary`
- `/api/trace-timeline`
- `/api/version`

The existing friendly aliases also remain compatible:

- `/api/trace-events/batch`
- `/api/trace/recent`
- `/api/trace/:traceId/timeline`
- `/api/trace/:traceId/summary`

Direct `.ts` URLs and direct dynamic calls to the three internal trace handler
names are not documented client contracts. The extension, mobile application,
tests, and documentation do not use them, so the router does not add new
compatibility guarantees for those implementation paths.

## Components

### Route table

A focused module owns the mapping between normalized API paths and imported
handlers. It exposes route resolution independently from Vercel request and
response objects so the mapping can be tested directly.

### Catch-all handler

A single Vercel handler reads the trusted catch-all parameter populated by the
rewrite, resolves the route, prepares dynamic trace parameters when necessary,
and delegates to the existing handler. It removes the synthetic wildcard
parameter before delegation while preserving the original method, body,
headers, and all other query parameters. A dynamic URL trace ID overrides any
client-supplied `traceId`. Client query parameters cannot select the handler.
Unknown routes receive status `404`.

The catch-all function configures `maxDuration` to at least 30 seconds so the
existing 25-second SSE loop can finish and emit its `reconnect` event on Hobby.

### Vercel configuration

`vercel.json` removes both broad build globs (`api/**/*.ts` and `lib/**/*.ts`)
and allowlists only the catch-all entry point. Rewrites preserve all existing
URLs while directing them to the single function. The delegated modules may
remain under `api` because the explicit build allowlist prevents Vercel from
turning them into independent functions.

## Error Handling

- Unknown API path: `404` JSON response
- Known handler errors: unchanged; handled by the delegated handler
- Unsupported method: unchanged; handled by the delegated handler
- Missing dynamic trace ID: route resolution fails and returns `404`

## Verification

1. Add route-resolution tests first and confirm they fail before implementation.
2. Add adapter-level tests for delegation and confirm they fail before
   implementation. Cover method/body/header/query preservation, wildcard
   removal, trace-ID injection, JSON `404`, and streaming `write`/`end`
   pass-through.
3. Run TypeScript type checking and all existing relay unit scripts.
4. Run a local Vercel build and assert that it produces exactly one `.func`
   output.
5. Deploy to production and attach `codex-relay.jaloveeye.com`.
6. Verify the complete route inventory, run the full relay API smoke test, and
   keep an SSE connection open long enough to observe the terminal `reconnect`
   event.

## Non-goals

- No mobile, web, CLI, or extension changes
- No changes to Cursor Remote or `relay.jaloveeye.com`
- No API schema changes
- No storage migration
