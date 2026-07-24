import 'dart:async';

import 'package:codex_remote/services/runtime_capability_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeRuntimeModel', () {
    test('uses auto until a runtime catalog is loaded', () {
      expect(
        normalizeRuntimeModel(
          'gpt-stale',
          catalogLoaded: false,
          availableModels: const [],
        ),
        'auto',
      );
    });

    test('preserves only a model present in the live catalog', () {
      expect(
        normalizeRuntimeModel(
          'gpt-current',
          catalogLoaded: true,
          availableModels: const ['gpt-current'],
        ),
        'gpt-current',
      );
      expect(
        normalizeRuntimeModel(
          'gpt-stale',
          catalogLoaded: true,
          availableModels: const ['gpt-current'],
        ),
        'auto',
      );
    });
  });

  test('RuntimeCapabilitySingleFlight coalesces concurrent loads', () async {
    final gate = RuntimeCapabilitySingleFlight();
    final completer = Completer<void>();
    var loads = 0;

    Future<void> load() async {
      loads += 1;
      await completer.future;
    }

    final first = gate.run(load);
    final second = gate.run(load);

    expect(identical(first, second), isTrue);
    expect(loads, 1);

    completer.complete();
    await Future.wait([first, second]);

    await gate.run(() async {
      loads += 1;
    });
    expect(loads, 2);
  });
}
