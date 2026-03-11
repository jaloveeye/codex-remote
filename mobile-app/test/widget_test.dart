import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:codex_remote/main.dart';
import 'package:codex_remote/services/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(
    WidgetTester tester, {
    required bool onboardingDone,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (onboardingDone) 'mobile_onboarding_done_v1': true,
    });
    await AppSettings().load();
    await tester.binding.setSurfaceSize(const Size(1440, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  group('0.1.7 launch flow', () {
    testWidgets('첫 실행 시 온보딩 화면을 렌더링한다', (WidgetTester tester) async {
      await pumpApp(
        tester,
        onboardingDone: false,
      );

      expect(find.text('Codex Remote 시작하기'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
    });

    testWidgets('온보딩 완료 후 연결 화면으로 진입한다', (WidgetTester tester) async {
      await pumpApp(
        tester,
        onboardingDone: false,
      );

      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('첫 연결을 시작해요'), findsOneWidget);
      expect(find.text('연결하기'), findsOneWidget);
      expect(find.text('로컬'), findsOneWidget);
      expect(find.text('릴레이'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('온보딩 완료 상태에서는 연결 화면이 첫 화면이고 설정으로 이동할 수 있다',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        onboardingDone: true,
      );

      expect(find.text('첫 연결을 시작해요'), findsOneWidget);
      expect(find.byTooltip('설정'), findsOneWidget);

      await tester.tap(find.byTooltip('설정'));
      await tester.pumpAndSettle();

      expect(find.text('설정'), findsOneWidget);
      expect(find.text('버전 0.2.0'), findsOneWidget);
    });
  });
}
