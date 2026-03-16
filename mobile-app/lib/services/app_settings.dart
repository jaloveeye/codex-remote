import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/connection_models.dart';

enum ThemeModeSetting {
  light,
  dark,
  system,
}

enum AppLanguageSetting {
  system,
  korean,
  english,
}

extension AppLanguageSettingCode on AppLanguageSetting {
  String get storageKey {
    switch (this) {
      case AppLanguageSetting.system:
        return 'system';
      case AppLanguageSetting.korean:
        return 'ko';
      case AppLanguageSetting.english:
        return 'en';
    }
  }

  Locale? get locale {
    switch (this) {
      case AppLanguageSetting.system:
        return null;
      case AppLanguageSetting.korean:
        return const Locale('ko');
      case AppLanguageSetting.english:
        return const Locale('en');
    }
  }
}

class RuntimeCapabilitiesCache {
  const RuntimeCapabilitiesCache({
    required this.capabilities,
    required this.cachedAt,
  });

  final Map<String, dynamic> capabilities;
  final DateTime cachedAt;
}

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // 설정 키
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyShowHistory = 'show_history';
  static const String _keyDefaultAgentMode = 'default_agent_mode';
  static const String _keyDefaultModel = 'default_model';
  static const String _keyDefaultReasoningEffort = 'default_reasoning_effort';
  static const String _keyAutoConnect = 'auto_connect';
  static const String _keyConnectionHistory = 'connection_history';
  static const String _keyRuntimeCapabilitiesCache =
      'runtime_capabilities_cache';
  static const String _keyAppLanguage = 'app_language';

  // 최대 히스토리 개수
  static const int _maxHistoryCount = 5;

  // 현재 설정값
  ThemeModeSetting _themeMode = ThemeModeSetting.system;
  bool _showHistory = false; // 기본값: 숨김
  String _defaultAgentMode = 'auto';
  String _defaultModel = 'auto';
  String _defaultReasoningEffort = 'low';
  bool _autoConnect = false;
  AppLanguageSetting _appLanguage = AppLanguageSetting.system;
  List<ConnectionHistoryItem> _connectionHistory = [];

  // getters
  ThemeModeSetting get themeMode => _themeMode;
  bool get showHistory => _showHistory;
  String get defaultAgentMode => _defaultAgentMode;
  String get defaultModel => _defaultModel;
  String get defaultReasoningEffort => _defaultReasoningEffort;
  bool get autoConnect => _autoConnect;
  AppLanguageSetting get appLanguage => _appLanguage;
  Locale? get appLocale => _appLanguage.locale;
  List<ConnectionHistoryItem> get connectionHistory =>
      List.unmodifiable(_connectionHistory);

  ThemeMode get themeModeValue {
    switch (_themeMode) {
      case ThemeModeSetting.light:
        return ThemeMode.light;
      case ThemeModeSetting.dark:
        return ThemeMode.dark;
      case ThemeModeSetting.system:
        return ThemeMode.system;
    }
  }

  static AppLanguageSetting _parseAppLanguage(String? value) {
    for (final language in AppLanguageSetting.values) {
      if (language.storageKey == value) {
        return language;
      }
    }
    return AppLanguageSetting.system;
  }

  // 설정 로드
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 테마
    final themeModeIndex = prefs.getInt(_keyThemeMode) ?? 2; // system default
    _themeMode = ThemeModeSetting.values[themeModeIndex.clamp(0, 2)];

    // 히스토리 표시
    _showHistory = prefs.getBool(_keyShowHistory) ?? false;

    // 기본 에이전트 모드
    _defaultAgentMode = prefs.getString(_keyDefaultAgentMode) ?? 'auto';

    // 기본 모델
    _defaultModel = prefs.getString(_keyDefaultModel) ?? 'auto';

    // 기본 이성(추론) 수준
    _defaultReasoningEffort =
        prefs.getString(_keyDefaultReasoningEffort) ?? 'low';

    // 자동 연결
    _autoConnect = prefs.getBool(_keyAutoConnect) ?? false;

    // 앱 언어
    _appLanguage = _parseAppLanguage(prefs.getString(_keyAppLanguage));

    // 연결 히스토리
    final historyJson = prefs.getString(_keyConnectionHistory);
    if (historyJson != null && historyJson.isNotEmpty) {
      _connectionHistory = parseConnectionHistory(historyJson);
    }

    notifyListeners();
  }

  // 테마 모드 설정
  Future<void> setThemeMode(ThemeModeSetting mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  // 히스토리 표시 설정
  Future<void> setShowHistory(bool value) async {
    _showHistory = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowHistory, value);
    notifyListeners();
  }

  // 앱 언어 설정
  Future<void> setAppLanguage(AppLanguageSetting language) async {
    _appLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLanguage, language.storageKey);
    notifyListeners();
  }

  // 기본 에이전트 모드 설정
  Future<void> setDefaultAgentMode(String mode) async {
    _defaultAgentMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultAgentMode, mode);
    notifyListeners();
  }

  // 기본 모델 설정
  Future<void> setDefaultModel(String model) async {
    _defaultModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultModel, model);
    notifyListeners();
  }

  // 기본 이성(추론) 수준 설정
  Future<void> setDefaultReasoningEffort(String effort) async {
    _defaultReasoningEffort = effort;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultReasoningEffort, effort);
    notifyListeners();
  }

  // 자동 연결 설정
  Future<void> setAutoConnect(bool value) async {
    _autoConnect = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoConnect, value);
    notifyListeners();
  }

  // 연결 히스토리에 추가
  Future<void> addConnectionHistory(ConnectionHistoryItem item) async {
    // 동일한 연결이 있으면 제거 (최신으로 갱신하기 위해)
    _connectionHistory.removeWhere((h) => h.isSameConnection(item));

    // 맨 앞에 추가
    _connectionHistory.insert(0, item);

    // 최대 개수 유지
    if (_connectionHistory.length > _maxHistoryCount) {
      _connectionHistory = _connectionHistory.sublist(0, _maxHistoryCount);
    }

    // 저장
    await _saveConnectionHistory();
    notifyListeners();
  }

  // 연결 히스토리 저장
  Future<void> _saveConnectionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson =
        jsonEncode(_connectionHistory.map((h) => h.toJson()).toList());
    await prefs.setString(_keyConnectionHistory, historyJson);
  }

  // 연결 히스토리 삭제
  Future<void> removeConnectionHistory(ConnectionHistoryItem item) async {
    _connectionHistory.removeWhere((h) => h.isSameConnection(item));
    await _saveConnectionHistory();
    notifyListeners();
  }

  // 연결 히스토리 전체 삭제
  Future<void> clearConnectionHistory() async {
    _connectionHistory.clear();
    await _saveConnectionHistory();
    notifyListeners();
  }

  Future<void> saveRuntimeCapabilitiesCache(
      Map<String, dynamic> capabilities) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'cachedAt': DateTime.now().toIso8601String(),
      'capabilities': capabilities,
    };
    await prefs.setString(_keyRuntimeCapabilitiesCache, jsonEncode(payload));
  }

  Future<RuntimeCapabilitiesCache?> getRuntimeCapabilitiesCache({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRuntimeCapabilitiesCache);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final cachedAtRaw = decoded['cachedAt']?.toString();
      final capabilitiesRaw = decoded['capabilities'];
      if (cachedAtRaw == null || capabilitiesRaw is! Map) return null;

      final cachedAt = DateTime.tryParse(cachedAtRaw);
      if (cachedAt == null) return null;
      if (DateTime.now().difference(cachedAt) > maxAge) return null;

      return RuntimeCapabilitiesCache(
        capabilities: Map<String, dynamic>.from(capabilitiesRaw),
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }
}
