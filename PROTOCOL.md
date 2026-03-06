# Codex Remote Protocol

This document defines the message flow between the mobile/web client, relay server, and VS Code extension.

## Transport

- **Local mode**: WebSocket client ⇄ extension
- **Relay mode**: App ⇄ relay HTTP API ⇄ extension polling client

## Base command shape

```json
{
  "type": "insert_text",
  "id": "msg_123",
  "text": "Explain this file",
  "prompt": true,
  "execute": true,
  "agentMode": "agent"
}
```

## Client → extension messages

### `insert_text`
Send text to one of three targets:

- editor insert (`prompt: false`, `terminal: false`)
- terminal input (`terminal: true`)
- codex prompt (`prompt: true`)

Fields:

```json
{
  "type": "insert_text",
  "id": "msg_123",
  "text": "Refactor this function",
  "prompt": true,
  "execute": true,
  "newSession": false,
  "agentMode": "agent"
}
```

### `execute_command`
Execute a VS Code command by id.

```json
{
  "type": "execute_command",
  "id": "msg_124",
  "command": "workbench.action.files.save",
  "args": []
}
```

### `get_chat_history`
Return recent Codex chat history for the current client or session.

### `get_session_info`
Return the current Codex thread id for the client.

### `stop_prompt`
Cancel the active Codex turn if possible.

## Extension → client messages

### `connected`
```json
{ "type": "connected", "message": "Connected to Codex Remote" }
```

### `command_result`
```json
{
  "id": "msg_124",
  "type": "command_result",
  "success": true,
  "command_type": "execute_command"
}
```

### `chat_response`
Final Codex response.

### `chat_response_chunk`
Streaming response chunk from `codex app-server`.

### `chat_response_complete`
Marks the end of the streaming response.

### `log`
Structured extension/runtime log message.

## Relay endpoints

- `POST /api/session`
- `POST /api/connect`
- `GET /api/poll`
- `POST /api/send`
- `GET /api/command-approvals`
- `POST /api/resolve-command-approval`
- `GET /api/command-events`
- `GET /api/health`

## Approval policy

Relay policy currently evaluates risky `execute_command` messages.

- `allow`: command is dispatched immediately
- `approval_required`: command is held until approved
- `deny`: command is rejected and never dispatched
