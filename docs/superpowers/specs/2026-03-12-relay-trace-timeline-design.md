# Relay Trace Timeline Design

**Date:** 2026-03-12  
**Status:** Approved (Design Only)  
**Author:** Codex Assistant + User agreement

---

## 1) Goal

릴레이 서버를 단일 수집 지점(SSOT)으로 사용해, 프롬프트 1건의 전체 경로를 `traceId` 기준으로 재구성하고 병목/누락 지점을 빠르게 확인한다.

---

## 2) Scope

### In Scope
- 릴레이 서버 중심 trace 이벤트 수집
- trace 조회 API (`timeline`, `summary`, `recent`)
- 모바일 UI에 Trace Timeline 디버그 섹션 추가
- 운영 확인 절차(지연 발생 시 traceId 기반 분석)

### Out of Scope
- OpenTelemetry 전면 도입
- 프롬프트/응답 원문 저장
- 일반 사용자용 상시 노출 화면(디버그/운영 중심)

---

## 3) End-to-End Hop Model

표준 hop 순서:
1. `mobile.prompt.created`
2. `mobile.send.to_relay`
3. `relay.recv.from_mobile`
4. `relay.enqueue.to_pc`
5. `ext.poll.recv`
6. `ext.dispatch.to_codex`
7. `codex.turn.started`
8. `codex.first_chunk`
9. `codex.turn.completed`
10. `ext.send.to_relay`
11. `relay.recv.from_pc`
12. `relay.enqueue.to_mobile`
13. `mobile.poll.recv`
14. `mobile.ui.rendered`

---

## 4) Trace Event Contract

모든 컴포넌트가 유지할 공통 식별자:
- `traceId` (프롬프트 단위)
- `sessionId`
- `commandId` (기존 command id 재사용 가능)
- `relayMessageId` (릴레이 부여)
- `clientId`, `senderDeviceId`, `targetDeviceId` (가능한 경우)

### Event Schema
```json
{
  "eventId": "tev_...",
  "traceId": "trc_...",
  "sessionId": "ABC123",
  "hop": "relay.recv.from_mobile",
  "status": "ok",
  "serverTs": 1760000000000,
  "sourceTs": 1760000000000,
  "commandId": "cmd_...",
  "relayMessageId": "msg_...",
  "clientId": "relay-client",
  "senderDeviceId": "mobile-...",
  "targetDeviceId": "pc-...",
  "meta": {
    "httpStatus": 200,
    "textLength": 128,
    "chunkIndex": 3,
    "errorCode": null
  }
}
```

정렬/지연 계산 기준 시간은 `serverTs`로 통일한다.

---

## 5) Relay API Design

### Write APIs
- `POST /api/trace-event` : 단건 수집
- `POST /api/trace-events/batch` : 배치 수집(권장)

### Read APIs
- `GET /api/trace/:traceId/timeline`  
  - hop 정렬, 구간별 latency, 누락 hop, slowest segment 반환
- `GET /api/trace/:traceId/summary`  
  - 총 지연/오류/타임아웃/병목 요약
- `GET /api/trace/recent?sessionId=...&limit=20`  
  - 모바일 UI 최근 trace 목록

### Timeline Response (UI 소비형)
```json
{
  "success": true,
  "data": {
    "traceId": "trc_...",
    "sessionId": "ABC123",
    "startedAt": 1760000000000,
    "endedAt": 1760000004567,
    "totalMs": 4567,
    "hops": [
      { "hop": "mobile.send.to_relay", "ts": 1760000000100, "deltaFromPrevMs": 0, "status": "ok" },
      { "hop": "relay.recv.from_mobile", "ts": 1760000000150, "deltaFromPrevMs": 50, "status": "ok" }
    ],
    "missingHops": ["codex.first_chunk"],
    "slowestSegment": {
      "from": "ext.dispatch.to_codex",
      "to": "codex.first_chunk",
      "ms": 3200
    },
    "errors": []
  },
  "timestamp": 1760000005000
}
```

---

## 6) Storage & Retention

### Tables / Collections
1. `relay_trace_events` (raw events)
2. `relay_trace_summary` (집계)

### Index
- `(trace_id, server_ts)`
- `(session_id, server_ts desc)`

### Retention
- raw: 7일
- summary: 30일

Redis 모드에서는 short TTL 리스트를 사용하되, 운영 분석은 summary 보존을 우선한다.

---

## 7) Mobile UI Design (Trace Timeline)

위치: `Approvals & actions` 아래 디버그 섹션

### 구성
1. 조회 입력
   - traceId 입력
   - recent trace dropdown
   - 조회/새로고침
   - auto-refresh 토글(기본 OFF)
2. 요약 카드
   - total latency
   - slowest segment
   - missing hops
   - error/timeout count
3. hop 타임라인 리스트
   - `hop | ts | delta(ms) | status`
   - 색상: ok(초록), slow(주황), error/timeout(빨강), missing(배지)
4. 액션
   - Copy trace report
   - Raw JSON 보기

### 상태 모델
- `idle`, `loading`, `loaded`, `empty`, `error`

### 임계치
- segment > 2s: slow
- segment > 10s: critical slow
- total > 30s: warning banner

---

## 8) Operations Playbook

1. 사용자 지연 제보 + `traceId` 확보
2. 모바일 UI 또는 API에서 `timeline` 조회
3. 병목/누락 hop 판별
4. 컴포넌트별 상세 로그 drill-down

진단 예시:
- `relay.recv.from_mobile` 없음 → 모바일 전송 문제
- `ext.poll.recv` 없음 → 릴레이→익스텐션 문제
- `codex.first_chunk` 장지연 → codex 처리 병목
- `mobile.poll.recv` 없음 → 모바일 폴링/수신 문제

---

## 9) Security & Privacy

- 프롬프트/응답 원문 미저장 (메타데이터만)
- 민감 필드 마스킹
- `/api/trace*` 인증/권한 및 rate limit 적용
- trace 수집 실패는 본 기능에 영향 주지 않는 best-effort

---

## 10) Rollout Plan

1. Phase 1: 릴레이 수집 API + 저장소 + 조회 API
2. Phase 2: 모바일/익스텐션 trace 이벤트 발행
3. Phase 3: 모바일 Trace Timeline UI
4. Phase 4: 자동 병목 판정/경고 고도화

---

## 11) Verification Plan

- 단위: 정렬/중복 제거/누락 판정/latency 계산
- 통합: synthetic trace로 timeline expected 검증
- 실환경: live roundtrip 스크립트 + trace API 결과 대조

---

## 12) Acceptance Criteria

- traceId 1개로 E2E hop 타임라인 재구성 가능
- 총 지연/병목 구간 자동 계산
- 누락 hop 탐지 가능
- 모바일 UI에서 trace 조회/복사 가능
- 민감 원문 미저장 정책 준수

