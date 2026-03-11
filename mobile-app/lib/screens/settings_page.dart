import 'dart:async';

import 'package:flutter/material.dart';

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
                '앱 둘러보기 모드',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '현재 둘러보기 모드입니다. 실제 연결 기능은 제외된 상태로 UI/기능 흐름만 확인 가능합니다.',
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
                  child: const Text('둘러보기 나가기'),
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
        color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '앱 둘러보기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '실제 연결 없이도 화면 흐름을 확인할 수 있는 심사 모드로 전환합니다.',
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
                  child: const Text('둘러보기 시작'),
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
        title: const Text('둘러보기 모드 종료'),
        content: const Text(
          '심사용 둘러보기 모드를 종료하고 실제 연결 화면으로 이동합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('종료하기'),
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
        title: const Text('앱 둘러보기 시작'),
        content: const Text(
          '실제 연결 없이 화면/기능 흐름을 확인하는 둘러보기 모드로 전환합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('시작'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await widget.onEnterDemoMode!();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isDemoMode)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '둘러보기 나가기',
              onPressed: () {
                unawaited(_exitDemoMode());
              },
            ),
          if (!_isDemoMode && widget.onEnterDemoMode != null)
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: '둘러보기 시작',
              onPressed: () {
                unawaited(_enterDemoMode());
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          _buildDemoModeHint(),
          _buildSectionHeader(context, '외관'),
          _buildThemeModeTile(context),
          const Divider(),
          _buildSectionHeader(context, '기능'),
          _buildShowHistoryTile(context),
          const Divider(),
          _buildSectionHeader(context, '정보'),
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
      title: const Text('테마'),
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
        return '라이트 모드';
      case ThemeModeSetting.dark:
        return '다크 모드';
      case ThemeModeSetting.system:
        return '시스템 설정';
    }
  }

  void _showThemeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 선택'),
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
      title: const Text('세션 및 대화 히스토리'),
      subtitle: const Text('메인 화면에 히스토리 섹션 표시'),
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
      title: const Text('Codex Remote'),
      subtitle: const Text('버전 0.2.0'),
      onTap: () => _showAboutDialog(context),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Codex Remote',
      applicationVersion: '0.2.0',
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
      children: const [
        SizedBox(height: 16),
        Text(
          '모바일에서 Codex를 원격으로 제어하세요.',
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
