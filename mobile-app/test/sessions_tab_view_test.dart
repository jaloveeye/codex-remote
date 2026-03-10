import 'package:codex_remote/models/connection_models.dart';
import 'package:codex_remote/widgets/sessions_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSessionsTab({
    required bool isConnected,
    required List<ConnectionHistoryItem> connectionHistory,
    required List<String> availableSessions,
    required List<Map<String, dynamic>> chatHistory,
    ConnectionType connectionType = ConnectionType.relay,
    String? sessionId,
    String? currentCodexSessionId,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SessionsTabView(
          isConnected: isConnected,
          connectionType: connectionType,
          sessionId: sessionId,
          currentCodexSessionId: currentCodexSessionId,
          connectionHistory: connectionHistory,
          availableSessions: availableSessions,
          chatHistory: chatHistory,
          subtitle: '연결 상태, 최근 세션, 대화 히스토리를 확인합니다.',
          onRefresh: () {},
          onDisconnect: () {},
          onOpenChat: () {},
          onConnectFromHistory: (_) {},
          onLoadChatHistory: ({String? sessionId}) {},
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
          availableSessions: const [],
          chatHistory: const [],
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
          availableSessions: const [],
          chatHistory: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('최근 연결이 없어요'), findsNothing);
      expect(find.text('127.0.0.1:3000'), findsOneWidget);
      expect(find.text('relay-session-1'), findsOneWidget);
    });

    testWidgets('세션 히스토리를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildSessionsTab(
          isConnected: true,
          connectionHistory: const [],
          availableSessions: const ['session-a', 'session-b'],
          chatHistory: const [
            {
              'userMessage': 'show me latest logs',
              'assistantResponse': 'Here are the latest logs summary.',
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('세션 히스토리'), findsOneWidget);
      expect(find.text('session-a'), findsOneWidget);
      expect(find.text('session-b'), findsOneWidget);
      expect(find.text('show me latest logs'), findsOneWidget);
      expect(find.text('Here are the latest logs summary.'), findsOneWidget);
      expect(find.text('사용 가능한 세션이 없습니다'), findsNothing);
    });
  });
}
