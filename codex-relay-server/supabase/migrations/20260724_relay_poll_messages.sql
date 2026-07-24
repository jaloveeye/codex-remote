-- Atomically validate a relay session, refresh the PC heartbeat, and dequeue
-- messages in one PostgREST RPC call.
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
