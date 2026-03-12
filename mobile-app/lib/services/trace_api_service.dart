import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trace_timeline_models.dart';
import 'trace_timeline_parser.dart';

class TraceApiService {
  final String relayServerUrl;

  const TraceApiService({required this.relayServerUrl});

  String get _base => relayServerUrl.trim().replaceAll(RegExp(r'/+$'), '');

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_base$normalizedPath');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<TraceTimelineData> fetchTimeline(String traceId) async {
    final response = await http.get(
      _uri('/api/trace/$traceId/timeline'),
    );

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'HTTP ${response.statusCode}');
    }

    return TraceTimelineParser.parseTimelineResponse(body);
  }

  Future<List<String>> fetchRecentTraceIds(
    String sessionId, {
    int limit = 20,
  }) async {
    final response = await http.get(
      _uri('/api/trace/recent', {
        'sessionId': sessionId,
        'limit': '$limit',
      }),
    );

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'HTTP ${response.statusCode}');
    }

    return TraceTimelineParser.parseRecentTraceIdsResponse(body);
  }

  Future<void> sendTraceEvents(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return;
    try {
      await http.post(
        _uri('/api/trace-events/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'events': events}),
      );
    } catch (_) {
      // trace는 best-effort
    }
  }
}
