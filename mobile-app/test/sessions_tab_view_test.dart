import 'package:codex_remote/models/connection_models.dart';
import 'package:codex_remote/widgets/sessions_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  Widget buildSessionsTab({
    required bool isConnected,
    required List<ConnectionHistoryItem> connectionHistory,
    ConnectionType connectionType = ConnectionType.relay,
    String? sessionId,
    String? currentCodexSessionId,
  }) {
    return MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: const [Locale('en'), Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SessionsTabView(
          isConnected: isConnected,
          connectionType: connectionType,
          sessionId: sessionId,
          currentCodexSessionId: currentCodexSessionId,
          connectionHistory: connectionHistory,
          subtitle: '연결 상태와 최근 연결 정보를 확인합니다.',
          onRefresh: () {},
          onDisconnect: () {},
          onOpenChat: () {},
          onConnectFromHistory: (_) {},
        ),
      ),
    );
  }

  group('SessionsTabView states', () {
    testWidgets('비연결 상태를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildSessionsTab(
          isConnected: false,
          connectionHistory: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('연결 안 됨'), findsOneWidget);
      expect(find.text('연결하기'), findsOneWidget);
      expect(find.text('채팅 탭에서 로컬 또는 릴레이 연결을 시작하세요.'), findsOneWidget);
      expect(find.text('연결 해제'), findsNothing);
    });

    testWidgets('최근 연결 목록을 표시한다', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        buildSessionsTab(
          isConnected: true,
          connectionHistory: [
            ConnectionHistoryItem(
              type: ConnectionType.local,
              ip: '127.0.0.1',
              port: 3000,
              timestamp: now.subtract(const Duration(minutes: 5)),
            ),
            ConnectionHistoryItem(
              type: ConnectionType.relay,
              sessionId: 'relay-session-1',
              timestamp: now.subtract(const Duration(hours: 1)),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('최근 연결이 없어요'), findsNothing);
      expect(find.text('127.0.0.1:3000'), findsOneWidget);
      expect(find.text('relay-session-1'), findsOneWidget);
    });

    testWidgets('세션 히스토리 섹션을 표시하지 않는다', (tester) async {
      await tester.pumpWidget(
        buildSessionsTab(
          isConnected: true,
          connectionHistory: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('세션'), findsOneWidget);
      expect(find.text('최근 연결이 없어요'), findsOneWidget);
    });
  });
}
