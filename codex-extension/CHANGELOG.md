# Changelog

## 0.2.2

- Switch relay polling to opt-in long-poll (server holds the request up to 25s) to cut idle relay traffic.
- Add exponential backoff (1s → 30s cap) for relay connect retries while waiting for a mobile session to appear.
- Remove the redundant 30s relay heartbeat; polling already refreshes PC presence on the relay.
- Add request timeouts and failure backoff around relay polling for network resilience.

## 0.2.1

- Coalesce concurrent Codex runtime capability requests with a short-lived cache.
- Resolve runtime models dynamically and preserve supported explicit selections.
- Omit stale or unsupported model IDs so Codex can use the current account default.
- Update the bundled WebSocket runtime to `ws` 8.21.1.

## 0.2.0

- Add English/Korean localization for web landing pages and extension metadata.
- Update extension/package metadata and localized resource handling.
- Bump app-facing versioning to 0.2.0 for release preparation.

## 0.1.6

- Add codex-remote.jaloveeye.com quick link in the extension connections panel.
- Add iOS/Android app store quick links in connections panel with configurable URLs (currently optional, ready for later store publication).
- Align extension and relay client/server handshake/version metadata to 0.1.6.

## 0.1.5

- Remove desktop fallback for mobile approval and mobile user-input requests
- Make mobile-side Codex request prompts more prominent with immediate modal alerts

## 0.1.4

- Bump the extension package for the latest patch release
- Preserve relay envelope device metadata in forwarded payloads for approval/response routing

## 0.1.1

- Fix Marketplace metadata links for repository, homepage, and issue tracker
- Refine public documentation structure and remove deprecated legacy paths
- Remove the unused legacy `pc-server` package from the repository

## 0.1.0

- Initial public release of Codex Remote
- Remote Codex control through the VS Code extension, mobile/web client, and relay session flow
- Runtime model and reasoning controls in the client experience
- Frog status bar indicator and public Marketplace/repository metadata cleanup
