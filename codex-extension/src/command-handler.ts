import * as vscode from "vscode";
import * as path from "path";
import { CodexCliStatus, CodexHandler } from "./codex-handler";
import { WebSocketServer } from "./websocket-server";
import { CONFIG } from "./config";

export class CommandHandler {
  private outputChannel: vscode.OutputChannel | null = null;
  private wsServer: WebSocketServer | null = null;
  private codexHandler: CodexHandler | null = null;

  constructor(
    outputChannel?: vscode.OutputChannel,
    wsServer?: WebSocketServer,
    _useLegacyMode: boolean = false
  ) {
    this.outputChannel = outputChannel || null;
    this.wsServer = wsServer || null;

    const workspaceFolders = vscode.workspace.workspaceFolders;
    const workspaceRoot =
      workspaceFolders && workspaceFolders.length > 0
        ? workspaceFolders[0].uri.fsPath
        : undefined;

    this.codexHandler = new CodexHandler(outputChannel, wsServer, workspaceRoot);
    this.log("[Codex Remote] Backend mode enabled (codex app-server)");
  }

  notifyIfCodexCliUnavailable(): void {
    this.codexHandler?.notifyIfCodexCliUnavailable();
  }

  refreshCodexCliStatus(): void {
    this.codexHandler?.refreshCodexCliStatus();
  }

  setOnCodexCliStatusChange(callback: (() => void) | null): void {
    this.codexHandler?.setOnCodexCliStatusChange(callback);
  }

  getCodexCliStatus(): CodexCliStatus | null {
    return this.codexHandler?.getCodexCliStatus() ?? null;
  }

  /**
   * Backward-compatible no-op. Chat history is now maintained by CodexHandler only.
   */
  setGetRelaySessionId(_getter: () => string | null): void {
    // no-op
  }

  private log(message: string) {
    const timestamp = new Date().toLocaleTimeString();
    const logMessage = `[${timestamp}] ${message}`;
    if (this.outputChannel) {
      this.outputChannel.appendLine(logMessage);
    }
    console.log(logMessage);
  }

  private logError(message: string, error?: any) {
    const timestamp = new Date().toLocaleTimeString();
    const logMessage = `[${timestamp}] ERROR: ${message}${
      error ? ` - ${error}` : ""
    }`;
    if (this.outputChannel) {
      this.outputChannel.appendLine(logMessage);
    }
    console.error(logMessage);
  }

  private isLikelyCommand(text: string): boolean {
    if (!text || text.length === 0) {
      return false;
    }

    if (!text.includes(" ") && !text.includes("	")) {
      for (const pattern of CONFIG.COMMAND_PATTERNS) {
        if (pattern.test(text)) {
          return true;
        }
      }
      return false;
    }

    for (const pattern of CONFIG.PLAIN_TEXT_PATTERNS) {
      if (pattern.test(text.trim())) {
        return false;
      }
    }

    return true;
  }

  async insertText(text: string): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
      throw new Error("No active editor. Please open a file in VS Code.");
    }

    const success = await editor.edit((editBuilder) => {
      const position = editor.selection.active;
      editBuilder.insert(position, text);
    });

    if (!success) {
      throw new Error(
        "Failed to insert text. The editor may be read-only or the edit was rejected."
      );
    }
  }

  async insertToTerminal(text: string, execute: boolean = false): Promise<void> {
    this.log(
      `[Codex Remote] insertToTerminal called - textLength: ${text.length}, execute: ${execute}`
    );
    this.log(
      `[Codex Remote] Text content: "${text.substring(0, 100)}${
        text.length > 100 ? "..." : ""
      }"`
    );

    try {
      const workspaceFolders = vscode.workspace.workspaceFolders;
      let outputFile: string | null = null;
      if (workspaceFolders && workspaceFolders.length > 0) {
        const workspaceRoot = workspaceFolders[0].uri.fsPath;
        outputFile = path.join(workspaceRoot, CONFIG.TERMINAL_OUTPUT_FILE);
      }

      let terminal = vscode.window.activeTerminal;
      this.log(
        `[Codex Remote] Active terminal: ${terminal ? terminal.name : "null"}`
      );

      if (!terminal) {
        this.log("[Codex Remote] No active terminal, creating new terminal");
        terminal = vscode.window.createTerminal("Codex Remote");
        terminal.show(true);
        await new Promise((resolve) => setTimeout(resolve, CONFIG.TERMINAL_ACTIVATION_DELAY));
      } else {
        terminal.show(true);
        await new Promise((resolve) => setTimeout(resolve, CONFIG.TERMINAL_FOCUS_DELAY));
      }

      await vscode.commands.executeCommand("workbench.action.terminal.focus");
      await new Promise((resolve) => setTimeout(resolve, CONFIG.TERMINAL_FOCUS_DELAY));

      if (execute) {
        await new Promise((resolve) => setTimeout(resolve, 100));
        let commandToSend = text;
        if (outputFile) {
          const trimmedText = text.trim();
          const isCommand = this.isLikelyCommand(trimmedText);
          if (isCommand && !text.includes("| tee") && !text.includes(">>") && !text.includes(">")) {
            commandToSend = `(${text}) 2>&1 | tee -a "${outputFile}"`;
            this.log(`[Codex Remote] Auto-capturing output to: ${outputFile}`);
          }
        }

        terminal.sendText(commandToSend, false);
        await new Promise((resolve) => setTimeout(resolve, CONFIG.TERMINAL_EXECUTION_DELAY));
        terminal.sendText("\n", false);

        if (this.wsServer) {
          this.wsServer.send(
            JSON.stringify({
              type: "user_message",
              text,
              timestamp: new Date().toISOString(),
            })
          );
        }
        return;
      }

      terminal.sendText(text, false);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "Unknown error";
      this.logError(`[Codex Remote] Error in insertToTerminal: ${errorMsg}`);
      throw new Error(`터미널 입력 실패: ${errorMsg}`);
    }
  }

  async insertToPrompt(
    text: string,
    execute: boolean = false,
    clientId?: string,
    newSession: boolean = false,
    agentMode: "agent" | "ask" | "plan" | "debug" | "auto" = "auto",
    senderDeviceId?: string,
    model?: string,
    reasoningEffort?: "none" | "minimal" | "low" | "medium" | "high" | "xhigh",
    useIdeContext?: boolean,
    useFlatMode?: boolean
  ): Promise<void> {
    this.log(
      `[Codex Remote] insertToPrompt called - textLength: ${text.length}, execute: ${execute}, clientId: ${
        clientId || "none"
      }, newSession: ${newSession}, agentMode: ${agentMode}, senderDeviceId: ${
        senderDeviceId || "none"
      }, model: ${model || "auto"}, reasoningEffort: ${
        reasoningEffort || "auto"
      }, useIdeContext: ${useIdeContext ?? false}, useFlatMode: ${
        useFlatMode ?? false
      }`
    );

    if (!this.codexHandler) {
      throw new Error("Codex handler is not initialized.");
    }

    await this.codexHandler.sendPrompt(
      text,
      execute,
      clientId,
      newSession,
      agentMode,
      senderDeviceId,
      model,
      reasoningEffort,
      useIdeContext,
      useFlatMode
    );
  }

  async executeCommand(command: string, ...args: any[]): Promise<any> {
    return await vscode.commands.executeCommand(command, ...args);
  }

  async getActiveFile(): Promise<{ path: string; content: string } | null> {
    const editor = vscode.window.activeTextEditor;
    if (!editor || !editor.document) {
      return null;
    }

    return {
      path: editor.document.fileName,
      content: editor.document.getText(),
    };
  }

  async saveFile(): Promise<{ success: boolean; path?: string }> {
    const editor = vscode.window.activeTextEditor;
    if (!editor || !editor.document) {
      throw new Error("No active editor");
    }

    await editor.document.save();
    return {
      success: true,
      path: editor.document.fileName,
    };
  }

  async getAIResponse(): Promise<string> {
    if (!this.codexHandler) {
      return "";
    }
    const history = this.codexHandler.getChatHistory(undefined, undefined, undefined, 1);
    return history.length > 0 ? history[history.length - 1].assistantResponse : "";
  }

  async getSessionInfo(clientId?: string): Promise<any> {
    if (!this.codexHandler) {
      return { currentSessionId: null, clientId: clientId || null, hasSession: false };
    }
    return this.codexHandler.getSessionInfo(clientId);
  }

  async getChatHistory(
    clientId?: string,
    sessionId?: string,
    relaySessionId?: string,
    limit: number = 50
  ): Promise<any> {
    const entries = this.codexHandler
      ? this.codexHandler.getChatHistory(clientId, sessionId, relaySessionId, limit)
      : [];
    return { entries };
  }

  async getRuntimeCapabilities(): Promise<any> {
    if (!this.codexHandler) {
      return {
        provider: "codex",
        ready: false,
        models: [],
        agentModes: ["auto", "agent", "ask", "plan", "debug"],
      };
    }
    return this.codexHandler.getRuntimeCapabilities();
  }

  async stopPrompt(): Promise<{ success: boolean }> {
    this.log("[Codex Remote] stopPrompt called");
    if (!this.codexHandler) {
      return { success: true };
    }
    return this.codexHandler.stopPrompt();
  }

  async executeAction(action: string): Promise<{ success: boolean }> {
    const candidates = [action, `workbench.action.${action}`, `editor.action.${action}`];
    for (const command of candidates) {
      try {
        await vscode.commands.executeCommand(command);
        return { success: true };
      } catch {
        // try next candidate
      }
    }
    return { success: false };
  }

  dispose() {
    if (this.codexHandler) {
      this.codexHandler.dispose();
      this.codexHandler = null;
    }
  }
}
