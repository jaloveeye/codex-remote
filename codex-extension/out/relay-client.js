"use strict";
/**
 * Relay Server Client for Codex Remote Extension
 * Handles communication with the relay server for remote mobile client connections
 */
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
exports.RelayClient = void 0;
const https = __importStar(require("https"));
const http = __importStar(require("http"));
const url_1 = require("url");
const trace_emitter_1 = require("./trace_emitter");
class RelayClient {
    constructor(relayServerUrl, outputChannel) {
        this.sessionId = null;
        this.pollInterval = null;
        this.isConnected = false;
        this.onMessageCallback = null;
        this.onSessionConnectedCallback = null;
        /** 복수 세션 발견 시 사용자 선택용. (sessions) => 선택한 sessionId 또는 null */
        this.onSessionsDiscoveredCallback = null;
        /** 익스텐션 시작 시 사용자가 입력한 세션 ID (이 세션만 연결 시도) */
        this.targetSessionId = null;
        /** PC가 설정한 PIN (모바일은 이 PIN을 알아야 접속 가능, 메모리에만 보관) */
        this.targetPin = null;
        /** 409 PC_IN_USE 시 재시도 안 함 */
        this.pcInUse = false;
        this.lastSessionDiscoveryTime = 0;
        this.lastPollHeartbeatTime = 0;
        this.lastNoSessionHeartbeatTime = 0; // 세션 없을 때 폴링 동작 확인용
        this.lastPollAt = 0;
        this.lastRelayActivityAt = 0;
        this.SESSION_DISCOVERY_INTERVAL = 5000; // 5초마다 세션 탐지 (빠른 연결용)
        this.POLL_IDLE_INTERVAL = 1000; // 유휴 상태 1초 폴링
        this.POLL_ACTIVE_INTERVAL = 250; // 활성 상태 0.25초 폴링
        this.POLL_LOOP_TICK = 100; // 내부 스케줄러 tick
        this.POLL_ACTIVITY_WINDOW_MS = 60000; // 최근 활동 60초는 활성 폴링 유지
        this.POLL_HEARTBEAT_INTERVAL = 30000; // 30초마다 폴링 동작 로그
        /** 연결 유지용 heartbeat (2분 무heartbeat 시 서버가 연결 끊김으로 간주) */
        this.heartbeatInterval = null;
        this.HEARTBEAT_INTERVAL_MS = 30 * 1000; // 30초마다 heartbeat
        /** 릴레이로 보내는 메시지 순서 보장용 직렬화 큐 */
        this.sendQueue = Promise.resolve();
        /** 서버 disconnect 중복 호출 방지 */
        this.disconnectInFlight = null;
        /** poll 중복 실행 방지 */
        this.pollInFlight = false;
        /** connect 중복 실행 방지 */
        this.connectInFlight = null;
        /** stop 이후 stale 비동기 응답 무시용 실행 토큰 */
        this.runToken = 0;
        /** 현재 relay loop 실행 여부 */
        this.isRunning = false;
        this.relayServerUrl = relayServerUrl;
        this.deviceId = `pc-${Date.now()}`;
        this.outputChannel = outputChannel;
        this.traceEmitter = new trace_emitter_1.TraceEmitter(async (events) => {
            await this.httpRequest(`${this.relayServerUrl}/api/trace-events/batch`, "POST", {
                events,
            });
        });
    }
    log(message, level = "info") {
        const timestamp = new Date().toLocaleTimeString();
        const logMessage = `[${timestamp}] [Relay] ${message}`;
        this.outputChannel.appendLine(logMessage);
        console.log(logMessage);
    }
    logError(message, error) {
        const errorMessage = error instanceof Error ? error.message : String(error || "");
        const logMessage = `[Relay] ERROR: ${message}${errorMessage ? ` - ${errorMessage}` : ""}`;
        this.outputChannel.appendLine(logMessage);
        console.error(logMessage, error);
    }
    recordTraceHop(input) {
        if (!this.sessionId)
            return;
        const accepted = this.traceEmitter.emitTraceHop({
            ...input,
            sessionId: input.sessionId || this.sessionId,
        });
        if (!accepted)
            return;
        this.traceEmitter.flushNow().catch(() => undefined);
    }
    /**
     * Set callback for receiving messages from relay server
     */
    setOnMessage(callback) {
        this.onMessageCallback = callback;
    }
    /**
     * Set callback for when session is connected (e.g. to update status bar)
     */
    setOnSessionConnected(callback) {
        this.onSessionConnectedCallback = callback;
    }
    /**
     * Set callback for when multiple sessions are discovered (user picks one).
     * If not set or returns null, first session is used.
     */
    setOnSessionsDiscovered(callback) {
        this.onSessionsDiscoveredCallback = callback;
    }
    /**
     * Connect to a specific relay session by ID (e.g. when user entered 3ZUESK).
     * If already connected, disconnects from current session then connects to sid.
     * pin: PC가 설정한 PIN (설정 시 서버에 저장되어 모바일은 이 PIN으로 접속)
     */
    async connectToSessionById(sid, pin) {
        const trimmed = sid.trim().toUpperCase();
        if (!trimmed) {
            this.logError("connectToSessionById", "session ID is empty");
            return;
        }
        if (this.sessionId && this.isConnected) {
            this.log(`🔌 기존 세션 ${this.sessionId} 연결 해제 후 ${trimmed}로 연결`);
            this.clearHeartbeat();
            this.sessionId = null;
            this.isConnected = false;
        }
        this.targetSessionId = trimmed;
        this.targetPin =
            pin != null && typeof pin === "string" && pin.trim() ? pin.trim() : null;
        this.isRunning = true;
        this.runToken += 1;
        this.startPolling();
        await this.connectToSession(trimmed, this.targetPin ?? undefined);
    }
    /**
     * Start relay client with session ID (익스텐션 시작 시 입력·저장한 세션 ID만 연결)
     * pin: PC가 설정한 PIN (설정 시 모바일은 이 PIN을 입력해야만 접속 가능)
     */
    async start(sessionId, pin) {
        const sid = sessionId.trim().toUpperCase();
        if (!sid) {
            this.logError("start", "session ID is required");
            return;
        }
        this.targetSessionId = sid;
        this.targetPin =
            pin != null && typeof pin === "string" && pin.trim() ? pin.trim() : null;
        this.pcInUse = false;
        this.isRunning = true;
        this.runToken += 1;
        this.log("Starting relay client...");
        this.log(`Relay Server: ${this.relayServerUrl}`);
        this.log(`Device ID: ${this.deviceId}`);
        this.log(`Target session ID: ${this.targetSessionId}`);
        this.startPolling();
        this.log("Relay client started - connecting to session when it becomes available (create/connect from mobile first).");
    }
    /**
     * Stop relay client
     */
    stop() {
        this.isRunning = false;
        this.runToken += 1;
        this.clearHeartbeat();
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
            this.pollInterval = null;
        }
        this.pollInFlight = false;
        this.connectInFlight = null;
        this.isConnected = false;
        this.sessionId = null;
        this.targetSessionId = null;
        this.targetPin = null;
        this.pcInUse = false;
        this.log("Relay client stopped");
    }
    clearHeartbeat() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
            this.heartbeatInterval = null;
        }
    }
    /** 서버에 "살아있음" 신호 전송 (2분간 없으면 연결 끊김으로 간주 → 같은 세션 ID 재사용 가능) */
    async sendHeartbeat() {
        if (!this.sessionId || !this.isConnected)
            return;
        const url = `${this.relayServerUrl}/api/heartbeat?sessionId=${encodeURIComponent(this.sessionId)}&deviceId=${encodeURIComponent(this.deviceId)}`;
        try {
            await this.httpRequest(url);
        }
        catch {
            // 로그만 하고 유지 (다음 heartbeat에서 재시도)
        }
    }
    startHeartbeat() {
        this.clearHeartbeat();
        this.heartbeatInterval = setInterval(() => {
            this.sendHeartbeat();
        }, this.HEARTBEAT_INTERVAL_MS);
        this.log(`💓 Heartbeat 시작 (${this.HEARTBEAT_INTERVAL_MS / 1000}초마다, 2분 무응답 시 연결 해제로 간주)`);
    }
    /**
     * Start polling for messages and session discovery
     */
    startPolling() {
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
        }
        this.lastPollAt = 0;
        const pollingRunToken = this.runToken;
        this.pollInterval = setInterval(() => {
            if (!this.isRunning || pollingRunToken !== this.runToken)
                return;
            const now = Date.now();
            const interval = this.getCurrentPollIntervalMs(now);
            if (now - this.lastPollAt < interval)
                return;
            if (this.pollInFlight)
                return;
            this.lastPollAt = now;
            this.pollInFlight = true;
            this.pollMessages()
                .catch((err) => {
                this.logError("pollMessages threw", err);
            })
                .finally(() => {
                this.pollInFlight = false;
            });
        }, this.POLL_LOOP_TICK);
        this.log("⏱️ Adaptive poll interval started (idle 1s / active 0.25s)");
    }
    getCurrentPollIntervalMs(now = Date.now()) {
        const isActive = now - this.lastRelayActivityAt <= this.POLL_ACTIVITY_WINDOW_MS;
        return isActive ? this.POLL_ACTIVE_INTERVAL : this.POLL_IDLE_INTERVAL;
    }
    /**
     * Poll messages from relay server; when no session, try connect to targetSessionId
     */
    async pollMessages() {
        if (!this.isRunning)
            return;
        // If no session, try to connect to targetSessionId (입력한 세션 ID만 연결)
        if (!this.sessionId) {
            if (this.pcInUse)
                return;
            if (this.targetSessionId) {
                const now = Date.now();
                if (now - this.lastNoSessionHeartbeatTime >=
                    this.POLL_HEARTBEAT_INTERVAL) {
                    this.lastNoSessionHeartbeatTime = now;
                    this.log(`⏳ 세션 ${this.targetSessionId} 대기 중 (모바일에서 해당 세션 생성·연결 후 자동 연결)`);
                }
                await this.connectToSession(this.targetSessionId, this.targetPin ?? undefined);
                return;
            }
            // targetSessionId 없을 때만 discovery (하위 호환)
            const now = Date.now();
            if (now - this.lastNoSessionHeartbeatTime >=
                this.POLL_HEARTBEAT_INTERVAL) {
                this.lastNoSessionHeartbeatTime = now;
                this.log("⏳ 세션 없음 - 폴링 루프 동작 중 (세션 ID를 입력하거나 모바일에서 세션 생성 후 대기)");
            }
            const discoveredSessionId = await this.discoverSession();
            if (discoveredSessionId) {
                this.log(`🔍 Found session waiting for Extension: ${discoveredSessionId}`);
                await this.connectToSession(discoveredSessionId);
                return;
            }
            return;
        }
        // If session exists, poll for messages
        if (!this.sessionId || !this.isConnected) {
            this.log(`⚠️ Polling skipped: sessionId=${this.sessionId}, isConnected=${this.isConnected}`);
            return;
        }
        try {
            const now = Date.now();
            if (now - this.lastPollHeartbeatTime >= this.POLL_HEARTBEAT_INTERVAL) {
                this.lastPollHeartbeatTime = now;
                this.log(`🔄 Polling sessionId=${this.sessionId} (정상 폴링 중)`);
            }
            const pollUrl = `${this.relayServerUrl}/api/poll?sessionId=${this.sessionId}&deviceType=pc&deviceId=${encodeURIComponent(this.deviceId)}`;
            const data = await this.httpRequest(pollUrl);
            if (!data) {
                this.logError("⚠️ Poll returned null/undefined data");
                return;
            }
            // 응답 형식 허용: data.data.messages 또는 data.messages
            const messages = Array.isArray(data.data?.messages)
                ? data.data.messages
                : Array.isArray(data.messages)
                    ? data.messages
                    : [];
            if (messages.length > 0) {
                this.lastRelayActivityAt = Date.now();
                this.log(`📥 Received ${messages.length} message(s) from relay`);
                this.log(`📋 Messages: ${JSON.stringify(messages.map((m) => ({
                    id: m.id,
                    type: m.type,
                    from: m.from,
                    hasData: !!m.data,
                })))}`);
            }
            for (const msg of messages) {
                this.log(`📨 Processing message: id=${msg.id}, type=${msg.type}, from=${msg.from}`);
                // Forward message to callback (Extension WebSocket server)
                if (this.onMessageCallback) {
                    // 페이로드: msg.data가 있으면 그대로, 없으면 전체 msg (하위 호환)
                    // 릴레이 envelope 메타데이터(sender/target device id)는
                    // 원본 payload에 없더라도 유지해서 원격 승인/응답 라우팅에 사용한다.
                    const basePayload = msg.data !== undefined && msg.data !== null ? msg.data : msg;
                    const payload = basePayload &&
                        typeof basePayload === "object" &&
                        !Array.isArray(basePayload)
                        ? {
                            ...basePayload,
                            senderDeviceId: basePayload.senderDeviceId ??
                                msg.senderDeviceId,
                            targetDeviceId: basePayload.targetDeviceId ??
                                msg.targetDeviceId,
                        }
                        : basePayload;
                    const messageStr = typeof payload === "string" ? payload : JSON.stringify(payload);
                    const payloadObj = payload && typeof payload === "object" && !Array.isArray(payload)
                        ? payload
                        : null;
                    const traceId = (payloadObj && typeof payloadObj.traceId === "string" && payloadObj.traceId.trim()) ||
                        (payloadObj && typeof payloadObj.id === "string" && payloadObj.id.trim()) ||
                        null;
                    const commandId = (payloadObj && typeof payloadObj.id === "string" && payloadObj.id.trim()) || null;
                    this.recordTraceHop({
                        traceId,
                        sessionId: this.sessionId,
                        hop: "ext.poll.recv",
                        commandId,
                        relayMessageId: typeof msg.id === "string" ? msg.id : undefined,
                        senderDeviceId: typeof msg.senderDeviceId === "string"
                            ? msg.senderDeviceId
                            : undefined,
                        targetDeviceId: typeof msg.targetDeviceId === "string"
                            ? msg.targetDeviceId
                            : undefined,
                        meta: {
                            messageType: payloadObj && typeof payloadObj.type === "string"
                                ? payloadObj.type
                                : msg.type,
                        },
                    });
                    this.log(`📤 Calling onMessageCallback with: ${messageStr.substring(0, 200)}`);
                    this.onMessageCallback(messageStr);
                    this.log(`✅ onMessageCallback completed`);
                }
                else {
                    this.logError("⚠️ onMessageCallback is null - cannot forward message");
                }
            }
            if (!data.success) {
                this.logError(`Poll failed: ${data.error}`);
            }
            else if (messages.length === 0 && data.success) {
                // No messages - this is normal, don't log
            }
        }
        catch (error) {
            this.logError("Polling error", error);
            if (error instanceof Error) {
                this.logError(`   Error message: ${error.message}`);
                this.logError(`   Error stack: ${error.stack}`);
            }
        }
    }
    /**
     * Discover sessions waiting for Extension (this client) to connect
     */
    async discoverSession() {
        if (this.sessionId) {
            return null; // Already connected to a session
        }
        // Rate limiting
        const now = Date.now();
        if (now - this.lastSessionDiscoveryTime < this.SESSION_DISCOVERY_INTERVAL) {
            return null;
        }
        this.lastSessionDiscoveryTime = now;
        try {
            const discoveryUrl = `${this.relayServerUrl}/api/sessions-with-mobile`;
            this.log(`🔍 Discovery: GET ${discoveryUrl}`);
            const data = await this.httpRequest(discoveryUrl);
            if (!data) {
                this.log("🔍 Discovery: API returned no data");
                return null;
            }
            if (!data.success) {
                this.log(`🔍 Discovery: API error - ${data.error ?? "unknown"}`);
                return null;
            }
            const sessions = data.data?.sessions ?? [];
            const sessionsCount = Array.isArray(sessions) ? sessions.length : 0;
            this.log(`🔍 Discovery: 서버 응답 success=true, sessionsCount=${sessionsCount} (모바일 연결된 세션)`);
            if (sessionsCount === 0) {
                this.log("🔍 Discovery: 모바일이 연결된 세션이 없습니다 (모바일에서 세션 생성 후 연결하세요)");
                this.log("💡 다른 VS Code 창이 열려 있으면 그 익스텐션이 세션을 먼저 가져갔을 수 있습니다. 다른 창을 모두 닫고 새 세션으로 다시 시도해 보세요.");
                const debugUrl = `${this.relayServerUrl}/api/debug-sessions`;
                this.log(`🔧 서버 상태 확인: GET ${debugUrl} (또는 명령 팔레트에서 "Codex Remote: 릴레이 서버 상태 확인" 실행)`);
                return null;
            }
            let chosenSessionId = null;
            if (sessionsCount > 1 && this.onSessionsDiscoveredCallback) {
                this.log(`🔍 Discovery: 세션 ${sessionsCount}개 발견 → 사용자 선택 대기`);
                chosenSessionId = await this.onSessionsDiscoveredCallback(sessions);
                if (chosenSessionId === null || chosenSessionId === undefined) {
                    this.log("🔍 Discovery: 연결할 세션을 선택하지 않음 (다음 탐지에서 다시 표시)");
                    return null;
                }
            }
            const foundSession = chosenSessionId
                ? sessions.find((s) => s.sessionId === chosenSessionId) ?? sessions[0]
                : sessions[0];
            if (foundSession?.sessionId) {
                this.log(`🔍 Discovery: 세션 발견 → ${foundSession.sessionId}`);
                return foundSession.sessionId;
            }
            this.log("🔍 Discovery: session has no sessionId");
            return null;
        }
        catch (error) {
            this.logError("Discovery failed", error);
            return null;
        }
    }
    /**
     * Connect to a relay session (404/409 구분을 위해 statusCode 사용)
     * pin: PC가 설정하면 모바일은 이 PIN을 알아야만 접속 가능 (세션 ID만으로 타인 접속 방지)
     */
    async connectToSession(sid, pin) {
        if (this.connectInFlight) {
            return this.connectInFlight;
        }
        const connectRunToken = this.runToken;
        this.connectInFlight = (async () => {
            this.log(`🔗 Connecting to session ${sid}...`);
            try {
                const body = {
                    sessionId: sid,
                    deviceId: this.deviceId,
                    deviceType: "pc",
                };
                if (pin != null && pin.trim()) {
                    body.pin = pin.trim();
                }
                const result = await this.httpRequestWithStatus(`${this.relayServerUrl}/api/connect`, "POST", body);
                if (!this.isRunning || connectRunToken !== this.runToken) {
                    this.log(`ℹ️ Ignored stale connect response for session ${sid}`);
                    return;
                }
                if (result.statusCode === 409) {
                    this.pcInUse = true;
                    const msg = result.body?.error ??
                        "Session already in use by another PC";
                    this.logError("중복 사용 중인 세션 ID (다른 PC에서 사용 중입니다)", msg);
                    this.log("💡 다른 PC 창을 닫거나, 모바일에서 새 세션을 만든 뒤 해당 세션 ID를 입력하세요.");
                    return;
                }
                if (result.statusCode === 404) {
                    this.log("세션을 찾을 수 없습니다. 모바일에서 먼저 세션을 생성·연결한 뒤 같은 세션 ID로 접속하세요.");
                    return;
                }
                if (result.statusCode >= 200 &&
                    result.statusCode < 300 &&
                    result.body?.success) {
                    this.sessionId = sid;
                    this.isConnected = true;
                    this.startHeartbeat();
                    this.log(`✅ 익스텐션은 릴레이 서버를 통해 세션 ${this.sessionId}에 접속했습니다.`);
                    this.log(`💡 모바일에서 세션 ID ${this.sessionId}로 연결하세요.`);
                    if (this.onSessionConnectedCallback) {
                        this.onSessionConnectedCallback();
                    }
                }
                else {
                    const errMsg = result.body?.error ??
                        (typeof result.body === "object" && result.body !== null
                            ? JSON.stringify(result.body)
                            : String(result.statusCode));
                    this.logError(`Failed to connect: ${errMsg}`);
                    if (result.statusCode >= 500 && result.body) {
                        this.logError(`[Relay] Server 500 response: ${JSON.stringify(result.body)}`);
                    }
                }
            }
            catch (error) {
                this.logError("Error connecting to session", error);
            }
            finally {
                this.connectInFlight = null;
            }
        })();
        return this.connectInFlight;
    }
    /**
     * Send message to relay server
     */
    async sendMessage(message) {
        if (!this.sessionId || !this.isConnected) {
            this.logError("Cannot send message: not connected to session");
            return;
        }
        const sessionId = this.sessionId;
        const deviceId = this.deviceId;
        const relayServerUrl = this.relayServerUrl;
        this.sendQueue = this.sendQueue
            .catch(() => undefined)
            .then(async () => {
            try {
                this.lastRelayActivityAt = Date.now();
                const parsed = JSON.parse(message);
                if (parsed.type === "chat_response") {
                    this.log(`Sending chat_response to relay (text length: ${(parsed.text || "").length})`);
                }
                const data = await this.httpRequest(`${relayServerUrl}/api/send`, "POST", {
                    sessionId,
                    deviceId,
                    deviceType: "pc",
                    type: parsed.type || "message",
                    data: parsed,
                });
                const traceId = (typeof parsed.traceId === "string" && parsed.traceId.trim()) ||
                    (typeof parsed.id === "string" && parsed.id.trim()) ||
                    null;
                const commandId = (typeof parsed.id === "string" && parsed.id.trim()) || null;
                this.recordTraceHop({
                    traceId,
                    sessionId,
                    hop: "ext.send.to_relay",
                    commandId,
                    senderDeviceId: this.deviceId,
                    targetDeviceId: typeof parsed.targetDeviceId === "string"
                        ? parsed.targetDeviceId
                        : undefined,
                    meta: {
                        messageType: typeof parsed.type === "string" ? parsed.type : "message",
                    },
                });
                if (!data) {
                    this.logError("Relay /api/send returned no data");
                    return;
                }
                if (data.success) {
                    this.log("✅ Message sent to relay");
                }
                else {
                    this.logError(`Failed to send to relay: ${data.error}`);
                }
            }
            catch (error) {
                this.logError("Error sending to relay", error);
            }
        });
        return this.sendQueue;
    }
    /**
     * Get current session ID
     */
    getSessionId() {
        return this.sessionId;
    }
    /**
     * Check if connected to relay session
     */
    isConnectedToSession() {
        return this.isConnected && this.sessionId !== null;
    }
    /**
     * 현재 연결된 릴레이 세션에서 PC를 서버 기준으로 즉시 분리한다.
     * 실패해도 로컬 연결 상태는 stop()으로 정리한다.
     */
    async disconnectCurrentSession() {
        if (this.disconnectInFlight) {
            return this.disconnectInFlight;
        }
        this.disconnectInFlight = (async () => {
            const currentSessionId = this.sessionId;
            const wasConnected = this.isConnected;
            if (!currentSessionId || !wasConnected) {
                this.stop();
                return { success: true };
            }
            try {
                const result = await this.httpRequestWithStatus(`${this.relayServerUrl}/api/disconnect`, "POST", {
                    sessionId: currentSessionId,
                    deviceId: this.deviceId,
                    deviceType: "pc",
                });
                if (result.statusCode >= 200 &&
                    result.statusCode < 300 &&
                    result.body?.success) {
                    this.log(`🔌 릴레이 세션 ${currentSessionId} 서버 연결 해제 완료`);
                    return { success: true };
                }
                if (result.statusCode === 404) {
                    // 서버에 세션이 이미 없어도 로컬 정리 목적에는 성공으로 간주
                    this.log(`ℹ️ 릴레이 세션 ${currentSessionId}는 서버에 이미 없음(로컬 연결 정리 진행)`);
                    return { success: true };
                }
                const errMsg = result.body?.error ??
                    (typeof result.body === "object" && result.body !== null
                        ? JSON.stringify(result.body)
                        : `HTTP ${result.statusCode}`);
                this.logError("Failed to disconnect relay session", errMsg);
                return { success: false, error: String(errMsg) };
            }
            catch (error) {
                const errMsg = error instanceof Error ? error.message : String(error);
                this.logError("Failed to disconnect relay session", errMsg);
                return { success: false, error: errMsg };
            }
            finally {
                this.stop();
            }
        })();
        const result = await this.disconnectInFlight;
        this.disconnectInFlight = null;
        return result;
    }
    /**
     * 현재 연결된 릴레이 세션을 서버에서 정리한다.
     * keepPc=true(기본): 같은 세션 ID를 재생성하고 현재 PC 연결은 유지
     */
    async clearCurrentSession(keepPc = true) {
        if (!this.sessionId || !this.isConnected) {
            return { success: false, error: "No connected relay session" };
        }
        const currentSessionId = this.sessionId;
        if (!keepPc) {
            // 세션 종료 요청 시에는 즉시 로컬 폴링/자동 재연결 루프를 중단해
            // stale poll/connect가 다시 세션을 붙잡지 않도록 한다.
            this.stop();
        }
        try {
            const result = await this.httpRequestWithStatus(`${this.relayServerUrl}/api/session-clear`, "POST", {
                sessionId: currentSessionId,
                deviceId: this.deviceId,
                keepPc,
            });
            if (result.statusCode >= 200 &&
                result.statusCode < 300 &&
                result.body?.success) {
                const clearedCount = result.body?.data?.cleared?.mobileDeviceCount ?? "?";
                if (keepPc) {
                    this.sessionId = currentSessionId;
                    this.isConnected = true;
                    this.pcInUse = false;
                    this.startHeartbeat();
                    this.log(`🧹 세션 ${currentSessionId} 정리 완료 (모바일 ${clearedCount}개 정리, PC 연결 유지)`);
                }
                else {
                    this.log(`🧹 세션 ${currentSessionId} 정리 완료 (모바일 ${clearedCount}개 정리, 연결 종료)`);
                }
                return { success: true };
            }
            const errMsg = result.body?.error ??
                (typeof result.body === "object" && result.body !== null
                    ? JSON.stringify(result.body)
                    : `HTTP ${result.statusCode}`);
            this.logError("Failed to clear relay session", errMsg);
            return { success: false, error: String(errMsg) };
        }
        catch (error) {
            const errMsg = error instanceof Error ? error.message : String(error);
            this.logError("Failed to clear relay session", errMsg);
            return { success: false, error: errMsg };
        }
    }
    /**
     * 릴레이 서버 상태 확인 (디버그 API 호출)
     * Output 채널에 totalSessions, waitingForPc, hint 출력
     */
    async checkServerStatus() {
        const debugUrl = `${this.relayServerUrl}/api/debug-sessions`;
        this.log(`🔧 Checking relay server: GET ${debugUrl}`);
        try {
            const data = await this.httpRequest(debugUrl);
            if (!data) {
                this.log("🔧 서버 응답 없음 (네트워크 또는 CORS 확인)");
                return;
            }
            if (!data.success) {
                this.log(`🔧 API 오류: ${data.error ?? "unknown"}`);
                return;
            }
            const d = data.data;
            if (!d) {
                this.log("🔧 응답 data 없음");
                return;
            }
            this.log(`🔧 totalSessions=${d.totalSessions ?? "?"}, waitingForPc=${d.waitingForPc ?? "?"}, sessionsWithPc=${d.sessionsWithPc ?? "?"}`);
            if (d.hint) {
                this.log(`🔧 hint: ${d.hint}`);
            }
        }
        catch (error) {
            this.logError("checkServerStatus failed", error);
        }
    }
    /**
     * HTTP request that returns statusCode + body (connect API 404/409 구분용)
     */
    async httpRequestWithStatus(url, method = "GET", body) {
        return new Promise((resolve, reject) => {
            const urlObj = new url_1.URL(url);
            const isHttps = urlObj.protocol === "https:";
            const httpModule = isHttps ? https : http;
            const options = {
                hostname: urlObj.hostname,
                port: urlObj.port || (isHttps ? 443 : 80),
                path: urlObj.pathname + urlObj.search,
                method: method,
                headers: {
                    "Content-Type": "application/json",
                },
            };
            const req = httpModule.request(options, (res) => {
                let data = "";
                res.on("data", (chunk) => {
                    data += chunk;
                });
                res.on("end", () => {
                    const statusCode = res.statusCode ?? 0;
                    let parsed = null;
                    try {
                        parsed = data ? JSON.parse(data) : null;
                    }
                    catch {
                        parsed = null;
                    }
                    // 5xx인데 JSON이 아니면 원문 일부를 남겨 로그로 확인 가능하게
                    if (statusCode >= 500 && !parsed && data) {
                        parsed = {
                            error: data.length > 800 ? data.substring(0, 800) + "…" : data,
                        };
                    }
                    resolve({ statusCode, body: parsed });
                });
            });
            req.on("error", (error) => {
                this.logError("Request error", error);
                resolve({ statusCode: 0, body: null });
            });
            if (body && method === "POST") {
                req.write(JSON.stringify(body));
            }
            req.end();
        });
    }
    /**
     * HTTP request helper (using Node.js http/https modules)
     */
    async httpRequest(url, method = "GET", body) {
        return new Promise((resolve, reject) => {
            const urlObj = new url_1.URL(url);
            const isHttps = urlObj.protocol === "https:";
            const httpModule = isHttps ? https : http;
            const options = {
                hostname: urlObj.hostname,
                port: urlObj.port || (isHttps ? 443 : 80),
                path: urlObj.pathname + urlObj.search,
                method: method,
                headers: {
                    "Content-Type": "application/json",
                },
            };
            const req = httpModule.request(options, (res) => {
                let data = "";
                res.on("data", (chunk) => {
                    data += chunk;
                });
                res.on("end", () => {
                    if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
                        try {
                            const parsed = JSON.parse(data);
                            resolve(parsed);
                        }
                        catch (error) {
                            this.logError("Failed to parse response", error);
                            resolve(null);
                        }
                    }
                    else {
                        this.logError(`HTTP ${res.statusCode}: ${data}`);
                        resolve(null);
                    }
                });
            });
            req.on("error", (error) => {
                this.logError("Request error", error);
                resolve(null);
            });
            if (body && method === "POST") {
                req.write(JSON.stringify(body));
            }
            req.end();
        });
    }
}
exports.RelayClient = RelayClient;
//# sourceMappingURL=relay-client.js.map