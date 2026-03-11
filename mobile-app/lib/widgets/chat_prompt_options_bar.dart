import 'package:flutter/material.dart';

import '../services/app_i18n.dart';

class PromptOptionItem {
  final String value;
  final String label;

  const PromptOptionItem({
    required this.value,
    required this.label,
  });
}

class ChatPromptOptionsBar extends StatelessWidget {
  const ChatPromptOptionsBar({
    super.key,
    required this.showLoading,
    this.loadingLabel = '모델 목록을 불러오는 중...',
    required this.selectedModelLabel,
    required this.selectedReasoningLabel,
    required this.modelItems,
    required this.reasoningItems,
    required this.onModelSelected,
    required this.onReasoningSelected,
  });

  final bool showLoading;
  final String loadingLabel;
  final String selectedModelLabel;
  final String selectedReasoningLabel;
  final List<PromptOptionItem> modelItems;
  final List<PromptOptionItem> reasoningItems;
  final ValueChanged<String> onModelSelected;
  final ValueChanged<String> onReasoningSelected;

  @override
  Widget build(BuildContext context) {
    if (showLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loadingLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          PopupMenuButton<String>(
            key: const Key('chat_model_selector'),
            tooltip: AppI18n.t(context, AppTextKey.promptModelSelectorTooltip),
            onSelected: onModelSelected,
            itemBuilder: (context) {
              return modelItems
                  .map(
                    (item) => PopupMenuItem<String>(
                      value: item.value,
                      child: Text(item.label),
                    ),
                  )
                  .toList();
            },
            child: _OptionChip(
              icon: Icons.smart_toy_outlined,
              label: AppI18n.t(context, AppTextKey.promptModelLabel),
              value: selectedModelLabel,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            key: const Key('chat_reasoning_selector'),
            tooltip:
                AppI18n.t(context, AppTextKey.promptReasoningSelectorTooltip),
            onSelected: onReasoningSelected,
            itemBuilder: (context) {
              return reasoningItems
                  .map(
                    (item) => PopupMenuItem<String>(
                      value: item.value,
                      child: Text(item.label),
                    ),
                  )
                  .toList();
            },
            child: _OptionChip(
              icon: Icons.psychology_alt_outlined,
              label: AppI18n.t(context, AppTextKey.promptReasoningLabel),
              value: selectedReasoningLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
