String normalizeRuntimeModel(
  String requestedModel, {
  required bool catalogLoaded,
  required Iterable<String> availableModels,
}) {
  final normalized = requestedModel.trim();
  if (!catalogLoaded || normalized.isEmpty || normalized == 'auto') {
    return 'auto';
  }
  return availableModels.contains(normalized) ? normalized : 'auto';
}

class RuntimeCapabilitySingleFlight {
  Future<void>? _inFlight;

  Future<void> run(Future<void> Function() loader) {
    final active = _inFlight;
    if (active != null) return active;

    final request = loader();
    _inFlight = request;
    request.then<void>(
      (_) => _clear(request),
      onError: (Object _, StackTrace __) => _clear(request),
    );
    return request;
  }

  void _clear(Future<void> request) {
    if (identical(_inFlight, request)) {
      _inFlight = null;
    }
  }
}
