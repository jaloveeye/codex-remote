List<String> prependUniqueTraceId({
  required List<String> current,
  required String traceId,
  int maxItems = 20,
}) {
  final normalized = traceId.trim();
  if (normalized.isEmpty) {
    return List<String>.from(current);
  }

  final next = <String>[normalized];
  for (final id in current) {
    if (id == normalized) continue;
    next.add(id);
    if (next.length >= maxItems) break;
  }
  return next;
}

Map<String, dynamic>? buildMobileUiRenderedTraceEvent({
  required String? traceId,
  required Map<String, dynamic> messageData,
  required String messageType,
  int? sourceTs,
}) {
  final normalizedTraceId = traceId?.trim() ?? '';
  if (normalizedTraceId.isEmpty) return null;

  return {
    'traceId': normalizedTraceId,
    'hop': 'mobile.ui.rendered',
    'status': 'ok',
    'commandId': messageData['id']?.toString(),
    'senderDeviceId': messageData['senderDeviceId']?.toString(),
    'targetDeviceId': messageData['targetDeviceId']?.toString(),
    'clientId': messageData['clientId']?.toString(),
    'sourceTs': sourceTs ?? DateTime.now().millisecondsSinceEpoch,
    'meta': {
      'messageType': messageType,
    },
  };
}
