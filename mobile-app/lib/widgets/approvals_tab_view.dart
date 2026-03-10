import 'package:flutter/material.dart';

import 'home_shell_widgets.dart';

class ApprovalsTabView extends StatelessWidget {
  const ApprovalsTabView({
    super.key,
    required this.isConnected,
    required this.isRelayMode,
    required this.pendingCodexServerRequests,
    required this.pendingCommandApprovals,
    required this.submittingCodexRequestIds,
    required this.subtitle,
    required this.onOpenChat,
    required this.onRefresh,
    required this.codexRequestTitle,
    required this.codexRequestSummary,
    required this.codexRequestAccentColor,
    required this.onShowCodexRequestDetail,
    required this.onOpenCodexUserInputDialog,
    required this.onSubmitCodexDecision,
    required this.approvalRequestTypeLabel,
    required this.approvalCommandRaw,
    required this.approvalRequestedBy,
    required this.onResolveCommandApproval,
    required this.onMarkRelayApprovalLater,
    required this.truncateForLog,
  });

  final bool isConnected;
  final bool isRelayMode;
  final List<Map<String, dynamic>> pendingCodexServerRequests;
  final List<Map<String, dynamic>> pendingCommandApprovals;
  final Set<String> submittingCodexRequestIds;
  final String subtitle;
  final VoidCallback onOpenChat;
  final Future<void> Function() onRefresh;
  final String Function(Map<String, dynamic>) codexRequestTitle;
  final String Function(Map<String, dynamic>) codexRequestSummary;
  final Color Function(BuildContext, Map<String, dynamic>)
      codexRequestAccentColor;
  final void Function(Map<String, dynamic>) onShowCodexRequestDetail;
  final void Function(Map<String, dynamic>) onOpenCodexUserInputDialog;
  final void Function(Map<String, dynamic>, Map<String, dynamic>)
      onSubmitCodexDecision;
  final String Function(Map<String, dynamic>) approvalRequestTypeLabel;
  final String Function(Map<String, dynamic>) approvalCommandRaw;
  final String Function(Map<String, dynamic>) approvalRequestedBy;
  final void Function(String approvalId, String action)
      onResolveCommandApproval;
  final void Function(Map<String, dynamic>) onMarkRelayApprovalLater;
  final String Function(String value, {int maxLength}) truncateForLog;

  @override
  Widget build(BuildContext context) {
    if (!isConnected || !isRelayMode) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          HomeTabIntroCard(
            icon: Icons.gpp_good_outlined,
            title: 'Approvals',
            subtitle: subtitle,
          ),
          const SizedBox(height: 12),
          HomeEmptyStateCard(
            icon: Icons.lock_clock_outlined,
            title: '승인 요청을 받을 준비가 필요해요',
            message: '릴레이 세션에 연결되면 모바일 승인 요청과 Codex 액션을 여기서 처리할 수 있어요.',
            action: FilledButton(
              onPressed: onOpenChat,
              child: const Text('채팅 화면으로 이동'),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          HomeTabIntroCard(
            icon: Icons.gpp_good_outlined,
            title: 'Approvals',
            subtitle: subtitle,
            trailing: IconButton(
              tooltip: '새로고침',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HomeMetricCard(
                  label: 'Codex requests',
                  value: '${pendingCodexServerRequests.length}',
                  icon: Icons.notification_important_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HomeMetricCard(
                  label: 'Relay approvals',
                  value: '${pendingCommandApprovals.length}',
                  icon: Icons.approval_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Pending Codex actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (pendingCodexServerRequests.isEmpty)
            const HomeEmptyStateCard(
              icon: Icons.task_alt_outlined,
              title: '대기 중인 Codex 요청이 없어요',
              message: '명령 실행, 파일 변경, 추가 입력 요청이 오면 이곳에 표시됩니다.',
            )
          else
            ...pendingCodexServerRequests.take(10).map((request) {
              final requestId = request['requestId']?.toString() ?? '';
              final summary = codexRequestSummary(request);
              final choices = List<Map<String, dynamic>>.from(
                  (request['choices'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map)));
              final isSubmitting =
                  submittingCodexRequestIds.contains(requestId);
              final accentColor = codexRequestAccentColor(context, request);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: accentColor.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              codexRequestTitle(request),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => onShowCodexRequestDetail(request),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            tooltip: '자세히 보기',
                          ),
                        ],
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(summary, style: const TextStyle(fontSize: 12)),
                      ],
                      const SizedBox(height: 10),
                      if ((request['requestKind']?.toString() ?? '') ==
                          'user_input')
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () => onOpenCodexUserInputDialog(request),
                            child: Text(isSubmitting ? '전송 중...' : '응답하기'),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: choices.map((choice) {
                            final label =
                                choice['label']?.toString() ?? 'Respond';
                            final style =
                                choice['style']?.toString() ?? 'secondary';
                            final responsePayload = Map<String, dynamic>.from(
                                choice['response'] as Map? ?? {});
                            if (style == 'primary') {
                              return FilledButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => onSubmitCodexDecision(
                                        request, responsePayload),
                                child: Text(isSubmitting ? '전송 중...' : label),
                              );
                            }
                            return OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => onSubmitCodexDecision(
                                      request, responsePayload),
                              child: Text(isSubmitting ? '전송 중...' : label),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          Text(
            'Relay approvals',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (pendingCommandApprovals.isEmpty)
            const HomeEmptyStateCard(
              icon: Icons.mark_email_read_outlined,
              title: '대기 중인 승인 요청이 없어요',
              message: '릴레이 서버를 통한 실행 승인 요청이 생기면 여기에 표시됩니다.',
            )
          else
            ...pendingCommandApprovals.take(10).map((approval) {
              final approvalId = approval['approval_id']?.toString() ?? '';
              final requestType = approvalRequestTypeLabel(approval);
              final commandRaw =
                  truncateForLog(approvalCommandRaw(approval), maxLength: 72);
              final requestedBy = approvalRequestedBy(approval);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requestType,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(commandRaw, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        '요청자: $requestedBy · ID: $approvalId',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () =>
                                onResolveCommandApproval(approvalId, 'approve'),
                            child: const Text('허용'),
                          ),
                          OutlinedButton(
                            onPressed: () => onMarkRelayApprovalLater(approval),
                            child: const Text('나중에'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                onResolveCommandApproval(approvalId, 'deny'),
                            child: const Text('거부'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
