import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../services/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.isDemoMode = false,
    this.onExitDemoMode,
    this.onEnterDemoMode,
  });

  final bool isDemoMode;
  final Future<void> Function()? onExitDemoMode;
  final Future<void> Function()? onEnterDemoMode;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettings _settings = AppSettings();

  bool get _isDemoMode => widget.isDemoMode;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  Widget _buildDemoModeHint() {
    if (_isDemoMode && widget.onExitDemoMode == null) {
      return const SizedBox.shrink();
    }
    if (!_isDemoMode && widget.onEnterDemoMode == null) {
      return const SizedBox.shrink();
    }

    if (_isDemoMode) {
      return _buildDemoModeExitCard();
    }
    return _buildDemoModeEnterCard();
  }

  Widget _buildDemoModeExitCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppI18n.t(context, AppTextKey.demoModeStop),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppI18n.t(context, AppTextKey.demoModeStopSub),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    unawaited(_exitDemoMode());
                  },
                  child: Text(AppI18n.t(context, AppTextKey.leaveDemo)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoModeEnterCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        color:
            Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppI18n.t(context, AppTextKey.demoModeStart),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppI18n.t(context, AppTextKey.demoModeStartSub),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    unawaited(_enterDemoMode());
                  },
                  child: Text(AppI18n.t(context, AppTextKey.startDemo)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exitDemoMode() async {
    if (!_isDemoMode || widget.onExitDemoMode == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppI18n.t(context, AppTextKey.demoModeStopDialogTitle)),
        content: Text(AppI18n.t(context, AppTextKey.demoModeStopDialogContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppI18n.t(context, AppTextKey.dialogCancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppI18n.t(context, AppTextKey.demoModeStopButton)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await widget.onExitDemoMode!();
  }

  Future<void> _enterDemoMode() async {
    if (_isDemoMode || widget.onEnterDemoMode == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppI18n.t(context, AppTextKey.demoModeStartDialogTitle)),
        content:
            Text(AppI18n.t(context, AppTextKey.demoModeStartDialogContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppI18n.t(context, AppTextKey.dialogCancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppI18n.t(context, AppTextKey.demoModeStartButton)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (mounted) {
      Navigator.of(context).pop();
    }
    await widget.onEnterDemoMode!();
  }

  String _languageSubLabel() {
    return AppI18n.t(context, AppTextKey.languageSub);
  }

  String _languageTitle() {
    return AppI18n.t(context, AppTextKey.language);
  }

  Widget _buildLanguageTile(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.translate,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(_languageTitle()),
      subtitle: Text(_languageSubLabel()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppI18n.t(context, AppTextKey.languageSelectTitle)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguageSetting.values.map((language) {
            return RadioListTile<AppLanguageSetting>(
              title: Text(_languageName(language)),
              value: language,
              groupValue: _settings.appLanguage,
              onChanged: (value) {
                if (value != null) {
                  _settings.setAppLanguage(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _languageName(AppLanguageSetting language) {
    switch (language) {
      case AppLanguageSetting.system:
        return AppI18n.t(context, AppTextKey.languageSystem);
      case AppLanguageSetting.korean:
        return AppI18n.t(context, AppTextKey.languageKorean);
      case AppLanguageSetting.english:
        return AppI18n.t(context, AppTextKey.languageEnglish);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppI18n.t(context, AppTextKey.settings),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isDemoMode)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: AppI18n.t(context, AppTextKey.demoModeTooltipStop),
              onPressed: () {
                unawaited(_exitDemoMode());
              },
            ),
          if (!_isDemoMode && widget.onEnterDemoMode != null)
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: AppI18n.t(context, AppTextKey.demoModeTooltipStart),
              onPressed: () {
                unawaited(_enterDemoMode());
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          _buildDemoModeHint(),
          _buildSectionHeader(
              context, AppI18n.t(context, AppTextKey.settingsAppearance)),
          _buildThemeModeTile(context),
          const Divider(),
          _buildSectionHeader(
              context, AppI18n.t(context, AppTextKey.settingsFunction)),
          _buildLanguageTile(context),
          const Divider(),
          _buildShowHistoryTile(context),
          const Divider(),
          _buildSectionHeader(
              context, AppI18n.t(context, AppTextKey.settingsInfo)),
          _buildAboutTile(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeModeTile(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getThemeIcon(_settings.themeMode),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(AppI18n.t(context, AppTextKey.theme)),
      subtitle: Text(_getThemeModeLabel(_settings.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeModeDialog(context),
    );
  }

  IconData _getThemeIcon(ThemeModeSetting mode) {
    switch (mode) {
      case ThemeModeSetting.light:
        return Icons.light_mode;
      case ThemeModeSetting.dark:
        return Icons.dark_mode;
      case ThemeModeSetting.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeModeLabel(ThemeModeSetting mode) {
    switch (mode) {
      case ThemeModeSetting.light:
        return AppI18n.t(context, AppTextKey.themeLight);
      case ThemeModeSetting.dark:
        return AppI18n.t(context, AppTextKey.themeDark);
      case ThemeModeSetting.system:
        return AppI18n.t(context, AppTextKey.themeSystem);
    }
  }

  void _showThemeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppI18n.t(context, AppTextKey.themeSelect)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeModeSetting.values.map((mode) {
            return RadioListTile<ThemeModeSetting>(
              title: Row(
                children: [
                  Icon(_getThemeIcon(mode), size: 20),
                  const SizedBox(width: 12),
                  Text(_getThemeModeLabel(mode)),
                ],
              ),
              value: mode,
              groupValue: _settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  _settings.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShowHistoryTile(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.history,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(AppI18n.t(context, AppTextKey.showHistoryTitle)),
      subtitle: Text(AppI18n.t(context, AppTextKey.showHistorySub)),
      value: _settings.showHistory,
      onChanged: (value) => _settings.setShowHistory(value),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(AppI18n.t(context, AppTextKey.aboutTitle)),
      subtitle: Text(AppI18n.t(context, AppTextKey.appVersion)),
      onTap: () => _showAboutDialog(context),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppI18n.t(context, AppTextKey.aboutTitle),
      applicationVersion: '0.2.1',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.code,
          size: 32,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        Text(
          AppI18n.t(context, AppTextKey.appVersionSub),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
