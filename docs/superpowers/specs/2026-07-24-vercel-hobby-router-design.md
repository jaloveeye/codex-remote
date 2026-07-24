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

## Components

### Route table

A focused module owns the mapping between normalized API paths and imported
handlers. It exposes route resolution independently from Vercel request and
response objects so the mapping can be tested directly.

### Catch-all handler

A single Vercel handler reads the catch-all path, resolves the route, prepares
dynamic trace parameters when necessary, and delegates to the existing
handler. Unknown routes receive status `404`.

### Vercel configuration

`vercel.json` builds only the catch-all entry point. Rewrites preserve all
existing URLs while directing them to the single function.

## Error Handling

- Unknown API path: `404` JSON response
- Known handler errors: unchanged; handled by the delegated handler
- Unsupported method: unchanged; handled by the delegated handler
- Missing dynamic trace ID: route resolution fails and returns `404`

## Verification

1. Add route-resolution tests first and confirm they fail before implementation.
2. Run TypeScript type checking and all existing relay unit scripts.
3. Run a local Vercel build and confirm it produces no more than one function.
4. Deploy to production and attach `codex-relay.jaloveeye.com`.
5. Verify `/api/health`, then run the full relay API smoke test.

## Non-goals

- No mobile, web, CLI, or extension changes
- No changes to Cursor Remote or `relay.jaloveeye.com`
- No API schema changes
- No storage migration
