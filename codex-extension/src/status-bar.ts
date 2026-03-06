/**
 * Status bar management for Codex Remote extension
 */

import * as vscode from "vscode";
import { WebSocketServer } from "./websocket-server";

export class StatusBarManager {
  private statusBarItem: vscode.StatusBarItem;
  private wsServer: WebSocketServer | null = null;
  private relayClient: {
    isConnectedToSession: () => boolean;
    getSessionId: () => string | null;
  } | null = null;

  constructor(context: vscode.ExtensionContext) {
    this.statusBarItem = vscode.window.createStatusBarItem(
      vscode.StatusBarAlignment.Right,
      100
    );
    this.statusBarItem.command = "codexRemote.statusBarClick";
    this.statusBarItem.tooltip =
      "Codex Remote: 클릭 시 릴레이 연결(세션 ID·PIN) 또는 연결 정보 보기";
    context.subscriptions.push(this.statusBarItem);
  }

  /**
   * Set WebSocket server reference
   */
  setWebSocketServer(wsServer: WebSocketServer) {
    this.wsServer = wsServer;
  }

  /**
   * Set relay client reference (for status when connected via relay)
   */
  setRelayClient(
    relayClient: {
      isConnectedToSession: () => boolean;
      getSessionId: () => string | null;
    } | null
  ) {
    this.relayClient = relayClient;
  }

  /**
   * Refresh status bar from current state (local WebSocket + relay)
   */
  refresh() {
    if (!this.statusBarItem) return;

    const hasLocalClient = this.wsServer
      ? this.wsServer.getClientCount() > 0
      : false;
    const hasRelaySession = this.relayClient
      ? this.relayClient.isConnectedToSession()
      : false;
    const connected = hasLocalClient || hasRelaySession;
    this.statusBarItem.text = "🐸 ●";

    if (this.wsServer && this.wsServer.isRunning()) {
      if (connected) {
        if (hasRelaySession && this.relayClient) {
          const sessionId = this.relayClient.getSessionId();
          this.statusBarItem.tooltip =
            (sessionId != null
              ? `Codex Remote: 릴레이 세션 ${sessionId}`
              : "Codex Remote: 릴레이 세션에 연결됨") +
            " · 클릭: 연결 정보 보기";
          this.statusBarItem.color = new vscode.ThemeColor("terminal.ansiGreen");
        } else {
          this.statusBarItem.tooltip =
            "Codex Remote: 클라이언트 연결됨 · 클릭: 연결 정보 보기";
          this.statusBarItem.color = new vscode.ThemeColor("terminal.ansiGreen");
        }
        this.statusBarItem.backgroundColor = undefined;
      } else if (!hasRelaySession) {
        this.statusBarItem.tooltip =
          "Codex Remote: 릴레이 끔 · 클릭: 세션 ID·PIN 입력하여 연결";
        this.statusBarItem.backgroundColor = undefined;
        this.statusBarItem.color = new vscode.ThemeColor("terminal.ansiRed");
      } else {
        this.statusBarItem.tooltip =
          "Codex Remote: 클라이언트 대기 중 · 클릭: 연결 정보 보기";
        this.statusBarItem.backgroundColor = undefined;
        this.statusBarItem.color = new vscode.ThemeColor("terminal.ansiRed");
      }
    } else {
      this.statusBarItem.tooltip =
        "Codex Remote: 서버 중지됨 · 클릭: 연결 정보 보기";
      this.statusBarItem.backgroundColor = undefined;
      this.statusBarItem.color = new vscode.ThemeColor("terminal.ansiRed");
    }
    this.statusBarItem.show();
  }

  /**
   * Update status bar (called when WebSocket client connects/disconnects)
   */
  update(connected: boolean) {
    this.refresh();
  }

  /**
   * Show status bar
   */
  show() {
    this.statusBarItem.show();
  }
}
