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
exports.CodexHandler = void 0;
const child_process = __importStar(require("child_process"));
const readline = __importStar(require("readline"));
const vscode = __importStar(require("vscode"));
const config_1 = require("./config");
const streaming_text_logic_1 = require("./streaming_text_logic");
const runtime_capability_policy_1 = require("./runtime_capability_policy");
class CodexHandler {
    constructor(outputChannel, wsServer, workspaceRoot) {
        this.outputChannel = null;
        this.wsServer = null;
        this.workspaceRoot = null;
        this.codexProcess = null;
        this.stdoutReader = null;
        this.stderrReader = null;
        this.nextRequestId = 1;
        this.pendingRequests = new Map();
        this.pendingRemoteServerRequests = new Map();
        this.initPromise = null;
        this.initialized = false;
        this.clientThreads = new Map();
        this.threadToClient = new Map();
        this.clientTurnStates = new Map();
        this.turnToClient = new Map();
        this.chatHistory = [];
        this.pendingHistoryByClient = new Map();
        this.recentStderrLines = [];
        this.shownSetupDiagnostics = new Set();
        this.hasConfirmedCodexCommand = false;
        this.codexCliStatus = {
            state: "unknown",
            severity: "info",
            summary: "아직 확인되지 않음",
            checkedAt: null,
            command: config_1.CONFIG.CODEX_COMMAND,
        };
        this.onCodexCliStatusChange = null;
        this.runtimeCapabilitiesCache = new runtime_capability_policy_1.AsyncSingleFlightCache(15000);
        this.outputChannel = outputChannel || null;
        this.wsServer = wsServer || null;
        this.workspaceRoot = workspaceRoot || null;
    }
    log(message, sendToClient = false) {
        const timestamp = new Date().toLocaleTimeString();
        const formatted = `[${timestamp}] [CODEX] ${message}`;
        if (this.outputChannel) {
            this.outputChannel.appendLine(formatted);
        }
        console.log(formatted);
        if (sendToClient && this.wsServer) {
            this.wsServer.broadcast(JSON.stringify({
                type: "log",
                level: "info",
                message: `[CODEX] ${message}`,
                timestamp: new Date().toISOString(),
                source: "codex",
            }));
        }
    }
    logError(message, error) {
        const timestamp = new Date().toLocaleTimeString();
        const errorText = error instanceof Error ? error.message : String(error ?? "");
        const formatted = `[${timestamp}] [CODEX] ERROR: ${message}${errorText ? ` - ${errorText}` : ""}`;
        if (this.outputChannel) {
            this.outputChannel.appendLine(formatted);
        }
        console.error(formatted);
        if (this.wsServer) {
            this.wsServer.broadcast(JSON.stringify({
                type: "log",
                level: "error",
                message: `[CODEX] ${message}`,
                timestamp: new Date().toISOString(),
                source: "codex",
                error: errorText || undefined,
            }));
        }
    }
    setCodexCliStatus(state, severity, summary) {
        this.codexCliStatus = {
            state,
            severity,
            summary,
            checkedAt: new Date().toISOString(),
            command: config_1.CONFIG.CODEX_COMMAND,
        };
        if (this.onCodexCliStatusChange) {
            this.onCodexCliStatusChange();
        }
    }
    rememberStderrLine(line) {
        const trimmed = line.trim();
        if (!trimmed)
            return;
        this.recentStderrLines.push(trimmed);
        if (this.recentStderrLines.length > 12) {
            this.recentStderrLines.shift();
        }
    }
    getDiagnosticContext(source) {
        const parts = [];
        const sourceText = source instanceof Error
            ? source.message
            : typeof source === "string"
                ? source
                : source != null
                    ? String(source)
                    : "";
        if (sourceText.trim().length > 0) {
            parts.push(sourceText.trim());
        }
        const stderrText = this.recentStderrLines.join("\n").trim();
        if (stderrText.length > 0) {
            parts.push(stderrText);
        }
        return parts.join("\n");
    }
    createSetupDiagnostic(source) {
        const raw = this.getDiagnosticContext(source);
        if (!raw)
            return null;
        const normalized = raw.toLowerCase();
        const commandName = config_1.CONFIG.CODEX_COMMAND.toLowerCase();
        const mentionsCommand = normalized.includes(commandName);
        if (normalized.includes(`spawn ${commandName} enoent`) ||
            normalized.includes(`spawnsync ${commandName} enoent`) ||
            (mentionsCommand && normalized.includes("enoent")) ||
            normalized.includes(`failed to run ${commandName} --version`)) {
            return {
                issue: "cli-unavailable",
                severity: "error",
                message: `Codex CLI를 실행할 수 없습니다. 터미널에서 \`${config_1.CONFIG.CODEX_COMMAND} --version\`이 동작하는지 확인하고 설치 후 VS Code를 다시 시작하세요.`,
            };
        }
        const authPatterns = [
            /\bnot logged in\b/i,
            /\blogin required\b/i,
            /\bplease log(?:\s|-)?in\b/i,
            /\bcodex auth login\b/i,
            /\bauthentication\b/i,
            /\bunauthorized\b/i,
            /\b401\b/i,
            /\bsign in\b/i,
            /\bauth required\b/i,
        ];
        if (authPatterns.some((pattern) => pattern.test(raw))) {
            return {
                issue: "auth-required",
                severity: "warning",
                message: `Codex CLI 로그인이 필요합니다. 터미널에서 \`${config_1.CONFIG.CODEX_COMMAND} auth login\`을 실행한 뒤 다시 시도하세요.`,
            };
        }
        if (normalized.includes("json-rpc timeout: initialize") ||
            normalized.includes("codex process closed") ||
            normalized.includes("failed to obtain threadid from codex app-server")) {
            return {
                issue: "startup-failed",
                severity: "warning",
                message: "Codex app-server를 시작하지 못했습니다. Codex CLI 설치 또는 로그인 상태를 확인한 뒤 다시 시도하세요.",
            };
        }
        return null;
    }
    notifySetupDiagnostic(source) {
        const diagnostic = this.createSetupDiagnostic(source);
        if (!diagnostic)
            return;
        this.setCodexCliStatus(diagnostic.issue, diagnostic.severity, diagnostic.message);
        if (this.shownSetupDiagnostics.has(diagnostic.issue))
            return;
        this.shownSetupDiagnostics.add(diagnostic.issue);
        const actionLabel = "출력 보기";
        const message = `Codex Remote: ${diagnostic.message}`;
        const showMessage = diagnostic.severity === "error"
            ? vscode.window.showErrorMessage
            : vscode.window.showWarningMessage;
        void showMessage(message, actionLabel).then((selected) => {
            if (selected === actionLabel) {
                this.outputChannel?.show(true);
            }
        });
    }
    ensureCodexCommandAvailable() {
        if (this.hasConfirmedCodexCommand) {
            return;
        }
        const cwd = this.workspaceRoot || process.cwd();
        const probe = child_process.spawnSync(config_1.CONFIG.CODEX_COMMAND, ["--version"], {
            cwd,
            shell: false,
            env: {
                ...process.env,
            },
            encoding: "utf8",
            timeout: 5000,
        });
        if (probe.error) {
            this.notifySetupDiagnostic(`Failed to run ${config_1.CONFIG.CODEX_COMMAND} --version: ${probe.error.message}`);
            throw probe.error;
        }
        if ((probe.status ?? 1) !== 0) {
            const details = [probe.stdout, probe.stderr]
                .filter((value) => typeof value === "string")
                .join("\n")
                .trim();
            const failureMessage = details
                ? `Failed to run ${config_1.CONFIG.CODEX_COMMAND} --version: ${details}`
                : `Failed to run ${config_1.CONFIG.CODEX_COMMAND} --version`;
            this.notifySetupDiagnostic(failureMessage);
            throw new Error(failureMessage);
        }
        this.hasConfirmedCodexCommand = true;
        this.shownSetupDiagnostics.delete("cli-unavailable");
        if (this.codexCliStatus.state !== "ready") {
            this.setCodexCliStatus("cli-available", "info", `Codex CLI 실행 가능 (\`${config_1.CONFIG.CODEX_COMMAND} --version\` 확인됨)`);
        }
    }
    notifyIfCodexCliUnavailable() {
        try {
            this.ensureCodexCommandAvailable();
        }
        catch (error) {
            this.notifySetupDiagnostic(error);
        }
    }
    refreshCodexCliStatus() {
        this.hasConfirmedCodexCommand = false;
        try {
            this.ensureCodexCommandAvailable();
        }
        catch (error) {
            this.notifySetupDiagnostic(error);
        }
    }
    setOnCodexCliStatusChange(callback) {
        this.onCodexCliStatusChange = callback;
    }
    getCodexCliStatus() {
        return { ...this.codexCliStatus };
    }
    getClientKey(clientId) {
        return clientId || "global";
    }
    safeString(value) {
        if (typeof value === "string") {
            return value;
        }
        if (typeof value === "number" || typeof value === "boolean") {
            return String(value);
        }
        return "";
    }
    asObject(value) {
        if (value && typeof value === "object" && !Array.isArray(value)) {
            return value;
        }
        return null;
    }
    getNested(value, ...keys) {
        let current = value;
        for (const key of keys) {
            const currentObject = this.asObject(current);
            if (!currentObject)
                return null;
            current = currentObject[key];
            if (current === undefined || current === null)
                return null;
        }
        return current;
    }
    extractText(value, depth = 0, preserveWhitespace = false) {
        if (depth > 6 || value === null || value === undefined)
            return "";
        if (typeof value === "string")
            return value;
        if (typeof value === "number" || typeof value === "boolean")
            return String(value);
        if (Array.isArray(value)) {
            const parts = value.map((item) => this.extractText(item, depth + 1, preserveWhitespace));
            return (0, streaming_text_logic_1.combineExtractedParts)(parts);
        }
        const objectValue = this.asObject(value);
        if (!objectValue)
            return "";
        const prioritizedKeys = [
            "delta",
            "text",
            "content",
            "message",
            "result",
            "outputText",
            "finalText",
            "value",
            "items",
            "item",
        ];
        for (const key of prioritizedKeys) {
            if (key in objectValue) {
                const nestedText = this.extractText(objectValue[key], depth + 1, preserveWhitespace);
                if (preserveWhitespace ? nestedText.length > 0 : nestedText.trim().length > 0) {
                    return nestedText;
                }
            }
        }
        return "";
    }
    extractCompletionText(value, depth = 0) {
        if (depth > 6 || value === null || value === undefined)
            return "";
        if (typeof value === "string")
            return value;
        if (typeof value === "number" || typeof value === "boolean")
            return String(value);
        if (Array.isArray(value)) {
            const parts = value.map((item) => this.extractCompletionText(item, depth + 1));
            return (0, streaming_text_logic_1.combineExtractedParts)(parts);
        }
        const objectValue = this.asObject(value);
        if (!objectValue)
            return "";
        // 완료 텍스트 추출 시에는 delta/text 조각보다 최종 결과 키를 우선한다.
        const prioritizedKeys = [
            "outputText",
            "finalText",
            "result",
            "content",
            "message",
            "value",
            "items",
            "item",
            "text",
            "delta",
        ];
        for (const key of prioritizedKeys) {
            if (key in objectValue) {
                const nestedText = this.extractCompletionText(objectValue[key], depth + 1);
                if (nestedText.trim().length > 0) {
                    return nestedText;
                }
            }
        }
        return "";
    }
    extractThreadId(params) {
        const objectParams = this.asObject(params);
        if (!objectParams)
            return null;
        const directCandidates = [
            objectParams.threadId,
            objectParams.thread_id,
            objectParams.conversationId,
            objectParams.sessionId,
            this.getNested(objectParams, "thread", "id"),
            this.getNested(objectParams, "turn", "threadId"),
            this.getNested(objectParams, "turn", "thread_id"),
            this.getNested(objectParams, "item", "threadId"),
            this.getNested(objectParams, "item", "thread_id"),
            this.getNested(objectParams, "item", "conversationId"),
            this.getNested(objectParams, "msg", "threadId"),
            this.getNested(objectParams, "msg", "thread_id"),
            this.getNested(objectParams, "msg", "conversationId"),
        ];
        for (const candidate of directCandidates) {
            const parsed = this.safeString(candidate).trim();
            if (parsed)
                return parsed;
        }
        return null;
    }
    extractTurnId(params) {
        const objectParams = this.asObject(params);
        if (!objectParams)
            return null;
        const candidates = [
            objectParams.turnId,
            objectParams.turn_id,
            this.getNested(objectParams, "turn", "id"),
            this.getNested(objectParams, "item", "turnId"),
            this.getNested(objectParams, "item", "turn_id"),
            this.getNested(objectParams, "msg", "turnId"),
            this.getNested(objectParams, "msg", "turn_id"),
        ];
        for (const candidate of candidates) {
            const parsed = this.safeString(candidate).trim();
            if (parsed)
                return parsed;
        }
        return null;
    }
    extractDeltaText(params) {
        const objectParams = this.asObject(params);
        if (!objectParams)
            return "";
        const candidates = [
            objectParams.delta,
            objectParams.chunk,
            this.getNested(objectParams, "item", "delta"),
            this.getNested(objectParams, "agentMessage", "delta"),
            this.getNested(objectParams, "data", "delta"),
            this.getNested(objectParams, "msg", "delta"),
            objectParams.text,
            this.getNested(objectParams, "item", "text"),
            this.getNested(objectParams, "agentMessage", "text"),
            this.getNested(objectParams, "data", "text"),
            this.getNested(objectParams, "msg", "text"),
            this.getNested(objectParams, "msg", "message"),
        ];
        for (const candidate of candidates) {
            const text = this.extractText(candidate, 0, true);
            if (text.length > 0) {
                return text;
            }
        }
        return this.extractText(params, 0, true);
    }
    extractCompletedText(params) {
        const objectParams = this.asObject(params);
        if (!objectParams)
            return "";
        const candidates = [
            objectParams.outputText,
            objectParams.finalText,
            objectParams.result,
            objectParams.text,
            this.getNested(objectParams, "turn", "result"),
            this.getNested(objectParams, "turn", "outputText"),
            this.getNested(objectParams, "turn", "finalText"),
            this.getNested(objectParams, "data", "result"),
            this.getNested(objectParams, "data", "outputText"),
        ];
        for (const candidate of candidates) {
            const text = this.extractCompletionText(candidate, 0);
            if (text.length > 0)
                return text;
        }
        return this.extractCompletionText(params, 0);
    }
    extractErrorMessage(params) {
        const objectParams = this.asObject(params);
        if (!objectParams)
            return "Unknown Codex error";
        const candidates = [
            objectParams.error,
            objectParams.message,
            this.getNested(objectParams, "error", "message"),
            this.getNested(objectParams, "data", "error"),
            this.getNested(objectParams, "data", "message"),
        ];
        for (const candidate of candidates) {
            const message = this.extractText(candidate).trim();
            if (message.length > 0)
                return message;
        }
        return "Unknown Codex error";
    }
    resolveClientIdFromParams(params) {
        const turnId = this.extractTurnId(params);
        if (turnId && this.turnToClient.has(turnId)) {
            return this.turnToClient.get(turnId) || null;
        }
        const threadId = this.extractThreadId(params);
        if (threadId && this.threadToClient.has(threadId)) {
            return this.threadToClient.get(threadId) || null;
        }
        if (this.clientTurnStates.size === 1) {
            return Array.from(this.clientTurnStates.keys())[0] || null;
        }
        // 이벤트에 turn/thread 정보가 없거나 매핑이 누락된 경우,
        // 가장 최근 turn 상태를 보수적으로 사용해 응답 누락을 줄인다.
        if (this.clientTurnStates.size > 1) {
            const keys = Array.from(this.clientTurnStates.keys());
            const fallback = keys[keys.length - 1] || null;
            if (fallback) {
                this.log(`[CODEX] resolveClientId fallback -> ${fallback} (states=${this.clientTurnStates.size})`);
            }
            return fallback;
        }
        return null;
    }
    methodKey(method) {
        return method.toLowerCase().replace(/[^a-z]/g, "");
    }
    makeJsonRpcError(method, error) {
        const message = error?.message || "Unknown JSON-RPC error";
        return new Error(`${method} failed (${error?.code ?? "unknown"}): ${message}`);
    }
    setupProcessStreams(process) {
        this.stdoutReader = readline.createInterface({ input: process.stdout });
        this.stderrReader = readline.createInterface({ input: process.stderr });
        this.stdoutReader.on("line", (line) => this.handleStdoutLine(line));
        this.stderrReader.on("line", (line) => {
            if (line.trim().length > 0) {
                this.rememberStderrLine(line);
                this.logError(`codex stderr: ${line}`);
                this.notifySetupDiagnostic(line);
            }
        });
        process.on("error", (error) => {
            this.logError("Codex process error", error);
            this.notifySetupDiagnostic(error);
            this.handleProcessExit(`Codex process error: ${error.message}`);
        });
        process.on("close", (code, signal) => {
            const reason = `Codex process closed (code=${code ?? "null"}, signal=${signal || "none"})`;
            this.log(reason);
            if (!this.initialized && (code ?? 0) !== 0) {
                this.notifySetupDiagnostic(reason);
            }
            this.handleProcessExit(reason);
        });
    }
    handleProcessExit(reason) {
        this.initialized = false;
        this.initPromise = null;
        this.runtimeCapabilitiesCache.invalidate();
        if (this.stdoutReader) {
            this.stdoutReader.removeAllListeners();
            this.stdoutReader.close();
            this.stdoutReader = null;
        }
        if (this.stderrReader) {
            this.stderrReader.removeAllListeners();
            this.stderrReader.close();
            this.stderrReader = null;
        }
        if (this.codexProcess) {
            this.codexProcess.removeAllListeners();
            this.codexProcess = null;
        }
        const pendingEntries = Array.from(this.pendingRequests.entries());
        this.pendingRequests.clear();
        for (const [, pending] of pendingEntries) {
            clearTimeout(pending.timeout);
            pending.reject(new Error(reason));
        }
        if (this.wsServer) {
            for (const [clientId, state] of this.clientTurnStates.entries()) {
                this.wsServer.send(JSON.stringify({
                    type: "error",
                    message: `Codex turn interrupted: ${reason}`,
                    timestamp: new Date().toISOString(),
                    source: "codex",
                    clientId,
                    sessionId: state.threadId,
                    targetDeviceId: state.senderDeviceId || undefined,
                    traceId: state.traceId || undefined,
                }));
            }
        }
        this.clientTurnStates.clear();
        this.turnToClient.clear();
        this.clientThreads.clear();
        this.threadToClient.clear();
        this.pendingHistoryByClient.clear();
    }
    writeJsonRpcMessage(payload) {
        if (!this.codexProcess || !this.codexProcess.stdin.writable) {
            throw new Error("Codex app-server stdin is not writable");
        }
        this.codexProcess.stdin.write(`${JSON.stringify(payload)}\n`);
    }
    writeJsonRpcResult(id, result) {
        this.writeJsonRpcMessage({
            jsonrpc: "2.0",
            id,
            result,
        });
    }
    writeJsonRpcError(id, code, message, data) {
        this.writeJsonRpcMessage({
            jsonrpc: "2.0",
            id,
            error: {
                code,
                message,
                ...(data ? { data } : {}),
            },
        });
    }
    async sendRpcRequestRaw(method, params, timeoutMs = 20000) {
        if (!this.codexProcess) {
            throw new Error("Codex app-server process is not running");
        }
        const id = this.nextRequestId++;
        const requestPayload = {
            jsonrpc: "2.0",
            id,
            method,
        };
        if (params !== undefined) {
            requestPayload.params = params;
        }
        return new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
                this.pendingRequests.delete(id);
                reject(new Error(`JSON-RPC timeout: ${method}`));
            }, timeoutMs);
            this.pendingRequests.set(id, { method, resolve, reject, timeout });
            try {
                this.writeJsonRpcMessage(requestPayload);
            }
            catch (error) {
                clearTimeout(timeout);
                this.pendingRequests.delete(id);
                reject(error instanceof Error ? error : new Error(String(error)));
            }
        });
    }
    async sendRpcRequest(method, params, timeoutMs = 20000) {
        await this.ensureServerReady();
        return this.sendRpcRequestRaw(method, params, timeoutMs);
    }
    sendRpcNotification(method, params) {
        if (!this.codexProcess) {
            throw new Error("Codex app-server process is not running");
        }
        const payload = {
            jsonrpc: "2.0",
            method,
        };
        if (params !== undefined) {
            payload.params = params;
        }
        this.writeJsonRpcMessage(payload);
    }
    handleStdoutLine(line) {
        const trimmed = line.trim();
        if (!trimmed)
            return;
        let parsed;
        try {
            parsed = JSON.parse(trimmed);
        }
        catch (error) {
            this.logError(`Failed to parse codex JSONL line`, error);
            return;
        }
        if ("id" in parsed && "method" in parsed) {
            void this.handleServerRequest(parsed);
            return;
        }
        if ("id" in parsed) {
            this.handleRpcResponse(parsed);
            return;
        }
        const method = this.safeString(parsed.method).trim();
        const params = parsed.params;
        if (!method)
            return;
        this.handleRpcNotification(method, params);
    }
    async handleServerRequest(request) {
        const requestId = request.id;
        const method = this.safeString(request.method).trim();
        const params = request.params;
        if (!method) {
            this.writeJsonRpcError(requestId, -32600, "Invalid JSON-RPC request: method is required");
            return;
        }
        this.log(`[CODEX] server request received method=${method}, params=${JSON.stringify(params).substring(0, 400)}`);
        try {
            const result = await this.resolveServerRequest(method, params);
            this.writeJsonRpcResult(requestId, result);
            this.log(`[CODEX] server request resolved method=${method}`);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error || "Unknown error");
            this.logError(`[CODEX] server request failed method=${method}`, error);
            this.writeJsonRpcError(requestId, -32000, errorMessage, {
                method,
            });
        }
    }
    handleRpcResponse(response) {
        const rawId = response.id;
        const id = typeof rawId === "number"
            ? rawId
            : typeof rawId === "string"
                ? Number(rawId)
                : NaN;
        if (!Number.isFinite(id))
            return;
        const pending = this.pendingRequests.get(id);
        if (!pending)
            return;
        clearTimeout(pending.timeout);
        this.pendingRequests.delete(id);
        if (response.error) {
            const errorObject = this.asObject(response.error) || {};
            pending.reject(this.makeJsonRpcError(pending.method, errorObject));
            return;
        }
        pending.resolve(response.result);
    }
    async resolveServerRequest(method, params) {
        switch (method) {
            case "item/commandExecution/requestApproval":
                return this.handleCommandExecutionApprovalRequest(params, false);
            case "execCommandApproval":
                return this.handleCommandExecutionApprovalRequest(params, true);
            case "item/fileChange/requestApproval":
                return this.handleFileChangeApprovalRequest(params, false);
            case "applyPatchApproval":
                return this.handleFileChangeApprovalRequest(params, true);
            case "item/tool/requestUserInput":
                return this.handleUserInputRequest(params);
            case "item/tool/call":
                throw new Error("Dynamic tool calls are not supported by Codex Remote yet.");
            case "mcpServer/elicitation/request":
                throw new Error("MCP elicitation requests are not supported by Codex Remote yet.");
            case "account/chatgptAuthTokens/refresh":
                throw new Error("ChatGPT auth token refresh must be completed in the local Codex environment.");
            default:
                throw new Error(`Unsupported server request method: ${method}`);
        }
    }
    getApprovalClientContext(params) {
        const clientId = this.resolveClientIdFromParams(params);
        const state = clientId ? this.clientTurnStates.get(clientId) : null;
        return {
            clientId,
            senderDeviceId: state?.senderDeviceId || null,
            threadId: this.extractThreadId(params),
        };
    }
    notifyRemoteApprovalStatus(message, params, kind = "info") {
        if (!this.wsServer)
            return;
        const context = this.getApprovalClientContext(params);
        const payload = kind === "error"
            ? {
                type: "error",
                message,
                timestamp: new Date().toISOString(),
                source: "codex",
                clientId: context.clientId || undefined,
                sessionId: context.threadId || undefined,
                targetDeviceId: context.senderDeviceId || undefined,
            }
            : {
                type: "log",
                level: "warning",
                message: `[CODEX] ${message}`,
                timestamp: new Date().toISOString(),
                source: "codex",
                clientId: context.clientId || undefined,
                sessionId: context.threadId || undefined,
                targetDeviceId: context.senderDeviceId || undefined,
            };
        this.wsServer.broadcast(JSON.stringify(payload));
    }
    resolveRemoteServerRequestResponse(requestId, method, response) {
        const normalizedRequestId = requestId.trim();
        const normalizedMethod = method.trim();
        if (!normalizedRequestId) {
            throw new Error("requestId is required");
        }
        if (!normalizedMethod) {
            throw new Error("method is required");
        }
        const pending = this.pendingRemoteServerRequests.get(normalizedRequestId);
        if (!pending) {
            throw new Error(`No pending mobile request for requestId=${requestId}`);
        }
        if (pending.method !== normalizedMethod) {
            throw new Error(`Method mismatch for requestId=${requestId}: expected ${pending.method}, got ${normalizedMethod}`);
        }
        clearTimeout(pending.timeout);
        this.pendingRemoteServerRequests.delete(normalizedRequestId);
        pending.resolve(response);
        this.sendRemoteServerRequestStatus(normalizedRequestId, normalizedMethod, "resolved", "Mobile response received.", pending.clientId, pending.senderDeviceId);
    }
    shouldUseRemoteServerRequestFlow(params) {
        if (!this.wsServer)
            return false;
        const context = this.getApprovalClientContext(params);
        return !!context.senderDeviceId;
    }
    sendRemoteServerRequestStatus(requestId, method, status, message, clientId, senderDeviceId) {
        if (!this.wsServer)
            return;
        this.wsServer.send(JSON.stringify({
            type: "codex_server_request_status",
            requestId,
            method,
            status,
            message,
            timestamp: new Date().toISOString(),
            source: "codex",
            clientId: clientId || undefined,
            targetDeviceId: senderDeviceId || undefined,
        }));
    }
    async requestRemoteServerResponse(method, params, requestPayload, timeoutMs = 120000) {
        if (!this.wsServer) {
            throw new Error("WebSocket server is not available for remote requests.");
        }
        const context = this.getApprovalClientContext(params);
        if (!context.senderDeviceId) {
            throw new Error("No remote mobile device is associated with this turn.");
        }
        const requestId = `srvreq-${Date.now()}-${Math.random()
            .toString(36)
            .slice(2, 8)}`;
        return await new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
                this.pendingRemoteServerRequests.delete(requestId);
                this.sendRemoteServerRequestStatus(requestId, method, "timed_out", "Timed out waiting for a mobile response.", context.clientId, context.senderDeviceId);
                reject(new Error("Timed out waiting for response from mobile client."));
            }, timeoutMs);
            this.pendingRemoteServerRequests.set(requestId, {
                method,
                clientId: context.clientId,
                senderDeviceId: context.senderDeviceId,
                resolve,
                reject,
                timeout,
            });
            this.wsServer.send(JSON.stringify({
                type: "codex_server_request",
                requestId,
                method,
                timestamp: new Date().toISOString(),
                source: "codex",
                clientId: context.clientId || undefined,
                sessionId: context.threadId || undefined,
                targetDeviceId: context.senderDeviceId,
                ...requestPayload,
            }));
        });
    }
    async handleCommandExecutionApprovalRequest(params, legacy) {
        const objectParams = this.asObject(params) || {};
        const command = this.safeString(objectParams.command).trim() ||
            (Array.isArray(objectParams.command)
                ? objectParams.command
                    .map((part) => this.safeString(part).trim())
                    .filter((part) => part.length > 0)
                    .join(" ")
                : "") ||
            "(unknown command)";
        const cwd = this.safeString(objectParams.cwd).trim();
        const reason = this.safeString(objectParams.reason).trim();
        const detailLines = [
            `Command: ${command}`,
            cwd ? `cwd: ${cwd}` : null,
            reason ? `Reason: ${reason}` : null,
        ].filter((line) => !!line);
        const allow = "Allow";
        const allowForSession = "Allow for Session";
        const deny = "Deny";
        const availableDecisions = Array.isArray(objectParams.availableDecisions)
            ? objectParams.availableDecisions.map((decision) => JSON.stringify(decision))
            : null;
        const actionItems = [allow, deny];
        if (legacy ||
            !availableDecisions ||
            availableDecisions.includes(JSON.stringify("acceptForSession"))) {
            actionItems.splice(1, 0, allowForSession);
        }
        if (this.shouldUseRemoteServerRequestFlow(params)) {
            const remoteChoices = [
                {
                    label: allow,
                    style: "primary",
                    response: {
                        decision: legacy ? "approved" : "accept",
                    },
                },
                {
                    label: deny,
                    style: "danger",
                    response: {
                        decision: legacy ? "denied" : "decline",
                    },
                },
            ];
            if (actionItems.includes(allowForSession)) {
                remoteChoices.splice(1, 0, {
                    label: allowForSession,
                    style: "secondary",
                    response: {
                        decision: legacy ? "approved_for_session" : "acceptForSession",
                    },
                });
            }
            return await this.requestRemoteServerResponse(legacy ? "execCommandApproval" : "item/commandExecution/requestApproval", params, {
                requestKind: "command_execution",
                title: "Codex wants to run a command",
                summary: command,
                detailLines,
                choices: remoteChoices,
            });
        }
        this.notifyRemoteApprovalStatus("Approval required in VS Code desktop for command execution.", params);
        const selection = await vscode.window.showWarningMessage("Codex wants to run a command. Allow this execution?", {
            modal: true,
            detail: detailLines.join("\n"),
        }, ...actionItems);
        if (legacy) {
            if (selection === allow)
                return { decision: "approved" };
            if (selection === allowForSession) {
                return { decision: "approved_for_session" };
            }
            if (selection === deny)
                return { decision: "denied" };
            return { decision: "abort" };
        }
        if (selection === allow)
            return { decision: "accept" };
        if (selection === allowForSession)
            return { decision: "acceptForSession" };
        if (selection === deny)
            return { decision: "decline" };
        return { decision: "cancel" };
    }
    async handleFileChangeApprovalRequest(params, legacy) {
        const objectParams = this.asObject(params) || {};
        const reason = this.safeString(objectParams.reason).trim();
        const grantRoot = this.safeString(objectParams.grantRoot).trim() ||
            this.safeString(objectParams.grant_root).trim();
        const changedFiles = this.asObject(objectParams.changes) ||
            this.asObject(objectParams.fileChanges);
        const changeCount = changedFiles ? Object.keys(changedFiles).length : null;
        const detailLines = [
            changeCount != null ? `Files: ${changeCount}` : null,
            grantRoot ? `Grant root: ${grantRoot}` : null,
            reason ? `Reason: ${reason}` : null,
        ].filter((line) => !!line);
        const allow = "Allow";
        const allowForSession = "Allow for Session";
        const deny = "Deny";
        if (this.shouldUseRemoteServerRequestFlow(params)) {
            const remoteChoices = [
                {
                    label: allow,
                    style: "primary",
                    response: {
                        decision: legacy ? "approved" : "accept",
                    },
                },
                {
                    label: allowForSession,
                    style: "secondary",
                    response: {
                        decision: legacy ? "approved_for_session" : "acceptForSession",
                    },
                },
                {
                    label: deny,
                    style: "danger",
                    response: {
                        decision: legacy ? "denied" : "decline",
                    },
                },
            ];
            return await this.requestRemoteServerResponse(legacy ? "applyPatchApproval" : "item/fileChange/requestApproval", params, {
                requestKind: "file_change",
                title: "Codex wants to modify files",
                summary: changeCount != null
                    ? `${changeCount} file(s) will be changed`
                    : "Codex requested file changes",
                detailLines,
                choices: remoteChoices,
            });
        }
        this.notifyRemoteApprovalStatus("Approval required in VS Code desktop for file changes.", params);
        const selection = await vscode.window.showWarningMessage("Codex wants to modify files. Allow these file changes?", {
            modal: true,
            detail: detailLines.join("\n"),
        }, allow, allowForSession, deny);
        if (legacy) {
            if (selection === allow)
                return { decision: "approved" };
            if (selection === allowForSession) {
                return { decision: "approved_for_session" };
            }
            if (selection === deny)
                return { decision: "denied" };
            return { decision: "abort" };
        }
        if (selection === allow)
            return { decision: "accept" };
        if (selection === allowForSession)
            return { decision: "acceptForSession" };
        if (selection === deny)
            return { decision: "decline" };
        return { decision: "cancel" };
    }
    async handleUserInputRequest(params) {
        const objectParams = this.asObject(params) || {};
        const rawQuestions = Array.isArray(objectParams.questions)
            ? objectParams.questions
            : [];
        if (rawQuestions.length === 0) {
            throw new Error("requestUserInput received without questions");
        }
        if (this.shouldUseRemoteServerRequestFlow(params)) {
            return await this.requestRemoteServerResponse("item/tool/requestUserInput", params, {
                requestKind: "user_input",
                title: "Codex needs more input",
                summary: `${rawQuestions.length} additional question(s)`,
                questions: rawQuestions,
                choices: [],
            });
        }
        this.notifyRemoteApprovalStatus("Codex is asking for additional user input in VS Code desktop.", params);
        const answers = {};
        for (const rawQuestion of rawQuestions) {
            const question = this.asObject(rawQuestion) || {};
            const id = this.safeString(question.id).trim();
            const header = this.safeString(question.header).trim() || "Input required";
            const prompt = this.safeString(question.question).trim() ||
                "Provide the requested input.";
            const isSecret = question.isSecret === true;
            const options = Array.isArray(question.options)
                ? question.options
                    .map((option) => this.asObject(option) || {})
                    .map((option) => ({
                    label: this.safeString(option.label).trim(),
                    description: this.safeString(option.description).trim(),
                }))
                    .filter((option) => option.label.length > 0)
                : [];
            if (!id) {
                throw new Error("requestUserInput question is missing id");
            }
            if (options.length > 0) {
                const picked = await vscode.window.showQuickPick(options.map((option) => ({
                    label: option.label,
                    description: option.description,
                })), {
                    title: header,
                    placeHolder: prompt,
                    ignoreFocusOut: true,
                });
                if (!picked) {
                    throw new Error(`User cancelled input request: ${header}`);
                }
                answers[id] = { answers: [picked.label] };
                continue;
            }
            const input = await vscode.window.showInputBox({
                title: header,
                prompt,
                ignoreFocusOut: true,
                password: isSecret,
            });
            if (input == null) {
                throw new Error(`User cancelled input request: ${header}`);
            }
            answers[id] = { answers: [input] };
        }
        return { answers };
    }
    handleRpcNotification(method, params) {
        const normalized = method.toLowerCase();
        const key = this.methodKey(method);
        const isAgentDelta = normalized === "item/agentmessage/delta" ||
            normalized.endsWith("/item/agentmessage/delta") ||
            normalized.includes("agent_message_content_delta") ||
            key.includes("itemagentmessagedelta") ||
            key.includes("agentmessagedelta") ||
            key.includes("agentmessagecontentdelta");
        if (isAgentDelta) {
            this.handleAgentDelta(params);
            return;
        }
        const isAgentMessageSnapshot = normalized.endsWith("/agent_message") || key.endsWith("agentmessage");
        if (isAgentMessageSnapshot) {
            this.handleAgentMessageSnapshot(params);
            return;
        }
        const isTurnCompleted = normalized === "turn/completed" ||
            normalized.endsWith("/turn/completed") ||
            key.includes("turncompleted");
        if (isTurnCompleted) {
            this.handleTurnCompleted(params);
            return;
        }
        const isTurnStarted = normalized === "turn/started" ||
            normalized.endsWith("/turn/started") ||
            key.includes("turnstarted");
        if (isTurnStarted) {
            this.handleTurnStarted(params);
            return;
        }
        const isTurnFailed = normalized === "turn/failed" ||
            normalized.endsWith("/turn/failed") ||
            key.includes("turnfailed");
        if (isTurnFailed) {
            this.handleTurnFailed(params);
            return;
        }
        if (normalized === "error" || normalized.endsWith("/error")) {
            this.handleGenericError(params);
            return;
        }
        this.forwardRawCodexNotification(method, params);
        const isReasoningNoise = key.includes("agentreasoningdelta") ||
            key.includes("agentreasoningsectionbreak") ||
            key.includes("agentreasoning");
        if (!isReasoningNoise &&
            (key.includes("turn") || key.includes("agent") || key.includes("error"))) {
            this.log(`[CODEX] ignored rpc notification method=${method}, params=${JSON.stringify(params).substring(0, 300)}`);
        }
    }
    forwardRawCodexNotification(method, params) {
        if (!this.wsServer)
            return;
        const clientId = this.resolveClientIdFromParams(params);
        const state = clientId ? this.clientTurnStates.get(clientId) : null;
        this.wsServer.send(JSON.stringify({
            type: "codex_raw_notification",
            method,
            params,
            timestamp: new Date().toISOString(),
            source: "codex",
            clientId: clientId || undefined,
            sessionId: state?.threadId,
            targetDeviceId: state?.senderDeviceId || undefined,
            traceId: state?.traceId || undefined,
        }));
    }
    handleAgentDelta(params) {
        const clientId = this.resolveClientIdFromParams(params);
        if (!clientId)
            return;
        const state = this.clientTurnStates.get(clientId);
        if (!state || !this.wsServer)
            return;
        const delta = this.extractDeltaText(params);
        if (!delta)
            return;
        const merged = (0, streaming_text_logic_1.mergeStreamingAccumulator)({
            current: state.accumulatedText,
            incoming: delta,
        });
        if (merged.next === state.accumulatedText)
            return;
        state.accumulatedText = merged.next;
        if (!config_1.CONFIG.STREAM_CHAT_CHUNKS) {
            this.clientTurnStates.set(clientId, state);
            return;
        }
        state.hasChunks = true;
        this.clientTurnStates.set(clientId, state);
        this.wsServer.send(JSON.stringify({
            type: "chat_response_chunk",
            text: merged.emittedText || merged.next,
            fullText: state.accumulatedText,
            isReplace: merged.isReplace,
            timestamp: new Date().toISOString(),
            source: "codex",
            sessionId: state.threadId,
            clientId,
            targetDeviceId: state.senderDeviceId || undefined,
            traceId: state.traceId || undefined,
        }));
    }
    handleAgentMessageSnapshot(params) {
        const clientId = this.resolveClientIdFromParams(params);
        if (!clientId)
            return;
        const state = this.clientTurnStates.get(clientId);
        if (!state || !this.wsServer)
            return;
        const messageText = this.extractCompletionText(params, 0).trim();
        if (!messageText)
            return;
        const merged = (0, streaming_text_logic_1.mergeStreamingAccumulator)({
            current: state.accumulatedText,
            incoming: messageText,
        });
        if (merged.next === state.accumulatedText)
            return;
        state.accumulatedText = merged.next;
        if (!config_1.CONFIG.STREAM_CHAT_CHUNKS) {
            this.clientTurnStates.set(clientId, state);
            return;
        }
        state.hasChunks = true;
        this.clientTurnStates.set(clientId, state);
        this.wsServer.send(JSON.stringify({
            type: "chat_response_chunk",
            text: state.accumulatedText,
            fullText: state.accumulatedText,
            isReplace: true,
            timestamp: new Date().toISOString(),
            source: "codex",
            sessionId: state.threadId,
            clientId,
            targetDeviceId: state.senderDeviceId || undefined,
            traceId: state.traceId || undefined,
        }));
    }
    handleTurnCompleted(params) {
        const clientId = this.resolveClientIdFromParams(params);
        if (!clientId)
            return;
        const state = this.clientTurnStates.get(clientId);
        if (!state || !this.wsServer)
            return;
        const completedText = this.extractCompletedText(params).trim();
        if (!completedText) {
            this.log(`[CODEX] turn/completed extracted empty text; raw=${JSON.stringify(params).substring(0, 500)}`);
        }
        else {
            this.log(`[CODEX] turn/completed extracted text length=${completedText.length}`);
        }
        if (completedText && completedText !== state.accumulatedText) {
            const merged = (0, streaming_text_logic_1.mergeStreamingAccumulator)({
                current: state.accumulatedText,
                incoming: completedText,
            });
            const canPromoteCompleted = state.accumulatedText.length === 0 || merged.isReplace || !state.hasChunks;
            if (canPromoteCompleted && merged.next !== state.accumulatedText) {
                state.accumulatedText = merged.next;
            }
            else if (!canPromoteCompleted) {
                this.log(`[CODEX] ignored non-replace turn/completed text to avoid duplication (currentLen=${state.accumulatedText.length}, completedLen=${completedText.length})`);
            }
            if (config_1.CONFIG.STREAM_CHAT_CHUNKS && state.hasChunks && canPromoteCompleted) {
                this.wsServer.send(JSON.stringify({
                    type: "chat_response_chunk",
                    text: state.accumulatedText,
                    fullText: state.accumulatedText,
                    isReplace: true,
                    timestamp: new Date().toISOString(),
                    source: "codex",
                    sessionId: state.threadId,
                    clientId,
                    targetDeviceId: state.senderDeviceId || undefined,
                    traceId: state.traceId || undefined,
                }));
            }
        }
        const finalText = (state.accumulatedText || completedText || "").trim();
        if (finalText) {
            this.log(`[CODEX] forwarding final chat_response length=${finalText.length}`);
        }
        else {
            this.log(`[CODEX] final chat_response empty; accumulatedLen=${state.accumulatedText.length}`);
        }
        const streamedChunks = config_1.CONFIG.STREAM_CHAT_CHUNKS && state.hasChunks;
        if (finalText && !streamedChunks) {
            this.wsServer.send(JSON.stringify({
                type: "chat_response",
                text: finalText,
                timestamp: new Date().toISOString(),
                source: "codex",
                sessionId: state.threadId,
                clientId,
                targetDeviceId: state.senderDeviceId || undefined,
                traceId: state.traceId || undefined,
            }));
        }
        else if (finalText && streamedChunks) {
            this.log(`[CODEX] skip final chat_response because stream chunks were already emitted (len=${finalText.length})`);
        }
        if (streamedChunks) {
            this.wsServer.send(JSON.stringify({
                type: "chat_response_complete",
                timestamp: new Date().toISOString(),
                source: "codex",
                sessionId: state.threadId,
                clientId,
                targetDeviceId: state.senderDeviceId || undefined,
                traceId: state.traceId || undefined,
            }));
        }
        this.saveAssistantResponse(clientId, finalText);
        this.clearTurnState(clientId);
    }
    handleTurnFailed(params) {
        const clientId = this.resolveClientIdFromParams(params);
        if (!clientId)
            return;
        const state = this.clientTurnStates.get(clientId);
        if (!state || !this.wsServer)
            return;
        const errorMessage = this.extractErrorMessage(params);
        this.wsServer.send(JSON.stringify({
            type: "error",
            message: `Codex turn failed: ${errorMessage}`,
            timestamp: new Date().toISOString(),
            source: "codex",
            sessionId: state.threadId,
            clientId,
            targetDeviceId: state.senderDeviceId || undefined,
            traceId: state.traceId || undefined,
        }));
        this.clearTurnState(clientId);
    }
    handleTurnStarted(params) {
        const clientId = this.resolveClientIdFromParams(params);
        if (!clientId)
            return;
        const state = this.clientTurnStates.get(clientId);
        if (!state)
            return;
        const turnId = this.extractTurnId(params);
        if (!turnId)
            return;
        state.turnId = turnId;
        this.clientTurnStates.set(clientId, state);
        this.turnToClient.set(turnId, clientId);
    }
    handleGenericError(params) {
        const clientId = this.resolveClientIdFromParams(params);
        if (!clientId || !this.wsServer)
            return;
        const state = this.clientTurnStates.get(clientId);
        if (!state)
            return;
        const errorMessage = this.extractErrorMessage(params);
        this.wsServer.send(JSON.stringify({
            type: "error",
            message: `Codex error: ${errorMessage}`,
            timestamp: new Date().toISOString(),
            source: "codex",
            sessionId: state.threadId,
            clientId,
            targetDeviceId: state.senderDeviceId || undefined,
            traceId: state.traceId || undefined,
        }));
    }
    clearTurnState(clientId) {
        const state = this.clientTurnStates.get(clientId);
        if (state?.turnId) {
            this.turnToClient.delete(state.turnId);
        }
        this.clientTurnStates.delete(clientId);
    }
    async startProcessAndInitialize() {
        const cwd = this.workspaceRoot || process.cwd();
        const command = config_1.CONFIG.CODEX_COMMAND;
        const args = config_1.CONFIG.CODEX_APP_SERVER_ARGS.length
            ? config_1.CONFIG.CODEX_APP_SERVER_ARGS
            : ["app-server"];
        this.recentStderrLines = [];
        this.ensureCodexCommandAvailable();
        this.log(`Starting Codex app-server: ${command} ${args.join(" ")} (cwd=${cwd})`, true);
        const spawned = child_process.spawn(command, args, {
            cwd,
            stdio: ["pipe", "pipe", "pipe"],
            shell: false,
            env: {
                ...process.env,
            },
        });
        this.codexProcess = spawned;
        this.setupProcessStreams(spawned);
        const initializeResult = await this.sendRpcRequestRaw("initialize", {
            clientInfo: {
                name: "codex-remote-extension",
                version: "0.2.0",
            },
            capabilities: {},
        }, 15000);
        this.log(`Codex initialize response: ${JSON.stringify(initializeResult).substring(0, 300)}`);
        this.sendRpcNotification("initialized", {});
        this.initialized = true;
        this.shownSetupDiagnostics.delete("auth-required");
        this.shownSetupDiagnostics.delete("startup-failed");
        this.setCodexCliStatus("ready", "info", "Codex CLI 및 app-server 준비됨");
        this.log("Codex app-server initialize/initialized handshake completed", true);
    }
    async ensureServerReady() {
        if (this.codexProcess && this.initialized) {
            return;
        }
        if (this.initPromise) {
            await this.initPromise;
            return;
        }
        this.initPromise = this.startProcessAndInitialize();
        try {
            await this.initPromise;
        }
        catch (error) {
            this.notifySetupDiagnostic(error);
            throw error;
        }
        finally {
            this.initPromise = null;
        }
    }
    async ensureThread(clientId, newSession) {
        if (!newSession) {
            const existing = this.clientThreads.get(clientId);
            if (existing) {
                try {
                    await this.sendRpcRequest("thread/resume", { threadId: existing }, 8000);
                }
                catch {
                    // resume 실패해도 동일 프로세스에서는 threadId 저장값으로 turn/start 시도 가능
                }
                this.threadToClient.set(existing, clientId);
                return existing;
            }
        }
        let threadResult;
        try {
            threadResult = await this.sendRpcRequest("thread/start", {}, 15000);
        }
        catch (error) {
            // 하위/변형 서버 호환
            threadResult = await this.sendRpcRequest("thread/create", {}, 15000);
        }
        const threadObj = this.asObject(threadResult) || {};
        const threadIdCandidates = [
            threadObj.threadId,
            threadObj.thread_id,
            this.getNested(threadObj, "thread", "id"),
            threadObj.id,
        ];
        const threadId = threadIdCandidates
            .map((value) => this.safeString(value).trim())
            .find((value) => value.length > 0) || "";
        if (!threadId) {
            throw new Error("Failed to obtain threadId from Codex app-server");
        }
        this.clientThreads.set(clientId, threadId);
        this.threadToClient.set(threadId, clientId);
        return threadId;
    }
    normalizeReasoningEffort(effort) {
        const normalized = (effort || "").trim().toLowerCase();
        const allowed = new Set([
            "none",
            "minimal",
            "low",
            "medium",
            "high",
            "xhigh",
        ]);
        return allowed.has(normalized) ? normalized : "medium";
    }
    parseModelCapabilities(payload) {
        const resultObject = this.asObject(payload) || {};
        const rawItems = Array.isArray(resultObject.data)
            ? resultObject.data
            : Array.isArray(resultObject.models)
                ? resultObject.models
                : Array.isArray(payload)
                    ? payload
                    : [];
        return rawItems
            .map((item) => this.asObject(item) || {})
            .map((item) => {
            const rawReasoning = Array.isArray(item.supportedReasoningEfforts)
                ? item.supportedReasoningEfforts
                : [];
            const supportedReasoningEfforts = rawReasoning
                .map((entry) => {
                if (typeof entry === "string") {
                    return entry.trim();
                }
                const obj = this.asObject(entry) || {};
                return this.safeString(obj.reasoningEffort ?? obj.reasoning_effort).trim();
            })
                .filter((entry) => entry.length > 0);
            return {
                id: this.safeString(item.id || item.model).trim(),
                model: this.safeString(item.model || item.id).trim(),
                displayName: this.safeString(item.displayName || item.display_name || item.model || item.id).trim(),
                description: this.safeString(item.description).trim(),
                isDefault: item.isDefault === true,
                hidden: item.hidden === true,
                defaultReasoningEffort: this.safeString(item.defaultReasoningEffort || item.default_reasoning_effort).trim(),
                supportedReasoningEfforts,
                supportsPersonality: item.supportsPersonality === true,
                inputModalities: Array.isArray(item.inputModalities)
                    ? item.inputModalities
                        .map((value) => this.safeString(value).trim())
                        .filter((value) => value.length > 0)
                    : [],
            };
        })
            .filter((item) => item.model.length > 0);
    }
    async loadRuntimeCapabilities() {
        const startedAt = Date.now();
        const base = {
            provider: "codex",
            ready: false,
            cliStatus: this.getCodexCliStatus(),
            agentModes: ["auto", "agent", "ask", "plan", "debug"],
            models: [],
            ideContext: {
                supported: false,
                defaultEnabled: false,
                reason: "Remote prompt pipeline does not inject IDE context yet.",
            },
            flatMode: {
                supported: false,
                defaultEnabled: false,
                reason: "Flat mode is not exposed through the current app-server flow.",
            },
            defaults: {
                model: "auto",
                reasoningEffort: "auto",
                agentMode: "auto",
            },
        };
        try {
            const ensureStartedAt = Date.now();
            await this.ensureServerReady();
            const ensureElapsedMs = Date.now() - ensureStartedAt;
            const modelListStartedAt = Date.now();
            const modelResult = await this.sendRpcRequest("model/list", { includeHidden: false, limit: 100 }, 15000);
            const modelListElapsedMs = Date.now() - modelListStartedAt;
            const models = this.parseModelCapabilities(modelResult);
            const defaultModel = models.find((item) => item.isDefault) || models[0] || null;
            const totalElapsedMs = Date.now() - startedAt;
            this.log(`[CODEX] runtime capabilities loaded - models: ${models.length}, default: ${defaultModel?.model || "none"}, ensureReady=${ensureElapsedMs}ms, modelList=${modelListElapsedMs}ms, total=${totalElapsedMs}ms`);
            if (models.length > 0) {
                this.log(`[CODEX] runtime capability models: ${models
                    .map((item) => `${item.model}[${item.supportedReasoningEfforts.join("/") || "n/a"}]`)
                    .join(", ")}`);
            }
            return {
                ...base,
                ready: true,
                cliStatus: this.getCodexCliStatus(),
                models,
                defaults: {
                    model: defaultModel?.model || "auto",
                    reasoningEffort: defaultModel?.defaultReasoningEffort?.trim().length
                        ? defaultModel.defaultReasoningEffort.trim()
                        : "auto",
                    agentMode: "auto",
                },
            };
        }
        catch (error) {
            const totalElapsedMs = Date.now() - startedAt;
            const errorMessage = error instanceof Error ? error.message : "Unknown capability error";
            this.logError(`Runtime capability load failed after ${totalElapsedMs}ms`, error);
            this.logError("Failed to load runtime capabilities", error);
            return {
                ...base,
                cliStatus: this.getCodexCliStatus(),
                error: errorMessage,
            };
        }
    }
    async getRuntimeCapabilities() {
        return this.runtimeCapabilitiesCache.get(() => this.loadRuntimeCapabilities(), (capabilities) => capabilities.ready && capabilities.models.length > 0);
    }
    async startTurn(threadId, text, selectedMode, selectedModel, selectedEffort) {
        this.log(`[CODEX] turn/start options - mode: ${selectedMode}, model: ${selectedModel || "auto"}, effort: ${selectedEffort}`);
        const baseParams = {
            threadId,
            input: [{ type: "text", text }],
        };
        const extraCandidates = [];
        if (selectedModel) {
            extraCandidates.push({ model: selectedModel, effort: selectedEffort });
            extraCandidates.push({
                model: selectedModel,
                reasoning: { effort: selectedEffort },
            });
            extraCandidates.push({ model: selectedModel, summary: "auto" });
        }
        extraCandidates.push({ effort: selectedEffort });
        extraCandidates.push({ reasoning: { effort: selectedEffort } });
        extraCandidates.push({ summary: "auto" });
        extraCandidates.push({ personality: "default" });
        extraCandidates.push({});
        const seen = new Set();
        const candidateParams = [];
        for (const extra of extraCandidates) {
            const params = { ...baseParams, ...extra };
            const key = JSON.stringify(params);
            if (!seen.has(key)) {
                seen.add(key);
                candidateParams.push(params);
            }
        }
        let lastError = null;
        for (const params of candidateParams) {
            try {
                const result = await this.sendRpcRequest("turn/start", params, 20000);
                const resultObject = this.asObject(result) || {};
                const turnIdCandidates = [
                    resultObject.turnId,
                    resultObject.turn_id,
                    this.getNested(resultObject, "turn", "id"),
                    resultObject.id,
                ];
                const turnId = turnIdCandidates
                    .map((value) => this.safeString(value).trim())
                    .find((value) => value.length > 0) || null;
                // turn/start 응답은 최종 답변이 아닌 메타데이터를 포함할 수 있으므로
                // 즉시 응답 채택은 명시적인 완료 텍스트 필드에서만 허용한다.
                const immediateTextCandidates = [
                    resultObject.outputText,
                    resultObject.finalText,
                    resultObject.result,
                    this.getNested(resultObject, "turn", "outputText"),
                    this.getNested(resultObject, "turn", "finalText"),
                    this.getNested(resultObject, "turn", "result"),
                ];
                const immediateText = immediateTextCandidates
                    .map((value) => this.extractCompletionText(value, 0).trim())
                    .find((value) => value.length > 0) || "";
                if (immediateText) {
                    this.log(`[CODEX] turn/start immediateText accepted (len=${immediateText.length})`);
                }
                return { turnId, immediateText };
            }
            catch (error) {
                lastError = error;
            }
        }
        throw lastError instanceof Error
            ? lastError
            : new Error("turn/start failed");
    }
    detectAgentMode(text) {
        const normalized = text.toLowerCase();
        if (normalized.includes("debug") ||
            normalized.includes("버그") ||
            normalized.includes("오류")) {
            return "debug";
        }
        if (normalized.includes("plan") ||
            normalized.includes("계획") ||
            normalized.includes("설계")) {
            return "plan";
        }
        if (normalized.includes("why") ||
            normalized.includes("무엇") ||
            normalized.includes("질문") ||
            normalized.includes("?")) {
            return "ask";
        }
        return "agent";
    }
    getModeDisplayName(mode) {
        const displayNames = {
            agent: "Agent (코딩 작업)",
            ask: "Ask (질문/학습)",
            plan: "Plan (계획/설계)",
            debug: "Debug (문제 해결)",
            auto: "Auto (자동 선택)",
        };
        return displayNames[mode] || mode;
    }
    saveUserMessage(clientId, sessionId, text, agentMode) {
        const entry = {
            id: `codex-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`,
            sessionId,
            clientId,
            userMessage: text,
            assistantResponse: "",
            timestamp: new Date().toISOString(),
            agentMode,
            provider: "codex",
        };
        this.chatHistory.push(entry);
        this.pendingHistoryByClient.set(clientId, entry.id);
    }
    saveAssistantResponse(clientId, responseText) {
        if (!responseText)
            return;
        const pendingId = this.pendingHistoryByClient.get(clientId);
        if (!pendingId)
            return;
        const entry = this.chatHistory.find((item) => item.id === pendingId);
        if (!entry)
            return;
        entry.assistantResponse = responseText;
        this.pendingHistoryByClient.delete(clientId);
    }
    async sendPrompt(text, execute = true, clientId, newSession = false, agentMode = "auto", senderDeviceId, traceId, model, reasoningEffort = "auto", useIdeContext = false, useFlatMode = false) {
        const effectiveClientId = this.getClientKey(clientId);
        if (!execute) {
            this.log("Codex provider does not support non-execute mode. Executing anyway.");
        }
        let selectedMode = "agent";
        if (agentMode && agentMode !== "auto") {
            selectedMode = agentMode;
        }
        else if (agentMode === "auto") {
            selectedMode = this.detectAgentMode(text) || "agent";
        }
        const capabilities = await this.getRuntimeCapabilities();
        const modelResolution = (0, runtime_capability_policy_1.resolveRequestedModel)(model, {
            ready: capabilities.ready,
            models: capabilities.models,
            defaultModel: capabilities.defaults.model,
        });
        const selectedModel = modelResolution.selectedModel;
        const selectedEffort = reasoningEffort && reasoningEffort !== "auto"
            ? this.normalizeReasoningEffort(reasoningEffort)
            : selectedMode === "plan"
                ? "high"
                : "medium";
        this.log(`[CODEX] prompt config - mode: ${selectedMode}, requestedModel: ${modelResolution.requestedModel}, effectiveModel: ${modelResolution.effectiveModel}, explicitModel: ${selectedModel || "none"}, fallback: ${modelResolution.fallbackReason || "none"}, effort: ${selectedEffort}, useIdeContext: ${useIdeContext}, useFlatMode: ${useFlatMode}`);
        if (modelResolution.fallbackReason === "unsupported_model" ||
            modelResolution.fallbackReason === "catalog_unavailable") {
            this.log(`[CODEX] requested model "${modelResolution.requestedModel}" is not usable; Codex will select its current account default`, true);
            if (this.wsServer) {
                this.wsServer.send(JSON.stringify({
                    type: "model_selection_resolved",
                    requestedModel: modelResolution.requestedModel,
                    effectiveModel: modelResolution.effectiveModel,
                    fallbackReason: modelResolution.fallbackReason,
                    timestamp: new Date().toISOString(),
                }));
            }
        }
        await this.ensureServerReady();
        const threadId = await this.ensureThread(effectiveClientId, newSession);
        if (agentMode === "auto" && this.wsServer) {
            this.wsServer.send(JSON.stringify({
                type: "agent_mode_selected",
                requestedMode: "auto",
                actualMode: selectedMode,
                displayName: this.getModeDisplayName(selectedMode),
                timestamp: new Date().toISOString(),
            }));
        }
        const existingState = this.clientTurnStates.get(effectiveClientId);
        if (existingState?.turnId) {
            this.turnToClient.delete(existingState.turnId);
        }
        this.clientTurnStates.set(effectiveClientId, {
            threadId,
            turnId: null,
            accumulatedText: "",
            hasChunks: false,
            senderDeviceId: senderDeviceId || null,
            traceId: traceId || null,
        });
        this.threadToClient.set(threadId, effectiveClientId);
        this.saveUserMessage(effectiveClientId, threadId, text, selectedMode);
        let turnStartResult;
        try {
            turnStartResult = await this.startTurn(threadId, text, selectedMode, selectedModel, selectedEffort);
        }
        catch (error) {
            // 저장된 threadId가 만료/손상된 경우 새 thread로 1회 재시도
            this.logError(`turn/start failed for thread ${threadId}, retrying with a new thread`, error);
            const retryThreadId = await this.ensureThread(effectiveClientId, true);
            const retryState = this.clientTurnStates.get(effectiveClientId);
            if (retryState) {
                retryState.threadId = retryThreadId;
                this.clientTurnStates.set(effectiveClientId, retryState);
            }
            turnStartResult = await this.startTurn(retryThreadId, text, selectedMode, selectedModel, selectedEffort);
        }
        const state = this.clientTurnStates.get(effectiveClientId);
        if (!state) {
            return;
        }
        if (turnStartResult.turnId) {
            state.turnId = turnStartResult.turnId;
            this.turnToClient.set(turnStartResult.turnId, effectiveClientId);
            this.clientTurnStates.set(effectiveClientId, state);
        }
        if (turnStartResult.immediateText) {
            if (this.wsServer) {
                this.wsServer.send(JSON.stringify({
                    type: "chat_response",
                    text: turnStartResult.immediateText,
                    timestamp: new Date().toISOString(),
                    source: "codex",
                    sessionId: threadId,
                    clientId: effectiveClientId,
                    targetDeviceId: senderDeviceId || undefined,
                    traceId: traceId || undefined,
                }));
            }
            this.saveAssistantResponse(effectiveClientId, turnStartResult.immediateText);
            this.clearTurnState(effectiveClientId);
        }
    }
    async stopPrompt() {
        try {
            const entries = Array.from(this.clientTurnStates.entries());
            for (const [, state] of entries) {
                if (state.turnId) {
                    try {
                        await this.sendRpcRequest("turn/cancel", { turnId: state.turnId }, 5000);
                    }
                    catch {
                        // 서버가 turn/cancel 미지원일 수 있으므로 무시
                    }
                }
            }
            this.clientTurnStates.clear();
            this.turnToClient.clear();
            return { success: true };
        }
        catch (error) {
            this.logError("Failed to stop Codex turn", error);
            return { success: false };
        }
    }
    getSessionInfo(clientId) {
        const key = this.getClientKey(clientId);
        const sessionId = this.clientThreads.get(key) || null;
        return {
            clientId: clientId || null,
            currentSessionId: sessionId,
            hasSession: !!sessionId,
            provider: "codex",
        };
    }
    getChatHistory(clientId, sessionId, _relaySessionId, limit = 50) {
        let filtered = [...this.chatHistory];
        if (clientId) {
            const key = this.getClientKey(clientId);
            filtered = filtered.filter((entry) => entry.clientId === key);
        }
        if (sessionId) {
            filtered = filtered.filter((entry) => entry.sessionId === sessionId);
        }
        return filtered.slice(-limit);
    }
    hasClientSession(clientId) {
        const key = this.getClientKey(clientId);
        return this.clientThreads.has(key);
    }
    dispose() {
        if (this.codexProcess) {
            try {
                this.codexProcess.kill("SIGTERM");
            }
            catch {
                // ignore
            }
        }
        this.handleProcessExit("Codex handler disposed");
    }
}
exports.CodexHandler = CodexHandler;
//# sourceMappingURL=codex-handler.js.map