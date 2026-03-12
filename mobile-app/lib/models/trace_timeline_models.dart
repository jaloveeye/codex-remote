class TraceSlowestSegment {
  final String from;
  final String to;
  final int ms;

  const TraceSlowestSegment({
    required this.from,
    required this.to,
    required this.ms,
  });

  factory TraceSlowestSegment.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return TraceSlowestSegment(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      ms: toInt(json['ms']),
    );
  }
}

class TraceTimelineHop {
  final String hop;
  final int ts;
  final int deltaFromPrevMs;
  final String status;

  const TraceTimelineHop({
    required this.hop,
    required this.ts,
    required this.deltaFromPrevMs,
    required this.status,
  });

  factory TraceTimelineHop.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return TraceTimelineHop(
      hop: json['hop']?.toString() ?? 'unknown',
      ts: toInt(json['ts']),
      deltaFromPrevMs: toInt(json['deltaFromPrevMs']),
      status: json['status']?.toString() ?? 'ok',
    );
  }
}

class TraceTimelineData {
  final String traceId;
  final String? sessionId;
  final int startedAt;
  final int endedAt;
  final int totalMs;
  final List<TraceTimelineHop> hops;
  final List<String> missingHops;
  final TraceSlowestSegment? slowestSegment;
  final List<Map<String, dynamic>> errors;

  const TraceTimelineData({
    required this.traceId,
    required this.sessionId,
    required this.startedAt,
    required this.endedAt,
    required this.totalMs,
    required this.hops,
    required this.missingHops,
    required this.slowestSegment,
    required this.errors,
  });

  factory TraceTimelineData.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final rawHops = (json['hops'] as List? ?? const []);
    final rawMissing = (json['missingHops'] as List? ?? const []);
    final rawErrors = (json['errors'] as List? ?? const []);
    final rawSlowest = json['slowestSegment'];

    return TraceTimelineData(
      traceId: json['traceId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString(),
      startedAt: toInt(json['startedAt']),
      endedAt: toInt(json['endedAt']),
      totalMs: toInt(json['totalMs']),
      hops: rawHops
          .whereType<Map>()
          .map((hop) => TraceTimelineHop.fromJson(
              Map<String, dynamic>.from(hop as Map<dynamic, dynamic>)))
          .toList(),
      missingHops: rawMissing.map((e) => e.toString()).toList(),
      slowestSegment: rawSlowest is Map
          ? TraceSlowestSegment.fromJson(
              Map<String, dynamic>.from(rawSlowest as Map<dynamic, dynamic>),
            )
          : null,
      errors: rawErrors
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  String toReportText() {
    final buffer = StringBuffer();
    buffer.writeln('traceId: $traceId');
    if (sessionId != null && sessionId!.isNotEmpty) {
      buffer.writeln('sessionId: $sessionId');
    }
    buffer.writeln('totalMs: $totalMs');
    if (slowestSegment != null) {
      buffer.writeln(
          'slowest: ${slowestSegment!.from} -> ${slowestSegment!.to} (${slowestSegment!.ms}ms)');
    }
    if (missingHops.isNotEmpty) {
      buffer.writeln('missing: ${missingHops.join(', ')}');
    }
    if (errors.isNotEmpty) {
      buffer.writeln('errors: ${errors.length}');
    }
    buffer.writeln('--- hops ---');
    for (final hop in hops) {
      buffer.writeln(
          '${hop.hop} | +${hop.deltaFromPrevMs}ms | status=${hop.status} | ts=${hop.ts}');
    }
    return buffer.toString();
  }
}
