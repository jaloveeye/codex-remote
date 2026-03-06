# Codex Relay Server

Dedicated `codex-relay-server` deployment for Codex Remote.
Deploy this server separately from the legacy relay infrastructure.

## Responsibilities

- Create and manage 6-character sessions
- Join PC/mobile devices to a session
- Forward messages between app and extension
- Track heartbeat to release stale PC sessions
- Apply approval policy to risky `execute_command` requests
- Persist command events and approval history

## Separation checklist

- Create a **new Vercel project** for this repository
- Use **separate Supabase or Upstash Redis credentials**
- Configure both clients to use the same relay base URL
- Do not reuse a shared production relay by default

## Configure clients

### VS Code extension

Set the relay URL in VS Code settings:

```json
{
  "codexRemote.relayServerUrl": "https://relay.example.com"
}
```

### Mobile app

Pass the relay URL at build/run time:

```bash
flutter run --dart-define=RELAY_SERVER_URL=https://relay.example.com
flutter build web --dart-define=RELAY_SERVER_URL=https://relay.example.com
```

## Storage backends

- **Supabase** when `SUPABASE_URL` is present
- **Upstash Redis** otherwise

## Local development

```bash
cp .env.example .env.local
npm install
npm run dev
```

Local relay URL: `http://localhost:3000`

## Main API endpoints

- `GET /api/health`
- `GET /api/store`
- `POST /api/session`
- `POST /api/connect`
- `GET /api/poll`
- `POST /api/send`
- `GET /api/command-approvals`
- `POST /api/resolve-command-approval`
- `GET /api/command-events`

## Session model

- Session IDs are 6-character uppercase alphanumeric strings
- PC heartbeat timeout is 2 minutes
- Optional PIN can be attached by the extension
- Multiple mobile devices can join the same session

## Vercel link note

If `codex-relay-server/.vercel/project.json` still points to an older Vercel project, run `vercel link` before the first deploy for the new relay server.
