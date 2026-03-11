import 'package:codex_remote/services/app_settings.dart';
import 'package:codex_remote/widgets/settings_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppSettings> loadSettingsWithMockPrefs({
    int? themeModeIndex,
    bool? showHistory,
  }) async {
    final mockValues = <String, Object>{};
    mockValues['app_language'] = 'ko';
    if (themeModeIndex != null) mockValues['theme_mode'] = themeModeIndex;
    if (showHistory != null) mockValues['show_history'] = showHistory;

    SharedPreferences.setMockInitialValues(mockValues);
    final settings = AppSettings();
    await settings.load();
    return settings;
  }

  Widget buildSettingsTab({
    required AppSettings settings,
    required VoidCallback onOpenSettings,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SettingsTabView(
          settings: settings,
          subtitle: '앱 환경설정과 기본 동작을 정리합니다.',
          onOpenSettings: onOpenSettings,
        ),
      ),
    );
  }

  group('SettingsTabView summary UI', () {
    testWidgets('테마 항목과 앱 정보 항목을 표시하고 진입 콜백을 호출한다', (tester) async {
      final settings = await loadSettingsWithMockPrefs(
        themeModeIndex: ThemeModeSetting.dark.index,
      );
      var openSettingsTapped = 0;

      await tester.pumpWidget(
        buildSettingsTab(
          settings: settings,
          onOpenSettings: () => openSettingsTapped++,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('테마'), findsOneWidget);
      expect(find.text('다크 모드'), findsOneWidget);
      expect(find.text('Codex Remote'), findsOneWidget);
      expect(find.text('버전 0.2.0'), findsOneWidget);

      await tester.tap(find.text('테마'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Codex Remote'));
      await tester.pumpAndSettle();
      expect(openSettingsTapped, 2);
    });

    testWidgets('세션/히스토리 표시 스위치 상태를 반영하고 변경한다', (tester) async {
      final settings = await loadSettingsWithMockPrefs(showHistory: true);

      await tester.pumpWidget(
        buildSettingsTab(
          settings: settings,
          onOpenSettings: () {},
        ),
      );
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(find.text('세션 및 대화 히스토리'), findsOneWidget);
      expect(find.text('메인 화면에 히스토리 섹션 표시'), findsOneWidget);
      expect(switchTile.value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(settings.showHistory, isFalse);
    });
  });
}
