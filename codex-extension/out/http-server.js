"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HttpServer = void 0;
/**
 * Legacy placeholder kept only for source compatibility.
 * Codex-only runtime no longer starts a local hook HTTP server.
 */
class HttpServer {
    constructor(_outputChannel, _wsServer) { }
    async start() {
        // no-op
    }
    getPort() {
        return null;
    }
    stop() {
        // no-op
    }
}
exports.HttpServer = HttpServer;
//# sourceMappingURL=http-server.js.map