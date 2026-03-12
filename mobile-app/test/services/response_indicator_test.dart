import 'package:codex_remote/services/response_indicator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('streaming 활성 시 indicator state는 receiving', () {
    final state = resolveResponseIndicatorState(
      waitingForResponse: true,
      streamingResponse: true,
      approvalPending: false,
    );

    expect(state, ResponseIndicatorState.receiving);
  });

  test('응답 대기 상태는 waiting', () {
    final state = resolveResponseIndicatorState(
      waitingForResponse: true,
      streamingResponse: false,
      approvalPending: false,
    );

    expect(state, ResponseIndicatorState.waiting);
  });

  test('승인 대기는 approvalPending', () {
    final state = resolveResponseIndicatorState(
      waitingForResponse: false,
      streamingResponse: false,
      approvalPending: true,
    );

    expect(state, ResponseIndicatorState.approvalPending);
  });
}
