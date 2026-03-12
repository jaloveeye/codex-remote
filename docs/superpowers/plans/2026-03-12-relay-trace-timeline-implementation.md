# Relay Trace Timeline Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 릴레이 서버를 단일 로그 수집자로 두고 traceId 기반 E2E 타임라인(수집/조회/API/모바일 UI)을 구현한다.

**Architecture:** 모바일/익스텐션/릴레이가 trace event를 릴레이로 적재하고, 릴레이가 timeline/summary/recent 조회 API를 제공한다. 모바일은 Trace Timeline UI로 병목/누락 hop을 시각화한다.

**Tech Stack:** TypeScript (Vercel API, VS Code extension), Flutter (mobile UI), Supabase/Redis store

---

## Chunk 1: Relay Trace Data Model + Timeline Core

### Task 1: Trace timeline 순수 로직(TDD)

**Files:**
- Create: `codex-relay-server/lib/trace-timeline.ts`
- Create: `codex-relay-server/scripts/test-trace-timeline.ts`
- Modify: `codex-relay-server/package.json`

- [ ] **Step 1: 실패 테스트 작성 (타임라인 계산/누락 hop/slowest segment)**
  - `scripts/test-trace-timeline.ts`에 node:test 케이스 추가

- [ ] **Step 2: 실패 확인**
  - Run: `cd codex-relay-server && node --experimental-strip-types scripts/test-trace-timeline.ts`
  - Expected: FAIL (module/function not found)

- [ ] **Step 3: 최소 구현 작성**
  - `buildTraceTimeline(events)` 구현
  - `totalMs`, `deltaFromPrevMs`, `missingHops`, `slowestSegment` 계산

- [ ] **Step 4: 통과 확인**
  - Run: `cd codex-relay-server && node --experimental-strip-types scripts/test-trace-timeline.ts`
  - Expected: PASS

- [ ] **Step 5: Commit**
  - `git commit -m "feat(relay): add trace timeline core calculator"`

### Task 2: Trace 타입/스토어 계약 추가

**Files:**
- Modify: `codex-relay-server/lib/types.ts`
- Modify: `codex-relay-server/lib/store.ts`

- [ ] **Step 1: 실패 테스트/타입 체크 준비**
  - `trace-timeline.ts`에서 새 타입 import하도록 설정

- [ ] **Step 2: 실패 확인**
  - Run: `cd codex-relay-server && npm run type-check`
  - Expected: FAIL (missing trace types/store exports)

- [ ] **Step 3: 최소 구현 작성**
  - `TraceEvent`, `TraceTimeline`, `TraceSummary` 타입 추가
  - store export 계약 (`appendTraceEvents`, `listTraceEventsByTraceId`, `listRecentTraceIdsBySession`) 추가

- [ ] **Step 4: 통과 확인**
  - Run: `cd codex-relay-server && npm run type-check`
  - Expected: PASS

- [ ] **Step 5: Commit**
  - `git commit -m "feat(relay): define trace contracts and store interfaces"`

### Task 3: Redis/Supabase trace 저장 구현

**Files:**
- Modify: `codex-relay-server/lib/redis.ts`
- Modify: `codex-relay-server/lib/supabase-store.ts`
- Modify: `codex-relay-server/supabase/schema.sql`

- [ ] **Step 1: 실패 확인**
  - Run: `cd codex-relay-server && npm run type-check`
  - Expected: FAIL (store method not implemented)

- [ ] **Step 2: 최소 구현 작성 (Redis)**
  - trace event append/list/recent list 구현 (TTL 적용)

- [ ] **Step 3: 최소 구현 작성 (Supabase)**
  - `relay_trace_events`, `relay_trace_summary` 스키마 추가
  - append/list/recent list 구현

- [ ] **Step 4: 통과 확인**
  - Run: `cd codex-relay-server && npm run type-check`
  - Expected: PASS

- [ ] **Step 5: Commit**
  - `git commit -m "feat(relay): persist trace events in redis and supabase"`

---

## Chunk 2: Relay Trace APIs + Relay-side Instrumentation

### Task 4: Trace write APIs 구현

**Files:**
- Create: `codex-relay-server/api/trace-event.ts`
- Create: `codex-relay-server/api/trace-events-batch.ts`

- [ ] **Step 1: 실패 확인**
  - Run: `cd codex-relay-server && npm run type-check`
  - Expected: FAIL (new imports/handlers unresolved)

- [ ] **Step 2: 최소 구현 작성**
  - CORS/OPTIONS 처리
  - payload validation (`traceId`, `hop`, `status`, `sessionId`)
  - store append 호출

- [ ] **Step 3: 통과 확인**
  - Run: `cd codex-relay-server && npm run type-check`
  - Expected: PASS

- [ ] **Step 4: Commit**
  - `git commit -m "feat(relay): add trace event ingest APIs"`

### Task 5: Trace read APIs 구현

**Files:**
- Create: `codex-relay-server/api/trace-timeline.ts`
- Create: `codex-relay-server/api/trace-summary.ts`
- Create: `codex-relay-server/api/trace-recent.ts`
- Modify: `codex-relay-server/vercel.json`

- [ ] **Step 1: 실패 테스트 작성 (조회 응답 shape 검증)**
  - Create: `codex-relay-server/scripts/test-trace-api-shape.ts`

- [ ] **Step 2: 실패 확인**
  - Run: `cd codex-relay-server && node --experimental-strip-types scripts/test-trace-api-shape.ts`
  - Expected: FAIL

- [ ] **Step 3: 최소 구현 작성**
  - `traceId`/`sessionId` validation
  - `trace-timeline`에서 `buildTraceTimeline` 사용
  - `vercel.json`에 `/api/trace/:traceId/timeline|summary` rewrite 추가

- [ ] **Step 4: 통과 확인**
  - Run: `cd codex-relay-server && node --experimental-strip-types scripts/test-trace-api-shape.ts`
  - Expected: PASS

- [ ] **Step 5: Commit**
  - `git commit -m "feat(relay): add trace timeline/summary/recent APIs"`

### Task 6: 릴레이 자체 hop 로깅 삽입

**Files:**
- Modify: `codex-relay-server/api/send.ts`
- Modify: `codex-relay-server/api/poll.ts`
- Create: `codex-relay-server/lib/trace-ingest.ts`

- [ ] **Step 1: 실패 확인 (type-check)**
  - Run: `cd codex-relay-server && npm run type-check`
  - Expected: FAIL (trace helper 미구현)

- [ ] **Step 2: 최소 구현 작성**
  - `/api/send`: `relay.recv.from_mobile`, `relay.recv.from_pc`, `relay.enqueue.*`
  - `/api/poll`: 반환 시 `relay.dequeue.*` equivalent event
  - trace write 실패는 본 요청 실패로 전파하지 않음(best-effort)

- [ ] **Step 3: 통과 확인**
  - Run: `cd codex-relay-server && npm run type-check`
  - Expected: PASS

- [ ] **Step 4: Commit**
  - `git commit -m "feat(relay): emit relay-side trace hops in send/poll"`

---

## Chunk 3: Extension Trace Emission

### Task 7: Extension trace emitter 유틸(TDD)

**Files:**
- Create: `codex-extension/src/trace_emitter.ts`
- Create: `codex-extension/src/trace_emitter.test.ts`

- [ ] **Step 1: 실패 테스트 작성**
  - node:test로 payload normalization / batch flush 규칙 검증

- [ ] **Step 2: 실패 확인**
  - Run: `cd codex-extension && npm run compile && node --test out/trace_emitter.test.js`
  - Expected: FAIL

- [ ] **Step 3: 최소 구현 작성**
  - `emitTraceHop()` / `flushTraceBatch()` 구현
  - 실패 시 swallow + outputChannel warn

- [ ] **Step 4: 통과 확인**
  - Run: `cd codex-extension && npm run compile && node --test out/trace_emitter.test.js`
  - Expected: PASS

- [ ] **Step 5: Commit**
  - `git commit -m "feat(extension): add relay trace emitter utility"`

### Task 8: Extension 수신/전송/codex hop 삽입

**Files:**
- Modify: `codex-extension/src/relay-client.ts`
- Modify: `codex-extension/src/extension.ts`
- Modify: `codex-extension/src/codex-handler.ts`
- Modify: `codex-extension/src/types.ts`

- [ ] **Step 1: 실패 확인 (compile)**
  - Run: `cd codex-extension && npm run compile`
  - Expected: FAIL (trace fields missing)

- [ ] **Step 2: 최소 구현 작성**
  - relay poll 수신 시 `ext.poll.recv`
  - codex dispatch/start/chunk/complete 시 hop emit
  - relay 재전송 시 `ext.send.to_relay`
  - message payload에 `traceId` pass-through 유지

- [ ] **Step 3: 통과 확인**
  - Run: `cd codex-extension && npm run compile`
  - Expected: PASS

- [ ] **Step 4: Commit**
  - `git commit -m "feat(extension): emit trace hops across relay and codex pipeline"`

---

## Chunk 4: Mobile Trace Emission + Timeline UI

### Task 9: Mobile trace 모델/파서(TDD)

**Files:**
- Create: `mobile-app/lib/models/trace_timeline_models.dart`
- Create: `mobile-app/lib/services/trace_timeline_parser.dart`
- Create: `mobile-app/test/services/trace_timeline_parser_test.dart`

- [ ] **Step 1: 실패 테스트 작성**
  - timeline JSON -> model 파싱, missing hop/slowest segment 계산값 검증

- [ ] **Step 2: 실패 확인**
  - Run: `cd mobile-app && flutter test test/services/trace_timeline_parser_test.dart`
  - Expected: FAIL

- [ ] **Step 3: 최소 구현 작성**
  - parser/model 구현

- [ ] **Step 4: 통과 확인**
  - Run: `cd mobile-app && flutter test test/services/trace_timeline_parser_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit**
  - `git commit -m "feat(mobile): add trace timeline models and parser"`

### Task 10: Mobile trace emit + 조회 서비스

**Files:**
- Create: `mobile-app/lib/services/trace_api_service.dart`
- Modify: `mobile-app/lib/main.dart`

- [ ] **Step 1: 실패 확인 (analyze/test)**
  - Run: `cd mobile-app && flutter test test/widget_test.dart`
  - Expected: FAIL (new wiring absent)

- [ ] **Step 2: 최소 구현 작성**
  - prompt 전송 시 `traceId` 생성/전달
  - hop emit: `mobile.prompt.created`, `mobile.send.to_relay`, `mobile.poll.recv`, `mobile.ui.rendered`
  - timeline/recent 조회 서비스 연결

- [ ] **Step 3: 통과 확인**
  - Run: `cd mobile-app && flutter test test/widget_test.dart`
  - Expected: PASS

- [ ] **Step 4: Commit**
  - `git commit -m "feat(mobile): emit trace hops and fetch trace timeline APIs"`

### Task 11: Trace Timeline UI 구현

**Files:**
- Create: `mobile-app/lib/widgets/trace_timeline_panel.dart`
- Create: `mobile-app/test/trace_timeline_panel_test.dart`
- Modify: `mobile-app/lib/main.dart`
- Modify: `mobile-app/lib/services/app_i18n.dart`

- [ ] **Step 1: 실패 위젯 테스트 작성**
  - loading/loaded/error/missing hop 색상/배지 검증

- [ ] **Step 2: 실패 확인**
  - Run: `cd mobile-app && flutter test test/trace_timeline_panel_test.dart`
  - Expected: FAIL

- [ ] **Step 3: 최소 구현 작성**
  - 입력(traceId/recent), summary card, hop list, copy report 구현

- [ ] **Step 4: 통과 확인**
  - Run: `cd mobile-app && flutter test test/trace_timeline_panel_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit**
  - `git commit -m "feat(mobile): add trace timeline debug panel UI"`

---

## Chunk 5: E2E Verification + Docs

### Task 12: 실전 검증 스크립트/문서 업데이트

**Files:**
- Modify: `test-relay-live-roundtrip.js`
- Modify: `README.md`
- Modify: `codex-relay-server/README.md`
- Modify: `mobile-app/README.md`

- [ ] **Step 1: traceId 포함 e2e 스크립트 확장**
  - 라운드트립 후 `trace-timeline` 조회 및 핵심 latency 출력

- [ ] **Step 2: 로컬 검증**
  - Run: `npm run build:extension`
  - Run: `cd codex-relay-server && npm run type-check`
  - Run: `cd mobile-app && flutter test`
  - Run (환경 필요): `npm run test:relay:live -- --relay <RELAY_URL>`

- [ ] **Step 3: 문서 반영**
  - trace 수집 정책(원문 미저장), 운영 점검 절차, API 예시 업데이트

- [ ] **Step 4: Commit**
  - `git commit -m "docs: add relay trace timeline operations and verification guide"`

---

## Final Verification Gate (feature 브랜치)

- [ ] `cd codex-relay-server && npm run type-check`
- [ ] `cd codex-extension && npm run compile`
- [ ] `cd mobile-app && flutter test`
- [ ] `cd mobile-app && flutter test test/services/streaming_text_merge_test.dart` *(스트리밍/응답 처리 경로 영향 회귀)*
- [ ] `npm run test:relay:live -- --relay <RELAY_URL>` *(실환경 가능 시)*

---

## Risks & Guardrails

- trace 수집 실패는 절대 사용자 요청 실패로 전파하지 않는다.
- 프롬프트/응답 원문 저장 금지, 길이/해시/코드만 저장한다.
- 대규모 로그 폭주 방지를 위해 batch write + sampling(기본 10%, error/timeout 100%)를 적용한다.
