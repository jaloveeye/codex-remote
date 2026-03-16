import 'package:codex_remote/services/trace_timeline_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseTimelineResponse parses trace timeline payload', () {
    final body = {
      'success': true,
      'data': {
        'traceId': 'trc_123',
        'sessionId': 'ABC123',
        'startedAt': 1000,
        'endedAt': 2000,
        'totalMs': 1000,
        'hops': [
          {
            'hop': 'mobile.send.to_relay',
            'ts': 1000,
            'deltaFromPrevMs': 0,
            'status': 'ok',
          },
          {
            'hop': 'relay.recv.from_mobile',
            'ts': 1100,
            'deltaFromPrevMs': 100,
            'status': 'ok',
          },
        ],
        'missingHops': ['codex.first_chunk'],
        'slowestSegment': {
          'from': 'ext.dispatch.to_codex',
          'to': 'codex.first_chunk',
          'ms': 800,
        },
        'errors': [
          {'hop': 'mobile.poll.recv', 'status': 'timeout'}
        ],
      }
    };

    final timeline = TraceTimelineParser.parseTimelineResponse(body);
    expect(timeline.traceId, 'trc_123');
    expect(timeline.sessionId, 'ABC123');
    expect(timeline.totalMs, 1000);
    expect(timeline.hops.length, 2);
    expect(timeline.missingHops, contains('codex.first_chunk'));
    expect(timeline.slowestSegment?.ms, 800);
    expect(timeline.errors.length, 1);
  });

  test('parseRecentTraceIdsResponse parses trace ids', () {
    final body = {
      'success': true,
      'data': {
        'traceIds': ['trc_1', 'trc_2']
      }
    };

    final traceIds = TraceTimelineParser.parseRecentTraceIdsResponse(body);
    expect(traceIds, ['trc_1', 'trc_2']);
  });
}
