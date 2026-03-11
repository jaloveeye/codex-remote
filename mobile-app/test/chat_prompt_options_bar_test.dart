import 'package:codex_remote/widgets/chat_prompt_options_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ChatPromptOptionsBar', () {
    testWidgets('capabilities 로딩 중에는 로딩 UI를 보여준다', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          ChatPromptOptionsBar(
            showLoading: true,
            loadingLabel: '이후 모든 모델을 불러오고 있습니다...',
            selectedModelLabel: 'Auto',
            selectedReasoningLabel: 'Auto',
            modelItems: const [],
            reasoningItems: const [],
            onModelSelected: (_) {},
            onReasoningSelected: (_) {},
          ),
        ),
      );

      expect(find.text('이후 모든 모델을 불러오고 있습니다...'), findsOneWidget);
      expect(find.byKey(const Key('chat_model_selector')), findsNothing);
      expect(find.byKey(const Key('chat_reasoning_selector')), findsNothing);
    });

    testWidgets('모델/이성 메뉴 선택 시 콜백이 호출된다', (WidgetTester tester) async {
      String? selectedModel;
      String? selectedReasoning;

      await tester.pumpWidget(
        wrap(
          ChatPromptOptionsBar(
            showLoading: false,
            selectedModelLabel: 'Auto',
            selectedReasoningLabel: 'Auto',
            modelItems: const [
              PromptOptionItem(value: 'auto', label: 'Auto'),
              PromptOptionItem(value: 'gpt-5', label: 'GPT-5'),
            ],
            reasoningItems: const [
              PromptOptionItem(value: 'auto', label: 'Auto'),
              PromptOptionItem(value: 'medium', label: 'Medium'),
            ],
            onModelSelected: (value) => selectedModel = value,
            onReasoningSelected: (value) => selectedReasoning = value,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('chat_model_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GPT-5').last);
      await tester.pumpAndSettle();

      expect(selectedModel, 'gpt-5');

      await tester.tap(find.byKey(const Key('chat_reasoning_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medium').last);
      await tester.pumpAndSettle();

      expect(selectedReasoning, 'medium');
    });
  });
}
