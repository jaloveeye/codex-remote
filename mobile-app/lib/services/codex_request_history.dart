Map<String, dynamic> buildCodexRequestHistoryEntry({
  required String requestId,
  required String status,
  required String title,
  required String summary,
  String requestKind = 'codex',
  String resolvedBy = '-',
  int? timestampMs,
}) {
  final normalizedRequestId = requestId.trim();
  final normalizedStatus = status.trim().toLowerCase();
  final ts = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
  return {
    'requestId': normalizedRequestId,
    'status': normalizedStatus,
    'title': title,
    'summary': summary,
    'requestKind': requestKind,
    'resolvedBy': resolvedBy,
    'timestamp': ts,
    'dedupeKey': '${normalizedRequestId}_$normalizedStatus',
  };
}

List<Map<String, dynamic>> upsertCodexRequestHistory({
  required List<Map<String, dynamic>> current,
  required Map<String, dynamic> entry,
  int maxItems = 60,
}) {
  final dedupeKey = entry['dedupeKey']?.toString() ?? '';
  final next = current
      .where((item) => item['dedupeKey']?.toString() != dedupeKey)
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
  next.insert(0, Map<String, dynamic>.from(entry));
  if (next.length > maxItems) {
    return next.take(maxItems).toList();
  }
  return next;
}

Map<String, dynamic> toApprovalHistoryItem(Map<String, dynamic> entry) {
  final status = entry['status']?.toString() ?? 'unknown';
  final title = entry['title']?.toString() ?? 'Codex 요청';
  final summary = entry['summary']?.toString() ?? '';
  final requestId = entry['requestId']?.toString() ?? '-';
  final requestKind = entry['requestKind']?.toString() ?? 'codex';
  final resolvedBy = entry['resolvedBy']?.toString() ?? '-';
  final timestamp = entry['timestamp'];

  String historyTitle;
  switch (status) {
    case 'pending':
      historyTitle = 'Codex 요청 도착';
      break;
    case 'resolved':
      historyTitle = 'Codex 요청 처리';
      break;
    case 'submitted':
      historyTitle = 'Codex 요청 응답 전송';
      break;
    case 'timed_out':
      historyTitle = 'Codex 요청 시간 초과';
      break;
    case 'fallback_to_desktop':
      historyTitle = 'Codex 요청 데스크톱 폴백';
      break;
    case 'error':
      historyTitle = 'Codex 요청 오류';
      break;
    default:
      historyTitle = 'Codex 요청 기록';
      break;
  }

  String cardStatus;
  if (status == 'resolved' || status == 'approved') {
    cardStatus = 'approved';
  } else if (status == 'pending' || status == 'submitted') {
    cardStatus = 'pending';
  } else {
    cardStatus = 'rejected';
  }

  final normalizedSummary = summary.trim().isEmpty ? title : summary;
  return {
    'status': cardStatus,
    'title': historyTitle,
    'command': normalizedSummary,
    'riskLevel': requestKind,
    'approvalId': requestId,
    'resolvedBy': resolvedBy,
    'timeLabel': _formatTimestamp(timestamp),
    'sortTs': _toInt(timestamp),
  };
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatTimestamp(dynamic value) {
  final ts = _toInt(value);
  if (ts <= 0) return '-';
  final dt = DateTime.fromMillisecondsSinceEpoch(ts);
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}
