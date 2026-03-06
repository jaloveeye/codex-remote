# Codex Remote 📱

## English

Codex Remote lets you control `codex app-server` from a mobile or web client through a VS Code extension.

### What it includes

- **VS Code extension**: bridges VS Code and Codex
- **Mobile/Web client**: sends prompts and displays streamed responses
- **Dedicated relay server**: enables remote sessions outside the local network
- **Protocol and setup docs**: define how clients, relay, and extension communicate

### Installation

#### 1) VS Code Marketplace

1. Open the Extensions view in VS Code (`Ctrl/Cmd+Shift+X`)
2. Search for **Codex Remote**
3. Install the extension published by **jaloveeye**
4. Reload the window if VS Code asks you to do so

#### 2) VSIX

Use a packaged VSIX if you want to test a local build:

```bash
code --install-extension codex-remote-extension-<version>.vsix --force
```

#### 3) Build from source

```bash
cd codex-extension
npm install
npm run compile
```

### Prerequisites

```bash
codex --version
codex auth login
```

If you want remote relay mode, set this in VS Code settings:

```json
{
  "codexRemote.relayServerUrl": "https://your-relay.example.com"
}
```

### Quick start

1. Install the VS Code extension
2. Make sure Codex CLI is installed and authenticated locally
3. Click the Codex Remote status bar item in VS Code
4. Create or connect to a relay session ID (optional PIN)
5. Open the mobile or web client and connect with the same session ID
6. Send prompts and receive streamed Codex responses
7. When available, choose agent mode, model, and reasoning effort from the client UI

### Repository layout

- `codex-extension/` — VS Code extension
- `mobile-app/` — Flutter mobile/web client
- `codex-relay-server/` — relay server for remote sessions
- `PROTOCOL.md` — message contract reference

### Related documents

- [VS Code extension guide](./codex-extension/README.md)
- [Mobile app guide](./mobile-app/README.md)
- [Relay server guide](./codex-relay-server/README.md)
- [Protocol reference](./PROTOCOL.md)

---

## 한국어

Codex Remote는 VS Code 확장을 통해 모바일 또는 웹 클라이언트에서 `codex app-server`를 제어할 수 있게 해주는 프로젝트입니다.

### 구성 요소

- **VS Code 확장**: VS Code와 Codex를 연결합니다
- **모바일/웹 클라이언트**: 프롬프트를 보내고 스트리밍 응답을 표시합니다
- **전용 릴레이 서버**: 로컬 네트워크 밖에서도 원격 세션을 사용할 수 있게 합니다
- **프로토콜/설정 문서**: 클라이언트, 릴레이, 확장 간 통신 방식을 설명합니다

### 설치

#### 1) VS Code Marketplace

1. VS Code에서 확장 탭을 엽니다 (`Ctrl/Cmd+Shift+X`)
2. **Codex Remote**를 검색합니다
3. **jaloveeye**가 배포한 확장을 설치합니다
4. 필요하면 VS Code 창을 다시 로드합니다

#### 2) VSIX

로컬 빌드를 테스트하려면 패키징된 VSIX를 사용할 수 있습니다:

```bash
code --install-extension codex-remote-extension-<version>.vsix --force
```

#### 3) 소스에서 빌드

```bash
cd codex-extension
npm install
npm run compile
```

### 필수 준비

```bash
codex --version
codex auth login
```

원격 릴레이 모드를 사용하려면 VS Code 설정에 아래 값을 지정하세요:

```json
{
  "codexRemote.relayServerUrl": "https://your-relay.example.com"
}
```

### 빠른 시작

1. VS Code 확장을 설치합니다
2. 로컬에 Codex CLI가 설치되어 있고 인증되었는지 확인합니다
3. VS Code 상태바의 Codex Remote 항목을 클릭합니다
4. 릴레이 세션 ID를 생성하거나 연결합니다 (선택: PIN)
5. 모바일 또는 웹 클라이언트에서 같은 세션 ID로 연결합니다
6. 프롬프트를 보내고 스트리밍 Codex 응답을 받습니다
7. 지원되는 경우 클라이언트 UI에서 agent mode, model, reasoning effort를 선택합니다

### 저장소 구조

- `codex-extension/` — VS Code 확장
- `mobile-app/` — Flutter 모바일/웹 클라이언트
- `codex-relay-server/` — 원격 세션용 릴레이 서버
- `PROTOCOL.md` — 메시지 규격 문서

### 관련 문서

- [VS Code 확장 가이드](./codex-extension/README.md)
- [모바일 앱 가이드](./mobile-app/README.md)
- [릴레이 서버 가이드](./codex-relay-server/README.md)
- [프로토콜 문서](./PROTOCOL.md)
