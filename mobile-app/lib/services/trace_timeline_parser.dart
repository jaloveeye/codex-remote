import '../models/trace_timeline_models.dart';

class TraceTimelineParser {
  static TraceTimelineData parseTimelineResponse(Map<String, dynamic> body) {
    if (body['success'] != true) {
      throw Exception(
          body['error']?.toString() ?? 'trace timeline request failed');
    }
    final data = body['data'];
    if (data is! Map) {
      throw Exception('trace timeline data is missing');
    }
    return TraceTimelineData.fromJson(
      Map<String, dynamic>.from(data as Map<dynamic, dynamic>),
    );
  }

  static List<String> parseRecentTraceIdsResponse(Map<String, dynamic> body) {
    if (body['success'] != true) {
      throw Exception(
          body['error']?.toString() ?? 'trace recent request failed');
    }
    final data = body['data'];
    if (data is! Map) return const [];
    final traceIds = (data['traceIds'] as List? ?? const []);
    return traceIds
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
