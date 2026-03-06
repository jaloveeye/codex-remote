import * as vscode from "vscode";
import { WebSocketServer } from "./websocket-server";

/**
 * Legacy placeholder kept only for source compatibility.
 * Runtime chat capture is handled directly by CodexHandler streaming.
 */
export class ChatCapture {
  constructor(
    _outputChannel: vscode.OutputChannel,
    _wsServer: WebSocketServer
  ) {}

  setup(_context: vscode.ExtensionContext): void {
    // no-op
  }

  dispose(): void {
    // no-op
  }
}
