# Codex Remote Protocol

## English

This document defines the message flow between the mobile/web client, relay server, and VS Code extension.

## 1. Transport

- **Local mode**: WebSocket client ⇄ extension
- **Relay mode**: app ⇄ relay HTTP API ⇄ extension polling client

## 2. Base command shape

```json
{
  "type": "insert_text",
  "id": "msg_123",
  "text": "Explain this file",
  "prompt": true,
  "execute": true,
  "agentMode": "agent",
  "model": "gpt-5",
  "reasoningEffort": "medium"
}
```

## 3. Client → extension messages

### `insert_text`

Send text to one of these targets:

- editor insert (`prompt: false`, `terminal: false`)
- terminal input (`terminal: true`)
- Codex prompt (`prompt: true`)

Example:

```json
{
  "type": "insert_text",
  "id": "msg_123",
  "text": "Refactor this function",
  "prompt": true,
  "execute": true,
  "newSession": false,
  "agentMode": "agent",
  "model": "gpt-5",
  "reasoningEffort": "medium",
  "useIdeContext": false,
  "useFlatMode": false
}
```

Optional fields:

- `model`: runtime model id, or omit / use `auto`
- `reasoningEffort`: `none | minimal | low | medium | high | xhigh | auto`
- `useIdeContext`: request IDE context when supported
- `useFlatMode`: request flat mode when supported

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

### `get_runtime_capabilities`

Return live runtime capability information such as available models, supported reasoning efforts, and supported agent modes.

### `get_session_info`

Return the current Codex thread id for the client.

### `stop_prompt`

Cancel the active Codex turn if possible.

## 4. Extension → client messages

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

For `get_runtime_capabilities`, `data` contains a capability payload similar to:

```json
{
  "provider": "codex",
  "ready": true,
  "agentModes": ["auto", "agent", "ask", "plan", "debug"],
  "models": [
    {
      "model": "gpt-5",
      "displayName": "GPT-5",
      "defaultReasoningEffort": "medium",
      "supportedReasoningEfforts": ["low", "medium", "high"]
    }
  ],
  "defaults": {
    "model": "gpt-5",
    "reasoningEffort": "medium",
    "agentMode": "auto"
  }
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

## 5. Relay endpoints

- `POST /api/session`
- `POST /api/connect`
- `GET /api/poll`
- `POST /api/send`
- `GET /api/command-approvals`
- `POST /api/resolve-command-approval`
- `GET /api/command-events`
- `GET /api/health`

## 6. Approval policy

Relay policy currently evaluates risky `execute_command` messages.

- `allow`: dispatch immediately
- `approval_required`: hold until approved
- `deny`: reject and never dispatch

---

## 한국어

이 문서는 모바일/웹 클라이언트, 릴레이 서버, VS Code 확장 사이의 메시지 흐름을 정의합니다.

## 1. 전송 방식

- **로컬 모드**: WebSocket 클라이언트 ⇄ 확장
- **릴레이 모드**: 앱 ⇄ 릴레이 HTTP API ⇄ 확장 폴링 클라이언트

## 2. 기본 명령 형태

```json
{
  "type": "insert_text",
  "id": "msg_123",
  "text": "Explain this file",
  "prompt": true,
  "execute": true,
  "agentMode": "agent",
  "model": "gpt-5",
  "reasoningEffort": "medium"
}
```

## 3. 클라이언트 → 확장 메시지

### `insert_text`

텍스트를 아래 대상 중 하나로 보냅니다:

- 에디터 삽입 (`prompt: false`, `terminal: false`)
- 터미널 입력 (`terminal: true`)
- Codex 프롬프트 (`prompt: true`)

예시:

```json
{
  "type": "insert_text",
  "id": "msg_123",
  "text": "Refactor this function",
  "prompt": true,
  "execute": true,
  "newSession": false,
  "agentMode": "agent",
  "model": "gpt-5",
  "reasoningEffort": "medium",
  "useIdeContext": false,
  "useFlatMode": false
}
```

선택 필드:

- `model`: 런타임 model id, 또는 생략 / `auto`
- `reasoningEffort`: `none | minimal | low | medium | high | xhigh | auto`
- `useIdeContext`: 지원 시 IDE context 요청
- `useFlatMode`: 지원 시 flat mode 요청

### `execute_command`

id로 VS Code 명령을 실행합니다.

```json
{
  "type": "execute_command",
  "id": "msg_124",
  "command": "workbench.action.files.save",
  "args": []
}
```

### `get_chat_history`

현재 클라이언트 또는 세션의 최근 Codex 채팅 히스토리를 반환합니다.

### `get_runtime_capabilities`

사용 가능한 model, reasoning effort, agent mode 같은 실시간 런타임 capability 정보를 반환합니다.

### `get_session_info`

현재 클라이언트의 Codex thread id를 반환합니다.

### `stop_prompt`

가능하면 현재 활성 Codex turn을 취소합니다.

## 4. 확장 → 클라이언트 메시지

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

`get_runtime_capabilities`의 경우 `data`에는 아래와 비슷한 capability payload가 들어갑니다:

```json
{
  "provider": "codex",
  "ready": true,
  "agentModes": ["auto", "agent", "ask", "plan", "debug"],
  "models": [
    {
      "model": "gpt-5",
      "displayName": "GPT-5",
      "defaultReasoningEffort": "medium",
      "supportedReasoningEfforts": ["low", "medium", "high"]
    }
  ],
  "defaults": {
    "model": "gpt-5",
    "reasoningEffort": "medium",
    "agentMode": "auto"
  }
}
```

### `chat_response`

최종 Codex 응답입니다.

### `chat_response_chunk`

`codex app-server`에서 오는 스트리밍 응답 청크입니다.

### `chat_response_complete`

스트리밍 응답 종료를 표시합니다.

### `log`

구조화된 확장/런타임 로그 메시지입니다.

## 5. 릴레이 엔드포인트

- `POST /api/session`
- `POST /api/connect`
- `GET /api/poll`
- `POST /api/send`
- `GET /api/command-approvals`
- `POST /api/resolve-command-approval`
- `GET /api/command-events`
- `GET /api/health`

## 6. 승인 정책

현재 릴레이 정책은 위험한 `execute_command` 메시지를 평가합니다.

- `allow`: 즉시 전달
- `approval_required`: 승인될 때까지 보류
- `deny`: 거부하고 전달하지 않음
