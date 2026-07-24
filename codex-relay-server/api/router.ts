import commandApprovals from "./command-approvals.js";
import commandEvents from "./command-events.js";
import commandTimelineSummary from "./command-timeline-summary.js";
import connect from "./connect.js";
import debugSessions from "./debug-sessions.js";
import disconnect from "./disconnect.js";
import health from "./health.js";
import heartbeat from "./heartbeat.js";
import poll from "./poll.js";
import resolveCommandApproval from "./resolve-command-approval.js";
import send from "./send.js";
import sessionClear from "./session-clear.js";
import session from "./session.js";
import sessionsWaitingForPc from "./sessions-waiting-for-pc.js";
import sessionsWithMobile from "./sessions-with-mobile.js";
import store from "./store.js";
import stream from "./stream.js";
import traceEvent from "./trace-event.js";
import traceEventsBatch from "./trace-events-batch.js";
import traceRecent from "./trace-recent.js";
import traceSummary from "./trace-summary.js";
import traceTimeline from "./trace-timeline.js";
import version from "./version.js";
import {
  createRelayRouter,
  type RelayHandlerRegistry,
} from "../lib/relay-router.js";

const handlers = {
  "command-approvals": commandApprovals,
  "command-events": commandEvents,
  "command-timeline-summary": commandTimelineSummary,
  connect,
  "debug-sessions": debugSessions,
  disconnect,
  health,
  heartbeat,
  poll,
  "resolve-command-approval": resolveCommandApproval,
  send,
  "session-clear": sessionClear,
  session,
  "sessions-waiting-for-pc": sessionsWaitingForPc,
  "sessions-with-mobile": sessionsWithMobile,
  store,
  stream,
  "trace-event": traceEvent,
  "trace-events-batch": traceEventsBatch,
  "trace-recent": traceRecent,
  "trace-summary": traceSummary,
  "trace-timeline": traceTimeline,
  version,
} satisfies RelayHandlerRegistry;

export const config = {
  maxDuration: 30,
};

export default createRelayRouter(handlers);
