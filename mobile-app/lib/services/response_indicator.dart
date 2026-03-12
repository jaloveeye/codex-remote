enum ResponseIndicatorState {
  idle,
  waiting,
  receiving,
  approvalPending,
}

ResponseIndicatorState resolveResponseIndicatorState({
  required bool waitingForResponse,
  required bool streamingResponse,
  required bool approvalPending,
}) {
  if (approvalPending) return ResponseIndicatorState.approvalPending;
  if (waitingForResponse && streamingResponse) {
    return ResponseIndicatorState.receiving;
  }
  if (waitingForResponse) return ResponseIndicatorState.waiting;
  return ResponseIndicatorState.idle;
}
