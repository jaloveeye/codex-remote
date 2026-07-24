// 메시지 타입 정의

export type DeviceType = "mobile" | "pc";

export interface RelayMessage {
  id: string;
  type: string;
  from: DeviceType;
  to: DeviceType;
  data: Record<string, unknown>;
  timestamp: number;
  senderDeviceId?: string; // 요청을 보낸 클라이언트 ID
  targetDeviceId?: string; // 응답을 받을 클라이언트 ID (유니캐스트)
}

export interface PollMessagesResult {
  sessionFound: boolean;
  messages: RelayMessage[];
}

export interface DeviceInfo {
  deviceId: string;
  deviceType: DeviceType;
  sessionId: string;
  connectedAt: number;
  lastSeen: number;
}

export interface Session {
  sessionId: string;
  pcDeviceId?: string;
  /** PC가 마지막으로 폴링한 시각(ms). 없으면 PC 비연결/구버전. */
  pcLastSeenAt?: number;
  /** PC가 설정한 PIN의 해시. 있으면 모바일 연결 시 PIN 필요 (세션 ID만으로 타인 접속 방지) */
  pcPinHash?: string;
  mobileDeviceIds?: string[]; // 멀티 클라이언트 지원을 위해 배열로 변경
  createdAt: number;
  expiresAt: number;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: number;
}

export const TRACE_HOP_ORDER = [
  "mobile.prompt.created",
  "mobile.send.to_relay",
  "relay.recv.from_mobile",
  "relay.enqueue.to_pc",
  "ext.poll.recv",
  "ext.dispatch.to_codex",
  "codex.turn.started",
  "codex.first_chunk",
  "codex.turn.completed",
  "ext.send.to_relay",
  "relay.recv.from_pc",
  "relay.enqueue.to_mobile",
  "mobile.poll.recv",
  "mobile.ui.rendered",
] as const;

export type TraceHop = (typeof TRACE_HOP_ORDER)[number] | (string & {});
export type TraceStatus = "ok" | "error" | "timeout" | "fail";

export interface TraceEvent {
  event_id: string;
  trace_id: string;
  session_id: string;
  hop: TraceHop;
  status: TraceStatus;
  server_ts: number;
  source_ts?: number;
  command_id?: string | null;
  relay_message_id?: string | null;
  client_id?: string | null;
  sender_device_id?: string | null;
  target_device_id?: string | null;
  meta?: Record<string, unknown>;
}

export interface TraceTimelineHop {
  hop: string;
  ts: number;
  deltaFromPrevMs: number;
  status: TraceStatus;
}

export interface TraceTimeline {
  traceId: string;
  sessionId: string | null;
  startedAt: number;
  endedAt: number;
  totalMs: number;
  hops: TraceTimelineHop[];
  missingHops: string[];
  slowestSegment: {
    from: string;
    to: string;
    ms: number;
  } | null;
  errors: Array<{ hop: string; status: TraceStatus }>;
}

export interface TraceSummary {
  traceId: string;
  sessionId: string | null;
  startedAt: number;
  endedAt: number;
  totalMs: number;
  missingHopCount: number;
  errorCount: number;
  slowestSegment: {
    from: string;
    to: string;
    ms: number;
  } | null;
}

export type RiskLevel = "low" | "medium" | "high" | "critical";
export type PolicyDecision = "allow" | "approval_required" | "deny";
export type ApprovalStatus =
  | "not_required"
  | "pending"
  | "approved"
  | "rejected";

export interface CommandEvent {
  event_id: string;
  session_id: string;
  timestamp: number;
  tool: {
    provider: "codex" | "other";
    name: string;
  };
  command: {
    raw: string;
    cwd?: string;
  };
  risk: {
    level: RiskLevel;
    reasons: string[];
  };
  policy: {
    decision: PolicyDecision;
    rule_id?: string;
  };
  approval: {
    required: boolean;
    status: ApprovalStatus;
    approved_by?: string | null;
    approved_at?: number | null;
    reason?: string | null;
  };
  result: {
    status: "pending" | "running" | "success" | "error" | "cancelled" | "timeout";
    exit_code?: number | null;
    duration_ms?: number;
    error_message?: string | null;
  };
  metadata?: Record<string, unknown>;
}

export interface CommandApprovalRequest {
  approval_id: string;
  session_id: string;
  created_at: number;
  status: "pending" | "approved" | "rejected";
  requested_by: string;
  command_message: RelayMessage;
  policy: {
    decision: "approval_required";
    rule_id: string;
    risk_level: RiskLevel;
    reasons: string[];
  };
  resolved_at?: number | null;
  resolved_by?: string | null;
  resolution_reason?: string | null;
}

export type CodexServerRequestKind =
  | "command_execution"
  | "file_change"
  | "user_input";

export interface CodexServerRequestChoice {
  label: string;
  style?: "primary" | "secondary" | "danger";
  response: Record<string, unknown>;
}

export interface CodexServerRequestMessage {
  type: "codex_server_request";
  requestId: string;
  method: string;
  requestKind: CodexServerRequestKind;
  title: string;
  summary?: string;
  detailLines?: string[];
  choices?: CodexServerRequestChoice[];
  questions?: Array<Record<string, unknown>>;
  clientId?: string;
  sessionId?: string;
  targetDeviceId?: string;
  timestamp?: string;
  source?: "codex";
}

export interface CodexServerRequestResponseMessage {
  type: "codex_server_request_response";
  requestId: string;
  method: string;
  response: Record<string, unknown>;
  clientId?: string;
  timestamp?: string;
}

export interface CodexServerRequestStatusMessage {
  type: "codex_server_request_status";
  requestId: string;
  method: string;
  status: "resolved" | "timed_out" | "fallback_to_desktop" | "error";
  message: string;
  clientId?: string;
  targetDeviceId?: string;
  timestamp?: string;
}

// Redis 키 패턴
export const REDIS_KEYS = {
  // 세션 정보
  session: (sessionId: string) => `session:${sessionId}`,
  // 세션 목록 (Set)
  sessionList: () => `sessions:list`,
  // 디바이스 → 세션 매핑
  deviceSession: (deviceId: string) => `device:${deviceId}:session`,
  // 메시지 큐 (PC → Mobile) - 세션 단위 (deprecated, 하위 호환용)
  messagesPC2Mobile: (sessionId: string) => `messages:${sessionId}:pc2mobile`,
  // 메시지 큐 (Mobile → PC) - 세션 단위
  messagesMobile2PC: (sessionId: string) => `messages:${sessionId}:mobile2pc`,
  // 메시지 큐 (PC → 특정 Mobile 클라이언트) - 클라이언트별 큐
  messagesForDevice: (sessionId: string, deviceId: string) =>
    `messages:${sessionId}:device:${deviceId}`,
  // 푸시 알림용 pubsub 채널
  channel: (sessionId: string, target: DeviceType) =>
    `channel:${sessionId}:${target}`,
  // 커맨드 이벤트 로그 (세션별 타임라인)
  commandEvents: (sessionId: string) => `events:${sessionId}:commands`,
  // 커맨드 승인 요청 (세션별 + 개별)
  sessionApprovals: (sessionId: string) => `approvals:${sessionId}:ids`,
  commandApproval: (approvalId: string) => `approval:${approvalId}`,
  // Trace 이벤트 (traceId 단위 + session 최근 trace 목록)
  traceEvents: (traceId: string) => `trace:${traceId}:events`,
  traceIdsBySession: (sessionId: string) => `trace:${sessionId}:trace-ids`,
} as const;

// TTL 설정 (초)
export const TTL = {
  session: 24 * 60 * 60, // 24시간
  message: 5 * 60, // 5분
  device: 24 * 60 * 60, // 24시간
  trace: 7 * 24 * 60 * 60, // 7일
} as const;

export const MAX_MOBILE_DEVICE_IDS = 5;
