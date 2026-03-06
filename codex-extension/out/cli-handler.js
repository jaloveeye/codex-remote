"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CLIHandler = void 0;
/**
 * Legacy placeholder kept only for source compatibility.
 * The active runtime path is codex-only via CodexHandler.
 */
class CLIHandler {
    constructor(_outputChannel, _wsServer, _workspaceRoot) { }
    setGetRelaySessionId(_getter) {
        // no-op
    }
    getChatHistory(_clientId, _sessionId, _relaySessionId, _limit = 50) {
        return [];
    }
    dispose() {
        // no-op
    }
}
exports.CLIHandler = CLIHandler;
//# sourceMappingURL=cli-handler.js.map