import * as vscode from "vscode";
import { WebSocketServer } from "./websocket-server";

/**
 * Legacy placeholder kept only for source compatibility.
 * Codex-only runtime no longer starts a local hook HTTP server.
 */
export class HttpServer {
  constructor(
    _outputChannel: vscode.OutputChannel,
    _wsServer: WebSocketServer
  ) {}

  async start(): Promise<void> {
    // no-op
  }

  getPort(): number | null {
    return null;
  }

  stop(): void {
    // no-op
  }
}
