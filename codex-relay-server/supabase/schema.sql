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

-- 세션 검증, PC heartbeat 갱신, FIFO dequeue를 한 번의 RPC로 수행
CREATE OR REPLACE FUNCTION public.relay_poll_messages(
  p_session_id TEXT,
  p_device_type TEXT,
  p_device_id TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_pc_device_id TEXT;
  v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 10), 1), 50);
  v_messages JSONB := '[]'::JSONB;
BEGIN
  IF p_device_type NOT IN ('pc', 'mobile') THEN
    RAISE EXCEPTION 'device type must be pc or mobile';
  END IF;

  SELECT pc_device_id
    INTO v_pc_device_id
    FROM public.relay_sessions
   WHERE session_id = p_session_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'sessionFound', FALSE,
      'messages', '[]'::JSONB
    );
  END IF;

  IF p_device_type = 'pc'
     AND p_device_id IS NOT NULL
     AND v_pc_device_id = p_device_id THEN
    UPDATE public.relay_sessions
       SET pc_last_seen_at =
             (EXTRACT(EPOCH FROM clock_timestamp()) * 1000)::BIGINT,
           expires_at =
             (EXTRACT(EPOCH FROM clock_timestamp()) * 1000)::BIGINT
             + 86400000
     WHERE session_id = p_session_id;
  END IF;

  WITH candidates AS (
    SELECT id
      FROM public.relay_messages
     WHERE session_id = p_session_id
       AND (
         (p_device_type = 'pc' AND direction = 'mobile2pc')
         OR
         (
           p_device_type = 'mobile'
           AND p_device_id IS NOT NULL
           AND direction = 'pc2device'
           AND device_id = p_device_id
         )
         OR
         (
           p_device_type = 'mobile'
           AND p_device_id IS NULL
           AND direction = 'pc2mobile'
           AND device_id IS NULL
         )
       )
     ORDER BY created_at ASC, id ASC
     LIMIT v_limit
     FOR UPDATE SKIP LOCKED
  ),
  deleted AS (
    DELETE FROM public.relay_messages AS message
     USING candidates
     WHERE message.id = candidates.id
     RETURNING message.body, message.created_at, message.id
  )
  SELECT COALESCE(
           jsonb_agg(body ORDER BY created_at ASC, id ASC),
           '[]'::JSONB
         )
    INTO v_messages
    FROM deleted;

  RETURN jsonb_build_object(
    'sessionFound', TRUE,
    'messages', v_messages
  );
END;
$$;

REVOKE ALL ON FUNCTION public.relay_poll_messages(
  TEXT,
  TEXT,
  TEXT,
  INTEGER
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.relay_poll_messages(
  TEXT,
  TEXT,
  TEXT,
  INTEGER
) TO service_role;

-- 만료된 행 정리용 (선택: pg_cron 또는 Edge Function에서 주기 실행)
-- DELETE FROM relay_sessions WHERE expires_at < extract(epoch from now()) * 1000;
-- DELETE FROM relay_device_sessions WHERE expires_at < extract(epoch from now()) * 1000;
-- DELETE FROM relay_messages WHERE expires_at IS NOT NULL AND expires_at < extract(epoch from now()) * 1000;
-- DELETE FROM relay_trace_events WHERE server_ts < (extract(epoch from now()) * 1000 - 7 * 24 * 60 * 60 * 1000);
