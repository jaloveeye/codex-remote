import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:codex_remote/main.dart';
import 'package:codex_remote/services/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings().load();
    await tester.binding.setSurfaceSize(const Size(1440, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
  }

  group('0.1.6 app shell', () {
    testWidgets('기본으로 Chat 탭과 4개 하단 탭을 렌더링한다', (WidgetTester tester) async {
      await pumpApp(tester);

      expect(find.text('Codex Remote'), findsOneWidget);
      expect(find.text('Chat'), findsAtLeastNWidgets(1));
      expect(find.text('Approvals'), findsAtLeastNWidgets(1));
      expect(find.text('Sessions'), findsAtLeastNWidgets(1));
      expect(find.text('Settings'), findsAtLeastNWidgets(1));
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Approvals, Sessions, Settings 탭으로 이동할 수 있다', (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Approvals').last);
      await tester.pumpAndSettle();
      expect(find.text('승인 요청을 받을 준비가 필요해요'), findsOneWidget);
      expect(find.text('모바일 승인 요청과 대기 중인 액션을 한곳에서 처리합니다.'), findsOneWidget);

      await tester.tap(find.text('Sessions').last);
      await tester.pumpAndSettle();
      expect(find.text('연결 안 됨'), findsOneWidget);
      expect(find.text('최근 연결'), findsOneWidget);

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      expect(find.text('0.1.6 준비 중'), findsOneWidget);
      expect(find.text('Codex Remote 0.1.6'), findsOneWidget);
    });

    testWidgets('설정 아이콘은 먼저 Settings 탭으로 이동하고 다시 누르면 전체 설정 화면을 연다',
        (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.byTooltip('설정 탭'));
      await tester.pumpAndSettle();

      expect(find.text('0.1.6 준비 중'), findsOneWidget);
      expect(find.byTooltip('전체 설정'), findsOneWidget);

      await tester.tap(find.byTooltip('전체 설정'));
      await tester.pumpAndSettle();

      expect(find.text('설정'), findsOneWidget);
      expect(find.text('버전 0.1.6'), findsOneWidget);
    });
  });
}
