# Codex Remote 📱

**Control Codex from your mobile device through a VS Code extension.**

Codex Remote now assumes a **dedicated relay deployment** for this project.
Do not point it at the legacy shared relay.

## Architecture

### Local mode

```text
Mobile App / Web
      ⇅ WebSocket (8766)
VS Code extension
      ⇅ JSON-RPC / stdio
codex app-server
```

### Relay mode

```text
Mobile App / Web ⇄ Dedicated Relay Server ⇄ VS Code extension ⇄ codex app-server
```

## Active components

```text
.
├── codex-extension/   # VS Code extension runtime (codex-only)
├── codex-relay-server/      # Codex Relay Server to deploy separately
├── mobile-app/        # Flutter client
├── PROTOCOL.md        # Client/extension message protocol
└── USER_MANUAL.md     # Setup and usage guide
```

## Prerequisites

- Node.js 20+ recommended
- `codex` CLI installed and authenticated
- Flutter SDK (only for mobile/web client development)
- A dedicated relay deployment URL such as `https://relay.example.com`

## Quick start

### 1. Verify Codex CLI

```bash
codex --version
codex auth login
codex app-server
```

### 2. Build the extension

```bash
cd codex-extension
npm install
npm run compile
```

Then set the relay URL in VS Code settings:

```json
{
  "codexRemote.relayServerUrl": "https://relay.example.com"
}
```

### 3. Run the mobile app

```bash
cd mobile-app
flutter pub get
flutter run --dart-define=RELAY_SERVER_URL=https://relay.example.com
```

### 4. Run or deploy the relay server

```bash
cd codex-relay-server
cp .env.example .env.local
npm install
npm run dev
```

For local development, use `http://localhost:3000` as the relay URL in both the extension and the mobile app.

## AI prompt starter (복붙용)

아래 부분을 긁어서 프롬프트에 입력하시오.

```text
You are my Codex Remote setup assistant.

Project goal:
- Control Codex from mobile/web through a VS Code extension and relay server.

Environment:
- Repo root: /Users/herace/Workspace/codex-remote
- Extension: ./codex-extension
- Relay server: ./codex-relay-server
- Flutter client: ./mobile-app
- Relay URL (example): https://relay.example.com

What I need from you:
1) Install/prepare
   - Verify Node.js, Codex CLI, Flutter SDK prerequisites.
   - Build VS Code extension (npm run compile in codex-extension).
   - If using VSIX, guide install command and reload window steps.
2) Configure
   - Set VS Code setting: codexRemote.relayServerUrl
   - Ensure mobile/web client uses the same RELAY_SERVER_URL.
3) Run
   - Start relay server (codex-relay-server).
   - Run Flutter web client (mobile-app).
   - Connect extension and mobile with same 6-char session ID (+ optional PIN).
4) Troubleshoot
   - Check Codex Remote output logs.
   - Verify session/PIN mismatch, relay URL mismatch, and stale sessions.
   - Explain each fix step-by-step with exact commands.

Use concise Korean instructions, but include exact shell commands and file paths.
```

## Relay separation rules

- Deploy the relay as a **separate Vercel project** for this repository
- Use **separate storage credentials** (Supabase or Upstash Redis)
- Point both clients at the **same relay base URL**
- Do not run tests against a legacy shared production relay by default

## Connection flow

### Local mode
1. Start the extension
2. Connect the app to `ws://<PC_IP>:8766`
3. Send `insert_text` / `execute_command` messages
4. Receive `chat_response`, `chat_response_chunk`, and `command_result`

### Relay mode
1. Deploy or start the relay server
2. Configure the extension with `codexRemote.relayServerUrl`
3. Launch the app with the same `RELAY_SERVER_URL`
4. Connect both sides with the same 6-character session ID
5. The relay forwards app commands to the extension and Codex responses back to the app

## Development checks

```bash
npx tsc --noEmit -p codex-extension/tsconfig.json
cd codex-relay-server && npm run type-check
```

## Notes

- `pc-server` and `codex-cli` are legacy artifacts and are not part of the supported architecture.
- The extension falls back to `RELAY_SERVER_URL` from the process environment when no VS Code setting is provided.

## Related docs

- [USER_MANUAL.md](./USER_MANUAL.md)
- [PROTOCOL.md](./PROTOCOL.md)
- [codex-extension/README.md](./codex-extension/README.md)
- [codex-relay-server/README.md](./codex-relay-server/README.md)
- [mobile-app/README.md](./mobile-app/README.md)
