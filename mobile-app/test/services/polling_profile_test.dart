import 'package:codex_remote/services/polling_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('relayPollIntervalMs', () {
    test('idle 상태는 기본 2000ms', () {
      final ms = relayPollIntervalMs(
        waitingForResponse: false,
        streamingResponse: false,
        hasPendingRelayApprovals: false,
        hasPendingCodexRequests: false,
      );

      expect(ms, relayPollIntervalIdleMs);
    });

    test('응답 대기/수신/승인 대기 중에는 active interval', () {
      expect(
        relayPollIntervalMs(
          waitingForResponse: true,
          streamingResponse: false,
          hasPendingRelayApprovals: false,
          hasPendingCodexRequests: false,
        ),
        relayPollIntervalActiveMs,
      );

      expect(
        relayPollIntervalMs(
          waitingForResponse: false,
          streamingResponse: true,
          hasPendingRelayApprovals: false,
          hasPendingCodexRequests: false,
        ),
        relayPollIntervalActiveMs,
      );

      expect(
        relayPollIntervalMs(
          waitingForResponse: false,
          streamingResponse: false,
          hasPendingRelayApprovals: true,
          hasPendingCodexRequests: false,
        ),
        relayPollIntervalActiveMs,
      );
    });
  });
}
