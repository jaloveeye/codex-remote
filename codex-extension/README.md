# Codex Remote Extension

## English

Codex Remote is a VS Code extension that connects remote clients to `codex app-server`.

### Features

- Starts a local WebSocket bridge on port `8766`
- Sends remote prompts to Codex inside VS Code
- Streams Codex responses back to the client
- Connects to relay sessions for remote access
- Supports approval-aware command dispatch in relay mode
- Exposes runtime capabilities so clients can load live model and reasoning options

### Requirements

```bash
codex --version
codex auth login
```

- VS Code `1.74+`
- Codex CLI installed locally
- A relay server URL if you plan to use relay mode

### Install

1. Open the VS Code Extensions view
2. Search for **Codex Remote**
3. Install the extension published by **jaloveeye**
4. Reload the window if needed

You can also install a local VSIX for unpublished builds.

### Configure relay mode

Set your relay URL in VS Code settings:

```json
{
  "codexRemote.relayServerUrl": "https://your-relay.example.com"
}
```

If you change this setting while the extension is running, reload the VS Code window before reconnecting.

### How to use

1. Click the Codex Remote status bar item
2. Create or connect to a relay session ID
3. Optionally set a PIN
4. Open the mobile or web client
5. Connect with the same session ID
6. Send prompts and receive streamed Codex responses

### Runtime capabilities

Connected clients can request runtime capabilities and render live options for:

- agent mode
- model selection
- reasoning effort
- optional IDE context / flat mode toggles when supported

### Commands

- `Codex Remote: 연결 정보 보기`
- `Codex Remote: 릴레이 연결 (상태줄 클릭 시)`
- `Codex Remote: 릴레이 서버 상태 확인`
- `Codex Remote: 릴레이 연결 끊기`
- `Codex Remote: 세션 ID로 릴레이 연결`
- `Codex Remote: 릴레이 세션 ID 설정 (다음 시작 시 사용)`

### Development

```bash
npm install
npm run compile
```

### Notes

- The supported runtime path is codex-only
- The relay server is not bundled with the extension
- Legacy CLI and hook-based paths remain only as compatibility placeholders

---

## 한국어

Codex Remote는 원격 클라이언트를 `codex app-server`에 연결하는 VS Code 확장입니다.

### 기능

- 포트 `8766`에서 로컬 WebSocket 브리지를 시작합니다
- 원격 프롬프트를 VS Code 내부의 Codex로 전달합니다
- Codex 응답을 클라이언트로 스트리밍합니다
- 원격 접속을 위해 릴레이 세션에 연결합니다
- 릴레이 모드에서 승인 기반 명령 전달을 지원합니다
- 클라이언트가 실시간 model / reasoning 옵션을 불러올 수 있도록 런타임 capabilities를 제공합니다

### 요구 사항

```bash
codex --version
codex auth login
```

- VS Code `1.74+`
- 로컬에 설치된 Codex CLI
- 릴레이 모드를 사용할 경우 릴레이 서버 URL

### 설치

1. VS Code 확장 탭을 엽니다
2. **Codex Remote**를 검색합니다
3. **jaloveeye**가 배포한 확장을 설치합니다
4. 필요하면 창을 다시 로드합니다

공개 전 빌드는 로컬 VSIX로도 설치할 수 있습니다.

### 릴레이 모드 설정

VS Code 설정에 릴레이 URL을 지정하세요:

```json
{
  "codexRemote.relayServerUrl": "https://your-relay.example.com"
}
```

확장이 실행 중일 때 이 값을 바꾸면 다시 연결하기 전에 VS Code 창을 다시 로드하세요.

### 사용 방법

1. Codex Remote 상태바 항목을 클릭합니다
2. 릴레이 세션 ID를 생성하거나 연결합니다
3. 필요하면 PIN을 설정합니다
4. 모바일 또는 웹 클라이언트를 엽니다
5. 같은 세션 ID로 연결합니다
6. 프롬프트를 보내고 스트리밍 Codex 응답을 받습니다

### 런타임 capabilities

연결된 클라이언트는 런타임 capabilities를 요청하여 아래 옵션을 실시간으로 표시할 수 있습니다:

- agent mode
- model 선택
- reasoning effort
- 지원 시 IDE context / flat mode 토글

### 명령

- `Codex Remote: 연결 정보 보기`
- `Codex Remote: 릴레이 연결 (상태줄 클릭 시)`
- `Codex Remote: 릴레이 서버 상태 확인`
- `Codex Remote: 릴레이 연결 끊기`
- `Codex Remote: 세션 ID로 릴레이 연결`
- `Codex Remote: 릴레이 세션 ID 설정 (다음 시작 시 사용)`

### 개발

```bash
npm install
npm run compile
```

### 참고

- 지원되는 런타임 경로는 codex 전용입니다
- 릴레이 서버는 확장에 포함되어 있지 않습니다
- 예전 CLI/hook 기반 경로는 호환성용 자리표시자만 남아 있습니다
