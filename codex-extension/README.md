# Codex Remote Extension

VS Code extension that launches `codex app-server`, exposes a local WebSocket endpoint, and optionally connects to a dedicated relay server.

## What it does

- Starts a WebSocket server on port `8766`
- Sends prompts to `codex app-server`
- Streams Codex responses back to connected clients
- Connects to relay sessions by session ID
- Supports approval-aware relay command dispatch

## Prerequisites

```bash
codex --version
codex auth login
codex app-server
```

## Build

```bash
npm install
npm run compile
```

## Relay configuration

Preferred: set the relay URL in VS Code settings.

```json
{
  "codexRemote.relayServerUrl": "https://relay.example.com"
}
```

Fallback for development: launch VS Code with `RELAY_SERVER_URL` in the process environment.

If you change the setting while the extension is running, reload the VS Code window before reconnecting.

## Runtime flow

```text
Client ⇄ WebSocket ⇄ Extension ⇄ codex app-server
Client ⇄ Relay ⇄ Extension ⇄ codex app-server
```

## Commands

- `Codex Remote: 연결 정보 보기`
- `Codex Remote: 릴레이 연결 (상태줄 클릭 시)`
- `Codex Remote: 릴레이 서버 상태 확인`
- `Codex Remote: 세션 ID로 릴레이 연결`
- `Codex Remote: 릴레이 세션 ID 설정 (다음 시작 시 사용)`

## Notes

- The active runtime path is codex-only.
- Legacy CLI and hook-based paths are retained only as compatibility placeholders and are not used by the extension.
