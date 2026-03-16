const int relayPollIntervalIdleMs = 2000;
const int relayPollIntervalActiveMs = 250;

int relayPollIntervalMs({
  required bool waitingForResponse,
  required bool streamingResponse,
  required bool hasPendingRelayApprovals,
  required bool hasPendingCodexRequests,
}) {
  final isActive = waitingForResponse ||
      streamingResponse ||
      hasPendingRelayApprovals ||
      hasPendingCodexRequests;
  return isActive ? relayPollIntervalActiveMs : relayPollIntervalIdleMs;
}
