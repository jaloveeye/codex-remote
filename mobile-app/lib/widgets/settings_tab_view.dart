import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import 'home_shell_widgets.dart';

class SettingsTabView extends StatelessWidget {
  const SettingsTabView({
    super.key,
    required this.settings,
    required this.subtitle,
    required this.onOpenSettings,
  });

  final AppSettings settings;
  final String subtitle;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        HomeTabIntroCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: subtitle,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('테마'),
                subtitle: Text(
                  settings.themeMode == ThemeModeSetting.system
                      ? '시스템 설정'
                      : settings.themeMode == ThemeModeSetting.dark
                          ? '다크 모드'
                          : '라이트 모드',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenSettings,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.history_outlined),
                title: const Text('세션/히스토리 표시'),
                subtitle: const Text('채팅 화면에 세션 및 대화 히스토리 섹션 표시'),
                value: settings.showHistory,
                onChanged: (value) => settings.setShowHistory(value),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('앱 정보'),
                subtitle: const Text('Codex Remote 0.1.6'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenSettings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HomeEmptyStateCard(
          icon: Icons.rocket_launch_outlined,
          title: '0.1.6 준비 중',
          message: '여기에는 출시형 설정, 진단, 브랜딩, 알림 옵션이 단계적으로 추가될 예정입니다.',
          action: FilledButton(
            onPressed: onOpenSettings,
            child: const Text('전체 설정 열기'),
          ),
        ),
      ],
    );
  }
}
