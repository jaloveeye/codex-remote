import * as vscode from "vscode";
import { CodexCliStatus } from "./codex-handler";
import { WebSocketServer } from "./websocket-server";
import { CommandHandler } from "./command-handler";
import { CommandRouter } from "./command-router";
import { StatusBarManager } from "./status-bar";
import { RelayClient } from "./relay-client";
import { CONFIG } from "./config";

let wsServer: WebSocketServer | null = null;
let commandHandler: CommandHandler | null = null;
let commandRouter: CommandRouter | null = null;
let statusBarManager: StatusBarManager | null = null;
let relayClient: RelayClient | null = null;
let outputChannel: vscode.OutputChannel;
let extensionDisplayVersion = "unknown";
/** 연결 정보 Webview 패널 (열려 있을 때만 갱신용) */
let connectionsPanel: vscode.WebviewPanel | null = null;
/** 패널 열린 동안 주기 갱신 타이머 (dispose 시 해제) */
let connectionsPanelRefreshInterval: ReturnType<typeof setInterval> | null =
  null;
/** 릴레이 서버 저장소 라벨 (연결 정보 패널에서 표시, /api/store 조회 결과) */
let lastRelayStoreLabel: string | null = null;

/** 연결 정보 Webview용 HTML 생성 */
function getConnectionsViewHtml(data: {
  serverRunning: boolean;
  serverPort: number | null;
  relaySessionId: string | null;
  relayStoreLabel: string | null;
  relayServerUrl: string | null;
  localClientIds: string[];
  codexCliStatus: CodexCliStatus;
  extensionVersion: string;
  iosAppStoreUrl: string | null;
  androidPlayStoreUrl: string | null;
}): string {
  const {
    serverRunning,
    serverPort,
    relaySessionId,
    relayStoreLabel,
    relayServerUrl,
    localClientIds,
    codexCliStatus,
    extensionVersion,
  } = data;
  const relayStoreLine =
    relayStoreLabel != null
      ? `<p class="relay-meta"><strong>저장소:</strong> ${escapeHtml(relayStoreLabel)}</p>`
      : "";
  const relayUrlLine =
    relayServerUrl != null
      ? `<p class="relay-meta"><strong>서버:</strong> <code>${escapeHtml(relayServerUrl)}</code></p>`
      : "";
  const relaySection =
    relaySessionId != null
      ? `
    <section class="section">
      <h2>📡 릴레이</h2>
      <p class="status connected">릴레이 서버를 통해 접속 중</p>
      <p class="session-id"><strong>세션 ID:</strong> <code>${escapeHtml(
        relaySessionId
      )}</code></p>
      ${relayStoreLine}
      ${relayUrlLine}
    </section>`
      : `
    <section class="section">
      <h2>📡 릴레이</h2>
      <p class="status disconnected">연결 안 됨</p>
      ${relayStoreLine}
      ${relayUrlLine}
    </section>`;

  const localSection =
    localClientIds.length > 0
      ? `
    <section class="section">
      <h2>🖥️ 로컬 클라이언트 (${localClientIds.length}개)</h2>
      <ul>${localClientIds
        .map((id) => `<li><code>${escapeHtml(id)}</code></li>`)
        .join("")}</ul>
    </section>`
      : `
    <section class="section">
      <h2>🖥️ 로컬 클라이언트</h2>
      <p class="status disconnected">연결 없음</p>
    </section>`;

  const codexStatusClass =
    codexCliStatus.severity === "error"
      ? "error"
      : codexCliStatus.severity === "warning"
      ? "warning"
      : codexCliStatus.state === "unknown"
      ? "disconnected"
      : "connected";
  const codexCheckedAtLine =
    codexCliStatus.checkedAt != null
      ? `<p class="relay-meta"><strong>마지막 확인:</strong> ${escapeHtml(
          new Date(codexCliStatus.checkedAt).toLocaleString()
        )}</p>`
      : "";
  const iosAppStoreButton = `<button type="button" data-action="openIosAppStore" ${
    data.iosAppStoreUrl == null ? "disabled title=\"준비 중\"" : ""
  }>iOS 앱</button>`;
  const androidAppStoreButton = `<button type="button" data-action="openAndroidPlayStore" ${
    data.androidPlayStoreUrl == null ? "disabled title=\"준비 중\"" : ""
  }>Android 앱</button>`;
  const codexSection = `
    <section class="section">
      <h2>🤖 Codex CLI</h2>
      <p class="status ${codexStatusClass}">${escapeHtml(
        codexCliStatus.summary
      )}</p>
      <p class="relay-meta"><strong>명령:</strong> <code>${escapeHtml(
        codexCliStatus.command
      )}</code></p>
      ${codexCheckedAtLine}
    </section>`;
  const actionsSection = `
    <section class="section">
      <h2>🛠️ 빠른 작업</h2>
      <div class="actions">
        <button type="button" data-action="openProjectSite">Codex Remote 사이트 열기</button>
        ${iosAppStoreButton}
        ${androidAppStoreButton}
        <button type="button" data-action="openGuide">가이드 열기</button>
        <button type="button" data-action="showOutput">출력 보기</button>
        <button type="button" data-action="refreshCodexStatus">Codex 상태 다시 확인</button>
        <button type="button" data-action="disconnectRelay" ${
          relaySessionId == null ? "disabled" : ""
        }>세션 종료</button>
        <button type="button" data-action="clearRelaySession" ${
          relaySessionId == null ? "disabled" : ""
        }>세션 클리어</button>
      </div>
      <p class="relay-meta">문제가 있으면 가이드를 열거나 출력 로그를 확인해 주세요.</p>
    </section>`;

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: var(--vscode-font-family); padding: 1rem; color: var(--vscode-foreground); }
    h1 { font-size: 1.2rem; margin-bottom: 1rem; }
    h2 { font-size: 1rem; margin: 1rem 0 0.5rem; color: var(--vscode-descriptionForeground); }
    .section { margin-bottom: 1.25rem; }
    .status.connected { color: var(--vscode-testing-iconPassed); }
    .status.warning { color: var(--vscode-testing-iconQueued); }
    .status.error { color: var(--vscode-errorForeground); }
    .status.disconnected { color: var(--vscode-descriptionForeground); }
    code { background: var(--vscode-textBlockQuote-background); padding: 0.2em 0.4em; border-radius: 4px; }
    ul { margin: 0.25rem 0; padding-left: 1.25rem; }
    .relay-meta { font-size: 0.9em; color: var(--vscode-descriptionForeground); margin-top: 0.25rem; }
    .actions { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.5rem; }
    button {
      border: 1px solid var(--vscode-button-border, transparent);
      background: var(--vscode-button-background);
      color: var(--vscode-button-foreground);
      border-radius: 6px;
      padding: 0.45rem 0.75rem;
      cursor: pointer;
    }
    button:hover:not(:disabled) { background: var(--vscode-button-hoverBackground); }
    button:disabled {
      cursor: default;
      opacity: 0.6;
      background: var(--vscode-button-secondaryBackground);
      color: var(--vscode-disabledForeground);
    }
  </style>
</head>
<body>
  <h1>Codex Remote - 연결 정보</h1>
  <section class="section">
    <h2>ℹ️ 버전</h2>
    <p class="relay-meta"><strong>확장:</strong> <code>${escapeHtml(
      extensionVersion
    )}</code></p>
  </section>
  <section class="section">
    <h2>🔌 서버</h2>
    <p class="status ${serverRunning ? "connected" : "disconnected"}">
      ${serverRunning ? `포트 ${serverPort ?? "-"}에서 실행 중` : "중지됨"}
    </p>
  </section>
  ${codexSection}
  ${actionsSection}
  ${relaySection}
  ${localSection}
  <script>
    const vscode = acquireVsCodeApi();
    document.querySelectorAll("button[data-action]").forEach((button) => {
      button.addEventListener("click", () => {
        if (button.disabled) return;
        vscode.postMessage({
          type: "panelAction",
          action: button.getAttribute("data-action"),
        });
      });
    });
  </script>
</body>
</html>`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function getRelayServerUrl(): string {
  const configured = vscode.workspace
    .getConfiguration("codexRemote")
    .get<string>("relayServerUrl");

  return configured?.trim() || CONFIG.RELAY_SERVER_URL;
}

function getStoreUrlSetting(
  key: "iosAppStoreUrl" | "androidPlayStoreUrl"
): string | null {
  const configured = vscode.workspace.getConfiguration("codexRemote").get<string>(key);
  const trimmed = configured?.trim();
  return trimmed ? trimmed : null;
}

function getCurrentCodexCliStatus(): CodexCliStatus {
  return (
    commandHandler?.getCodexCliStatus() ?? {
      state: "unknown",
      severity: "info",
      summary: "아직 확인되지 않음",
      checkedAt: null,
      command: CONFIG.CODEX_COMMAND,
    }
  );
}

/** 연결 정보가 바뀌었을 때 열려 있는 패널 내용 갱신 */
function updateConnectionsView() {
  if (!connectionsPanel) return;
  const serverStatus = wsServer
    ? wsServer.getConnectionStatus()
    : {
        isRunning: false,
        clientCount: 0,
        port: null as number | null,
      };
  const relaySessionId =
    relayClient?.isConnectedToSession() === true
      ? relayClient.getSessionId()
      : null;
  const localClientIds = wsServer ? wsServer.getClientIds() : [];
  connectionsPanel.webview.html = getConnectionsViewHtml({
    serverRunning: serverStatus.isRunning,
    serverPort: serverStatus.port,
    relaySessionId,
    relayStoreLabel: lastRelayStoreLabel,
    relayServerUrl: getRelayServerUrl(),
    localClientIds,
    codexCliStatus: getCurrentCodexCliStatus(),
    extensionVersion: extensionDisplayVersion,
    iosAppStoreUrl: getStoreUrlSetting("iosAppStoreUrl"),
    androidPlayStoreUrl: getStoreUrlSetting("androidPlayStoreUrl"),
  });
}

export async function activate(context: vscode.ExtensionContext) {
  extensionDisplayVersion =
    context.extension.packageJSON?.version ?? "unknown";
  // Output channel creation
  outputChannel = vscode.window.createOutputChannel("Codex Remote");
  context.subscriptions.push(outputChannel);
  outputChannel.show(true);

  // 로그를 클라이언트에 전송하는 헬퍼 함수
  const sendLogToClients = (
    level: "info" | "warn" | "error",
    message: string,
    error?: any
  ) => {
    if (wsServer) {
      const logData = {
        level,
        message,
        timestamp: new Date().toISOString(),
        source: "extension",
        ...(error && {
          error: error instanceof Error ? error.message : String(error),
        }),
      };
      wsServer.send(
        JSON.stringify({
          type: "log",
          ...logData,
        })
      );
    }
  };

  outputChannel.appendLine("Codex Remote extension is now active!");
  outputChannel.appendLine(
    `[${new Date().toLocaleTimeString()}] 🔄 Extension activation started`
  );
  console.log("Codex Remote extension is now active!");
  sendLogToClients("info", "Codex Remote extension is now active!");

  // Status bar manager
  statusBarManager = new StatusBarManager(context);

  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((event) => {
      if (!event.affectsConfiguration("codexRemote.relayServerUrl")) {
        return;
      }

      const relayServerUrl = getRelayServerUrl();
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] 🔄 Relay Server URL setting updated: ${relayServerUrl}`
      );
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] ℹ️ Reload the VS Code window to use the new relay server.`
      );
      updateConnectionsView();
      vscode.window.showInformationMessage(
        "Codex Remote: relayServerUrl changed. Reload the VS Code window to reconnect with the new relay server."
      );
    })
  );

  // WebSocket server initialization
  wsServer = new WebSocketServer(CONFIG.WEBSOCKET_PORT, outputChannel);
  statusBarManager.setWebSocketServer(wsServer);

  commandHandler = new CommandHandler(outputChannel, wsServer);
  commandRouter = new CommandRouter(commandHandler, wsServer, outputChannel);
  commandHandler.setOnCodexCliStatusChange(() => {
    updateConnectionsView();
  });

  outputChannel.appendLine("[Codex Remote] Backend mode is enabled (codex app-server)");
  commandHandler.notifyIfCodexCliUnavailable();

  // WebSocket message handler
  wsServer.onMessage((message: string) => {
    try {
      const command = JSON.parse(message);
      const clientId = command.clientId || "none";
      const source = command.source || "local";

      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] Received command: ${
          command.type
        } from client: ${clientId} (source: ${source})`
      );

      // Handle command locally (whether from local WebSocket or relay)
      if (
        source === "relay" &&
        relayClient &&
        command.type === "insert_text" &&
        (command.prompt === true || command.prompt === "true")
      ) {
        const traceId =
          (typeof command.traceId === "string" && command.traceId.trim()) ||
          (typeof command.id === "string" && command.id.trim()) ||
          null;
        const commandId =
          (typeof command.id === "string" && command.id.trim()) || null;
        relayClient.recordTraceHop({
          traceId,
          hop: "ext.dispatch.to_codex",
          commandId,
          senderDeviceId:
            typeof command.senderDeviceId === "string"
              ? command.senderDeviceId
              : undefined,
          meta: {
            commandType: command.type,
          },
        });
      }

      if (commandRouter) {
        commandRouter.handleCommand(command);
      }

      // If message is from local WebSocket client (not from relay), forward to relay
      if (
        source !== "relay" &&
        relayClient &&
        relayClient.isConnectedToSession()
      ) {
        relayClient.sendMessage(message).catch((error) => {
          const errorMsg =
            error instanceof Error ? error.message : "Unknown error";
          outputChannel.appendLine(
            `[${new Date().toLocaleTimeString()}] ❌ Failed to send to relay: ${errorMsg}`
          );
        });
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "Unknown error";
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] Error parsing message: ${errorMsg}`
      );
      console.error("Error parsing message:", error);
    }
  });

  // Client connection/disconnection event handling
  wsServer.onClientChange((connected: boolean) => {
    if (statusBarManager) {
      statusBarManager.update(connected);
    }
    updateConnectionsView();

    if (connected) {
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] Client connected - Ready to receive commands`
      );
      // 연결 상태 전송
      if (wsServer) {
        wsServer.sendConnectionStatus();
      }
    } else {
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] Client disconnected`
      );
      // 연결 상태 전송
      if (wsServer) {
        wsServer.sendConnectionStatus();
      }
    }
  });

  // Register commands
  const openGuideCommand = vscode.commands.registerCommand(
    "codexRemote.openGuide",
    async () => {
      try {
        const readmeUri = vscode.Uri.joinPath(context.extensionUri, "README.md");
        const doc = await vscode.workspace.openTextDocument(readmeUri);
        await vscode.window.showTextDocument(doc, { preview: false });
      } catch (error) {
        const errorMsg =
          error instanceof Error ? error.message : "Unknown error";
        vscode.window.showErrorMessage(
          `Codex Remote: 가이드를 열 수 없습니다 - ${errorMsg}`
        );
      }
    }
  );

  const showOutputCommand = vscode.commands.registerCommand(
    "codexRemote.showOutput",
    () => {
      outputChannel.show(true);
    }
  );

  const refreshCodexStatusCommand = vscode.commands.registerCommand(
    "codexRemote.refreshCodexStatus",
    () => {
      commandHandler?.refreshCodexCliStatus();
      updateConnectionsView();
      vscode.window.showInformationMessage(
        "Codex Remote: Codex CLI 상태를 다시 확인했습니다."
      );
    }
  );

  const disconnectRelayCommand = vscode.commands.registerCommand(
    "codexRemote.disconnectRelay",
    async () => {
      if (!relayClient || !relayClient.isConnectedToSession()) {
        vscode.window.showInformationMessage(
          "Codex Remote: 현재 연결된 릴레이 세션이 없습니다."
        );
        updateConnectionsView();
        return;
      }

      const previousSessionId = relayClient.getSessionId();
      if (!previousSessionId) {
        vscode.window.showInformationMessage(
          "Codex Remote: 세션 ID를 확인할 수 없습니다."
        );
        return;
      }

      const confirmLabel = "세션 종료";
      const confirmed = await vscode.window.showWarningMessage(
        `세션 ${previousSessionId}을(를) 종료합니다. 모바일/PC 연결이 모두 끊기며, 같은 세션 ID를 다시 시작할 수 있습니다.`,
        { modal: true },
        confirmLabel
      );
      if (confirmed !== confirmLabel) {
        return;
      }

      const result = await relayClient.clearCurrentSession(false);
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] [Relay] 수동으로 릴레이 세션 종료${
          previousSessionId ? ` (세션: ${previousSessionId})` : ""
        }`
      );
      outputChannel.show();
      if (statusBarManager) {
        statusBarManager.refresh();
      }
      updateConnectionsView();

      if (result.success) {
        vscode.window.showInformationMessage(
          `Codex Remote: 세션 ${previousSessionId}을(를) 종료했습니다.`
        );
      } else {
        vscode.window.showErrorMessage(
          `Codex Remote: 세션 종료 실패 - ${result.error ?? "Unknown error"}`
        );
      }
    }
  );

  const clearRelaySessionCommand = vscode.commands.registerCommand(
    "codexRemote.clearRelaySession",
    async () => {
      if (!relayClient || !relayClient.isConnectedToSession()) {
        vscode.window.showInformationMessage(
          "Codex Remote: 현재 연결된 릴레이 세션이 없습니다."
        );
        updateConnectionsView();
        return;
      }

      const sessionId = relayClient.getSessionId();
      if (!sessionId) {
        vscode.window.showInformationMessage(
          "Codex Remote: 세션 ID를 확인할 수 없습니다."
        );
        return;
      }

      const confirmLabel = "세션 클리어";
      const confirmed = await vscode.window.showWarningMessage(
        `세션 ${sessionId}의 모바일 목록/대기 메시지/trace 로그를 정리합니다. PC 연결은 유지됩니다.`,
        { modal: true },
        confirmLabel
      );
      if (confirmed !== confirmLabel) {
        return;
      }

      const result = await relayClient.clearCurrentSession(true);
      outputChannel.show();
      if (statusBarManager) {
        statusBarManager.refresh();
      }
      updateConnectionsView();

      if (result.success) {
        vscode.window.showInformationMessage(
          `Codex Remote: 세션 ${sessionId}을(를) 클리어했습니다.`
        );
      } else {
        vscode.window.showErrorMessage(
          `Codex Remote: 세션 클리어 실패 - ${result.error ?? "Unknown error"}`
        );
      }
    }
  );

  const startCommand = vscode.commands.registerCommand(
    "codexRemote.start",
    () => {
      if (wsServer && !wsServer.isRunning()) {
        wsServer
          .start()
          .then(() => {
            if (statusBarManager) {
              statusBarManager.update(false);
            }
            updateConnectionsView();
            vscode.window.showInformationMessage(
              `Codex Remote server started on port ${CONFIG.WEBSOCKET_PORT}`
            );
          })
          .catch((error) => {
            const errorMsg =
              error instanceof Error ? error.message : "Unknown error";
            outputChannel.appendLine(
              `[${new Date().toLocaleTimeString()}] ❌ Failed to start WebSocket server: ${errorMsg}`
            );
            vscode.window.showErrorMessage(
              `Codex Remote: Server start failed - ${errorMsg}`
            );
            if (statusBarManager) {
              statusBarManager.update(false);
            }
            updateConnectionsView();
          });
      } else {
        vscode.window.showInformationMessage(
          "Codex Remote server is already running"
        );
      }
    }
  );

  const stopCommand = vscode.commands.registerCommand(
    "codexRemote.stop",
    () => {
      if (wsServer && wsServer.isRunning()) {
        wsServer.stop();
        if (statusBarManager) {
          statusBarManager.update(false);
        }
        updateConnectionsView();
        vscode.window.showInformationMessage("Codex Remote server stopped");
      } else {
        vscode.window.showInformationMessage(
          "Codex Remote server is not running"
        );
      }
    }
  );

  const toggleCommand = vscode.commands.registerCommand(
    "codexRemote.toggle",
    () => {
      if (wsServer) {
        if (wsServer.isRunning()) {
          wsServer.stop();
          if (statusBarManager) {
            statusBarManager.update(false);
          }
          updateConnectionsView();
        } else {
          wsServer
            .start()
            .then(() => {
              if (statusBarManager) {
                statusBarManager.update(false);
              }
              updateConnectionsView();
            })
            .catch((error) => {
              const errorMsg =
                error instanceof Error ? error.message : "Unknown error";
              outputChannel.appendLine(
                `[${new Date().toLocaleTimeString()}] ❌ Failed to start WebSocket server: ${errorMsg}`
              );
              vscode.window.showErrorMessage(
                `Codex Remote: Server start failed - ${errorMsg}`
              );
              if (statusBarManager) {
                statusBarManager.update(false);
              }
              updateConnectionsView();
            });
        }
      }
    }
  );

  /** 연결 정보 뷰 (상태바 클릭 시 표시 - Git Graph처럼) */
  const checkRelayServerCommand = vscode.commands.registerCommand(
    "codexRemote.checkRelayServer",
    async () => {
      if (relayClient) {
        await relayClient.checkServerStatus();
        outputChannel.show();
      } else {
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] [Relay] ⚠️ Relay client not initialized`
        );
        outputChannel.show();
      }
    }
  );

  const connectToRelaySessionByIdCommand = vscode.commands.registerCommand(
    "codexRemote.connectToRelaySessionById",
    async () => {
      if (!relayClient) {
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] [Relay] ⚠️ Relay client not initialized`
        );
        outputChannel.show();
        return;
      }
      const sid = await vscode.window.showInputBox({
        title: "Codex Remote: 릴레이 세션 ID",
        prompt: "모바일에서 연결한 세션 ID 6자 입력 (예: 3ZUESK)",
        placeHolder: "3ZUESK",
        validateInput: (value) => {
          const v = value?.trim().toUpperCase() ?? "";
          if (!v) return "세션 ID를 입력하세요.";
          if (!/^[A-Z0-9]{6}$/.test(v)) return "6자 영숫자 (예: 3ZUESK)";
          return null;
        },
      });
      if (!sid) return;
      const pin = await vscode.window.showInputBox({
        title: "Codex Remote: PIN (선택)",
        prompt:
          "PC가 이 세션에 PIN을 설정했다면 4~6자리 PIN 입력. (설정 안 했으면 공백)",
        placeHolder: "1234",
        password: true,
        validateInput: (v) => {
          const t = (v ?? "").trim();
          if (!t) return null;
          if (!/^\d{4,6}$/.test(t)) return "4~6자리 숫자";
          return null;
        },
      });
      const pinToUse = pin != null && pin.trim() ? pin.trim() : undefined;
      await relayClient.connectToSessionById(sid, pinToUse);
      outputChannel.show();
    }
  );

  const setRelaySessionIdCommand = vscode.commands.registerCommand(
    "codexRemote.setRelaySessionId",
    async () => {
      const sid = await vscode.window.showInputBox({
        title: "Codex Remote: 릴레이 세션 ID 설정",
        prompt:
          "다음 릴레이 시작 시 사용할 세션 ID 6자 (모바일에서 같은 ID로 연결)",
        placeHolder: "3ZUESK",
        value: context.globalState.get<string>("codexRemote.sessionId") ?? "",
        validateInput: (value) => {
          const v = (value ?? "").trim().toUpperCase();
          if (!v) return "세션 ID를 입력하세요.";
          if (!/^[A-Z0-9]{6}$/.test(v)) return "6자 영숫자 (예: 3ZUESK)";
          return null;
        },
      });
      if (sid) {
        await context.globalState.update(
          "codexRemote.sessionId",
          sid.trim().toUpperCase()
        );
        vscode.window.showInformationMessage(
          `Codex Remote: 세션 ID가 ${sid
            .trim()
            .toUpperCase()}로 저장되었습니다. (다음 릴레이 시작 시 사용)`
        );
      }
    }
  );

  const showConnectionsCommand = vscode.commands.registerCommand(
    "codexRemote.showConnections",
    async () => {
      if (connectionsPanel) {
        connectionsPanel.reveal(vscode.ViewColumn.One);
        updateConnectionsView();
        return;
      }
      const serverStatus = wsServer
        ? wsServer.getConnectionStatus()
        : {
            isRunning: false,
            clientCount: 0,
            port: null as number | null,
          };
      const relaySessionId =
        relayClient?.isConnectedToSession() === true
          ? relayClient.getSessionId()
          : null;
      const localClientIds = wsServer ? wsServer.getClientIds() : [];

      // 릴레이 서버 저장소 정보 조회 (Supabase / Upstash Redis)
      try {
        const res = await fetch(`${getRelayServerUrl()}/api/store`);
        const json = (await res.json()) as {
          success?: boolean;
          data?: { storeLabel?: string };
        };
        if (json?.success && json?.data?.storeLabel) {
          lastRelayStoreLabel = json.data.storeLabel;
        }
      } catch {
        lastRelayStoreLabel = null;
      }

      const html = getConnectionsViewHtml({
        serverRunning: serverStatus.isRunning,
        serverPort: serverStatus.port,
        relaySessionId,
        relayStoreLabel: lastRelayStoreLabel,
        relayServerUrl: getRelayServerUrl(),
        localClientIds,
        codexCliStatus: getCurrentCodexCliStatus(),
        extensionVersion: extensionDisplayVersion,
        iosAppStoreUrl: getStoreUrlSetting("iosAppStoreUrl"),
        androidPlayStoreUrl: getStoreUrlSetting("androidPlayStoreUrl"),
      });

      const panel = vscode.window.createWebviewPanel(
        "codexRemote.connections",
        "Codex Remote - 연결 정보",
        vscode.ViewColumn.One,
        { enableScripts: true }
      );
      panel.webview.html = html;
      connectionsPanel = panel;
      panel.webview.onDidReceiveMessage(async (message) => {
        if (message?.type !== "panelAction") {
          return;
        }

        switch (message.action) {
          case "openGuide":
            await vscode.commands.executeCommand("codexRemote.openGuide");
            break;
          case "showOutput":
            await vscode.commands.executeCommand("codexRemote.showOutput");
            break;
          case "refreshCodexStatus":
            await vscode.commands.executeCommand(
              "codexRemote.refreshCodexStatus"
            );
            break;
          case "openProjectSite":
            await vscode.env.openExternal(
              vscode.Uri.parse("https://codex-remote.jaloveeye.com/")
            );
            break;
          case "openIosAppStore": {
            const storeUrl = getStoreUrlSetting("iosAppStoreUrl");
            if (storeUrl == null) {
              vscode.window.showInformationMessage(
                "iOS 앱스토어 링크가 아직 등록되지 않았습니다."
              );
              break;
            }
            await vscode.env.openExternal(vscode.Uri.parse(storeUrl));
            break;
          }
          case "openAndroidPlayStore": {
            const storeUrl = getStoreUrlSetting("androidPlayStoreUrl");
            if (storeUrl == null) {
              vscode.window.showInformationMessage(
                "Android 앱스토어 링크가 아직 등록되지 않았습니다."
              );
              break;
            }
            await vscode.env.openExternal(vscode.Uri.parse(storeUrl));
            break;
          }
          case "disconnectRelay":
            await vscode.commands.executeCommand("codexRemote.disconnectRelay");
            break;
          case "clearRelaySession":
            await vscode.commands.executeCommand("codexRemote.clearRelaySession");
            break;
          default:
            break;
        }
      });
      if (connectionsPanelRefreshInterval) {
        clearInterval(connectionsPanelRefreshInterval);
      }
      connectionsPanelRefreshInterval = setInterval(() => {
        updateConnectionsView();
      }, 2000);
      panel.onDidDispose(() => {
        connectionsPanel = null;
        if (connectionsPanelRefreshInterval) {
          clearInterval(connectionsPanelRefreshInterval);
          connectionsPanelRefreshInterval = null;
        }
      });
    }
  );

  /** 상태줄 클릭: 릴레이 비활성 시 세션 ID·PIN 입력 후 연결, 활성 시 연결 정보 패널 */
  const statusBarClickCommand = vscode.commands.registerCommand(
    "codexRemote.statusBarClick",
    async () => {
      const relayConnected =
        relayClient != null && relayClient.isConnectedToSession();
      if (relayConnected) {
        vscode.commands.executeCommand("codexRemote.showConnections");
        return;
      }
      if (!relayClient) {
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] [Relay] ⚠️ Relay client not initialized`
        );
        outputChannel.show();
        return;
      }
      const sid = await vscode.window.showInputBox({
        title: "Codex Remote: 릴레이 세션 ID",
        prompt:
          "모바일에서 연결할 세션 ID 6자 입력 (같은 ID를 모바일에서 입력하면 연결됩니다)",
        placeHolder: "3ZUESK",
        value: context.globalState.get<string>("codexRemote.sessionId") ?? "",
        validateInput: (value) => {
          const v = (value ?? "").trim().toUpperCase();
          if (!v) return "세션 ID를 입력하세요.";
          if (!/^[A-Z0-9]{6}$/.test(v)) return "6자 영숫자 (예: 3ZUESK)";
          return null;
        },
      });
      if (!sid) return;
      const sidTrimmed = sid.trim().toUpperCase();
      await context.globalState.update("codexRemote.sessionId", sidTrimmed);

      const pin = await vscode.window.showInputBox({
        title: "Codex Remote: PIN (선택)",
        prompt:
          "4~6자리 PIN을 설정하면 모바일에서 이 PIN을 알아야만 접속할 수 있습니다. (공백으로 두면 PIN 없음)",
        placeHolder: "1234",
        password: true,
        validateInput: (v) => {
          const t = (v ?? "").trim();
          if (!t) return null;
          if (!/^\d{4,6}$/.test(t)) return "4~6자리 숫자";
          return null;
        },
      });
      const pinToUse = pin != null && pin.trim() ? pin.trim() : undefined;
      try {
        await relayClient.start(sidTrimmed, pinToUse);
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] ✅ Relay 연결됨 - 세션: ${sidTrimmed}${
            pinToUse ? " (PIN 설정됨)" : ""
          }`
        );
        outputChannel.show();
        if (statusBarManager) statusBarManager.refresh();
        updateConnectionsView();
        vscode.window.showInformationMessage(
          `Codex Remote: 세션 ${sidTrimmed}에 연결되었습니다.`
        );
      } catch (error) {
        const errorMsg =
          error instanceof Error ? error.message : "Unknown error";
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] ⚠️ 릴레이 연결 실패: ${errorMsg}`
        );
        outputChannel.show();
        vscode.window.showErrorMessage(
          `Codex Remote: 릴레이 연결 실패 - ${errorMsg}`
        );
      }
    }
  );

  context.subscriptions.push(
    openGuideCommand,
    showOutputCommand,
    refreshCodexStatusCommand,
    disconnectRelayCommand,
    clearRelaySessionCommand,
    startCommand,
    stopCommand,
    toggleCommand,
    checkRelayServerCommand,
    connectToRelaySessionByIdCommand,
    setRelaySessionIdCommand,
    showConnectionsCommand,
    statusBarClickCommand
  );

  // Initialize relay client
  outputChannel.appendLine(
    `[${new Date().toLocaleTimeString()}] 🔄 Creating RelayClient instance...`
  );
  outputChannel.appendLine(
    `[${new Date().toLocaleTimeString()}] 🔄 Relay Server URL: ${
      getRelayServerUrl()
    }`
  );
  relayClient = new RelayClient(getRelayServerUrl(), outputChannel);
  outputChannel.appendLine(
    `[${new Date().toLocaleTimeString()}] ✅ RelayClient instance created`
  );

  // Set relay client in WebSocket server for automatic message forwarding
  if (wsServer && relayClient) {
    wsServer.setRelayClient(relayClient);
    outputChannel.appendLine(
      `[${new Date().toLocaleTimeString()}] ✅ Relay client set in WebSocket server`
    );
  }
  // 릴레이 모드일 때 챗 히스토리 저장 시 relaySessionId 포함하도록 getter 설정
  if (commandHandler) {
    commandHandler.setGetRelaySessionId(
      () => relayClient?.getSessionId() ?? null
    );
  }
  // Status bar: reflect relay connection (클라이언트 접속 시 "Connected" 표시)
  if (statusBarManager && relayClient) {
    statusBarManager.setRelayClient(relayClient);
    relayClient.setOnSessionConnected(() => {
      if (statusBarManager) statusBarManager.refresh();
      updateConnectionsView(); // 연결 정보 패널이 열려 있으면 즉시 갱신
      const sessionId = relayClient?.getSessionId();
      if (sessionId) {
        context.globalState.update("codexRemote.sessionId", sessionId);
      }
      vscode.window.showInformationMessage(
        sessionId != null
          ? `Codex Remote: 익스텐션은 릴레이 서버를 통해 세션 ${sessionId}에 접속했습니다.`
          : "Codex Remote: 익스텐션은 릴레이 서버에 연결되었습니다."
      );
    });
    // 복수 세션 발견 시 사용자가 선택할 수 있도록 QuickPick 표시
    relayClient.setOnSessionsDiscovered(async (sessions) => {
      const picked = await vscode.window.showQuickPick(
        sessions.map((s) => ({
          label: s.sessionId,
          description: "세션 ID",
        })),
        {
          title: "Codex Remote: 연결할 릴레이 세션 선택",
          placeHolder:
            "대기 중인 세션이 여러 개입니다. 모바일에서 연결한 세션을 선택하세요.",
        }
      );
      return picked?.label ?? null;
    });
  }
  // 상태바 즉시 표시 (서버/릴레이 시작 전에 한 번 그려서 늦게 뜨는 현상 완화)
  if (statusBarManager) {
    statusBarManager.refresh();
    statusBarManager.show();
  }

  // Set up message forwarding: Relay Server -> Extension WebSocket
  relayClient.setOnMessage((message: string) => {
    outputChannel.appendLine(
      `[${new Date().toLocaleTimeString()}] === RELAY: 메시지 수신됨 (길이: ${
        message.length
      }) ===`
    );
    // Mark message as from relay to prevent loop
    try {
      const parsed = JSON.parse(message);
      parsed.source = "relay";
      // clientId가 없으면 'relay'로 설정
      if (!parsed.clientId) {
        parsed.clientId = "relay-client";
      }
      const relayMessage = JSON.stringify(parsed);

      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] 📥 Message from relay, forwarding to command handler... (type: ${
          parsed.type
        })`
      );
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] 📋 Relay message: ${relayMessage.substring(
          0,
          300
        )}`
      );

      // Directly trigger the message handlers to process the command
      // This is the same handler that processes WebSocket client messages
      if (wsServer) {
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] 🔄 Calling triggerMessageHandlers...`
        );
        wsServer.triggerMessageHandlers(relayMessage);
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] ✅ triggerMessageHandlers called`
        );
      } else {
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] ⚠️ WebSocket server is null - cannot process relay message`
        );
      }
    } catch (error) {
      // If message is not JSON, send as-is but mark source
      const relayMessage = JSON.stringify({
        type: "message",
        data: message,
        source: "relay",
        clientId: "relay-client",
      });
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] 📥 Message from relay (non-JSON), forwarding to command handler...`
      );
      if (wsServer) {
        wsServer.triggerMessageHandlers(relayMessage);
      } else {
        outputChannel.appendLine(
          `[${new Date().toLocaleTimeString()}] ⚠️ WebSocket server is null - cannot process relay message`
        );
      }
    }
  });

  // Auto start WebSocket server only (릴레이는 상태줄 클릭 시 세션 ID·PIN 입력 후 연결)
  wsServer
    .start()
    .then(async () => {
      if (statusBarManager) {
        statusBarManager.update(false); // Client not connected yet
      }
      updateConnectionsView();
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] [Relay] 릴레이 비활성. 상태줄 'Codex Remote' 클릭 → 세션 ID·PIN 입력하여 연결`
      );
    })
    .catch((error) => {
      const errorMsg = error instanceof Error ? error.message : "Unknown error";
      outputChannel.appendLine(
        `[${new Date().toLocaleTimeString()}] ❌ Failed to start WebSocket server: ${errorMsg}`
      );
      vscode.window.showErrorMessage(
        `Codex Remote: Server start failed - ${errorMsg}`
      );
      if (statusBarManager) {
        statusBarManager.update(false);
      }
    });

  if (statusBarManager) {
    statusBarManager.show();
  }
}

export function deactivate() {
  if (connectionsPanelRefreshInterval) {
    clearInterval(connectionsPanelRefreshInterval);
    connectionsPanelRefreshInterval = null;
  }

  if (relayClient) {
    relayClient.stop();
    relayClient = null;
  }


  if (wsServer) {
    wsServer.stop();
    wsServer = null;
  }

  if (commandHandler) {
    commandHandler.dispose();
    commandHandler = null;
  }

  commandRouter = null;
  statusBarManager = null;
}
