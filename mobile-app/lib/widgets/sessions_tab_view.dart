import 'package:flutter/material.dart';

import '../models/connection_models.dart';
import 'home_shell_widgets.dart';

class SessionsTabView extends StatelessWidget {
  const SessionsTabView({
    super.key,
    required this.isConnected,
    required this.connectionType,
    required this.sessionId,
    required this.currentCodexSessionId,
    required this.connectionHistory,
    required this.availableSessions,
    required this.chatHistory,
    required this.subtitle,
    required this.onRefresh,
    required this.onDisconnect,
    required this.onOpenChat,
    required this.onConnectFromHistory,
    required this.onLoadChatHistory,
  });

  final bool isConnected;
  final ConnectionType connectionType;
  final String? sessionId;
  final String? currentCodexSessionId;
  final List<ConnectionHistoryItem> connectionHistory;
  final List<String> availableSessions;
  final List<Map<String, dynamic>> chatHistory;
  final String subtitle;
  final VoidCallback onRefresh;
  final VoidCallback onDisconnect;
  final VoidCallback onOpenChat;
  final void Function(ConnectionHistoryItem item) onConnectFromHistory;
  final void Function({String? sessionId}) onLoadChatHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        HomeTabIntroCard(
          icon: Icons.hub_outlined,
          title: 'Sessions',
          subtitle: subtitle,
          trailing: IconButton(
            tooltip: '새로고침',
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
                        isConnected ? '현재 연결됨' : '연결 안 됨',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isConnected)
                      OutlinedButton(
                        onPressed: onDisconnect,
                        child: const Text('연결 해제'),
                      )
                    else
                      FilledButton(
                        onPressed: onOpenChat,
                        child: const Text('연결하기'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isConnected
                      ? (connectionType == ConnectionType.local
                          ? '로컬 서버에 연결되어 있습니다.'
                          : '릴레이 세션 ${sessionId ?? '-'} 에 연결되어 있습니다.')
                      : '채팅 탭에서 로컬 또는 릴레이 연결을 시작하세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (currentCodexSessionId != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '현재 Codex 세션: $currentCodexSessionId',
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
          '최근 연결',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (connectionHistory.isEmpty)
          const HomeEmptyStateCard(
            icon: Icons.history_toggle_off,
            title: '최근 연결이 없어요',
            message: '세션에 연결하면 최근 연결 목록이 여기에 저장됩니다.',
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
                  subtitle: Text(item.relativeTime),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onConnectFromHistory(item),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '세션 히스토리',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              if (availableSessions.isEmpty)
                const ListTile(
                  leading: Icon(Icons.chat_bubble_outline),
                  title: Text('사용 가능한 세션이 없습니다'),
                  subtitle: Text('연결 후 세션 정보가 표시됩니다.'),
                )
              else
                ...availableSessions.take(8).map((sessionId) => ListTile(
                      leading: const Icon(Icons.chat_outlined),
                      title: Text(sessionId),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () =>
                            onLoadChatHistory(sessionId: sessionId),
                      ),
                    )),
              if (chatHistory.isNotEmpty) const Divider(height: 1),
              if (chatHistory.isNotEmpty)
                ...chatHistory.take(6).map((entry) {
                  final userMsg =
                      (entry['userMessage'] as String? ?? '').trim();
                  final assistantMsg =
                      (entry['assistantResponse'] as String? ?? '').trim();
                  return ListTile(
                    leading: const Icon(Icons.forum_outlined),
                    title: Text(
                      userMsg.isEmpty ? '(no prompt)' : userMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      assistantMsg.isEmpty ? '응답 없음' : assistantMsg,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
