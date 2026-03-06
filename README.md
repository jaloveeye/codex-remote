# Codex Remote 📱

Control Codex from mobile/web through a VS Code extension and relay session.  
VS Code 확장을 통해 모바일/웹에서 Codex를 원격 제어하는 프로젝트입니다.

---

## What is this? / 프로젝트 소개

**EN**
- Codex Remote connects:
  1) VS Code extension  
  2) Codex app-server  
  3) Mobile/Web client  
  via a relay session ID (optional PIN).

**KO**
- Codex Remote는 다음 3가지를 연결합니다.
  1) VS Code 확장  
  2) Codex app-server  
  3) 모바일/웹 클라이언트  
  그리고 세션 ID(선택: PIN)로 안전하게 연결합니다.

---

## Install / 설치

### A) VS Code Marketplace (Recommended) / 마켓플레이스 설치 (권장)

**EN**
1. Open VS Code Extensions (`Ctrl/Cmd+Shift+X`)
2. Search: **Codex Remote**
3. Install and reload window

**KO**
1. VS Code 확장 탭 열기 (`Ctrl/Cmd+Shift+X`)
2. **Codex Remote** 검색
3. 설치 후 창 다시 로드

### B) VSIX Install / VSIX 설치

```bash
code --install-extension codex-remote-extension-<version>.vsix --force
```

---

## Required setup / 필수 설정

### 1) Codex CLI

```bash
codex --version
codex auth login
```

### 2) Relay URL in VS Code / VS Code 릴레이 URL 설정

Add in `settings.json`:

```json
{
  "codexRemote.relayServerUrl": "https://your-relay.example.com"
}
```

---

## How to use / 사용 방법

**EN**
1. Click the Codex Remote status bar item in VS Code
2. Create/connect a relay session ID (optional PIN)
3. Open mobile/web client
4. Enter the same session ID (and PIN if enabled)
5. Send prompts from mobile/web and receive Codex responses

**KO**
1. VS Code 상태바의 Codex Remote를 클릭
2. 릴레이 세션 ID 생성/연결 (선택: PIN 설정)
3. 모바일/웹 클라이언트 열기
4. 같은 세션 ID(PIN 사용 시 동일 PIN) 입력
5. 모바일/웹에서 프롬프트 전송 후 Codex 응답 수신

---

## For self-hosting / 직접 운영 시

**EN**
- Use a dedicated relay server for your project.
- Make extension and client use the same relay base URL.

**KO**
- 프로젝트 전용 릴레이 서버를 사용하세요.
- 확장과 클라이언트가 동일한 릴레이 URL을 사용해야 합니다.

See:
- [codex-relay-server/README.md](./codex-relay-server/README.md)
- [mobile-app/README.md](./mobile-app/README.md)

---

## Related docs / 관련 문서

- [USER_MANUAL.md](./USER_MANUAL.md)
- [PROTOCOL.md](./PROTOCOL.md)
- [codex-extension/README.md](./codex-extension/README.md)
