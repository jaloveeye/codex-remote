import 'package:codex_remote/models/trace_timeline_models.dart';
import 'package:codex_remote/widgets/trace_timeline_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TraceTimelinePanel shows loading and timeline summary',
      (tester) async {
    final controller = TextEditingController(text: 'trc_123');
    final timeline = TraceTimelineData(
      traceId: 'trc_123',
      sessionId: 'ABC123',
      startedAt: 1000,
      endedAt: 3000,
      totalMs: 2000,
      hops: const [
        TraceTimelineHop(
          hop: 'mobile.send.to_relay',
          ts: 1000,
          deltaFromPrevMs: 0,
          status: 'ok',
        ),
        TraceTimelineHop(
          hop: 'relay.recv.from_mobile',
          ts: 1200,
          deltaFromPrevMs: 200,
          status: 'ok',
        ),
      ],
      missingHops: const ['codex.first_chunk'],
      slowestSegment: const TraceSlowestSegment(from: 'a', to: 'b', ms: 1200),
      errors: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TraceTimelinePanel(
            enabled: true,
            traceIdController: controller,
            recentTraceIds: const ['trc_123'],
            loading: true,
            autoRefresh: false,
            error: null,
            timeline: timeline,
            onRefreshRecent: () {},
            onFetchTimeline: () {},
            onSelectRecent: (_) {},
            onAutoRefreshChanged: (_) {},
            onCopyReport: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('Total 2000ms'), findsOneWidget);
    expect(find.textContaining('Missing 1'), findsOneWidget);
    expect(find.text('mobile.send.to_relay'), findsOneWidget);
    expect(find.textContaining('Missing hops:'), findsOneWidget);
  });

  testWidgets('TraceTimelinePanel shows error text', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TraceTimelinePanel(
            enabled: true,
            traceIdController: controller,
            recentTraceIds: const [],
            loading: false,
            autoRefresh: false,
            error: 'trace not found',
            timeline: null,
            onRefreshRecent: () {},
            onFetchTimeline: () {},
            onSelectRecent: (_) {},
            onAutoRefreshChanged: (_) {},
            onCopyReport: () {},
          ),
        ),
      ),
    );

    expect(find.text('trace not found'), findsOneWidget);
  });
}
