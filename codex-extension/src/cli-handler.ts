import * as vscode from "vscode";
import { WebSocketServer } from "./websocket-server";

/**
 * Legacy placeholder kept only for source compatibility.
 * The active runtime path is codex-only via CodexHandler.
 */
export class CLIHandler {
  constructor(
    _outputChannel?: vscode.OutputChannel,
    _wsServer?: WebSocketServer,
    _workspaceRoot?: string
  ) {}

  setGetRelaySessionId(_getter: () => string | null): void {
    // no-op
  }

  getChatHistory(
    _clientId?: string,
    _sessionId?: string,
    _relaySessionId?: string,
    _limit: number = 50
  ): any[] {
    return [];
  }

  dispose(): void {
    // no-op
  }
}
