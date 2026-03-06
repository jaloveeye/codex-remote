# Codex Remote Mobile App

Flutter client for Codex Remote.

## Features

- Local WebSocket connection to the extension
- Relay session connection for remote access
- Streaming response display
- Command approval review and resolution
- Chat history loading

## Run locally

```bash
flutter pub get
flutter run --dart-define=RELAY_SERVER_URL=http://localhost:3000
```

For a deployed relay, replace the value with your own URL such as `https://relay.example.com`.

## Build web

```bash
flutter pub get
flutter build web --release --base-href / --dart-define=RELAY_SERVER_URL=https://relay.example.com
```

For Vercel deployment, deploy the generated `build/web` output.
