-- Codex Relay Server - Supabase 스키마
-- Supabase Dashboard > SQL Editor에서 실행하세요.

-- 세션 (Redis session:* + sessions:list 역할)
CREATE TABLE IF NOT EXISTS relay_sessions (
  session_id TEXT PRIMARY KEY,
  pc_device_id TEXT,
  pc_last_seen_at BIGINT,
  pc_pin_hash TEXT,
  mobile_device_ids JSONB DEFAULT '[]',
  created_at BIGINT NOT NULL,
  expires_at BIGINT NOT NULL
);

-- 디바이스 → 세션 매핑 (Redis device:*:session)
CREATE TABLE IF NOT EXISTS relay_device_sessions (
  device_id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  expires_at BIGINT NOT NULL,
  FOREIGN KEY (session_id) REFERENCES relay_sessions(session_id) ON DELETE CASCADE
);

-- 메시지 큐 (Redis List 대체, FIFO)
CREATE TABLE IF NOT EXISTS relay_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id TEXT NOT NULL,
  direction TEXT NOT NULL,  -- 'mobile2pc' | 'pc2mobile' | 'pc2device'
  device_id TEXT,          -- pc2device 일 때 대상 모바일 device_id
  body JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at BIGINT
);

CREATE INDEX IF NOT EXISTS idx_relay_messages_session_direction
  ON relay_messages(session_id, direction, created_at);
CREATE INDEX IF NOT EXISTS idx_relay_messages_session_device
  ON relay_messages(session_id, direction, device_id, created_at);

-- 커맨드 이벤트 타임라인 (정책/승인/결과 감사 로그)
CREATE TABLE IF NOT EXISTS relay_command_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id TEXT NOT NULL,
  event_id TEXT NOT NULL,
  ts BIGINT NOT NULL,
  body JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_relay_command_events_session_ts
  ON relay_command_events(session_id, ts DESC);

-- 커맨드 승인 요청 (approval_required 명령 대기열)
CREATE TABLE IF NOT EXISTS relay_command_approvals (
  approval_id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  status TEXT NOT NULL, -- 'pending' | 'approved' | 'rejected'
  created_at BIGINT NOT NULL,
  resolved_at BIGINT,
  resolved_by TEXT,
  resolution_reason TEXT,
  body JSONB NOT NULL,
  inserted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_relay_command_approvals_session_status_created
  ON relay_command_approvals(session_id, status, created_at DESC);

-- Trace 이벤트 원본 (hop 단위)
CREATE TABLE IF NOT EXISTS relay_trace_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trace_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  event_id TEXT NOT NULL,
  hop TEXT NOT NULL,
  status TEXT NOT NULL, -- 'ok' | 'error' | 'timeout' | 'fail'
  server_ts BIGINT NOT NULL,
  source_ts BIGINT,
  command_id TEXT,
  relay_message_id TEXT,
  client_id TEXT,
  sender_device_id TEXT,
  target_device_id TEXT,
  body JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_relay_trace_events_trace_ts
  ON relay_trace_events(trace_id, server_ts);
CREATE INDEX IF NOT EXISTS idx_relay_trace_events_session_ts
  ON relay_trace_events(session_id, server_ts DESC);

-- Trace 요약(선택적 집계용)
CREATE TABLE IF NOT EXISTS relay_trace_summary (
  trace_id TEXT PRIMARY KEY,
  session_id TEXT,
  started_at BIGINT NOT NULL,
  ended_at BIGINT NOT NULL,
  total_ms BIGINT NOT NULL,
  missing_hop_count INT NOT NULL DEFAULT 0,
  error_count INT NOT NULL DEFAULT 0,
  slowest_from TEXT,
  slowest_to TEXT,
  slowest_ms BIGINT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_relay_trace_summary_session_updated
  ON relay_trace_summary(session_id, updated_at DESC);

-- 만료된 행 정리용 (선택: pg_cron 또는 Edge Function에서 주기 실행)
-- DELETE FROM relay_sessions WHERE expires_at < extract(epoch from now()) * 1000;
-- DELETE FROM relay_device_sessions WHERE expires_at < extract(epoch from now()) * 1000;
-- DELETE FROM relay_messages WHERE expires_at IS NOT NULL AND expires_at < extract(epoch from now()) * 1000;
-- DELETE FROM relay_trace_events WHERE server_ts < (extract(epoch from now()) * 1000 - 7 * 24 * 60 * 60 * 1000);
