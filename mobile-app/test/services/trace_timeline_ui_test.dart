import 'package:codex_remote/services/trace_timeline_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prependUniqueTraceId', () {
    test('새 traceId를 맨 앞에 추가하고 중복을 제거한다', () {
      final updated = prependUniqueTraceId(
        current: const ['trc_old', 'trc_keep'],
        traceId: 'trc_new',
      );

      expect(updated, ['trc_new', 'trc_old', 'trc_keep']);
    });

    test('기존 traceId 재선택 시 맨 앞으로 이동한다', () {
      final updated = prependUniqueTraceId(
        current: const ['trc_a', 'trc_b', 'trc_c'],
        traceId: 'trc_b',
      );

      expect(updated, ['trc_b', 'trc_a', 'trc_c']);
    });
  });

  group('buildMobileUiRenderedTraceEvent', () {
    test('traceId가 없으면 null을 반환한다', () {
      final event = buildMobileUiRenderedTraceEvent(
        traceId: '   ',
        messageData: const {'id': 'cmd_1'},
        messageType: 'chat_response_complete',
        sourceTs: 123,
      );

      expect(event, isNull);
    });

    test('streaming 완료 메시지에서 mobile.ui.rendered 이벤트를 만든다', () {
      final event = buildMobileUiRenderedTraceEvent(
        traceId: 'trc_123',
        messageData: const {
          'id': 'cmd_1',
          'senderDeviceId': 'pc-1',
          'targetDeviceId': 'mobile-1',
          'clientId': 'relay-client',
        },
        messageType: 'chat_response_complete',
        sourceTs: 456,
      );

      expect(event, isNotNull);
      expect(event!['traceId'], 'trc_123');
      expect(event['hop'], 'mobile.ui.rendered');
      expect(event['commandId'], 'cmd_1');
      expect(event['meta'], {'messageType': 'chat_response_complete'});
      expect(event['sourceTs'], 456);
    });
  });
}
