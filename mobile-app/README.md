# Codex Remote Mobile App

## English

Flutter client for Codex Remote.

### Features

- Local WebSocket connection to the extension
- Relay session connection for remote access
- Streaming response display
- Chat history loading
- Command approval review and resolution
- Runtime capability sync for model and reasoning options

### Run locally

```bash
flutter pub get
flutter run --dart-define=RELAY_SERVER_URL=http://localhost:3000
```

For a deployed relay, replace the URL with your own relay endpoint such as `https://codex-relay.jaloveeye.com`.

### Build for web

```bash
flutter pub get
flutter build web --release --base-href / --dart-define=RELAY_SERVER_URL=https://codex-relay.jaloveeye.com
```

Deploy the generated `build/web` output to your preferred static hosting provider.

---

## 한국어

Codex Remote용 Flutter 클라이언트입니다.

### 기능

- 확장과의 로컬 WebSocket 연결
- 원격 접속용 릴레이 세션 연결
- 스트리밍 응답 표시
- 채팅 히스토리 로딩
- 명령 승인 검토 및 처리
- model / reasoning 옵션을 위한 런타임 capability 동기화

### 로컬 실행

```bash
flutter pub get
flutter run --dart-define=RELAY_SERVER_URL=http://localhost:3000
```

배포된 릴레이를 사용할 경우 `https://codex-relay.jaloveeye.com` 같은 본인 릴레이 URL로 바꾸세요.

### 웹 빌드

```bash
flutter pub get
flutter build web --release --base-href / --dart-define=RELAY_SERVER_URL=https://codex-relay.jaloveeye.com
```

생성된 `build/web` 출력물을 원하는 정적 호스팅에 배포하면 됩니다.
