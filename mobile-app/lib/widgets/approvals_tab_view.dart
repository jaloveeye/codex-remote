import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import 'home_shell_widgets.dart';

class ApprovalsTabView extends StatelessWidget {
  const ApprovalsTabView({
    super.key,
    required this.isConnected,
    required this.isRelayMode,
    required this.pendingCodexServerRequests,
    required this.pendingCommandApprovals,
    required this.processedCommandApprovals,
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
    this.tracePanel,
  });

  final bool isConnected;
  final bool isRelayMode;
  final List<Map<String, dynamic>> pendingCodexServerRequests;
  final List<Map<String, dynamic>> pendingCommandApprovals;
  final List<Map<String, dynamic>> processedCommandApprovals;
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
  final void Function(Map<String, dynamic> approval, String action)
      onResolveCommandApproval;
  final void Function(Map<String, dynamic>) onMarkRelayApprovalLater;
  final String Function(String value, {int maxLength}) truncateForLog;
  final Widget? tracePanel;

  @override
  Widget build(BuildContext context) {
    if (!isConnected || !isRelayMode) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          HomeTabIntroCard(
            icon: Icons.gpp_good_outlined,
            title: AppI18n.t(context, AppTextKey.approvalsTitle),
            subtitle: subtitle,
          ),
          const SizedBox(height: 12),
          HomeEmptyStateCard(
            icon: Icons.lock_clock_outlined,
            title: AppI18n.t(context, AppTextKey.approvalsNotReadyTitle),
            message: AppI18n.t(context, AppTextKey.approvalsNotReadyMessage),
            action: FilledButton(
              onPressed: onOpenChat,
              child: Text(AppI18n.t(context, AppTextKey.openChatScreen)),
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
            title: AppI18n.t(context, AppTextKey.approvalsTitle),
            subtitle: subtitle,
            trailing: IconButton(
              tooltip: AppI18n.t(context, AppTextKey.refreshTooltip),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HomeMetricCard(
                  label: AppI18n.t(
                      context, AppTextKey.approvalsCodexRequestMetric),
                  value: '${pendingCodexServerRequests.length}',
                  icon: Icons.notification_important_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HomeMetricCard(
                  label: AppI18n.t(
                      context, AppTextKey.approvalsRelayApprovalMetric),
                  value: '${pendingCommandApprovals.length}',
                  icon: Icons.approval_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppI18n.t(context, AppTextKey.approvalsPendingCodexSection),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (pendingCodexServerRequests.isEmpty)
            HomeEmptyStateCard(
              icon: Icons.task_alt_outlined,
              title:
                  AppI18n.t(context, AppTextKey.approvalsNoPendingCodexTitle),
              message:
                  AppI18n.t(context, AppTextKey.approvalsNoPendingCodexMessage),
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
                            child: Text(
                              isSubmitting
                                  ? AppI18n.t(context, AppTextKey.sending)
                                  : AppI18n.t(context, AppTextKey.respond),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: choices.map((choice) {
                            final label = choice['label']?.toString() ?? '응답';
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
                                child: Text(
                                  isSubmitting
                                      ? AppI18n.t(context, AppTextKey.sending)
                                      : label,
                                ),
                              );
                            }
                            return OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => onSubmitCodexDecision(
                                      request, responsePayload),
                              child: Text(
                                isSubmitting
                                    ? AppI18n.t(context, AppTextKey.sending)
                                    : label,
                              ),
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
            AppI18n.t(context, AppTextKey.approvalsPendingRelaySection),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (pendingCommandApprovals.isEmpty)
            HomeEmptyStateCard(
              icon: Icons.mark_email_read_outlined,
              title:
                  AppI18n.t(context, AppTextKey.approvalsNoPendingRelayTitle),
              message:
                  AppI18n.t(context, AppTextKey.approvalsNoPendingRelayMessage),
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
                        '${AppI18n.t(context, AppTextKey.requesterLabel)}: $requestedBy · '
                        '${AppI18n.t(context, AppTextKey.approvalIdLabel)}: $approvalId',
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
                                onResolveCommandApproval(approval, 'approve'),
                            child: Text(
                                AppI18n.t(context, AppTextKey.approvalAllow)),
                          ),
                          OutlinedButton(
                            onPressed: () => onMarkRelayApprovalLater(approval),
                            child: Text(
                                AppI18n.t(context, AppTextKey.approvalLater)),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                onResolveCommandApproval(approval, 'reject'),
                            child: Text(
                                AppI18n.t(context, AppTextKey.approvalReject)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          Text(
            AppI18n.t(context, AppTextKey.approvalsHistorySection),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (processedCommandApprovals.isEmpty)
            HomeEmptyStateCard(
              icon: Icons.history_toggle_off_outlined,
              title: AppI18n.t(context, AppTextKey.approvalsNoHistoryTitle),
              message: AppI18n.t(context, AppTextKey.approvalsNoHistoryMessage),
            )
          else
            ...processedCommandApprovals.take(12).map((item) {
              final status = item['status']?.toString() ?? '';
              final title = item['title']?.toString() ?? '-';
              final command = item['command']?.toString() ?? '(unknown)';
              final riskLevel = item['riskLevel']?.toString() ?? 'unknown';
              final approvalId = item['approvalId']?.toString() ?? '-';
              final resolvedBy = item['resolvedBy']?.toString() ?? '-';
              final timeLabel = item['timeLabel']?.toString() ?? '-';
              final isApproved = status == 'approved';
              final isPending = status == 'pending';
              final iconColor = isApproved
                  ? Theme.of(context).colorScheme.primary
                  : isPending
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.error;
              final icon = isApproved
                  ? Icons.check_circle_outline
                  : isPending
                      ? Icons.hourglass_top_rounded
                      : Icons.block;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: iconColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$title · risk: $riskLevel',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              command,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$timeLabel · by $resolvedBy · ID: $approvalId',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (tracePanel != null) ...[
            const SizedBox(height: 16),
            Text(
              'Trace timeline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            tracePanel!,
          ],
        ],
      ),
    );
  }
}
