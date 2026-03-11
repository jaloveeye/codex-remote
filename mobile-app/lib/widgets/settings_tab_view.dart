import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
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
    final themeModeLabel = switch (settings.themeMode) {
      ThemeModeSetting.light => AppI18n.t(context, AppTextKey.themeLight),
      ThemeModeSetting.dark => AppI18n.t(context, AppTextKey.themeDark),
      ThemeModeSetting.system => AppI18n.t(context, AppTextKey.themeSystem),
    };

    final languageLabel = switch (settings.appLanguage) {
      AppLanguageSetting.system =>
        AppI18n.t(context, AppTextKey.languageSystem),
      AppLanguageSetting.korean =>
        AppI18n.t(context, AppTextKey.languageKorean),
      AppLanguageSetting.english =>
        AppI18n.t(context, AppTextKey.languageEnglish),
    };

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        HomeTabIntroCard(
          icon: Icons.settings_outlined,
          title: AppI18n.t(context, AppTextKey.settings),
          subtitle: subtitle,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(AppI18n.t(context, AppTextKey.theme)),
                subtitle: Text(themeModeLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenSettings,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(AppI18n.t(context, AppTextKey.language)),
                subtitle: Text(languageLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenSettings,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.history_outlined),
                title: Text(AppI18n.t(context, AppTextKey.showHistoryTitle)),
                subtitle: Text(AppI18n.t(context, AppTextKey.showHistorySub)),
                value: settings.showHistory,
                onChanged: (value) => settings.setShowHistory(value),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(AppI18n.t(context, AppTextKey.aboutTitle)),
                subtitle: Text(AppI18n.t(context, AppTextKey.appVersion)),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenSettings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HomeEmptyStateCard(
          icon: Icons.rocket_launch_outlined,
          title: AppI18n.t(context, AppTextKey.releaseSoonTitle),
          message: AppI18n.t(context, AppTextKey.releaseSoonMessage),
          action: FilledButton(
            onPressed: onOpenSettings,
            child: Text(AppI18n.t(context, AppTextKey.quickOpenSettings)),
          ),
        ),
      ],
    );
  }
}
