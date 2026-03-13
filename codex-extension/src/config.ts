/**
 * Configuration constants for Codex Remote Extension
 */

export const CONFIG = {
    // WebSocket server port
    WEBSOCKET_PORT: 8766,

    // Relay server URL
    RELAY_SERVER_URL: process.env.RELAY_SERVER_URL || 'https://codex-relay.jaloveeye.com',

    // Codex app-server command
    CODEX_COMMAND: process.env.CODEX_COMMAND || 'codex',
    CODEX_APP_SERVER_ARGS: (process.env.CODEX_APP_SERVER_ARGS || 'app-server')
        .split(' ')
        .map((arg) => arg.trim())
        .filter((arg) => arg.length > 0),
    // 스트리밍 chunk 전송 사용 여부 (체감 속도 우선 기본값: true)
    STREAM_CHAT_CHUNKS:
        (process.env.CODEX_REMOTE_STREAM_CHAT_CHUNKS || 'true').toLowerCase() === 'true',

    // Port range for finding available ports
    PORT_SEARCH_MAX_ATTEMPTS: 10,

    // File paths
    TERMINAL_OUTPUT_FILE: '.codex-remote-terminal-output.log',

    // Timeouts (in milliseconds)
    TERMINAL_ACTIVATION_DELAY: 800,
    TERMINAL_FOCUS_DELAY: 500,
    TERMINAL_EXECUTION_DELAY: 500,

    // Content processing
    MIN_AI_RESPONSE_LENGTH: 50,
    CONTENT_HASH_LENGTH: 200,
    MAX_CONTENT_CHECK_LENGTH: 1000,

    // Command patterns
    COMMAND_PATTERNS: [
        /^[a-z]+-[a-z]+/i,
        /^[a-z]+\.[a-z]+/i,
        /^[a-z]+:[a-z]+/i,
    ],

    // Plain text patterns (not commands)
    PLAIN_TEXT_PATTERNS: [
        /^hello\s*$/i,
        /^hi\s*$/i,
        /^hey\s*$/i,
    ],
} as const;
