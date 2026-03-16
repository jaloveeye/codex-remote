import 'package:codex_remote/services/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppSettings 기본 추론 강도는 low', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final settings = AppSettings();
    await settings.load();

    expect(settings.defaultReasoningEffort, 'low');
  });
}
