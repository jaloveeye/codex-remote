import 'package:flutter/material.dart';

import '../models/connection_models.dart';
import '../services/app_i18n.dart';
import 'home_shell_widgets.dart';

class SessionsTabView extends StatelessWidget {
  const SessionsTabView({
    super.key,
    required this.isConnected,
    required this.connectionType,
    required this.sessionId,
    required this.currentCodexSessionId,
    required this.connectionHistory,
    required this.subtitle,
    required this.onRefresh,
    required this.onDisconnect,
    required this.onOpenChat,
    required this.onConnectFromHistory,
  });

  final bool isConnected;
  final ConnectionType connectionType;
  final String? sessionId;
  final String? currentCodexSessionId;
  final List<ConnectionHistoryItem> connectionHistory;
  final String subtitle;
  final VoidCallback onRefresh;
  final VoidCallback onDisconnect;
  final VoidCallback onOpenChat;
  final void Function(ConnectionHistoryItem item) onConnectFromHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        HomeTabIntroCard(
          icon: Icons.hub_outlined,
          title: AppI18n.t(context, AppTextKey.sessionsTitle),
          subtitle: subtitle,
          trailing: IconButton(
            tooltip: AppI18n.t(context, AppTextKey.refreshTooltip),
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: isConnected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isConnected
                            ? AppI18n.t(context, AppTextKey.statusConnected)
                            : AppI18n.t(context, AppTextKey.statusNotConnected),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isConnected)
                      OutlinedButton(
                        onPressed: onDisconnect,
                        child: Text(
                            AppI18n.t(context, AppTextKey.disconnectAction)),
                      )
                    else
                      FilledButton(
                        onPressed: onOpenChat,
                        child:
                            Text(AppI18n.t(context, AppTextKey.connectAction)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isConnected
                      ? (connectionType == ConnectionType.local
                          ? AppI18n.t(
                              context, AppTextKey.sessionsLocalConnectedText)
                          : '${AppI18n.t(context, AppTextKey.sessionsRelayConnectedText)} ${sessionId ?? '-'}')
                      : AppI18n.t(context, AppTextKey.sessionsDisconnectedHint),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (currentCodexSessionId != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${AppI18n.t(context, AppTextKey.currentCodexSessionLabel)} $currentCodexSessionId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppI18n.t(context, AppTextKey.recentConnections),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (connectionHistory.isEmpty)
          HomeEmptyStateCard(
            icon: Icons.history_toggle_off,
            title: AppI18n.t(context, AppTextKey.sessionsNoHistoryTitle),
            message: AppI18n.t(context, AppTextKey.sessionsNoHistoryMessage),
          )
        else
          Card(
            child: Column(
              children: connectionHistory.map((item) {
                return ListTile(
                  leading: Icon(
                    item.type == ConnectionType.local
                        ? Icons.lan_outlined
                        : Icons.cloud_outlined,
                  ),
                  title: Text(item.displayText),
                  subtitle: Text(
                    item.relativeTimeForLanguage(
                        isEnglish: AppI18n.isEnglish(context)),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onConnectFromHistory(item),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
