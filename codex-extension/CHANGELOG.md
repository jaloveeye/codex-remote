# Changelog

## 0.1.0

- Show Codex Remote in the status bar as a frog face icon with red/green state colors
- Align the extension package version to 0.1.0

## 0.4.7

- Show Codex Remote in the status bar as a single arrow icon with red/green state colors

## 0.4.6

- Add runtime capability handshake so clients can load live model/reasoning options from Codex CLI
- Improve relay client capability refresh responsiveness
- Simplify status bar to icon-only state indicators

## 0.4.5

- Bump VSIX release version for fresh install validation
- Improve Codex response extraction stability in relay mode

## 0.4.4

- Preserve whitespace in streamed Codex delta chunks so responses render in the correct order/spacing

## 0.4.3

- Show extension version in the connection info panel

## 0.4.2

- Fix VSIX packaging so the runtime `ws` dependency is included
- Restore activation/status bar in installed builds

## 0.4.1

- Add Codex CLI status to the connection info panel
- Add quick actions in the panel for guide/output/status refresh
- Add relay disconnect action from the connection info panel

## Current line

- Codex-only extension runtime
- Relay session connection with optional PIN
- Streaming Codex responses over local WebSocket and relay

## Notes

Historical product-specific release notes were intentionally removed during the codex-only cleanup.
