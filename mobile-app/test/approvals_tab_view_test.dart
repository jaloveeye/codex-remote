import 'package:codex_remote/widgets/approvals_tab_view.dart';
import 'package:codex_remote/widgets/home_shell_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApprovalsTab({
    required bool isConnected,
    required bool isRelayMode,
    List<Map<String, dynamic>> pendingCodexServerRequests = const [],
    List<Map<String, dynamic>> pendingCommandApprovals = const [],
    List<Map<String, dynamic>> processedCommandApprovals = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ApprovalsTabView(
          isConnected: isConnected,
          isRelayMode: isRelayMode,
          pendingCodexServerRequests: pendingCodexServerRequests,
          pendingCommandApprovals: pendingCommandApprovals,
          processedCommandApprovals: processedCommandApprovals,
          submittingCodexRequestIds: const <String>{},
          subtitle: '모바일 승인 요청과 대기 중인 액션을 한곳에서 처리합니다.',
          onOpenChat: () {},
          onRefresh: () async {},
          codexRequestTitle: (request) => request['title']?.toString() ?? '',
          codexRequestSummary: (request) =>
              request['summary']?.toString() ?? '',
          codexRequestAccentColor: (_, __) => Colors.blue,
          onShowCodexRequestDetail: (_) {},
          onOpenCodexUserInputDialog: (_) {},
          onSubmitCodexDecision: (_, __) {},
          approvalRequestTypeLabel: (approval) =>
              approval['typeLabel']?.toString() ?? '',
          approvalCommandRaw: (approval) =>
              approval['command']?.toString() ?? '',
          approvalRequestedBy: (approval) =>
              approval['requestedBy']?.toString() ?? '',
          onResolveCommandApproval: (_, __) {},
          onMarkRelayApprovalLater: (_) {},
          truncateForLog: (value, {maxLength = 80}) => value,
        ),
      ),
    );
  }

  group('ApprovalsTabView states', () {
    testWidgets('비연결 상태에서 empty state를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildApprovalsTab(
          isConnected: false,
          isRelayMode: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('승인 요청을 받을 준비가 필요해요'), findsOneWidget);
      expect(find.text('채팅 화면으로 이동'), findsOneWidget);
      expect(find.text('Codex 요청'), findsNothing);
      expect(find.text('릴레이 승인 요청'), findsNothing);
    });

    testWidgets('연결 상태에서 metric 카드를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildApprovalsTab(
          isConnected: true,
          isRelayMode: true,
          pendingCodexServerRequests: const [
            {'requestId': 'r1'},
            {'requestId': 'r2'},
          ],
          pendingCommandApprovals: const [
            {'approval_id': 'a1'},
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeMetricCard), findsNWidgets(2));
      expect(find.text('Codex 요청'), findsOneWidget);
      expect(find.text('릴레이 승인'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('pending request 카드들을 노출한다', (tester) async {
      await tester.pumpWidget(
        buildApprovalsTab(
          isConnected: true,
          isRelayMode: true,
          pendingCodexServerRequests: const [
            {
              'requestId': 'codex-1',
              'requestKind': 'command_approval',
              'title': 'Run tests',
              'summary': 'Run npm run verify',
              'choices': [
                {
                  'label': 'Approve',
                  'style': 'primary',
                  'response': {'action': 'approve'}
                },
                {
                  'label': 'Deny',
                  'style': 'secondary',
                  'response': {'action': 'deny'}
                }
              ],
            }
          ],
          pendingCommandApprovals: const [
            {
              'approval_id': 'relay-1',
              'typeLabel': 'Command approval',
              'command': 'npm run verify',
              'requestedBy': 'desktop-client',
            }
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Run tests'), findsOneWidget);
      expect(find.text('Run npm run verify'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);

      expect(find.text('Command approval'), findsOneWidget);
      expect(find.text('npm run verify'), findsOneWidget);
      expect(find.text('요청자: desktop-client · ID: relay-1'), findsOneWidget);
      expect(find.text('허용'), findsOneWidget);
      expect(find.text('나중에'), findsOneWidget);
      expect(find.text('거부'), findsOneWidget);
    });

    testWidgets('처리 히스토리 카드를 노출한다', (tester) async {
      await tester.pumpWidget(
        buildApprovalsTab(
          isConnected: true,
          isRelayMode: true,
          processedCommandApprovals: const [
            {
              'status': 'approved',
              'title': '허용됨',
              'command': 'npm run verify',
              'riskLevel': 'high',
              'approvalId': 'ap-1',
              'resolvedBy': 'mobile',
              'timeLabel': '13:20:10',
            }
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('처리 히스토리'), findsOneWidget);
      expect(find.text('허용됨 · risk: high'), findsOneWidget);
      expect(find.text('npm run verify'), findsOneWidget);
      expect(find.text('13:20:10 · by mobile · ID: ap-1'), findsOneWidget);
    });
  });
}
