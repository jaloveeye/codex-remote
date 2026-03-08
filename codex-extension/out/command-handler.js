"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommandHandler = void 0;
const vscode = __importStar(require("vscode"));
const path = __importStar(require("path"));
const codex_handler_1 = require("./codex-handler");
const config_1 = require("./config");
class CommandHandler {
    constructor(outputChannel, wsServer, _useLegacyMode = false) {
        this.outputChannel = null;
        this.wsServer = null;
        this.codexHandler = null;
        this.outputChannel = outputChannel || null;
        this.wsServer = wsServer || null;
        const workspaceFolders = vscode.workspace.workspaceFolders;
        const workspaceRoot = workspaceFolders && workspaceFolders.length > 0
            ? workspaceFolders[0].uri.fsPath
            : undefined;
        this.codexHandler = new codex_handler_1.CodexHandler(outputChannel, wsServer, workspaceRoot);
        this.log("[Codex Remote] Backend mode enabled (codex app-server)");
    }
    notifyIfCodexCliUnavailable() {
        this.codexHandler?.notifyIfCodexCliUnavailable();
    }
    refreshCodexCliStatus() {
        this.codexHandler?.refreshCodexCliStatus();
    }
    setOnCodexCliStatusChange(callback) {
        this.codexHandler?.setOnCodexCliStatusChange(callback);
    }
    getCodexCliStatus() {
        return this.codexHandler?.getCodexCliStatus() ?? null;
    }
    /**
     * Backward-compatible no-op. Chat history is now maintained by CodexHandler only.
     */
    setGetRelaySessionId(_getter) {
        // no-op
    }
    log(message) {
        const timestamp = new Date().toLocaleTimeString();
        const logMessage = `[${timestamp}] ${message}`;
        if (this.outputChannel) {
            this.outputChannel.appendLine(logMessage);
        }
        console.log(logMessage);
    }
    logError(message, error) {
        const timestamp = new Date().toLocaleTimeString();
        const logMessage = `[${timestamp}] ERROR: ${message}${error ? ` - ${error}` : ""}`;
        if (this.outputChannel) {
            this.outputChannel.appendLine(logMessage);
        }
        console.error(logMessage);
    }
    isLikelyCommand(text) {
        if (!text || text.length === 0) {
            return false;
        }
        if (!text.includes(" ") && !text.includes("	")) {
            for (const pattern of config_1.CONFIG.COMMAND_PATTERNS) {
                if (pattern.test(text)) {
                    return true;
                }
            }
            return false;
        }
        for (const pattern of config_1.CONFIG.PLAIN_TEXT_PATTERNS) {
            if (pattern.test(text.trim())) {
                return false;
            }
        }
        return true;
    }
    async insertText(text) {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            throw new Error("No active editor. Please open a file in VS Code.");
        }
        const success = await editor.edit((editBuilder) => {
            const position = editor.selection.active;
            editBuilder.insert(position, text);
        });
        if (!success) {
            throw new Error("Failed to insert text. The editor may be read-only or the edit was rejected.");
        }
    }
    async insertToTerminal(text, execute = false) {
        this.log(`[Codex Remote] insertToTerminal called - textLength: ${text.length}, execute: ${execute}`);
        this.log(`[Codex Remote] Text content: "${text.substring(0, 100)}${text.length > 100 ? "..." : ""}"`);
        try {
            const workspaceFolders = vscode.workspace.workspaceFolders;
            let outputFile = null;
            if (workspaceFolders && workspaceFolders.length > 0) {
                const workspaceRoot = workspaceFolders[0].uri.fsPath;
                outputFile = path.join(workspaceRoot, config_1.CONFIG.TERMINAL_OUTPUT_FILE);
            }
            let terminal = vscode.window.activeTerminal;
            this.log(`[Codex Remote] Active terminal: ${terminal ? terminal.name : "null"}`);
            if (!terminal) {
                this.log("[Codex Remote] No active terminal, creating new terminal");
                terminal = vscode.window.createTerminal("Codex Remote");
                terminal.show(true);
                await new Promise((resolve) => setTimeout(resolve, config_1.CONFIG.TERMINAL_ACTIVATION_DELAY));
            }
            else {
                terminal.show(true);
                await new Promise((resolve) => setTimeout(resolve, config_1.CONFIG.TERMINAL_FOCUS_DELAY));
            }
            await vscode.commands.executeCommand("workbench.action.terminal.focus");
            await new Promise((resolve) => setTimeout(resolve, config_1.CONFIG.TERMINAL_FOCUS_DELAY));
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
                await new Promise((resolve) => setTimeout(resolve, config_1.CONFIG.TERMINAL_EXECUTION_DELAY));
                terminal.sendText("\n", false);
                if (this.wsServer) {
                    this.wsServer.send(JSON.stringify({
                        type: "user_message",
                        text,
                        timestamp: new Date().toISOString(),
                    }));
                }
                return;
            }
            terminal.sendText(text, false);
        }
        catch (error) {
            const errorMsg = error instanceof Error ? error.message : "Unknown error";
            this.logError(`[Codex Remote] Error in insertToTerminal: ${errorMsg}`);
            throw new Error(`터미널 입력 실패: ${errorMsg}`);
        }
    }
    async insertToPrompt(text, execute = false, clientId, newSession = false, agentMode = "auto", senderDeviceId, model, reasoningEffort, useIdeContext, useFlatMode) {
        this.log(`[Codex Remote] insertToPrompt called - textLength: ${text.length}, execute: ${execute}, clientId: ${clientId || "none"}, newSession: ${newSession}, agentMode: ${agentMode}, senderDeviceId: ${senderDeviceId || "none"}, model: ${model || "auto"}, reasoningEffort: ${reasoningEffort || "auto"}, useIdeContext: ${useIdeContext ?? false}, useFlatMode: ${useFlatMode ?? false}`);
        if (!this.codexHandler) {
            throw new Error("Codex handler is not initialized.");
        }
        await this.codexHandler.sendPrompt(text, execute, clientId, newSession, agentMode, senderDeviceId, model, reasoningEffort, useIdeContext, useFlatMode);
    }
    async executeCommand(command, ...args) {
        return await vscode.commands.executeCommand(command, ...args);
    }
    async resolveCodexServerRequestResponse(requestId, method, response) {
        if (!this.codexHandler) {
            throw new Error("Codex handler is not initialized.");
        }
        this.codexHandler.resolveRemoteServerRequestResponse(requestId, method, response);
    }
    async getActiveFile() {
        const editor = vscode.window.activeTextEditor;
        if (!editor || !editor.document) {
            return null;
        }
        return {
            path: editor.document.fileName,
            content: editor.document.getText(),
        };
    }
    async saveFile() {
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
    async getAIResponse() {
        if (!this.codexHandler) {
            return "";
        }
        const history = this.codexHandler.getChatHistory(undefined, undefined, undefined, 1);
        return history.length > 0 ? history[history.length - 1].assistantResponse : "";
    }
    async getSessionInfo(clientId) {
        if (!this.codexHandler) {
            return { currentSessionId: null, clientId: clientId || null, hasSession: false };
        }
        return this.codexHandler.getSessionInfo(clientId);
    }
    async getChatHistory(clientId, sessionId, relaySessionId, limit = 50) {
        const entries = this.codexHandler
            ? this.codexHandler.getChatHistory(clientId, sessionId, relaySessionId, limit)
            : [];
        return { entries };
    }
    async getRuntimeCapabilities() {
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
    async stopPrompt() {
        this.log("[Codex Remote] stopPrompt called");
        if (!this.codexHandler) {
            return { success: true };
        }
        return this.codexHandler.stopPrompt();
    }
    async executeAction(action) {
        const candidates = [action, `workbench.action.${action}`, `editor.action.${action}`];
        for (const command of candidates) {
            try {
                await vscode.commands.executeCommand(command);
                return { success: true };
            }
            catch {
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
exports.CommandHandler = CommandHandler;
//# sourceMappingURL=command-handler.js.map