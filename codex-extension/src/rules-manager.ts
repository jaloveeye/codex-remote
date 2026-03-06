import * as vscode from "vscode";
import { HttpServer } from "./http-server";

/**
 * Legacy placeholder kept only for source compatibility.
 * Codex-only runtime no longer manages editor hook files.
 */
export class RulesManager {
  constructor(
    _outputChannel: vscode.OutputChannel,
    _httpServer: HttpServer
  ) {}

  ensureHooksFile(_workspaceRoot: string): void {
    // no-op
  }
}
