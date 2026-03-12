import 'package:flutter/material.dart';

import '../models/trace_timeline_models.dart';

class TraceTimelinePanel extends StatelessWidget {
  final bool enabled;
  final TextEditingController traceIdController;
  final List<String> recentTraceIds;
  final bool loading;
  final bool autoRefresh;
  final String? error;
  final TraceTimelineData? timeline;
  final VoidCallback onRefreshRecent;
  final VoidCallback onFetchTimeline;
  final ValueChanged<String> onSelectRecent;
  final ValueChanged<bool> onAutoRefreshChanged;
  final VoidCallback onCopyReport;

  const TraceTimelinePanel({
    super.key,
    required this.enabled,
    required this.traceIdController,
    required this.recentTraceIds,
    required this.loading,
    required this.autoRefresh,
    required this.error,
    required this.timeline,
    required this.onRefreshRecent,
    required this.onFetchTimeline,
    required this.onSelectRecent,
    required this.onAutoRefreshChanged,
    required this.onCopyReport,
  });

  Color _statusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'error':
      case 'timeout':
      case 'fail':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeline = this.timeline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: traceIdController,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: 'Trace ID',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: enabled ? onRefreshRecent : null,
                icon: const Icon(Icons.refresh),
                tooltip: '최근 trace 갱신',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: recentTraceIds.contains(traceIdController.text)
                      ? traceIdController.text
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Recent traces',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: recentTraceIds
                      .map((id) => DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              id,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: enabled
                      ? (value) {
                          if (value == null) return;
                          onSelectRecent(value);
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: enabled ? onFetchTimeline : null,
                child: const Text('조회'),
              ),
            ],
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto refresh (5s)'),
            value: autoRefresh,
            onChanged: enabled ? onAutoRefreshChanged : null,
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (error != null && error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (timeline != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Total ${timeline.totalMs}ms')),
                Chip(label: Text('Missing ${timeline.missingHops.length}')),
                if (timeline.slowestSegment != null)
                  Chip(
                    label: Text('Slowest ${timeline.slowestSegment!.ms}ms'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Trace timeline (${timeline.hops.length})',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onCopyReport,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy report'),
                ),
              ],
            ),
            ...timeline.hops.take(40).map(
                  (hop) => ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -4),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.circle,
                      size: 10,
                      color: _statusColor(context, hop.status),
                    ),
                    title: Text(
                      hop.hop,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '+${hop.deltaFromPrevMs}ms · ${hop.status}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
            if (timeline.missingHops.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Missing hops: ${timeline.missingHops.join(', ')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
