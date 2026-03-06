# Codex Remote User Manual

## 1. Overview

Codex Remote lets you control `codex app-server` from a mobile device through a VS Code extension.

Supported modes:

- **Local mode**: direct WebSocket connection to the extension
- **Relay mode**: remote connection through a dedicated relay server for this project

## 2. Requirements

- VS Code
- Node.js 20+ recommended
- Codex CLI installed and authenticated
- Flutter SDK only if you build the mobile app yourself
- A relay URL you control, for example `https://relay.example.com`

Verify Codex CLI:

```bash
codex --version
codex auth login
codex app-server
```

## 3. Install the extension

```bash
cd codex-extension
npm install
npm run compile
```

Load the extension in VS Code and set the relay URL in settings:

```json
{
  "codexRemote.relayServerUrl": "https://relay.example.com"
}
```

Expected signals:

- Output channel: **Codex Remote**
- Status bar item: **Codex Remote**

## 4. Local mode

1. Start the extension
2. Find the PC IP address on the same network
3. In the app, connect to `ws://<PC_IP>:8766`
4. Send a prompt from the app
5. Watch streamed Codex responses arrive in the app

## 5. Relay mode

1. Deploy or start the relay server
2. Confirm the extension is using `codexRemote.relayServerUrl`
3. Run the app with the same relay URL:

```bash
cd mobile-app
flutter pub get
flutter run --dart-define=RELAY_SERVER_URL=https://relay.example.com
```

4. In the extension, click the status bar item and enter a 6-character session ID
5. Optionally set a 4–6 digit PIN
6. In the app, connect with the same session ID (and PIN if required)
7. The extension joins the relay session and starts forwarding Codex responses

## 6. Relay deployment

```bash
cd codex-relay-server
cp .env.example .env.local
npm install
npm run dev
```

Use one backend:

- **Supabase**: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- **Upstash Redis**: `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`

For production, deploy the relay as a separate Vercel project with its own storage.

## 7. Mobile app

```bash
cd mobile-app
flutter pub get
flutter run --dart-define=RELAY_SERVER_URL=https://relay.example.com
```

For local relay testing, replace the value with `http://localhost:3000`.

## 8. Common operations

### Save current file remotely
Send `execute_command` with:

```json
{
  "type": "execute_command",
  "command": "workbench.action.files.save"
}
```

### Ask Codex to work on code
Send `insert_text` with:

```json
{
  "type": "insert_text",
  "text": "Review the active file and suggest improvements",
  "prompt": true,
  "execute": true,
  "agentMode": "agent"
}
```

### Stop current turn
Send:

```json
{ "type": "stop_prompt" }
```

## 9. Troubleshooting

### Extension does not respond
- Make sure VS Code is open
- Check the **Codex Remote** output channel
- Verify `codex app-server` can start locally

### Relay connection fails
- Confirm both app and extension use the same relay URL and session ID
- Check `GET /api/health`
- Check the relay output/logs for storage configuration issues
- If you changed `codexRemote.relayServerUrl`, reload the VS Code window

### App connects but no response arrives
- Confirm the extension joined the relay session
- Confirm the request was sent with `prompt: true`
- Check whether relay policy held the request for approval

## 10. Supported architecture

```text
App ⇄ VS Code extension ⇄ codex app-server
App ⇄ Dedicated Relay Server ⇄ VS Code extension ⇄ codex app-server
```

Legacy `pc-server` and `codex-cli` directories are not part of the supported path.
