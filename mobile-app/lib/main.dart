import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/connection_models.dart';
import 'models/trace_timeline_models.dart';
import 'services/app_settings.dart';
import 'services/app_i18n.dart';
import 'services/trace_api_service.dart';
import 'services/streaming_text_merge.dart';
import 'services/polling_profile.dart';
import 'services/response_indicator.dart';
import 'services/codex_request_history.dart';
import 'services/trace_timeline_ui.dart';
import 'services/runtime_capability_policy.dart';
import 'screens/settings_page.dart';
import 'widgets/approvals_tab_view.dart';
import 'widgets/chat_prompt_options_bar.dart';
import 'widgets/sessions_tab_view.dart';
import 'widgets/settings_tab_view.dart';
import 'widgets/trace_timeline_panel.dart';

// Relay 서버 URL (빌드 시 --dart-define=RELAY_SERVER_URL=... 으로 덮어쓸 수 있음)
const String RELAY_SERVER_URL = String.fromEnvironment(
  'RELAY_SERVER_URL',
  defaultValue: 'https://codex-relay.jaloveeye.com',
);
const bool DEMO_MODE = bool.fromEnvironment(
  'DEMO_MODE',
  defaultValue: false,
);
const String DEMO_START_TAB = String.fromEnvironment(
  'DEMO_START_TAB',
  defaultValue: 'chat',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings().load();
  runApp(const MyApp());
}

// ============================================================
// 라이트 테마
// ============================================================
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    // Primary 색상 (웜 올리브)
    primary: const Color(0xFF6C7254),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFEDEDDD),
    onPrimaryContainer: const Color(0xFF383B2A),
    // Secondary 색상 (웜 그레이 올리브)
    secondary: const Color(0xFF6B7466),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFF0F2EA),
    onSecondaryContainer: const Color(0xFF3A4437),
    // Tertiary 색상 (옅은 모스 그린)
    tertiary: const Color(0xFF87967B),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFEAF0E4),
    onTertiaryContainer: const Color(0xFF3A4734),
    // Error 색상
    error: const Color(0xFFDC3545),
    onError: Colors.white,
    errorContainer: const Color(0xFFFFEBEE),
    onErrorContainer: const Color(0xFFB71C1C),
    // Surface 색상
    surface: const Color(0xFFFCFCF8),
    onSurface: const Color(0xFF22281F),
    surfaceContainerHighest: const Color(0xFFF2F1EA),
    onSurfaceVariant: const Color(0xFF70766C),
    // Outline 색상
    outline: const Color(0xFFD8DDD1),
    outlineVariant: const Color(0xFFE7EADF),
    // Shadow
    shadow: Colors.black.withOpacity(0.05),
    scrim: Colors.black.withOpacity(0.5),
    // Inverse
    inverseSurface: const Color(0xFF2B332B),
    onInverseSurface: Colors.white,
    inversePrimary: const Color(0xFFD9DCC6),
  ),
  scaffoldBackgroundColor: const Color(0xFFF7F5EF),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 1,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF22281F),
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Color(0xFF22281F),
      letterSpacing: -0.3,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFFFFFEFB),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(
        color: Color(0xFFD8DDD1),
        width: 1,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFBFAF6),
    hintStyle: const TextStyle(
      color: Color(0xFF9AA092),
      fontSize: 13,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFF6C7254),
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD8DDD1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD8DDD1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF6C7254), width: 1.1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFFD8DDD1)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE7EADF),
    thickness: 1,
    space: 1,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: const Color(0xFFEFF3EA),
    disabledColor: const Color(0xFFF8F7F2),
    side: const BorderSide(color: Color(0xFFD8DDD1)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    ),
    labelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  expansionTileTheme: const ExpansionTileThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    collapsedShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    childrenPadding: EdgeInsets.zero,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF454A34),
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
);

// ============================================================
// 다크 테마
// ============================================================
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    // Primary 색상 (은은한 웜 올리브)
    primary: const Color(0xFFD9DCC6),
    onPrimary: const Color(0xFF2D311F),
    primaryContainer: const Color(0xFF3A3F2A),
    onPrimaryContainer: const Color(0xFFF0F2E5),
    // Secondary 색상 (웜 그레이 올리브)
    secondary: const Color(0xFFA8B19F),
    onSecondary: const Color(0xFF202920),
    secondaryContainer: const Color(0xFF293029),
    onSecondaryContainer: const Color(0xFFE7EDE0),
    // Tertiary 색상 (부드러운 허브 그린)
    tertiary: const Color(0xFFB4C3A4),
    onTertiary: const Color(0xFF22301F),
    tertiaryContainer: const Color(0xFF334030),
    onTertiaryContainer: const Color(0xFFE7EFDE),
    // Error 색상
    error: const Color(0xFFFF6B6B),
    onError: const Color(0xFF3D0000),
    errorContainer: const Color(0xFF5C2323),
    onErrorContainer: const Color(0xFFFFDADA),
    // Surface 색상
    surface: const Color(0xFF171C17),
    onSurface: const Color(0xFFF1F4EA),
    surfaceContainerHighest: const Color(0xFF252D25),
    onSurfaceVariant: const Color(0xFFC0C8BA),
    // Outline 색상
    outline: const Color(0xFF596359),
    outlineVariant: const Color(0xFF3D463D),
    // Shadow
    shadow: Colors.black.withOpacity(0.25),
    scrim: Colors.black.withOpacity(0.6),
    // Inverse
    inverseSurface: const Color(0xFFE6EBDD),
    onInverseSurface: const Color(0xFF1D241D),
    inversePrimary: const Color(0xFF343923),
  ),
  scaffoldBackgroundColor: const Color(0xFF121612),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 1,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFE6EBDD),
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Color(0xFFE6EBDD),
      letterSpacing: -0.3,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFF1D241D),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(
        color: Color(0xFF3D463D),
        width: 1,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF202720),
    hintStyle: const TextStyle(
      color: Color(0xFFAAB3A3),
      fontSize: 13,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFFD9DCC6),
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF4A544A)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF4A544A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB9BE9B), width: 1.1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF596359)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF3D463D),
    thickness: 1,
    space: 1,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF202720),
    selectedColor: const Color(0xFF313A31),
    disabledColor: const Color(0xFF161B16),
    side: const BorderSide(color: Color(0xFF4A544A)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    ),
    labelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFFF1F4EA),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  expansionTileTheme: const ExpansionTileThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    collapsedShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    childrenPadding: EdgeInsets.zero,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF394139),
    contentTextStyle: const TextStyle(color: Color(0xFFF1F4EA)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
);

// ============================================================
// 앱 루트
// ============================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _onboardingDoneKey = 'mobile_onboarding_done_v1';
  bool _isBootstrapping = true;
  bool _showOnboarding = false;
  bool _demoModeEnabled = DEMO_MODE;

  @override
  void initState() {
    super.initState();
    AppSettings().addListener(_onSettingsChanged);
    unawaited(_prepareLaunchFlow());
  }

  @override
  void dispose() {
    AppSettings().removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  Future<void> _prepareLaunchFlow() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(_onboardingDoneKey) ?? false;

    if (!mounted) return;
    setState(() {
      _showOnboarding = !onboardingDone || DEMO_MODE;
      _isBootstrapping = false;
    });
  }

  Future<void> _completeOnboarding({bool demoMode = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
    if (!mounted) return;
    setState(() {
      _showOnboarding = false;
      _demoModeEnabled = demoMode;
    });
  }

  Future<void> _enterDemoMode() async {
    if (_demoModeEnabled || !mounted) return;
    setState(() {
      _showOnboarding = false;
      _demoModeEnabled = true;
    });
  }

  Future<void> _exitReviewMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, false);
    if (!mounted) return;
    setState(() {
      _demoModeEnabled = false;
      _showOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codex Remote',
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: AppSettings().appLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      themeMode: AppSettings().themeModeValue,
      home: _isBootstrapping
          ? const SplashLaunchPage()
          : (_showOnboarding
              ? OnboardingPage(
                  onContinue: _completeOnboarding,
                  onEnterDemoMode: () => _completeOnboarding(demoMode: true),
                )
              : HomePage(
                  demoMode: _demoModeEnabled,
                  onExitDemoMode: _exitReviewMode,
                  onEnterDemoMode: _enterDemoMode,
                  initialTab: _resolveDemoStartTab(),
                )),
    );
  }

  HomeTab _resolveDemoStartTab() {
    switch (DEMO_START_TAB.trim().toLowerCase()) {
      case 'approvals':
        return HomeTab.approvals;
      case 'sessions':
        return HomeTab.sessions;
      case 'settings':
        return HomeTab.settings;
      case 'chat':
      default:
        return HomeTab.chat;
    }
  }
}

class SplashLaunchPage extends StatelessWidget {
  const SplashLaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(26),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset('images/app_icon.png'),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Codex Remote',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppI18n.t(context, AppTextKey.connectionReadyText),
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(999),
                minHeight: 6,
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.onContinue,
    required this.onEnterDemoMode,
  });

  final Future<void> Function() onContinue;
  final Future<void> Function() onEnterDemoMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppI18n.t(context, AppTextKey.onboardingTitle),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppI18n.t(context, AppTextKey.onboardingSubtitle),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _OnboardingFeatureTile(
                icon: Icons.hub_outlined,
                title:
                    AppI18n.t(context, AppTextKey.onboardingFeatureConnection),
                description: AppI18n.t(
                    context, AppTextKey.onboardingFeatureConnectionDesc),
              ),
              const SizedBox(height: 12),
              _OnboardingFeatureTile(
                icon: Icons.gpp_good_outlined,
                title:
                    AppI18n.t(context, AppTextKey.onboardingFeatureApprovals),
                description: AppI18n.t(
                    context, AppTextKey.onboardingFeatureApprovalsDesc),
              ),
              const SizedBox(height: 12),
              _OnboardingFeatureTile(
                icon: Icons.chat_bubble_outline,
                title: AppI18n.t(context, AppTextKey.onboardingFeatureChat),
                description:
                    AppI18n.t(context, AppTextKey.onboardingFeatureChatDesc),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    unawaited(onContinue());
                  },
                  child: Text(
                      AppI18n.t(context, AppTextKey.onboardingStartButton)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    unawaited(onEnterDemoMode());
                  },
                  child:
                      Text(AppI18n.t(context, AppTextKey.onboardingDemoButton)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingFeatureTile extends StatelessWidget {
  const _OnboardingFeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.demoMode = false,
    this.onExitDemoMode,
    this.onEnterDemoMode,
    this.initialTab = HomeTab.chat,
  });

  final bool demoMode;
  final Future<void> Function()? onExitDemoMode;
  final Future<void> Function()? onEnterDemoMode;
  final HomeTab initialTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

// 메시지 타입 상수
class MessageType {
  static const String normal = 'normal';
  static const String chatResponse = 'chat_response';
  static const String chatResponseChunk = 'chat_response_chunk'; // 스트리밍 청크
  static const String chatResponseComplete =
      'chat_response_complete'; // 스트리밍 완료
  static const String chatResponseHeader = 'chat_response_header';
  static const String chatResponseDivider = 'chat_response_divider';
  static const String userMessage = 'user_message';
  static const String userPrompt = 'user_prompt'; // 사용자가 입력한 프롬프트
  static const String geminiResponse = 'gemini_response';
  static const String terminalOutput = 'terminal_output';
  static const String system = 'system'; // Sent, Received, Command succeeded 등
  static const String log = 'log'; // 실시간 로그
  static const String codexRawEvent = 'codex_raw_event';
}

// 필터 카테고리
enum MessageFilter {
  aiResponse, // Codex Response
  userPrompt, // 사용자가 입력한 프롬프트
  system, // Sent, Received, Command succeeded 등
  log, // 실시간 로그
}

// 로그 레벨
enum LogLevel {
  error, // 에러
  warning, // 경고
  info, // 정보
}

enum AutoDecisionMode {
  off,
  approve,
  reject,
}

enum HomeTab {
  chat,
  approvals,
  sessions,
  settings,
}

enum ModelCatalogLoadStage {
  idle,
  loading,
  defaultReady,
  syncingAll,
  completed,
  delayed,
  failed,
}

class MessageItem {
  final String text;
  final String type; // MessageType 상수 사용
  final DateTime timestamp;
  String? agentMode; // 에이전트 모드 (userPrompt 타입일 때만 사용)
  LogLevel? logLevel; // 로그 레벨 (log 타입일 때만 사용)
  String? logSource; // 로그 소스 (log 타입일 때만 사용)
  String? logChannel; // local/relay 채널 표시용

  MessageItem(this.text,
      {this.type = MessageType.normal,
      this.agentMode,
      this.logLevel,
      this.logSource,
      this.logChannel})
      : timestamp = DateTime.now();

  // 필터 카테고리 결정
  MessageFilter? get filterCategory {
    switch (type) {
      case MessageType.chatResponse:
      case MessageType.chatResponseChunk:
      case MessageType.chatResponseComplete:
      case MessageType.chatResponseHeader:
      case MessageType.chatResponseDivider:
      case MessageType.geminiResponse:
        return MessageFilter.aiResponse;
      case MessageType.userPrompt:
        return MessageFilter.userPrompt;
      case MessageType.log:
      case MessageType.codexRawEvent:
        return MessageFilter.log;
      case MessageType.system:
      case MessageType.normal:
      case MessageType.terminalOutput:
        return MessageFilter.system;
      default:
        return MessageFilter.system;
    }
  }
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool get _isDemoMode => widget.demoMode;

  HomeTab _selectedHomeTab = HomeTab.chat;

  // 연결 타입
  ConnectionType _connectionType = ConnectionType.relay;

  // Relay 서버 관련
  String? _sessionId;
  String _deviceId = '';
  bool _isConnected = false;
  bool _isWaitingForResponse = false; // 응답 대기 중 상태

  // Codex 세션 관련
  String? _currentCodexSessionId; // 현재 Codex 세션 ID
  String? _currentClientId; // 현재 클라이언트 ID
  Timer? _pollTimer;
  Timer? _capabilitiesLoadTimer;
  Timer? _capabilitiesStageTimer;
  bool _isRelayPollInFlight = false;
  int _lastRelayPollStartedAtMs = 0;
  int _traceIdSequence = 0;
  static const Duration _pollSchedulerTick = Duration(milliseconds: 250);

  // 스트리밍 관련
  int? _streamingMessageIndex; // 현재 스트리밍 중인 메시지의 인덱스
  String _streamingText = ''; // 스트리밍 중인 텍스트
  final Map<String, int> _recentCompletedTraceIds = <String, int>{};

  // 세션 및 대화 히스토리
  Map<String, dynamic>? _sessionInfo; // 현재 세션 정보
  List<Map<String, dynamic>> _chatHistory = []; // 대화 히스토리 목록
  List<String> _availableSessions = []; // 사용 가능한 세션 목록
  List<Map<String, dynamic>> _pendingCommandApprovals = [];
  List<Map<String, dynamic>> _pendingCodexServerRequests = [];
  List<Map<String, dynamic>> _codexRequestHistory = [];
  List<Map<String, dynamic>> _recentCommandEvents = [];
  final Map<String, Map<String, dynamic>> _resolvedApprovalEventFallbacks = {};
  final Set<String> _seenCommandApprovalIds = <String>{};
  final Set<String> _seenCodexRequestIds = <String>{};
  AutoDecisionMode _autoDecisionMode = AutoDecisionMode.off;
  int _autoDecisionTimeoutSec = 30;
  final Map<String, Timer> _autoDecisionTimers = <String, Timer>{};
  bool _loadingCommandApprovals = false;
  bool _loadingCommandEvents = false;
  bool _loadingTraceTimeline = false;
  bool _traceAutoRefresh = false;
  String? _traceTimelineError;
  TraceTimelineData? _traceTimeline;
  List<String> _recentTraceIds = [];
  Timer? _traceAutoRefreshTimer;
  final TextEditingController _traceIdController = TextEditingController();
  final Set<String> _submittingCodexRequestIds = <String>{};
  DateTime? _lastCommandMetaRefreshAt;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isNetworkReachable = true;
  bool _isAppForeground = true;
  int _notificationSequence = 1000;
  static const AndroidNotificationChannel _approvalNotificationChannel =
      AndroidNotificationChannel(
    'approval_requests',
    '승인 요청',
    description: 'Codex/Relay 승인 요청 알림',
    importance: Importance.high,
  );

  /// 같은 세션 재연결 시 메인 목록에 히스토리 반영용 (get_chat_history 응답 시 사용)
  bool _loadingSessionHistoryForDisplay = false;

  /// 과거 메시지 불러오기 버튼으로 요청한 로드 (응답 시 _messages에 반영)
  bool _loadingPastMessages = false;

  // 로컬 서버 관련
  WebSocketChannel? _localWebSocket;
  final TextEditingController _localIpController = TextEditingController();
  final TextEditingController _localPortController =
      TextEditingController(text: '8766');

  // 재연결 관련
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  bool _isConnectionActionInProgress = false;
  String? _connectionActionLabel;
  String? _lastConnectionError;

  // 런타임 옵션 관련
  String _selectedAgentMode = 'auto'; // 내부는 auto 유지
  String _selectedModel = 'auto';
  String _selectedReasoningEffort = 'low';
  bool _useIdeContext = false;
  bool _useFlatMode = false;
  bool _capabilitiesLoaded = false;
  bool _capabilitiesLoading = false;
  static const Set<String> _supportedAgentModes = {
    'auto',
    'agent',
    'ask',
    'plan',
    'debug',
  };
  static const List<String> _fallbackAgentModes = [
    'auto',
    'agent',
    'ask',
    'plan',
    'debug',
  ];
  static const List<Map<String, dynamic>> _fallbackModels = [];
  List<String> _availableAgentModes = List<String>.from(_fallbackAgentModes);
  List<Map<String, dynamic>> _availableModels =
      List<Map<String, dynamic>>.from(_fallbackModels);
  bool _supportsIdeContext = false;
  bool _supportsFlatMode = false;
  bool _capabilitiesFromCache = false;
  ModelCatalogLoadStage _modelCatalogLoadStage = ModelCatalogLoadStage.idle;
  final RuntimeCapabilitySingleFlight _capabilitiesSingleFlight =
      RuntimeCapabilitySingleFlight();
  DateTime? _runtimeCapabilitiesRequestedAt;
  String? _actualSelectedMode; // 자동 모드로 선택된 경우 실제 선택된 모드 (null이면 사용자가 직접 선택)
  MessageItem? _lastUserPrompt; // 마지막 User Prompt 메시지 (모드 업데이트용)

  final List<MessageItem> _messages = [];
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _sessionIdController = TextEditingController();

  // 입력창 상태 관리
  DateTime? _lastPromptSubmitTime; // Enter 중복 전송 방지용 debounce
  final FocusNode _sessionIdFocusNode = FocusNode();
  final FocusNode _localIpFocusNode = FocusNode();
  final FocusNode _commandFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ExpansionTileController _expansionTileController =
      ExpansionTileController();

  /// 스크롤 버튼 표시: 위로/아래로 스크롤 가능할 때만
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  /// 연결 후 컴팩트 뷰 (메시지 크게 + 한줄 프롬프트만)
  bool _isCompactView = true;

  // 필터 상태 (기본값: AI 응답 + 사용자 프롬프트만 활성화)
  final Map<MessageFilter, bool> _activeFilters = {
    MessageFilter.aiResponse: true,
    MessageFilter.userPrompt: true,
    MessageFilter.system: false,
    MessageFilter.log: false,
  };

  // 로그 레벨별 필터 상태 (기본값: 모두 활성화)
  final Map<LogLevel, bool> _logLevelFilters = {
    LogLevel.error: true,
    LogLevel.warning: true,
    LogLevel.info: true,
  };

  // 필터링된 메시지 목록 (카테고리 필터만)
  List<MessageItem> get _filteredMessages {
    return _messages.where((msg) {
      final category = msg.filterCategory;
      if (category == null) return true;

      // 로그 메시지인 경우 레벨별 필터도 적용
      if (category == MessageFilter.log &&
          (_activeFilters[MessageFilter.log] ?? false)) {
        final level = msg.logLevel ?? LogLevel.info;
        if (!(_logLevelFilters[level] ?? true)) return false;
      }

      return _activeFilters[category] ?? true;
    }).toList();
  }

  // 검색: 전체(프롬프트+답변) 또는 답변만
  static const String _searchScopeAll = 'all';
  static const String _searchScopeAnswerOnly = 'answer_only';
  String _searchQuery = '';
  String _searchScope = _searchScopeAll;

  // 검색 적용된 표시용 메시지 목록
  List<MessageItem> get _displayMessages {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _filteredMessages;
    return _filteredMessages.where((m) {
      final inScope = _searchScope == _searchScopeAnswerOnly
          ? m.filterCategory == MessageFilter.aiResponse
          : true;
      return inScope && m.text.toLowerCase().contains(q);
    }).toList();
  }

  /// 대화 메시지 수 (사용자 프롬프트 + AI 응답만, 구분선/헤더 제외)
  int get _contentMessageCount => _messages
      .where((m) =>
          m.type == MessageType.userPrompt ||
          m.type == MessageType.chatResponse)
      .length;
  int get _filteredContentMessageCount => _filteredMessages
      .where((m) =>
          m.type == MessageType.userPrompt ||
          m.type == MessageType.chatResponse)
      .length;

  String get _effectiveRelayServerUrl =>
      RELAY_SERVER_URL.trim().replaceAll(RegExp(r'/+$'), '');

  Uri _relayUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_effectiveRelayServerUrl$normalizedPath');
    return queryParameters == null
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  TraceApiService get _traceApi =>
      TraceApiService(relayServerUrl: _effectiveRelayServerUrl);

  String _newTraceId() {
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    _traceIdSequence = (_traceIdSequence + 1) % 1000;
    final seq = _traceIdSequence.toString().padLeft(3, '0');
    return 'trc_${nowUs}_${_deviceId.hashCode.abs()}_$seq';
  }

  String? _extractTraceIdFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    final traceId = payload['traceId']?.toString().trim();
    if (traceId != null && traceId.isNotEmpty) return traceId;
    final fallback = payload['id']?.toString().trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  void _syncTraceTimelineTargetTrace(
    String? traceId, {
    bool autoFetch = false,
  }) {
    final normalized = traceId?.trim() ?? '';
    if (normalized.isEmpty) return;

    final previousText = _traceIdController.text.trim();
    final nextRecent =
        prependUniqueTraceId(current: _recentTraceIds, traceId: normalized);
    final recentChanged = nextRecent.length != _recentTraceIds.length ||
        nextRecent.asMap().entries.any(
              (entry) => _recentTraceIds[entry.key] != entry.value,
            );

    if (previousText != normalized ||
        recentChanged ||
        _traceTimelineError != null) {
      setState(() {
        _traceIdController.text = normalized;
        _recentTraceIds = nextRecent;
        _traceTimelineError = null;
      });
    } else if (_traceIdController.text.trim() != normalized) {
      _traceIdController.text = normalized;
    }

    final canAutoFetch = autoFetch &&
        _isConnected &&
        _connectionType == ConnectionType.relay &&
        _selectedHomeTab == HomeTab.approvals;
    if (canAutoFetch) {
      unawaited(_loadTraceTimeline(traceId: normalized, silent: true));
    }
  }

  void _markTraceCompleted(String? traceId) {
    if (traceId == null || traceId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _recentCompletedTraceIds[traceId] = now;
    _pruneCompletedTraceIds(now);
  }

  bool _isRecentlyCompletedTrace(String? traceId) {
    if (traceId == null || traceId.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    _pruneCompletedTraceIds(now);
    final completedAt = _recentCompletedTraceIds[traceId];
    if (completedAt == null) return false;
    return now - completedAt <= 30000;
  }

  void _pruneCompletedTraceIds(int nowMs) {
    _recentCompletedTraceIds.removeWhere((_, ts) => nowMs - ts > 30000);
  }

  Future<void> _emitTraceEventsBestEffort(
      List<Map<String, dynamic>> rawEvents) async {
    if (_sessionId == null || rawEvents.isEmpty) return;
    final normalizedEvents = rawEvents
        .map((event) {
          final traceId = event['traceId']?.toString().trim() ?? '';
          final hop = event['hop']?.toString().trim() ?? '';
          if (traceId.isEmpty || hop.isEmpty) return null;
          return {
            'traceId': traceId,
            'sessionId': _sessionId,
            'hop': hop,
            'status': event['status']?.toString() ?? 'ok',
            'commandId': event['commandId'],
            'relayMessageId': event['relayMessageId'],
            'senderDeviceId': event['senderDeviceId'] ?? _deviceId,
            'targetDeviceId': event['targetDeviceId'],
            'clientId': event['clientId'],
            'sourceTs':
                event['sourceTs'] ?? DateTime.now().millisecondsSinceEpoch,
            'meta': event['meta'] is Map ? event['meta'] : <String, dynamic>{},
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (normalizedEvents.isEmpty) return;
    unawaited(_traceApi.sendTraceEvents(normalizedEvents));
  }

  Future<void> _loadRecentTraceIds({int limit = 20}) async {
    if (!_isConnected || _sessionId == null) return;
    try {
      final ids =
          await _traceApi.fetchRecentTraceIds(_sessionId!, limit: limit);
      if (!mounted) return;
      setState(() {
        _recentTraceIds = ids;
      });
    } catch (_) {
      // trace 조회 실패는 사용자 흐름에 영향 주지 않음
    }
  }

  Future<void> _loadTraceTimeline(
      {String? traceId, bool silent = false}) async {
    final id = (traceId ?? _traceIdController.text).trim();
    if (id.isEmpty) {
      if (!silent && mounted) {
        setState(() {
          _traceTimelineError = 'Trace ID를 입력하세요.';
        });
      }
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _loadingTraceTimeline = true;
        _traceTimelineError = null;
      });
    }

    try {
      final timeline = await _traceApi.fetchTimeline(id);
      if (!mounted) return;
      setState(() {
        _traceTimeline = timeline;
        _traceIdController.text = timeline.traceId;
        _loadingTraceTimeline = false;
        _traceTimelineError = null;
      });
      unawaited(_loadRecentTraceIds());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTraceTimeline = false;
        _traceTimelineError = 'Trace 조회 실패: $e';
      });
    }
  }

  void _setTraceAutoRefresh(bool enabled) {
    _traceAutoRefreshTimer?.cancel();
    _traceAutoRefreshTimer = null;
    final canEnable = _isConnected &&
        _connectionType == ConnectionType.relay &&
        _selectedHomeTab == HomeTab.approvals;
    _traceAutoRefresh = enabled && canEnable;
    if (!_traceAutoRefresh) return;
    _traceAutoRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_traceAutoRefresh || !mounted) return;
      if (!_isConnected || _connectionType != ConnectionType.relay) return;
      if (_selectedHomeTab != HomeTab.approvals) return;
      await _loadTraceTimeline(silent: true);
    });
  }

  Future<void> _copyTraceTimelineReport() async {
    final timeline = _traceTimeline;
    if (timeline == null) return;
    await Clipboard.setData(ClipboardData(text: timeline.toReportText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trace report copied')),
    );
  }

  bool get _isStreamingResponseActive =>
      _isWaitingForResponse && _streamingMessageIndex != null;

  bool get _isApprovalPendingForPrompt =>
      !_isWaitingForResponse &&
      (_pendingCommandApprovals.isNotEmpty ||
          _pendingCodexServerRequests.isNotEmpty);

  ResponseIndicatorState get _responseIndicatorState =>
      resolveResponseIndicatorState(
        waitingForResponse: _isWaitingForResponse,
        streamingResponse: _isStreamingResponseActive,
        approvalPending: _isApprovalPendingForPrompt,
      );

  int get _currentRelayPollIntervalMs => relayPollIntervalMs(
        waitingForResponse: _isWaitingForResponse,
        streamingResponse: _isStreamingResponseActive,
        hasPendingRelayApprovals: _pendingCommandApprovals.isNotEmpty,
        hasPendingCodexRequests: _pendingCodexServerRequests.isNotEmpty,
      );

  void _recordCodexRequestHistory({
    required String requestId,
    required String status,
    required String title,
    required String summary,
    String requestKind = 'codex',
    String resolvedBy = '-',
    int? timestampMs,
  }) {
    if (requestId.trim().isEmpty) return;
    final entry = buildCodexRequestHistoryEntry(
      requestId: requestId,
      status: status,
      title: title,
      summary: summary,
      requestKind: requestKind,
      resolvedBy: resolvedBy,
      timestampMs: timestampMs,
    );
    _codexRequestHistory = upsertCodexRequestHistory(
      current: _codexRequestHistory,
      entry: entry,
    );
  }

  // 새 세션 생성 (릴레이 서버 연결 시에만 사용)
  Future<void> _createSession() async {
    try {
      setState(() {
        _messages.add(
            MessageItem('Creating new session...', type: MessageType.system));
      });

      final response = await http.post(
        _relayUri('/api/session'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final sessionId = data['data']['sessionId'];
          setState(() {
            _sessionIdController.text = sessionId;
            _messages.add(MessageItem('✅ Session created: $sessionId',
                type: MessageType.system));
            _messages.add(MessageItem(
                '💡 Extension이 자동으로 이 세션을 감지하여 연결합니다 (최대 10초 소요)',
                type: MessageType.system));
            _messages.add(
                MessageItem('📋 세션 ID: $sessionId', type: MessageType.system));
          });

          // 자동으로 세션에 연결
          await _connectToSession(sessionId);
        }
      } else {
        setState(() {
          _messages.add(MessageItem(
              '❌ Failed to create session: ${response.body}',
              type: MessageType.system));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(MessageItem('❌ Error creating session: $e',
            type: MessageType.system));
      });
    }
  }

  // 로컬 서버 연결
  Future<void> _connectToLocal() async {
    if (_isDemoMode) {
      _activateDemoMode();
      return;
    }

    final ip = _localIpController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IP 주소를 입력하세요')),
      );
      return;
    }
    final portText = _localPortController.text.trim();
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포트는 1~65535 사이 숫자여야 합니다')),
      );
      return;
    }

    try {
      setState(() {
        _messages.add(MessageItem(
            'Connecting to Extension WebSocket server at $ip:$port...',
            type: MessageType.system));
      });

      // Extension의 WebSocket 서버에 직접 연결
      final wsUrl = 'ws://$ip:$port';
      _localWebSocket = WebSocketChannel.connect(Uri.parse(wsUrl));

      _localWebSocket!.stream.listen(
        (message) {
          // 로컬 서버에서 메시지 수신
          _handleLocalMessage(message.toString());
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _lastConnectionError = error.toString();
              _messages.add(MessageItem('❌ Local connection error: $error',
                  type: MessageType.system));
              _isConnected = false;
            });
            // 자동 재연결 시도
            _scheduleReconnect();
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _messages.add(MessageItem('Local connection closed',
                  type: MessageType.system));
              _isConnected = false;
            });
            // 자동 재연결 시도
            _scheduleReconnect();
          }
        },
      );

      setState(() {
        _isConnected = true;
        _isReconnecting = false;
        _reconnectAttempts = 0;
        _lastConnectionError = null;
        _capabilitiesLoaded = false;
        _capabilitiesLoading = false;
        _capabilitiesFromCache = false;
        _modelCatalogLoadStage = ModelCatalogLoadStage.idle;
        _runtimeCapabilitiesRequestedAt = null;
        _supportsIdeContext = false;
        _supportsFlatMode = false;
        _useIdeContext = false;
        _useFlatMode = false;
        _cancelCapabilitiesSequenceTimers();
        _stopReconnect();
        _messages.add(MessageItem(
            '✅ Connected to Extension WebSocket server at $ip:$port',
            type: MessageType.system));
      });

      // 연결 설정 저장
      _saveConnectionSettings();

      // 연결 히스토리에 추가
      AppSettings().addConnectionHistory(ConnectionHistoryItem(
        type: ConnectionType.local,
        ip: ip,
        port: port,
        timestamp: DateTime.now(),
      ));

      // 연결 성공 시 connect 화면 자동 닫기
      try {
        _expansionTileController.collapse();
      } catch (e) {
        // ExpansionTileController가 아직 연결되지 않은 경우 무시
      }

      // 연결 성공 시 즉시 최근 히스토리 조회 (clientId 없이도 가능)
      // clientId는 첫 메시지 응답에서 받을 수 있으므로, 일단 모든 최근 히스토리 조회
      Future.delayed(const Duration(milliseconds: 300), () {
        _loadChatHistory(); // clientId 없이 최근 히스토리 조회
      });
    } catch (e) {
      setState(() {
        _messages.add(MessageItem('❌ Error connecting to local server: $e',
            type: MessageType.system));
      });
    }
  }

  // 로컬 서버에서 받은 메시지 처리
  void _handleLocalMessage(String message) {
    if (!mounted) return;

    try {
      final data = jsonDecode(message);
      final type = data['type'] ?? 'unknown';

      setState(() {
        if (type == 'chat_response') {
          // 세션 ID 추출 및 저장
          if (data['sessionId'] != null) {
            setState(() {
              _currentCodexSessionId = data['sessionId'] as String;
            });
          }
          if (data['clientId'] != null) {
            final newClientId = data['clientId'] as String;
            setState(() {
              // clientId가 처음 설정되면 세션 정보 및 히스토리 조회
              if (_currentClientId == null) {
                _currentClientId = newClientId;
                _loadSessionInfo();
                _loadChatHistory();
              } else if (_currentClientId != newClientId) {
                // clientId가 변경된 경우
                _currentClientId = newClientId;
                _loadSessionInfo();
                _loadChatHistory();
              } else {
                // 같은 clientId면 히스토리만 새로고침
                Future.delayed(const Duration(milliseconds: 500), () {
                  _loadChatHistory();
                });
              }
            });
          } else if (_currentClientId != null) {
            // clientId가 이미 있으면 응답 수신 후 히스토리만 새로고침
            Future.delayed(const Duration(milliseconds: 500), () {
              _loadChatHistory();
            });
          }
          final text = data['text'] ?? '';
          _messages.add(MessageItem('', type: MessageType.chatResponseDivider));
          _messages.add(MessageItem('🤖 Codex Response',
              type: MessageType.chatResponseHeader));
          _messages.add(MessageItem(text, type: MessageType.chatResponse));
          _messages.add(MessageItem('', type: MessageType.chatResponseDivider));
          _isWaitingForResponse = false;
        } else if (type == 'command_result') {
          if (data['success'] == true) {
            final commandType = data['command_type'] as String? ?? '';

            // 세션 정보 조회 결과 처리
            if (commandType == 'get_session_info' && data['data'] != null) {
              setState(() {
                _sessionInfo = data['data'] as Map<String, dynamic>;
                if (_sessionInfo!['currentSessionId'] != null) {
                  _currentCodexSessionId =
                      _sessionInfo!['currentSessionId'] as String;
                }
                if (_sessionInfo!['clientId'] != null) {
                  _currentClientId = _sessionInfo!['clientId'] as String;
                }
              });
            }
            // 대화 히스토리 조회 결과 처리 (Extension은 data에 배열 직접 반환 또는 { entries: [] } 반환)
            else if (commandType == 'get_chat_history' &&
                data['data'] != null) {
              final raw = data['data'];
              final List<Map<String, dynamic>> entries = raw is List
                  ? List<Map<String, dynamic>>.from(
                      raw.map((e) => e as Map<String, dynamic>))
                  : (raw is Map<String, dynamic> && raw['entries'] != null)
                      ? List<Map<String, dynamic>>.from((raw['entries'] as List)
                          .map((e) => e as Map<String, dynamic>))
                      : <Map<String, dynamic>>[];
              if (entries.isNotEmpty ||
                  _loadingSessionHistoryForDisplay ||
                  _loadingPastMessages) {
                setState(() {
                  _chatHistory = entries;
                  _availableSessions = _chatHistory
                      .map((entry) => entry['sessionId'] as String? ?? '')
                      .where((id) => id.isNotEmpty)
                      .toSet()
                      .toList();
                  if (_loadingSessionHistoryForDisplay) {
                    // 연결 직후: 이전 세션 대화는 제거하고 현재 릴레이 세션 히스토리만 표시
                    if (entries.isNotEmpty)
                      _applyChatHistoryToMessages(entries,
                          replaceConversation: true);
                    _loadingSessionHistoryForDisplay = false;
                  }
                  if (_loadingPastMessages) {
                    if (entries.isNotEmpty)
                      _applyChatHistoryToMessages(entries, skipIfExists: true);
                    _loadingPastMessages = false;
                  }
                });
              } else {
                if (_loadingSessionHistoryForDisplay) {
                  _loadingSessionHistoryForDisplay = false;
                }
                if (_loadingPastMessages) _loadingPastMessages = false;
              }
            } else if (commandType == 'get_runtime_capabilities') {
              _handleRuntimeCapabilitiesResponse(data as Map<String, dynamic>);
            }

            // 일반 명령 성공 메시지는 세션/히스토리 조회 시에는 표시하지 않음
            if (commandType != 'get_session_info' &&
                commandType != 'get_chat_history' &&
                commandType != 'get_runtime_capabilities' &&
                commandType != 'codex_server_request_response') {
              _messages.add(
                  MessageItem('✅ Command succeeded', type: MessageType.system));
            }
            if (commandType == 'stop_prompt') {
              _isWaitingForResponse = false;
            }
          } else {
            if (data['command_type'] == 'get_runtime_capabilities') {
              _capabilitiesLoading = false;
              _modelCatalogLoadStage = ModelCatalogLoadStage.failed;
              _runtimeCapabilitiesRequestedAt = null;
              _cancelCapabilitiesSequenceTimers();
            }
            _messages.add(MessageItem('❌ Command failed: ${data['error']}',
                type: MessageType.system));
            _isWaitingForResponse = false;
          }
        } else if (type == 'codex_server_request') {
          unawaited(_handleCodexServerRequest(
              Map<String, dynamic>.from(data as Map)));
        } else if (type == 'codex_server_request_status') {
          _handleCodexServerRequestStatus(
              Map<String, dynamic>.from(data as Map));
        } else if (type == 'log') {
          _appendPrettyLogMessage(data, channel: 'local');
        } else if (type == 'agent_mode_selected') {
          // 자동 모드로 선택된 실제 모드 정보
          final requestedMode = data['requestedMode'] ?? 'auto';
          final actualMode = data['actualMode'] ?? 'agent';
          final displayName = data['displayName'] ?? actualMode;

          print(
              '📨 Received agent_mode_selected: requestedMode=$requestedMode, actualMode=$actualMode, _selectedAgentMode=$_selectedAgentMode');

          if (mounted) {
            setState(() {
              // 자동 모드로 선택된 경우에만 표시
              if (requestedMode == 'auto' && _selectedAgentMode == 'auto') {
                _actualSelectedMode = actualMode;

                // 마지막 User Prompt의 모드 업데이트
                // 메시지 리스트에서 가장 최근 User Prompt 찾아서 업데이트
                bool found = false;
                for (int i = _messages.length - 1; i >= 0; i--) {
                  if (_messages[i].type == MessageType.userPrompt) {
                    // agentMode가 null인 경우 (자동 모드로 전송된 경우) 업데이트
                    if (_messages[i].agentMode == null) {
                      final updatedItem = MessageItem(
                        _messages[i].text,
                        type: _messages[i].type,
                        agentMode: actualMode,
                      );
                      _messages[i] = updatedItem;
                      // _lastUserPrompt도 업데이트
                      if (_lastUserPrompt != null &&
                          _lastUserPrompt!.text == _messages[i].text) {
                        _lastUserPrompt = updatedItem;
                      }
                      print(
                          '🤖 Updated User Prompt mode to: $actualMode (text: ${_messages[i].text.substring(0, _messages[i].text.length > 30 ? 30 : _messages[i].text.length)}...)');
                      found = true;
                      break;
                    }
                  }
                }

                if (!found) {
                  print('⚠️ Could not find User Prompt to update');
                } else {
                  // UI 강제 업데이트를 위해 스크롤
                  Future.microtask(() {
                    if (mounted) {
                      _scrollToBottom();
                    }
                  });
                }
              }
            });

            // 사용자에게 알림 (SnackBar)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🤖 자동 모드: $displayName'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.blue.shade700,
              ),
            );
          }
        } else if (type == 'connection_status') {
          // 연결 상태 메시지 처리
          final status = data['status'] ?? 'unknown';
          final source = data['source'] ?? 'unknown';
          final message = data['message'] ?? '';
          final errorCode = data['errorCode'];
          final errorType = data['errorType'];

          String statusText = '';
          switch (status) {
            case 'connected':
              statusText = '✅ $message';
              setState(() {
                _isReconnecting = false;
                _reconnectAttempts = 0;
                _stopReconnect();
              });
              break;
            case 'disconnected':
              statusText = '⚠️ $message';
              setState(() {
                _isConnected = false;
              });
              _scheduleReconnect();
              break;
            case 'error':
              statusText = '❌ $message';
              setState(() {
                _isConnected = false;
                _lastConnectionError = message;
              });
              _scheduleReconnect();
              break;
          }

          if (statusText.isNotEmpty) {
            _messages.add(MessageItem(statusText, type: MessageType.system));
          }
        } else if (type == 'connected') {
          _messages.add(MessageItem(
              data['message']?.toString() ?? 'Connected to Codex Remote',
              type: MessageType.system));
          Future.delayed(const Duration(milliseconds: 150), () {
            _loadRuntimeCapabilities();
          });
        } else if (type == 'codex_raw_notification' ||
            type == 'codex_notification') {
          _recordCodexRawNotification(data, channel: 'local');
        } else {
          _recordUnhandledIncomingMessage(type.toString(), data, 'local');
        }
      });
      _scrollToBottom();
    } catch (e) {
      // JSON 파싱 실패 시 원본 메시지 표시
      if (mounted) {
        setState(() {
          _messages
              .add(MessageItem('Received: $message', type: MessageType.system));
        });
      }
    }
  }

  /// PC가 설정한 PIN 입력 다이얼로그 (403 PIN_REQUIRED 시 호출)
  Future<String?> _showPinDialog() async {
    if (!mounted) return null;
    final controller = TextEditingController();
    final navigator = Navigator.of(context);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (dialogContext) {
        var isSubmitting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(AppI18n.t(context, AppTextKey.pinDialogTitle)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppI18n.t(context, AppTextKey.pinDialogDescription),
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    maxLength: 6,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    enabled: !isSubmitting,
                    onSubmitted: (_) async {
                      final value = controller.text.trim();
                      if (value.length < 4 || value.length > 6) return;
                      setDialogState(() => isSubmitting = true);
                      await Future<void>.delayed(
                          const Duration(milliseconds: 140));
                      if (ctx.mounted) navigator.pop(value);
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText:
                          AppI18n.t(context, AppTextKey.pinDialogInputLabel),
                      hintText:
                          AppI18n.t(context, AppTextKey.pinDialogInputHint),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => navigator.pop(null),
                child: Text(AppI18n.t(context, AppTextKey.dialogCancel)),
              ),
              FilledButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final value = controller.text.trim();
                        if (value.length < 4 || value.length > 6) return;
                        setDialogState(() => isSubmitting = true);
                        await Future<void>.delayed(
                            const Duration(milliseconds: 140));
                        if (ctx.mounted) navigator.pop(value);
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  isSubmitting
                      ? AppI18n.t(context, AppTextKey.pinDialogConfirming)
                      : AppI18n.t(context, AppTextKey.pinDialogConfirm),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 기존 세션에 연결 (PIN은 PC가 설정한 경우에만 전달)
  Future<void> _connectToSession(String sessionId, [String? pin]) async {
    if (_isDemoMode) {
      _activateDemoMode();
      return;
    }

    if (sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세션 ID를 입력하세요')),
      );
      return;
    }

    // 디바이스 ID 생성 (없으면)
    if (_deviceId.isEmpty) {
      _deviceId = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      setState(() {
        _messages.add(MessageItem(
            pin != null
                ? 'Connecting to session $sessionId with PIN...'
                : 'Connecting to session $sessionId...',
            type: MessageType.system));
      });

      final body = <String, dynamic>{
        'sessionId': sessionId,
        'deviceId': _deviceId,
        'deviceType': 'mobile',
      };
      if (pin != null && pin.isNotEmpty) {
        body['pin'] = pin;
      }

      final response = await http.post(
        _relayUri('/api/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : <String, dynamic>{};
      final dataMap = data ?? {};
      final errorCode = dataMap['errorCode']?.toString();
      final errorMessage = dataMap['error']?.toString() ?? '';

      if (response.statusCode == 200 && dataMap['success'] == true) {
        _setTraceAutoRefresh(false);
        setState(() {
          _sessionId = sessionId;
          _isConnected = true;
          _isWaitingForResponse = false;
          _streamingMessageIndex = null;
          _streamingText = '';
          _isReconnecting = false;
          _reconnectAttempts = 0;
          _lastConnectionError = null;
          _lastCommandMetaRefreshAt = null;
          _capabilitiesLoaded = false;
          _capabilitiesLoading = false;
          _capabilitiesFromCache = false;
          _modelCatalogLoadStage = ModelCatalogLoadStage.idle;
          _runtimeCapabilitiesRequestedAt = null;
          _supportsIdeContext = false;
          _supportsFlatMode = false;
          _useIdeContext = false;
          _useFlatMode = false;
          _traceTimeline = null;
          _traceTimelineError = null;
          _recentTraceIds = [];
          _loadingTraceTimeline = false;
          _traceIdController.clear();
          _cancelCapabilitiesSequenceTimers();
          _stopReconnect();
          _messages.add(MessageItem('✅ Connected to session $sessionId',
              type: MessageType.system));
        });

        // 연결 설정 저장
        _saveConnectionSettings();

        // 연결 히스토리에 추가
        AppSettings().addConnectionHistory(ConnectionHistoryItem(
          type: ConnectionType.relay,
          sessionId: sessionId,
          timestamp: DateTime.now(),
        ));

        // 연결 성공 시 connect 화면 자동 닫기
        try {
          _expansionTileController.collapse();
        } catch (e) {
          // ExpansionTileController가 아직 연결되지 않은 경우 무시
        }

        // 폴링 시작
        _startPolling();
        Future.delayed(const Duration(milliseconds: 120), () {
          unawaited(_pollRelayMessagesOnce());
        });

        // 같은 세션이면 이전 프롬프트/답변을 메인 목록에 가져오기 위해 해당 세션 히스토리 조회
        _loadingSessionHistoryForDisplay = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          _loadChatHistory(sessionId: _sessionId);
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          _loadCommandApprovals(silent: true);
          _loadCommandEvents(silent: true);
          unawaited(_loadRecentTraceIds());
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          _loadRuntimeCapabilities();
        });
      } else if (response.statusCode == 403 &&
          (errorCode == 'PIN_REQUIRED' ||
              errorMessage.toLowerCase().contains('pin required') ||
              errorMessage.toLowerCase().contains('pin을 입력'))) {
        // PC가 PIN을 설정한 세션 → PIN 입력 후 재시도
        if (!mounted) return;
        setState(() {
          _connectionActionLabel =
              AppI18n.t(context, AppTextKey.connectionActionPendingPin);
          _messages.add(MessageItem(
            AppI18n.t(context, AppTextKey.pinDialogDescription),
            type: MessageType.system,
          ));
        });
        final enteredPin = await _showPinDialog();
        if (!mounted) return;
        if (enteredPin != null && enteredPin.isNotEmpty) {
          setState(() => _connectionActionLabel =
              AppI18n.t(context, AppTextKey.connectionActionConnectingWithPin));
          await _connectToSession(sessionId, enteredPin);
        } else {
          setState(() {
            _connectionActionLabel = null;
            _messages.add(MessageItem(
              AppI18n.t(context, AppTextKey.connectionActionPinRejected),
              type: MessageType.system,
            ));
          });
        }
      } else if (response.statusCode == 403 &&
          (errorCode == 'INVALID_PIN' ||
              errorMessage.toLowerCase().contains('invalid pin'))) {
        setState(() {
          _messages.add(MessageItem(
              '❌ ${AppI18n.t(context, AppTextKey.pinDialogInvalidMessage)}',
              type: MessageType.system));
        });
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppI18n.t(context, AppTextKey.pinDialogErrorTitle)),
              content: Text(
                AppI18n.t(context, AppTextKey.pinDialogErrorMessage),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppI18n.t(context, AppTextKey.dialogCancel)),
                ),
              ],
            ),
          );
        }
      } else if (response.statusCode == 403 &&
          (errorCode == 'PC_MUST_CONNECT_FIRST' ||
              errorMessage.toLowerCase().contains('pc must connect first'))) {
        setState(() {
          _messages.add(MessageItem(
              '❌ PC(익스텐션)에서 먼저 상태줄을 클릭해 세션 ID를 생성·연결한 뒤 다시 시도하세요.',
              type: MessageType.system));
        });
      } else {
        final error = errorMessage.isNotEmpty ? errorMessage : 'Unknown error';
        setState(() {
          _lastConnectionError = error;
          _messages
              .add(MessageItem('❌ 연결 실패: $error', type: MessageType.system));
        });
        // Session not found 시 자동 새 세션 생성/재연결 하지 않음 (사용자가 세션 ID 확인 후 재시도)
        final isSessionNotFound =
            error.toLowerCase().contains('session not found');
        if (!isSessionNotFound) {
          _scheduleReconnect();
        }
      }
    } catch (e) {
      setState(() {
        _lastConnectionError = e.toString();
        _messages.add(MessageItem('❌ Error connecting to session: $e',
            type: MessageType.system));
      });
      _scheduleReconnect();
    }
  }

  Future<void> _connect() async {
    if (_isDemoMode) {
      _activateDemoMode();
      return;
    }
    if (_isConnectionActionInProgress || _isConnected || _isReconnecting) {
      return;
    }

    setState(() {
      _isConnectionActionInProgress = true;
      _connectionActionLabel = _connectionType == ConnectionType.local
          ? AppI18n.t(context, AppTextKey.connectionActionLocalPreparing)
          : AppI18n.t(context, AppTextKey.connectionActionRelayPreparing);
      _lastConnectionError = null;
    });

    if (_connectionType == ConnectionType.local) {
      // 로컬 서버 연결
      try {
        setState(() => _connectionActionLabel =
            AppI18n.t(context, AppTextKey.connectionActionLocalConnecting));
        await _connectToLocal();
      } finally {
        if (mounted) {
          setState(() {
            _isConnectionActionInProgress = false;
            if (_isConnected || _isReconnecting) {
              _connectionActionLabel = null;
            } else {
              _connectionActionLabel =
                  AppI18n.t(context, AppTextKey.connectionActionNotCompleted);
            }
          });
        }
      }
    } else {
      // 릴레이 서버 연결: 무조건 익스텐션에서 먼저 활성화 후 세션 ID 입력
      final sessionId = _sessionIdController.text.trim();
      if (sessionId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'PC(익스텐션)에서 먼저 상태줄을 클릭해 세션 ID를 생성·연결한 뒤, 같은 세션 ID를 입력하세요.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
          setState(() {
            _isConnectionActionInProgress = false;
            _connectionActionLabel = null;
          });
        }
        return;
      }
      try {
        setState(() => _connectionActionLabel =
            AppI18n.t(context, AppTextKey.connectionActionRelayConnecting));
        await _connectToSession(sessionId);
      } finally {
        if (mounted) {
          setState(() {
            _isConnectionActionInProgress = false;
            if (_isConnected || _isReconnecting) {
              _connectionActionLabel = null;
            } else {
              _connectionActionLabel =
                  AppI18n.t(context, AppTextKey.connectionActionNotCompleted);
            }
          });
        }
      }
    }
  }

  // 히스토리에서 연결
  void _connectFromHistory(ConnectionHistoryItem item) {
    if (_isDemoMode) {
      _activateDemoMode();
      return;
    }
    setState(() {
      _connectionType = item.type;
      if (item.type == ConnectionType.local) {
        _localIpController.text = item.ip ?? '';
        if (item.port != null) {
          _localPortController.text = item.port!.toString();
        }
      } else {
        _sessionIdController.text = item.sessionId ?? '';
      }
    });

    // 연결 시도
    unawaited(_connect());
  }

  // 메시지 폴링 시작
  void _startPolling() {
    if (_isDemoMode) return;
    _stopPolling(); // 기존 타이머 정지

    _pollTimer = Timer.periodic(_pollSchedulerTick, (_) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastRelayPollStartedAtMs < _currentRelayPollIntervalMs) {
        return;
      }
      _lastRelayPollStartedAtMs = now;
      await _pollRelayMessagesOnce();
    });
  }

  Future<void> _pollRelayMessagesOnce() async {
    if (_isDemoMode) return;
    if (!_isConnected || _sessionId == null || _isRelayPollInFlight) return;

    _isRelayPollInFlight = true;
    try {
      final response = await http.get(
        _relayUri('/api/poll', {
          'sessionId': _sessionId!,
          'deviceType': 'mobile',
          'deviceId': _deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data']['messages'] != null) {
          final messages = data['data']['messages'] as List;
          final traceEvents = <Map<String, dynamic>>[];
          for (final msg in messages) {
            final msgMap = msg is Map
                ? Map<String, dynamic>.from(msg as Map<dynamic, dynamic>)
                : <String, dynamic>{};
            final payload = msgMap['data'] is Map
                ? Map<String, dynamic>.from(
                    msgMap['data'] as Map<dynamic, dynamic>)
                : msgMap;
            final traceId = _extractTraceIdFromPayload(payload);
            if (traceId != null) {
              traceEvents.add({
                'traceId': traceId,
                'hop': 'mobile.poll.recv',
                'status': 'ok',
                'commandId': payload['id']?.toString(),
                'relayMessageId': msgMap['id']?.toString(),
                'senderDeviceId': payload['senderDeviceId']?.toString(),
                'targetDeviceId': payload['targetDeviceId']?.toString(),
                'clientId': payload['clientId']?.toString(),
                'sourceTs': DateTime.now().millisecondsSinceEpoch,
                'meta': {
                  'messageType': payload['type']?.toString() ?? msgMap['type'],
                },
              });
            }
            _handleRelayMessage(msg);
          }
          if (traceEvents.isNotEmpty) {
            unawaited(_emitTraceEventsBestEffort(traceEvents));
          }
        }
        unawaited(_refreshCommandMetaIfStale());
      }
    } catch (e) {
      // 폴링 에러는 조용히 무시 (일시적인 네트워크 문제일 수 있음)
    } finally {
      _isRelayPollInFlight = false;
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isRelayPollInFlight = false;
    _lastRelayPollStartedAtMs = 0;
  }

  // relay 서버에서 받은 메시지 처리
  void _handleRelayMessage(Map<String, dynamic> msg) {
    if (!mounted) return;

    final type = msg['type'] ?? msg['data']?['type'];
    final messageData = msg['data'] ?? msg;
    Map<String, dynamic>? traceUiRenderedEvent;
    String? traceIdForTimeline;

    setState(() {
      _messages.add(MessageItem('Received: ${jsonEncode(msg)}',
          type: MessageType.system));

      if (type == 'command_result') {
        if (messageData['success'] == true) {
          final commandType = messageData['command_type'] as String? ?? '';

          // 세션 정보 조회 결과 처리
          if (commandType == 'get_session_info' &&
              messageData['data'] != null) {
            setState(() {
              _sessionInfo = messageData['data'] as Map<String, dynamic>;
              if (_sessionInfo!['currentSessionId'] != null) {
                _currentCodexSessionId =
                    _sessionInfo!['currentSessionId'] as String;
              }
              if (_sessionInfo!['clientId'] != null) {
                _currentClientId = _sessionInfo!['clientId'] as String;
              }
            });
          }
          // 대화 히스토리 조회 결과 처리 (Extension은 data에 배열 직접 또는 { entries: [] })
          else if (commandType == 'get_chat_history' &&
              messageData['data'] != null) {
            final raw = messageData['data'];
            final List<Map<String, dynamic>> entries = raw is List
                ? List<Map<String, dynamic>>.from(
                    raw.map((e) => e as Map<String, dynamic>))
                : (raw is Map<String, dynamic> && raw['entries'] != null)
                    ? List<Map<String, dynamic>>.from((raw['entries'] as List)
                        .map((e) => e as Map<String, dynamic>))
                    : <Map<String, dynamic>>[];
            setState(() {
              _chatHistory = entries;
              _availableSessions = _chatHistory
                  .map((entry) => entry['sessionId'] as String? ?? '')
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList();
              if (_loadingSessionHistoryForDisplay) {
                if (entries.isNotEmpty)
                  _applyChatHistoryToMessages(entries,
                      replaceConversation: true);
                _loadingSessionHistoryForDisplay = false;
              }
              if (_loadingPastMessages) {
                if (entries.isNotEmpty)
                  _applyChatHistoryToMessages(entries, skipIfExists: true);
                _loadingPastMessages = false;
              }
            });
            if (entries.isEmpty) {
              if (_loadingSessionHistoryForDisplay) {
                setState(() => _loadingSessionHistoryForDisplay = false);
              }
              if (_loadingPastMessages) {
                setState(() => _loadingPastMessages = false);
              }
            }
          } else if (commandType == 'get_runtime_capabilities') {
            _handleRuntimeCapabilitiesResponse(
                messageData as Map<String, dynamic>);
          }

          // 일반 명령 성공 메시지는 세션/히스토리 조회 시에는 표시하지 않음
          if (commandType != 'get_session_info' &&
              commandType != 'get_chat_history' &&
              commandType != 'get_runtime_capabilities' &&
              commandType != 'codex_server_request_response') {
            _messages.add(
                MessageItem('✅ Command succeeded', type: MessageType.system));
          }
          if (commandType == 'stop_prompt') {
            _isWaitingForResponse = false;
          }
        } else {
          if (messageData['command_type'] == 'get_runtime_capabilities') {
            _capabilitiesLoading = false;
            _modelCatalogLoadStage = ModelCatalogLoadStage.failed;
            _runtimeCapabilitiesRequestedAt = null;
            _cancelCapabilitiesSequenceTimers();
          }
          _messages.add(MessageItem('❌ Command failed: ${messageData['error']}',
              type: MessageType.system));
          _isWaitingForResponse = false;
        }
      } else if (type == 'error') {
        _messages.add(MessageItem('❌ Error: ${messageData['message']}',
            type: MessageType.system));
        _isWaitingForResponse = false;
      } else if (type == 'codex_server_request') {
        unawaited(_handleCodexServerRequest(
            Map<String, dynamic>.from(messageData as Map)));
      } else if (type == 'codex_server_request_status') {
        _handleCodexServerRequestStatus(
            Map<String, dynamic>.from(messageData as Map));
      } else if (type == 'user_message') {
        final text = messageData['text'] ?? '';
        _messages
            .add(MessageItem('💬 You: $text', type: MessageType.userMessage));
      } else if (type == 'gemini_response') {
        final text = messageData['text'] ?? '';
        _messages.add(
            MessageItem('🤖 Gemini: $text', type: MessageType.geminiResponse));
      } else if (type == 'terminal_output') {
        final text = messageData['text'] ?? '';
        _messages.add(MessageItem('📟 Terminal: $text',
            type: MessageType.terminalOutput));
      } else if (type == 'chat_response_chunk') {
        // 스트리밍 청크 처리
        if (_streamingMessageIndex == null && !_isWaitingForResponse) {
          return;
        }

        final chunkText = messageData['text']?.toString() ?? '';
        final fullText = messageData['fullText']?.toString() ?? chunkText;
        final isReplace = messageData['isReplace'] == true;

        // 세션 ID 추출 및 저장
        if (messageData['sessionId'] != null) {
          setState(() {
            _currentCodexSessionId = messageData['sessionId'] as String;
          });
        }
        if (messageData['clientId'] != null) {
          final newClientId = messageData['clientId'] as String;
          setState(() {
            if (_currentClientId == null) {
              _currentClientId = newClientId;
              _loadSessionInfo();
              _loadChatHistory();
            } else if (_currentClientId != newClientId) {
              _currentClientId = newClientId;
              _loadSessionInfo();
              _loadChatHistory();
            }
          });
        }

        setState(() {
          final mergedText = mergeStreamingText(
            current: _streamingText,
            chunkText: chunkText,
            fullText: fullText,
            isReplace: isReplace,
          );

          // 첫 번째 청크인 경우 메시지 추가
          if (_streamingMessageIndex == null) {
            _messages
                .add(MessageItem('', type: MessageType.chatResponseDivider));
            _messages.add(MessageItem('🤖 Codex Response',
                type: MessageType.chatResponseHeader));
            _streamingText = mergedText;
            _messages.add(MessageItem(_streamingText,
                type: MessageType.chatResponseChunk));
            _streamingMessageIndex = _messages.length - 1;
          } else {
            // 기존 스트리밍 메시지 업데이트
            _streamingText = mergedText;
            // 메시지 업데이트
            if (_streamingMessageIndex! < _messages.length) {
              _messages[_streamingMessageIndex!] = MessageItem(_streamingText,
                  type: MessageType.chatResponseChunk);
            }
          }
        });
        _scrollToBottom();
      } else if (type == 'chat_response_complete') {
        // 스트리밍 완료 처리
        final completedTraceId = _extractTraceIdFromPayload(
          messageData is Map
              ? Map<String, dynamic>.from(messageData as Map<dynamic, dynamic>)
              : null,
        );
        final payload = messageData is Map
            ? Map<String, dynamic>.from(messageData as Map<dynamic, dynamic>)
            : <String, dynamic>{};
        traceUiRenderedEvent = buildMobileUiRenderedTraceEvent(
          traceId: completedTraceId,
          messageData: payload,
          messageType: type.toString(),
        );
        traceIdForTimeline = completedTraceId;
        setState(() {
          _markTraceCompleted(completedTraceId);
          if (_streamingMessageIndex != null &&
              _streamingMessageIndex! < _messages.length) {
            // 스트리밍 메시지를 일반 chat_response로 변경
            _messages[_streamingMessageIndex!] =
                MessageItem(_streamingText, type: MessageType.chatResponse);
            _streamingMessageIndex = null;
            _streamingText = '';
          }
          // 세션 ID 추출 및 저장
          if (messageData['clientId'] != null) {
            final newClientId = messageData['clientId'] as String;
            if (_currentClientId == null || _currentClientId != newClientId) {
              _currentClientId = newClientId;
              _loadSessionInfo();
            }
            // 히스토리 새로고침
            Future.delayed(const Duration(milliseconds: 500), () {
              _loadChatHistory();
            });
          } else if (_currentClientId != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _loadChatHistory();
            });
          }
          _isWaitingForResponse = false;
        });
        _scrollToBottom();
      } else if (type == 'chat_response') {
        // 기존 방식 (비스트리밍 응답) - 하위 호환성
        final responseTraceId = _extractTraceIdFromPayload(
          messageData is Map
              ? Map<String, dynamic>.from(messageData as Map<dynamic, dynamic>)
              : null,
        );
        if (_streamingMessageIndex == null &&
            !_isWaitingForResponse &&
            _isRecentlyCompletedTrace(responseTraceId)) {
          return;
        }

        // 세션 ID 추출 및 저장
        if (messageData['sessionId'] != null) {
          setState(() {
            _currentCodexSessionId = messageData['sessionId'] as String;
          });
        }
        if (messageData['clientId'] != null) {
          final newClientId = messageData['clientId'] as String;
          setState(() {
            // clientId가 처음 설정되면 세션 정보 및 히스토리 조회
            if (_currentClientId == null) {
              _currentClientId = newClientId;
              _loadSessionInfo();
              _loadChatHistory();
            } else if (_currentClientId != newClientId) {
              // clientId가 변경된 경우
              _currentClientId = newClientId;
              _loadSessionInfo();
              _loadChatHistory();
            } else {
              // 같은 clientId면 히스토리만 새로고침
              Future.delayed(const Duration(milliseconds: 500), () {
                _loadChatHistory();
              });
            }
          });
        } else if (_currentClientId != null) {
          // clientId가 이미 있으면 응답 수신 후 히스토리만 새로고침
          Future.delayed(const Duration(milliseconds: 500), () {
            _loadChatHistory();
          });
        }
        final text = messageData['text'] ?? '';
        if (_streamingMessageIndex != null &&
            _streamingMessageIndex! < _messages.length) {
          _messages[_streamingMessageIndex!] =
              MessageItem(text, type: MessageType.chatResponse);
          _streamingMessageIndex = null;
          _streamingText = '';
        } else {
          _messages.add(MessageItem('', type: MessageType.chatResponseDivider));
          _messages.add(MessageItem('🤖 Codex Response',
              type: MessageType.chatResponseHeader));
          _messages.add(MessageItem(text, type: MessageType.chatResponse));
          _messages.add(MessageItem('', type: MessageType.chatResponseDivider));
        }
        _isWaitingForResponse = false;
        final traceId = _extractTraceIdFromPayload(
          messageData is Map
              ? Map<String, dynamic>.from(messageData as Map<dynamic, dynamic>)
              : null,
        );
        traceUiRenderedEvent = buildMobileUiRenderedTraceEvent(
          traceId: traceId,
          messageData: messageData is Map
              ? Map<String, dynamic>.from(messageData as Map<dynamic, dynamic>)
              : <String, dynamic>{},
          messageType: type.toString(),
        );
        traceIdForTimeline = traceId;
      } else if (type == 'agent_mode_selected') {
        // 자동 모드로 선택된 실제 모드 정보 (릴레이 서버 연결)
        final requestedMode = messageData['requestedMode'] ?? 'auto';
        final actualMode = messageData['actualMode'] ?? 'agent';
        final displayName = messageData['displayName'] ?? actualMode;

        print(
            '📨 Received agent_mode_selected (relay): requestedMode=$requestedMode, actualMode=$actualMode, _selectedAgentMode=$_selectedAgentMode');

        if (mounted) {
          setState(() {
            // 자동 모드로 선택된 경우에만 표시
            if (requestedMode == 'auto' && _selectedAgentMode == 'auto') {
              _actualSelectedMode = actualMode;

              // 마지막 User Prompt의 모드 업데이트
              // 메시지 리스트에서 가장 최근 User Prompt 찾아서 업데이트
              bool found = false;
              for (int i = _messages.length - 1; i >= 0; i--) {
                if (_messages[i].type == MessageType.userPrompt) {
                  // agentMode가 null인 경우 (자동 모드로 전송된 경우) 업데이트
                  if (_messages[i].agentMode == null) {
                    final updatedItem = MessageItem(
                      _messages[i].text,
                      type: _messages[i].type,
                      agentMode: actualMode,
                    );
                    _messages[i] = updatedItem;
                    // _lastUserPrompt도 업데이트
                    if (_lastUserPrompt != null &&
                        _lastUserPrompt!.text == _messages[i].text) {
                      _lastUserPrompt = updatedItem;
                    }
                    print(
                        '🤖 Updated User Prompt mode to: $actualMode (relay, text: ${_messages[i].text.substring(0, _messages[i].text.length > 30 ? 30 : _messages[i].text.length)}...)');
                    found = true;
                    break;
                  }
                }
              }

              if (!found) {
                print('⚠️ Could not find User Prompt to update (relay)');
              } else {
                // UI 강제 업데이트를 위해 스크롤
                Future.microtask(() {
                  if (mounted) {
                    _scrollToBottom();
                  }
                });
              }
            }
          });

          // 사용자에게 알림 (SnackBar)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🤖 자동 모드: $displayName'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blue.shade700,
            ),
          );
        }
      } else if (type == 'log') {
        setState(() {
          _appendPrettyLogMessage(messageData, channel: 'relay');
        });
        _scrollToBottom();
      } else if (type == 'codex_raw_notification' ||
          type == 'codex_notification') {
        _recordCodexRawNotification(messageData, channel: 'relay');
      } else {
        _recordUnhandledIncomingMessage(type.toString(), messageData, 'relay');
      }
    });
    if (traceIdForTimeline != null && traceIdForTimeline!.isNotEmpty) {
      _syncTraceTimelineTargetTrace(traceIdForTimeline, autoFetch: true);
    }
    if (traceUiRenderedEvent != null) {
      unawaited(_emitTraceEventsBestEffort([traceUiRenderedEvent!]));
    }
    _scrollToBottom();
  }

  // 모드 이름을 사용자 친화적인 표시 이름으로 변환
  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'agent':
        return 'Agent';
      case 'ask':
        return 'Ask';
      case 'plan':
        return 'Plan';
      case 'debug':
        return 'Debug';
      case 'auto':
        return 'Auto';
      default:
        return mode;
    }
  }

  // 모드에 따른 아이콘 반환
  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'agent':
        return Icons.code;
      case 'ask':
        return Icons.help_outline;
      case 'plan':
        return Icons.assignment;
      case 'debug':
        return Icons.bug_report;
      case 'auto':
        return Icons.auto_awesome;
      default:
        return Icons.smart_toy;
    }
  }

  String _normalizeAgentMode(String mode) {
    return _supportedAgentModes.contains(mode) ? mode : 'auto';
  }

  String _getDefaultModelFromCapabilities() {
    final models = _availableModels;
    for (final model in models) {
      if (model['isDefault'] == true) {
        final value = (model['model'] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
    }
    if (models.isNotEmpty) {
      final first = (models.first['model'] ?? '').toString().trim();
      if (first.isNotEmpty) return first;
    }
    return 'auto';
  }

  List<String> _getAvailableReasoningEffortsForModel([String? model]) {
    final normalizedModel = (model ?? _selectedModel).trim();
    final efforts = <String>{};

    if (normalizedModel == 'auto' || normalizedModel.isEmpty) {
      for (final item in _availableModels) {
        final raw = item['supportedReasoningEfforts'];
        if (raw is List) {
          for (final value in raw) {
            final effort = value.toString().trim();
            if (effort.isNotEmpty) {
              efforts.add(effort);
            }
          }
        }
      }
    } else {
      for (final item in _availableModels) {
        if ((item['model'] ?? '').toString().trim() == normalizedModel) {
          final raw = item['supportedReasoningEfforts'];
          if (raw is List) {
            for (final value in raw) {
              final effort = value.toString().trim();
              if (effort.isNotEmpty) {
                efforts.add(effort);
              }
            }
          }
          break;
        }
      }
    }

    if (efforts.isEmpty) {
      efforts.addAll(['low', 'medium', 'high']);
    }

    final ordered = ['none', 'minimal', 'low', 'medium', 'high', 'xhigh'];
    return ordered.where((item) => efforts.contains(item)).toList();
  }

  String _getDefaultReasoningEffortForModel([String? model]) {
    final normalizedModel = (model ?? _selectedModel).trim();
    if (normalizedModel != 'auto' && normalizedModel.isNotEmpty) {
      for (final item in _availableModels) {
        if ((item['model'] ?? '').toString().trim() == normalizedModel) {
          final value =
              (item['defaultReasoningEffort'] ?? '').toString().trim();
          if (value.isNotEmpty) return value;
          break;
        }
      }
    }

    final available = _getAvailableReasoningEffortsForModel(normalizedModel);
    return available.contains('medium')
        ? 'medium'
        : (available.isNotEmpty ? available.first : 'medium');
  }

  String _normalizeModel(String model) {
    return normalizeRuntimeModel(
      model,
      catalogLoaded: _capabilitiesLoaded,
      availableModels: _availableModels
          .map((item) => (item['model'] ?? '').toString().trim())
          .where((item) => item.isNotEmpty),
    );
  }

  String _normalizeReasoningEffort(String effort, [String? model]) {
    final normalized = effort.trim();
    if (normalized.isEmpty || normalized == 'auto') return 'auto';
    final supported = _getAvailableReasoningEffortsForModel(model);
    return supported.contains(normalized)
        ? normalized
        : _getDefaultReasoningEffortForModel(model);
  }

  String _getModelDisplayName(String model) {
    if (model == 'auto') return 'Auto';
    for (final item in _availableModels) {
      if ((item['model'] ?? '').toString().trim() == model) {
        final displayName = (item['displayName'] ?? '').toString().trim();
        if (displayName.isNotEmpty) return displayName;
      }
    }
    return model;
  }

  String _getReasoningEffortDisplayName(String effort) {
    final normalized = effort.trim();
    if (normalized.isEmpty || normalized == 'auto') return 'Auto';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  String _restoreSavedSelectionValue(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? 'auto' : normalized;
  }

  String get _modelCatalogLoadingText {
    switch (_modelCatalogLoadStage) {
      case ModelCatalogLoadStage.loading:
        return AppI18n.t(context, AppTextKey.modelCatalogLoadingLabelLoading);
      case ModelCatalogLoadStage.defaultReady:
        return AppI18n.t(
            context, AppTextKey.modelCatalogLoadingLabelDefaultReady);
      case ModelCatalogLoadStage.syncingAll:
        return AppI18n.t(context, AppTextKey.modelCatalogLoadingLabelSyncing);
      case ModelCatalogLoadStage.delayed:
        return AppI18n.t(context, AppTextKey.modelCatalogLoadingLabelDelayed);
      case ModelCatalogLoadStage.failed:
        return AppI18n.t(context, AppTextKey.modelCatalogLoadingLabelFailed);
      case ModelCatalogLoadStage.completed:
      case ModelCatalogLoadStage.idle:
        return AppI18n.t(context, AppTextKey.modelCatalogLoadingLabelLoading);
    }
  }

  void _cancelCapabilitiesSequenceTimers() {
    _capabilitiesLoadTimer?.cancel();
    _capabilitiesStageTimer?.cancel();
  }

  void _armCapabilitiesLoadTimeout() {
    _capabilitiesLoadTimer?.cancel();
    _capabilitiesLoadTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_capabilitiesLoading || _capabilitiesLoaded) return;
      final shouldNotify =
          _modelCatalogLoadStage != ModelCatalogLoadStage.delayed;
      setState(() {
        _modelCatalogLoadStage = ModelCatalogLoadStage.delayed;
        if (shouldNotify) {
          final elapsedSec = _runtimeCapabilitiesRequestedAt == null
              ? null
              : DateTime.now()
                  .difference(_runtimeCapabilitiesRequestedAt!)
                  .inSeconds;
          _messages.add(
            MessageItem(
              elapsedSec == null
                  ? AppI18n.t(context, AppTextKey.modelCatalogSyncDelayNotice)
                  : AppI18n.tWithParams(
                      context,
                      AppTextKey.modelCatalogSyncDelayNoticeWithElapsed,
                      {'elapsed': '$elapsedSec'},
                    ),
              type: MessageType.system,
            ),
          );
        }
      });
    });
  }

  void _startCapabilitiesLoadSequence() {
    _capabilitiesStageTimer?.cancel();
    _capabilitiesStageTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || !_capabilitiesLoading || _capabilitiesLoaded) return;
      final defaultModelLabel =
          _getModelDisplayName(_getDefaultModelFromCapabilities());
      setState(() {
        _modelCatalogLoadStage = ModelCatalogLoadStage.defaultReady;
        _messages.add(
          MessageItem(
            AppI18n.tWithParams(
              context,
              AppTextKey.modelCatalogDefaultModelLoaded,
              {'model': defaultModelLabel},
            ),
            type: MessageType.system,
          ),
        );
      });
      _capabilitiesStageTimer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted || !_capabilitiesLoading || _capabilitiesLoaded) return;
        setState(() {
          _modelCatalogLoadStage = ModelCatalogLoadStage.syncingAll;
          _messages.add(
            MessageItem(
              AppI18n.t(context, AppTextKey.modelCatalogSyncingModels),
              type: MessageType.system,
            ),
          );
        });
      });
    });
  }

  void _applyRuntimeCapabilities(Map<String, dynamic> capabilities) {
    final rawAgentModes = capabilities['agentModes'];
    final rawModels = capabilities['models'];
    final ideContext = capabilities['ideContext'] as Map<String, dynamic>?;
    final flatMode = capabilities['flatMode'] as Map<String, dynamic>?;
    final defaults = capabilities['defaults'] as Map<String, dynamic>?;

    final agentModes = rawAgentModes is List
        ? rawAgentModes
            .map((item) => _normalizeAgentMode(item.toString()))
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
        : List<String>.from(_fallbackAgentModes);

    final models = rawModels is List
        ? rawModels
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => (item['model'] ?? '').toString().trim().isNotEmpty)
            .toList()
        : List<Map<String, dynamic>>.from(_fallbackModels);

    final nextAgentModes = agentModes.isNotEmpty
        ? agentModes
        : List<String>.from(_fallbackAgentModes);
    final nextModels = models.isNotEmpty
        ? models
        : List<Map<String, dynamic>>.from(_fallbackModels);

    _availableAgentModes = nextAgentModes;
    _availableModels = nextModels;
    _supportsIdeContext = ideContext?['supported'] == true;
    _supportsFlatMode = flatMode?['supported'] == true;
    _capabilitiesLoaded = capabilities['ready'] == true;

    final defaultAgentMode = _normalizeAgentMode(
        (defaults?['agentMode'] ?? _selectedAgentMode).toString());
    final defaultModel =
        _normalizeModel((defaults?['model'] ?? _selectedModel).toString());
    final defaultReasoning = _normalizeReasoningEffort(
      (defaults?['reasoningEffort'] ?? _selectedReasoningEffort).toString(),
      defaultModel,
    );

    _selectedAgentMode = _normalizeAgentMode(_selectedAgentMode);
    if (!_availableAgentModes.contains(_selectedAgentMode)) {
      _selectedAgentMode = defaultAgentMode;
    }

    final normalizedCurrentModel = _selectedModel.trim();
    final hasSelectedModel = _availableModels.any(
      (item) =>
          (item['model'] ?? '').toString().trim() == normalizedCurrentModel,
    );
    if (normalizedCurrentModel.isEmpty || normalizedCurrentModel == 'auto') {
      _selectedModel = 'auto';
    } else if (!hasSelectedModel) {
      _selectedModel = defaultModel;
    } else {
      _selectedModel = normalizedCurrentModel;
    }

    _selectedReasoningEffort =
        _normalizeReasoningEffort(_selectedReasoningEffort, _selectedModel);
    if (_selectedReasoningEffort != 'auto' &&
        !_getAvailableReasoningEffortsForModel(_selectedModel)
            .contains(_selectedReasoningEffort)) {
      _selectedReasoningEffort = defaultReasoning;
    }

    if (_supportsIdeContext) {
      _useIdeContext = ideContext?['defaultEnabled'] == true;
    } else {
      _useIdeContext = false;
    }

    if (_supportsFlatMode) {
      _useFlatMode = flatMode?['defaultEnabled'] == true;
    } else {
      _useFlatMode = false;
    }
  }

  void _handleRuntimeCapabilitiesResponse(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      return;
    }

    final wasLoaded = _capabilitiesLoaded;
    final wasLoading = _capabilitiesLoading;
    final previousModelCount = _availableModels.length;
    _applyRuntimeCapabilities(data);
    if (_capabilitiesLoaded) {
      _cancelCapabilitiesSequenceTimers();
      _capabilitiesLoading = false;
      _capabilitiesFromCache = false;
      _modelCatalogLoadStage = ModelCatalogLoadStage.completed;
      if (wasLoading || !wasLoaded) {
        final defaultModelLabel =
            _getModelDisplayName(_getDefaultModelFromCapabilities());
        final elapsedMs = _runtimeCapabilitiesRequestedAt == null
            ? null
            : DateTime.now()
                .difference(_runtimeCapabilitiesRequestedAt!)
                .inMilliseconds;
        _messages.add(MessageItem(
          elapsedMs == null
              ? AppI18n.tWithParams(
                  context,
                  AppTextKey.modelCatalogAllLoaded,
                  {
                    'count': '${_availableModels.length}',
                    'model': defaultModelLabel,
                  },
                )
              : AppI18n.tWithParams(
                  context,
                  AppTextKey.modelCatalogAllLoadedWithElapsed,
                  {
                    'count': '${_availableModels.length}',
                    'model': defaultModelLabel,
                    'elapsed': '$elapsedMs',
                  },
                ),
          type: MessageType.system,
        ));
        if (previousModelCount > 0 &&
            previousModelCount != _availableModels.length) {
          _messages.add(MessageItem(
              AppI18n.tWithParams(
                  context, AppTextKey.modelCatalogListRefreshed, {
                'previous': '$previousModelCount',
                'next': '${_availableModels.length}',
              }),
              type: MessageType.system));
        }
      }
      unawaited(AppSettings().saveRuntimeCapabilitiesCache(
        Map<String, dynamic>.from(data),
      ));
      _runtimeCapabilitiesRequestedAt = null;
      _messages.add(MessageItem(
        '🧩 Runtime capabilities loaded: ${_availableModels.length} model(s), '
        'IDE context ${_supportsIdeContext ? 'enabled' : 'unsupported'}, '
        'flat mode ${_supportsFlatMode ? 'enabled' : 'unsupported'}',
        type: MessageType.system,
      ));
      return;
    }

    _capabilitiesLoading = true;
    _capabilitiesFromCache = false;
    _modelCatalogLoadStage = ModelCatalogLoadStage.syncingAll;
    if (wasLoading) {
      final defaultModelLabel =
          _getModelDisplayName(_getDefaultModelFromCapabilities());
      _messages.add(
        MessageItem(
          AppI18n.tWithParams(
            context,
            AppTextKey.modelCatalogDefaultModelLoaded,
            {'model': defaultModelLabel},
          ),
          type: MessageType.system,
        ),
      );
      _messages.add(MessageItem(
        AppI18n.t(context, AppTextKey.modelCatalogSyncingModels),
        type: MessageType.system,
      ));
    }
    _armCapabilitiesLoadTimeout();
  }

  // 텍스트 내용을 분석하여 적절한 에이전트 모드 자동 선택 (Extension의 detectAgentMode와 동일한 로직)
  String? _detectAgentMode(String text) {
    final lowerText = text.toLowerCase();
    final trimmed = lowerText.trim();

    // 짧은 인사/잡담은 Ask 모드로 보내 불필요한 작업 지시 문맥을 줄인다.
    const greetingKeywords = [
      'hello',
      'hi',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
      '안녕',
      '안녕하세요',
      '반가워',
      '반갑습니다',
    ];
    if (trimmed.length <= 40 &&
        greetingKeywords.any((keyword) => trimmed.contains(keyword))) {
      return 'ask';
    }

    // Debug 모드 키워드
    const debugKeywords = [
      'bug',
      'error',
      'fix',
      'debug',
      'issue',
      'problem',
      'crash',
      'exception',
      'trace',
      'log'
    ];
    if (debugKeywords.any((keyword) => lowerText.contains(keyword))) {
      // 버그 관련 키워드가 있지만, 단순 질문인지 확인
      if (lowerText.contains('why') ||
          lowerText.contains('what') ||
          lowerText.contains('how') ||
          lowerText.contains('?')) {
        // 질문 형태면 Ask 모드
        if (lowerText.contains('explain') ||
            lowerText.contains('understand') ||
            lowerText.contains('learn')) {
          return 'ask';
        }
      }
      return 'debug';
    }

    // Plan 모드 키워드
    const planKeywords = [
      'plan',
      'design',
      'architecture',
      'implement',
      'create',
      'build',
      'feature',
      'refactor',
      'analyze',
      'analysis',
      'project',
      'review',
      'overview',
      'structure'
    ];
    if (planKeywords.any((keyword) => lowerText.contains(keyword))) {
      // 복잡한 작업 키워드 확인
      const complexKeywords = [
        'multiple',
        'several',
        'many',
        'system',
        'module',
        'component',
        'project',
        '전체',
        '모든',
        '전반'
      ];
      if (complexKeywords.any((keyword) => lowerText.contains(keyword))) {
        return 'plan';
      }
      // "프로젝트 분석", "전체 분석" 같은 패턴도 Plan 모드
      if (lowerText.contains('analyze') ||
          lowerText.contains('analysis') ||
          lowerText.contains('분석')) {
        return 'plan';
      }
    }

    // Ask 모드 키워드 (질문, 학습, 탐색)
    const askKeywords = [
      'explain',
      'what is',
      'how does',
      'why',
      'understand',
      'learn',
      'show me',
      'tell me'
    ];
    if (askKeywords.any((keyword) => lowerText.contains(keyword)) ||
        lowerText.endsWith('?')) {
      return 'ask';
    }

    // 기본값: Agent 모드 (코드 작성/수정 작업)
    return null; // null이면 기본 Agent 모드 사용
  }

  void _disconnect() {
    if (_isDemoMode) {
      if (mounted) {
        _messages.add(MessageItem(
          AppI18n.t(context, AppTextKey.demoModeDisconnectActionSampleMessage),
          type: MessageType.system,
        ));
        _scrollToBottom();
      }
      return;
    }

    _stopPolling();
    _setTraceAutoRefresh(false);
    _cancelAllAutoDecisionTimers();
    _stopReconnect(); // 재연결 중지
    _cancelCapabilitiesSequenceTimers();

    // 로컬 WebSocket 연결 종료
    _localWebSocket?.sink.close();
    _localWebSocket = null;

    if (mounted) {
      setState(() {
        _isConnected = false;
        _sessionId = null;
        _isWaitingForResponse = false;
        _streamingMessageIndex = null;
        _streamingText = '';
        _isReconnecting = false;
        _isConnectionActionInProgress = false;
        _connectionActionLabel = null;
        _reconnectAttempts = 0;
        _pendingCommandApprovals = [];
        _pendingCodexServerRequests = [];
        _codexRequestHistory = [];
        _recentCommandEvents = [];
        _traceTimeline = null;
        _traceTimelineError = null;
        _recentTraceIds = [];
        _loadingTraceTimeline = false;
        _traceIdController.clear();
        _loadingCommandApprovals = false;
        _loadingCommandEvents = false;
        _lastCommandMetaRefreshAt = null;
        _capabilitiesLoaded = false;
        _capabilitiesLoading = false;
        _capabilitiesFromCache = false;
        _modelCatalogLoadStage = ModelCatalogLoadStage.idle;
        _runtimeCapabilitiesRequestedAt = null;
        _supportsIdeContext = false;
        _supportsFlatMode = false;
        _useIdeContext = false;
        _useFlatMode = false;
        _messages.add(MessageItem('Disconnected', type: MessageType.system));
      });
    }
  }

  // 재연결 스케줄링
  void _scheduleReconnect() {
    if (_isDemoMode) return;
    if (_isReconnecting || _isConnected) return;

    const maxAttempts = 5;
    if (_reconnectAttempts >= maxAttempts) {
      setState(() {
        _isReconnecting = false;
        _messages.add(MessageItem(
            '❌ 재연결 시도 횟수 초과 ($maxAttempts회). 수동으로 연결해주세요.',
            type: MessageType.system));
      });
      return;
    }

    setState(() {
      _isReconnecting = true;
      _reconnectAttempts++;
    });

    // 지수 백오프: 2초, 4초, 8초, 16초, 32초
    final delay = Duration(seconds: 2 * (1 << (_reconnectAttempts - 1)));

    setState(() {
      _messages.add(MessageItem(
          '🔄 ${delay.inSeconds}초 후 재연결 시도... ($_reconnectAttempts/$maxAttempts)',
          type: MessageType.system));
    });

    _reconnectTimer = Timer(delay, () {
      if (mounted && !_isConnected) {
        if (_connectionType == ConnectionType.local) {
          _connectToLocal();
        } else {
          final sessionId = _sessionIdController.text.trim();
          if (sessionId.isNotEmpty) {
            _connectToSession(sessionId);
          }
          // 세션 ID 없으면 재연결 안 함 (익스텐션 먼저 활성화 필요)
        }
      }
    });
  }

  // 재연결 중지
  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
  }

  void _forceStopReconnect() {
    if (!_isReconnecting && _reconnectTimer == null) return;
    _stopReconnect();
    if (!mounted) return;
    setState(() {
      _messages.add(
        MessageItem(
          '⏹️ 자동 재연결을 중지했습니다. 필요하면 다시 연결해주세요.',
          type: MessageType.system,
        ),
      );
    });
  }

  // 수동 재연결
  void _manualReconnect() {
    _stopReconnect();
    _reconnectAttempts = 0;
    unawaited(_connect());
  }

  Future<void> _sendCommand(String type,
      {String? text,
      String? command,
      List<dynamic>? args,
      bool? prompt,
      bool? terminal,
      bool? execute,
      String? action,
      bool? newSession,
      String? clientId,
      String? sessionId,
      String? relaySessionId,
      int? limit,
      String? agentMode,
      String? model,
      String? reasoningEffort,
      bool? useIdeContext,
      bool? useFlatMode}) async {
    if (_isDemoMode) {
      final message = text?.trim();
      if (type == 'insert_text' &&
          prompt == true &&
          execute == true &&
          message != null &&
          message.isNotEmpty) {
        await _simulateDemoPromptReply(message);
      } else if (message != null && message.isNotEmpty) {
        await _simulateDemoPromptReply(message, fallbackLabel: type);
      }
      return;
    }

    // 연결 상태 재확인
    _checkConnectionState();

    if (!_isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected')),
        );
      }
      return;
    }

    try {
      if (_deviceId.isEmpty) {
        _deviceId = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
      }

      // agentMode가 제공되지 않으면 선택된 모드 사용 (또는 auto)
      final mode = agentMode ?? 'auto';
      // model/reasoning이 제공되지 않으면 현재 선택값 사용
      final selectedModel = _normalizeModel((model ?? _selectedModel).trim());
      final selectedReasoningEffort = _normalizeReasoningEffort(
          (reasoningEffort ?? _selectedReasoningEffort).trim(), selectedModel);
      final ideContextForCommand = prompt == true &&
          _supportsIdeContext &&
          (useIdeContext ?? _useIdeContext);
      final flatModeForCommand =
          prompt == true && _supportsFlatMode && (useFlatMode ?? _useFlatMode);

      // 자동 모드이고 프롬프트인 경우 텍스트를 분석하여 모드 미리 감지
      String? finalModeForCommand;
      if (prompt == true && text != null && mode == 'auto') {
        final detectedMode = _detectAgentMode(text);
        finalModeForCommand = detectedMode ?? 'agent'; // 감지되지 않으면 기본 Agent 모드
        print(
            '🤖 Auto mode detected for command: $finalModeForCommand for text: ${text.substring(0, text.length > 30 ? 30 : text.length)}...');
      } else if (mode != 'auto') {
        finalModeForCommand = mode;
      }

      final modelForCommand = (prompt == true &&
              selectedModel.isNotEmpty &&
              selectedModel != 'auto')
          ? selectedModel
          : null;
      final reasoningEffortForCommand = (prompt == true &&
              selectedReasoningEffort.isNotEmpty &&
              selectedReasoningEffort != 'auto')
          ? selectedReasoningEffort
          : null;

      final commandId = DateTime.now().millisecondsSinceEpoch.toString();
      final traceId = _newTraceId();
      _syncTraceTimelineTargetTrace(traceId);

      final commandData = {
        'traceId': traceId,
        'type': type,
        'id': commandId,
        'senderDeviceId': _deviceId,
        if (text != null) 'text': text,
        if (command != null) 'command': command,
        if (args != null) 'args': args,
        if (prompt != null) 'prompt': prompt,
        if (terminal != null) 'terminal': terminal,
        if (execute != null) 'execute': execute,
        if (action != null) 'action': action,
        if (newSession != null) 'newSession': newSession,
        if (clientId != null) 'clientId': clientId,
        if (sessionId != null) 'sessionId': sessionId,
        if (relaySessionId != null) 'relaySessionId': relaySessionId,
        if (limit != null) 'limit': limit,
        // 자동 모드일 때도 감지된 모드를 전달하여 히스토리에 저장되도록 함
        if (finalModeForCommand != null) 'agentMode': finalModeForCommand,
        if (modelForCommand != null) 'model': modelForCommand,
        if (reasoningEffortForCommand != null)
          'reasoningEffort': reasoningEffortForCommand,
        if (ideContextForCommand) 'useIdeContext': true,
        if (flatModeForCommand) 'useFlatMode': true,
      };

      // 프롬프트 전송 시 사용자 프롬프트를 별도로 기록하고 응답 대기 상태 설정
      if (prompt == true && execute == true && text != null) {
        unawaited(_emitTraceEventsBestEffort([
          {
            'traceId': traceId,
            'hop': 'mobile.prompt.created',
            'status': 'ok',
            'commandId': commandId,
            'senderDeviceId': _deviceId,
            'sourceTs': DateTime.now().millisecondsSinceEpoch,
            'meta': {
              'messageType': type,
            },
          },
        ]));
        setState(() {
          _isWaitingForResponse = true;
          // 사용자 프롬프트를 별도 타입으로 추가 (선택된 모드와 함께)
          final promptItem = MessageItem(
            text,
            type: MessageType.userPrompt,
            agentMode: finalModeForCommand ?? mode, // 감지된 모드 또는 선택된 모드
          );
          _lastUserPrompt = promptItem;
          _messages.add(promptItem);

          // 디버깅: 모드 정보 출력
          print(
              '📝 User Prompt added - mode: $mode, finalModeForCommand: $finalModeForCommand, agentMode: ${promptItem.agentMode}');
        });
      }

      if (_connectionType == ConnectionType.local) {
        // 로컬 서버로 메시지 전송 (WebSocket)
        if (_localWebSocket != null) {
          _localWebSocket!.sink.add(jsonEncode(commandData));
          if (mounted) {
            setState(() {
              _messages.add(MessageItem('✅ Message sent to local server',
                  type: MessageType.system));
            });
            _scrollToBottom();
          }
        } else {
          throw Exception('Local WebSocket not connected');
        }
      } else {
        // 릴레이 서버로 메시지 전송
        if (_sessionId == null) {
          throw Exception('Session ID is required for relay connection');
        }
        // '응답 대기 중' UI가 먼저 그려지도록 다음 프레임에서 전송
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted || _sessionId == null) return;
          try {
            unawaited(_emitTraceEventsBestEffort([
              {
                'traceId': traceId,
                'hop': 'mobile.send.to_relay',
                'status': 'ok',
                'commandId': commandId,
                'senderDeviceId': _deviceId,
                'sourceTs': DateTime.now().millisecondsSinceEpoch,
                'meta': {
                  'messageType': type,
                },
              },
            ]));
            final response = await http.post(
              _relayUri('/api/send'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'sessionId': _sessionId,
                'deviceId': _deviceId,
                'deviceType': 'mobile',
                'type': type,
                'data': commandData,
              }),
            );

            if (mounted) {
              // 응답 파싱 실패 시에도 대기 상태 유지 (파싱 오류 ≠ 전송 실패)
              Map<String, dynamic>? responseData;
              if (response.body.isNotEmpty) {
                try {
                  responseData =
                      jsonDecode(response.body) as Map<String, dynamic>?;
                } catch (_) {
                  responseData = null;
                }
              }
              final success = response.statusCode == 200 &&
                  (responseData?['success'] == true);
              final responseMeta =
                  responseData?['data'] as Map<String, dynamic>? ?? {};
              final policyDecision =
                  responseMeta['policyDecision']?.toString() ?? '';
              final approvalId = responseMeta['approvalId']?.toString();
              final riskLevel = responseMeta['riskLevel']?.toString() ?? '';

              setState(() {
                if (success) {
                  _messages.add(MessageItem('✅ 메시지 전송됨, 응답 대기 중…',
                      type: MessageType.system));
                  // _isWaitingForResponse는 이미 true, 유지
                } else if (policyDecision == 'approval_required') {
                  _messages.add(MessageItem(
                      '⏳ 승인 필요: $approvalId (risk: $riskLevel) · 승인 후 응답이 시작됩니다.',
                      type: MessageType.system));
                  // 승인 대기 상태에서는 "응답 대기" 인디케이터를 끄고,
                  // 실제 승인(allow) 이후에만 다시 응답 대기로 전환한다.
                  _isWaitingForResponse = false;
                } else if (policyDecision == 'deny') {
                  _messages.add(MessageItem(
                      '🚫 정책 차단: ${responseData?['error'] ?? 'command denied'}',
                      type: MessageType.system));
                  _isWaitingForResponse = false;
                } else {
                  _messages.add(MessageItem(
                      '❌ 전송 실패: ${responseData?['error'] ?? 'HTTP ${response.statusCode}'}',
                      type: MessageType.system));
                  _isWaitingForResponse = false;
                }
              });

              if (policyDecision == 'approval_required') {
                _loadCommandApprovals(silent: true);
                _loadCommandEvents(silent: true);
              }
              _scrollToBottom();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('전송 오류: $e')),
              );
              setState(() {
                _isWaitingForResponse = false;
                _messages
                    .add(MessageItem('전송 오류: $e', type: MessageType.system));
              });
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 오류: $e')),
        );
        setState(() {
          _isWaitingForResponse = false;
          _messages.add(MessageItem('전송 오류: $e', type: MessageType.system));
        });
      }
    }
  }

  Future<void> _simulateDemoPromptReply(String userText,
      {String? fallbackLabel}) async {
    if (!_isDemoMode || !_isConnected || _isWaitingForResponse) return;
    final trimmed = userText.trim();
    if (trimmed.isEmpty) return;

    final detectedMode = _selectedAgentMode == 'auto'
        ? (_detectAgentMode(trimmed) ?? 'agent')
        : _selectedAgentMode;

    setState(() {
      _isWaitingForResponse = true;
      final promptItem = MessageItem(
        trimmed,
        type: MessageType.userPrompt,
        agentMode: detectedMode,
      );
      _lastUserPrompt = promptItem;
      _messages.add(promptItem);
      _chatHistory.insert(0, {
        'sessionId': _currentCodexSessionId ?? _sessionId ?? 'demo-session-id',
        'userMessage': trimmed,
        'assistantResponse':
            _generateDemoResponseForPrompt(trimmed, fallbackLabel),
        'agentMode': detectedMode,
      });
    });

    final responseText = _generateDemoResponseForPrompt(trimmed, fallbackLabel);

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_isDemoMode) return;

    setState(() {
      _isWaitingForResponse = false;
      _messages.add(MessageItem('', type: MessageType.chatResponseDivider));
      _messages.add(MessageItem('🤖 Codex Response',
          type: MessageType.chatResponseHeader));
      _messages.add(MessageItem(responseText, type: MessageType.chatResponse));
      _messages.add(MessageItem('', type: MessageType.chatResponseDivider));
    });
    _scrollToBottom();
  }

  String _generateDemoResponseForPrompt(String promptText, [String? fallback]) {
    final lower = promptText.toLowerCase();
    if (fallback != null) {
      return AppI18n.tWithParams(
        context,
        AppTextKey.demoModeResponseFallback,
        {'fallback': fallback},
      );
    }

    if (lower.contains('심사') || lower.contains('둘러보기')) {
      return AppI18n.t(context, AppTextKey.demoModeReviewModeDescription);
    }
    if (lower.contains('세션') || lower.contains('연결')) {
      return AppI18n.t(
          context, AppTextKey.demoModeSessionAutoConfiguredMessage);
    }
    if (lower.contains('승인') || lower.contains('결정')) {
      return AppI18n.t(context, AppTextKey.demoModeApprovalGuideMessage);
    }
    if (lower.contains('예시') || lower.contains('기능')) {
      return AppI18n.t(context, AppTextKey.demoModeFeatureGuideMessage);
    }

    return AppI18n.t(context, AppTextKey.demoModeSampleAssistantStart);
  }

  void _scrollToBottom() {
    // 다음 프레임에서 스크롤 (위젯이 빌드된 후)
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          // 스크롤 에러 무시
        }
      }
    });
  }

  Widget _buildFilterChipLabel({
    required IconData icon,
    required String text,
    required Color textColor,
    Color? iconColor,
    double iconSize = 14,
    double fontSize = 12,
  }) {
    final resolvedIconColor = iconColor ?? textColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: resolvedIconColor),
        SizedBox(width: fontSize <= 10 ? 2 : 4),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(MessageItem message) {
    // 구분선
    if (message.type == MessageType.chatResponseDivider) {
      return Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
    }

    // 헤더
    if (message.type == MessageType.chatResponseHeader) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.smart_toy,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    // 채팅 응답 본문 (스트리밍 중)
    if (message.type == MessageType.chatResponseChunk) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.45),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    message.text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                // 스트리밍 인디케이터
                const SizedBox(width: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // 애니메이션 반복
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 채팅 응답 본문 (완료)
    if (message.type == MessageType.chatResponse) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.45),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('메시지가 클립보드에 복사되었습니다'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 사용자 프롬프트 (입력한 내용) - 구분감 있게 표시
    if (message.type == MessageType.userPrompt) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .secondaryContainer
              .withOpacity(0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your prompt',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                // 에이전트 모드 표시 (null이 아니고 auto가 아닌 모든 경우, 자동 모드도 미리 감지되어 표시됨)
                if (message.agentMode != null &&
                    message.agentMode!.isNotEmpty &&
                    message.agentMode != 'auto') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.7),
                        width: 0.75,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getModeIcon(message.agentMode!),
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getModeDisplayName(message.agentMode!),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              message.text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('메시지가 클립보드에 복사되었습니다'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Codex raw event 메시지 스타일
    if (message.type == MessageType.codexRawEvent) {
      final parsed = _parseCodexRawEventText(message.text);
      final channel = parsed['channel'] ?? 'unknown';
      final methodWithKind = parsed['method'] ?? 'unknown';
      final detail = parsed['detail'] ?? '';
      final methodParts = methodWithKind.split('/');
      final kind = methodParts.isNotEmpty ? methodParts.last : 'event';

      Color kindColor;
      IconData kindIcon;
      switch (kind) {
        case 'reasoning':
          kindColor = Theme.of(context).colorScheme.primary;
          kindIcon = Icons.psychology_alt_outlined;
          break;
        case 'tool':
          kindColor = Theme.of(context).colorScheme.tertiary;
          kindIcon = Icons.build_outlined;
          break;
        case 'turn':
          kindColor = Theme.of(context).colorScheme.secondary;
          kindIcon = Icons.timelapse;
          break;
        case 'plan':
          kindColor = const Color(0xFF5E7CE2);
          kindIcon = Icons.checklist_rtl;
          break;
        case 'approval':
          kindColor = const Color(0xFFB56F00);
          kindIcon = Icons.gpp_maybe_outlined;
          break;
        case 'error':
          kindColor = Theme.of(context).colorScheme.error;
          kindIcon = Icons.error_outline;
          break;
        default:
          kindColor = Theme.of(context).colorScheme.onSurfaceVariant;
          kindIcon = Icons.radar_outlined;
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: kindColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: kindColor.withOpacity(0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(kindIcon, size: 14, color: kindColor),
                const SizedBox(width: 6),
                Text(
                  kind.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kindColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '[$channel]',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              methodWithKind,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            SelectableText(
              detail,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    // 로그 메시지 스타일
    if (message.type == MessageType.log) {
      final level = message.logLevel ?? LogLevel.info;
      final sourceLabel = _logSourceLabel(message.logSource ?? 'system');
      final levelLabel = _logLevelLabel(level);
      final channel = (message.logChannel ?? '').trim();
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final Color logColor = _logLevelColor(level);
      final IconData logIcon = _logLevelIcon(level);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: logColor.withOpacity(isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: logColor.withOpacity(0.32), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  logIcon,
                  size: 14,
                  color: logColor,
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: logColor.withOpacity(isDark ? 0.25 : 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    levelLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: logColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sourceLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (channel.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '[$channel]',
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              message.text,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    // 시스템 메시지 스타일
    if (message.type == MessageType.system) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              _getSystemMessageIcon(message.text),
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.6),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('메시지가 클립보드에 복사되었습니다'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // 일반 메시지
    return ListTile(
      title: Text(
        message.text,
        style: const TextStyle(fontSize: 13),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 2.0,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: message.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('메시지가 클립보드에 복사되었습니다'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  // 시스템 메시지 아이콘 결정
  IconData _getSystemMessageIcon(String text) {
    if (text.startsWith('✅')) return Icons.check_circle;
    if (text.startsWith('❌')) return Icons.error;
    if (text.startsWith('⚠️')) return Icons.warning;
    if (text.startsWith('Sent:')) return Icons.send;
    if (text.startsWith('Received:')) return Icons.download;
    if (text.contains('Connected')) return Icons.link;
    if (text.contains('Disconnected') || text.contains('Connection'))
      return Icons.link_off;
    return Icons.info_outline;
  }

  // 시간 포맷팅
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedHomeTab = widget.initialTab;
    _loadConnectionSettings();
    // 설정에서 기본 프롬프트 옵션 적용
    _selectedAgentMode = 'auto';
    _selectedModel = _restoreSavedSelectionValue(AppSettings().defaultModel);
    _selectedReasoningEffort =
        _restoreSavedSelectionValue(AppSettings().defaultReasoningEffort);
    // 설정 변경 리스너 추가
    AppSettings().addListener(_onAppSettingsChanged);
    _scrollController.addListener(_updateScrollButtonVisibility);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateScrollButtonVisibility());
    unawaited(_initializeNotifications());
    unawaited(_initializeConnectivityHandling());
    if (_isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isDemoMode) return;
        _activateDemoMode();
        if (widget.initialTab != HomeTab.chat) {
          unawaited(_selectHomeTab(widget.initialTab));
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.demoMode && widget.demoMode) {
      _activateDemoMode();
      if (widget.initialTab != HomeTab.chat) {
        unawaited(_selectHomeTab(widget.initialTab));
      }
    }
  }

  Future<void> _enterDemoMode() async {
    if (_isDemoMode) return;
    if (widget.onEnterDemoMode == null) return;

    await widget.onEnterDemoMode!();

    if (!mounted) return;

    // 데모 모드 진입 직후에는 설정 화면에서 벗어나 채팅 탭으로 이동
    if (_selectedHomeTab != HomeTab.chat) {
      await _selectHomeTab(HomeTab.chat);
    }
  }

  Future<void> _exitDemoMode() async {
    if (!_isDemoMode || widget.onExitDemoMode == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppI18n.t(context, AppTextKey.demoModePopupTitleExit)),
        content: Text(AppI18n.t(context, AppTextKey.demoModePopupContentExit)),
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

    if (confirm != true || !mounted) return;
    await widget.onExitDemoMode!();
  }

  Widget _buildExitDemoModeButton() {
    if (!_isDemoMode || widget.onExitDemoMode == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: AppI18n.t(context, AppTextKey.leaveDemo),
      icon: const Icon(Icons.logout),
      onPressed: () {
        unawaited(_exitDemoMode());
      },
    );
  }

  Widget _buildDemoModeGuideBanner() {
    if (!_isDemoMode || widget.onExitDemoMode == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppI18n.t(context, AppTextKey.demoModeStop),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppI18n.t(context, AppTextKey.demoModeStopSub),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
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

  Widget _wrapWithDemoModeGuide(Widget child) {
    if (!_isDemoMode || widget.onExitDemoMode == null) {
      return child;
    }

    return Column(
      children: [
        _buildDemoModeGuideBanner(),
        Expanded(child: child),
      ],
    );
  }

  Future<void> _initializeNotifications() async {
    try {
      const androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: darwinInitializationSettings,
        macOS: darwinInitializationSettings,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (_) {
          if (!mounted) return;
          unawaited(_selectHomeTab(HomeTab.approvals));
        },
      );

      final androidPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin
          ?.createNotificationChannel(_approvalNotificationChannel);
      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      final macosPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      await macosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } on MissingPluginException {
      // widget test/web 환경에서는 플러그인이 없을 수 있음
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages
            .add(MessageItem('⚠️ 알림 초기화 실패: $e', type: MessageType.system));
      });
    }
  }

  Future<void> _initializeConnectivityHandling() async {
    try {
      final connectivity = Connectivity();
      final current = await connectivity.checkConnectivity();
      _handleConnectivityChanged(current, emitSystemMessage: false);
      _connectivitySubscription =
          connectivity.onConnectivityChanged.listen(_handleConnectivityChanged);
    } on MissingPluginException {
      // widget test/web 환경에서는 플러그인이 없을 수 있음
    }
  }

  void _activateDemoMode() {
    if (!_isDemoMode) return;
    if (_isConnected && _sessionId == 'demo-session-id') {
      return;
    }
    final demoFirstMessage =
        AppI18n.t(context, AppTextKey.demoModeSamplePromptStart);
    final demoSecondMessage =
        AppI18n.t(context, AppTextKey.demoModeSamplePromptReview);
    final demoIntroMessage = AppI18n.t(context, AppTextKey.demoModeSampleIntro);
    final demoSessionMessage =
        AppI18n.t(context, AppTextKey.demoModeSampleSessionSummary);

    final demoHistory = <Map<String, dynamic>>[
      {
        'sessionId': 'demo-codex-session',
        'userMessage': AppI18n.isEnglish(context)
            ? 'How do I use Codex Remote?'
            : 'Codex Remote 앱은 어떻게 써요?',
        'assistantResponse': demoFirstMessage,
        'agentMode': 'auto',
      },
      {
        'sessionId': 'demo-codex-session',
        'userMessage': AppI18n.isEnglish(context)
            ? 'Where can I check approval requests?'
            : '승인 요청은 어디서 보나요?',
        'assistantResponse': demoSecondMessage,
        'agentMode': 'agent',
      },
    ];

    setState(() {
      _connectionType = ConnectionType.relay;
      _isConnected = true;
      _isWaitingForResponse = false;
      _isReconnecting = false;
      _isConnectionActionInProgress = false;
      _connectionActionLabel = null;
      _reconnectAttempts = 0;
      _stopReconnect();
      _isNetworkReachable = true;

      _sessionId = 'demo-session-id';
      _deviceId = 'mobile-demo-device';
      _currentCodexSessionId = 'demo-codex-session';
      _currentClientId = 'demo-client-id';
      _lastConnectionError = null;
      _lastCommandMetaRefreshAt = null;

      _sessionInfo = {
        'currentSessionId': 'demo-codex-session',
        'source': 'review-demo',
      };
      _chatHistory = List<Map<String, dynamic>>.from(demoHistory);
      _availableSessions = const ['demo-codex-session'];
      _pendingCodexServerRequests = [];
      _pendingCommandApprovals = [];
      _codexRequestHistory = [];
      _recentCommandEvents = [];
      _loadingCommandApprovals = false;
      _loadingCommandEvents = false;
      _loadingSessionHistoryForDisplay = false;
      _loadingPastMessages = false;
      _seenCodexRequestIds.clear();
      _seenCommandApprovalIds.clear();
      _resolvedApprovalEventFallbacks.clear();
      _autoDecisionTimers.clear();
      _submittingCodexRequestIds.clear();

      _capabilitiesLoaded = true;
      _capabilitiesLoading = false;
      _capabilitiesFromCache = true;
      _modelCatalogLoadStage = ModelCatalogLoadStage.completed;
      _runtimeCapabilitiesRequestedAt = null;
      _supportsIdeContext = false;
      _supportsFlatMode = false;
      _useIdeContext = false;
      _useFlatMode = false;
      _availableModels = List<Map<String, dynamic>>.from(_fallbackModels);
      _selectedModel = 'auto';
      _selectedReasoningEffort = 'auto';

      _messages.clear();
      _messages.add(MessageItem(demoIntroMessage, type: MessageType.system));
      _messages.add(MessageItem(
        demoSessionMessage,
        type: MessageType.system,
      ));
      _messages.add(MessageItem(
        AppI18n.tWithParams(
          context,
          AppTextKey.demoModeSampleRelaySessionLine,
          {'sessionId': 'demo-session-id'},
        ),
        type: MessageType.system,
      ));
      _applyChatHistoryToMessages(demoHistory, replaceConversation: true);
    });

    _scrollToBottom();
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results,
      {bool emitSystemMessage = true}) {
    final nextReachable =
        results.any((result) => result != ConnectivityResult.none);
    final changed = nextReachable != _isNetworkReachable;
    _isNetworkReachable = nextReachable;

    if (!changed) return;
    if (mounted && emitSystemMessage) {
      setState(() {
        _messages.add(MessageItem(
            nextReachable
                ? '📶 네트워크가 복구되었습니다. 승인 목록을 다시 확인합니다.'
                : '📡 네트워크 연결이 끊겼습니다. 연결 복구 시 자동 갱신됩니다.',
            type: MessageType.system));
      });
    }

    if (!emitSystemMessage) return;
    if (nextReachable &&
        _connectionType == ConnectionType.relay &&
        _isConnected) {
      unawaited(_loadCommandApprovals(silent: true));
      unawaited(_loadCommandEvents(silent: true));
    }
  }

  Future<void> _maybeNotifyApprovalArrival({
    int newRelayApprovals = 0,
    int newCodexRequests = 0,
  }) async {
    if (newRelayApprovals <= 0 && newCodexRequests <= 0) return;
    if (_isAppForeground && _selectedHomeTab == HomeTab.approvals) return;

    final pieces = <String>[];
    if (newCodexRequests > 0) {
      pieces.add('Codex $newCodexRequests건');
    }
    if (newRelayApprovals > 0) {
      pieces.add('Relay $newRelayApprovals건');
    }

    try {
      _notificationSequence++;
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'approval_requests',
          '승인 요청',
          channelDescription: 'Codex/Relay 승인 요청 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotificationsPlugin.show(
        _notificationSequence,
        '새 승인 요청이 도착했어요',
        pieces.join(' · '),
        notificationDetails,
        payload: 'approvals',
      );
    } on MissingPluginException {
      // 미지원 플랫폼은 무시
    } catch (_) {
      // 알림 실패는 치명적이지 않으므로 무시
    }
  }

  void _updateScrollButtonVisibility() {
    if (!mounted || !_scrollController.hasClients) return;
    final p = _scrollController.position;
    const threshold = 4.0;
    final canUp = p.pixels > p.minScrollExtent + threshold;
    final canDown = p.pixels < p.maxScrollExtent - threshold;
    if (canUp != _canScrollUp || canDown != _canScrollDown) {
      setState(() {
        _canScrollUp = canUp;
        _canScrollDown = canDown;
      });
    }
  }

  void _onAppSettingsChanged() {
    if (mounted) {
      final settings = AppSettings();
      setState(() {
        // 설정 변경 시 UI 업데이트 (히스토리/기본 프롬프트 옵션 등)
        _selectedAgentMode = 'auto';
        _selectedModel = _restoreSavedSelectionValue(settings.defaultModel);
        _selectedReasoningEffort =
            _restoreSavedSelectionValue(settings.defaultReasoningEffort);
      });
    }
  }

  bool _isCommandInputComposing([TextEditingValue? value]) {
    final current = value ?? _commandController.value;
    final composing = current.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  void _clearCommandInput() {
    _commandController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
      composing: TextRange.empty,
    );
    if (!_commandFocusNode.hasFocus) {
      _commandFocusNode.requestFocus();
    }
  }

  Future<void> _submitPromptFromInput({required bool newSession}) async {
    if (!_isConnected || _isWaitingForResponse) return;

    final now = DateTime.now();
    if (_lastPromptSubmitTime != null &&
        now.difference(_lastPromptSubmitTime!).inMilliseconds < 400) {
      return;
    }

    // 1차 체크: 한글 IME 조합 중이면 commit을 한 프레임 기다린다.
    if (_isCommandInputComposing()) {
      await Future<void>.delayed(Duration.zero);
      if (_isCommandInputComposing()) {
        return;
      }
    }

    final text = _commandController.text.trim();
    if (text.isEmpty) return;

    _lastPromptSubmitTime = now;
    _sendCommand('insert_text',
        text: text,
        prompt: true,
        execute: true,
        newSession: newSession,
        agentMode: _selectedAgentMode);
    _clearCommandInput();
  }

  KeyEventResult _handlePromptInputKeyEvent(FocusNode node, KeyEvent event) {
    if (!_commandFocusNode.hasFocus ||
        !_isConnected ||
        _isWaitingForResponse ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }

    // Shift+Enter는 줄바꿈
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }

    // 조합 중 Enter는 IME commit 동작을 우선
    if (_isCommandInputComposing()) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyUpEvent) {
      // KeyDown/Repeat 단계에서 먼저 consume해서 newline 삽입을 막는다.
      return KeyEventResult.handled;
    }

    unawaited(_submitPromptFromInput(newSession: false));
    return KeyEventResult.handled;
  }

  // 연결 설정 로드 (SharedPreferences)
  Future<void> _loadConnectionSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 연결 타입 로드
      final connectionTypeStr = prefs.getString('connection_type');
      if (connectionTypeStr != null) {
        setState(() {
          _connectionType = connectionTypeStr == 'local'
              ? ConnectionType.local
              : ConnectionType.relay;
        });
      }

      // PC(Extension) IP 주소 로드
      final savedIp = prefs.getString('pc_server_ip');
      if (savedIp != null && savedIp.isNotEmpty) {
        _localIpController.text = savedIp;
      }
      final savedPort = prefs.getString('local_ws_port');
      if (savedPort != null && savedPort.isNotEmpty) {
        _localPortController.text = savedPort;
      }
      // 마지막 세션 ID 로드 (선택사항)
      final lastSessionId = prefs.getString('last_session_id');
      if (lastSessionId != null && lastSessionId.isNotEmpty) {
        _sessionIdController.text = lastSessionId;
      }
    } catch (e) {
      // 에러는 조용히 무시 (첫 실행 시 prefs가 없을 수 있음)
    }
  }

  // 연결 설정 저장 (SharedPreferences)
  Future<void> _saveConnectionSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 연결 타입 저장
      await prefs.setString('connection_type',
          _connectionType == ConnectionType.local ? 'local' : 'relay');

      // PC(Extension) IP 주소 저장
      if (_localIpController.text.trim().isNotEmpty) {
        await prefs.setString('pc_server_ip', _localIpController.text.trim());
      }
      if (_localPortController.text.trim().isNotEmpty) {
        await prefs.setString(
            'local_ws_port', _localPortController.text.trim());
      }
      // 세션 ID 저장 (연결 성공 시)
      if (_sessionId != null && _sessionId!.isNotEmpty) {
        await prefs.setString('last_session_id', _sessionId!);
      }
    } catch (e) {
      // 에러는 조용히 무시
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _isAppForeground = true;
      // 앱이 다시 활성화되었을 때 연결 상태 확인 및 UI 갱신
      if (mounted) {
        // 연결 상태 확인
        _checkConnectionState();
        // UI 강제 갱신 - Future.microtask를 사용하여 다음 프레임에서 실행
        Future.microtask(() {
          if (mounted) {
            setState(() {
              // 상태 갱신으로 UI 다시 렌더링
            });
          }
        });
      }
      if (_connectionType == ConnectionType.relay && _isConnected) {
        unawaited(_loadCommandApprovals(silent: true));
        unawaited(_loadCommandEvents(silent: true));
      }
    } else if (state == AppLifecycleState.paused) {
      _isAppForeground = false;
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _isAppForeground = false;
    }
  }

  // 세션 정보 조회
  Future<void> _loadSessionInfo() async {
    if (_isDemoMode) return;
    if (!_isConnected) return;

    // clientId가 아직 없으면 잠시 대기 후 재시도
    if (_currentClientId == null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isConnected) _loadSessionInfo();
      });
      return;
    }

    try {
      await _sendCommand('get_session_info', clientId: _currentClientId);
    } catch (e) {
      // 에러는 조용히 무시
    }
  }

  // 대화 히스토리 조회
  // 릴레이 모드일 때 relaySessionId를 넘기면 현재 릴레이 세션의 히스토리만 반환됨
  Future<void> _loadChatHistory({String? sessionId, int limit = 50}) async {
    if (_isDemoMode) return;
    if (!_isConnected) return;

    try {
      await _sendCommand('get_chat_history',
          clientId: _currentClientId,
          sessionId: sessionId ?? _currentCodexSessionId,
          relaySessionId: _sessionId, // 릴레이 모드: 현재 세션 히스토리만
          limit: limit);
    } catch (e) {
      // 에러는 조용히 무시
    }
  }

  Future<void> _loadRuntimeCapabilities() {
    if (_isDemoMode || !_isConnected) return Future<void>.value();
    return _capabilitiesSingleFlight.run(_loadRuntimeCapabilitiesOnce);
  }

  Future<void> _loadRuntimeCapabilitiesOnce() async {
    try {
      final cached = await AppSettings().getRuntimeCapabilitiesCache(
        maxAge: const Duration(hours: 24),
      );
      _cancelCapabilitiesSequenceTimers();
      setState(() {
        _capabilitiesLoading = true;
        _runtimeCapabilitiesRequestedAt = DateTime.now();
        if (cached != null) {
          _applyRuntimeCapabilities(cached.capabilities);
          _capabilitiesLoaded = true;
          _capabilitiesFromCache = true;
          _modelCatalogLoadStage = ModelCatalogLoadStage.syncingAll;
          final ageMinutes =
              DateTime.now().difference(cached.cachedAt).inMinutes;
          _messages.add(MessageItem(
              AppI18n.tWithParams(
                context,
                AppTextKey.modelCatalogCacheApplied,
                {
                  'count': '${_availableModels.length}',
                  'minutes': '$ageMinutes',
                },
              ),
              type: MessageType.system));
          _messages.add(MessageItem(
              AppI18n.t(context, AppTextKey.modelCatalogSyncLatestLoading),
              type: MessageType.system));
        } else {
          _capabilitiesLoaded = false;
          _capabilitiesFromCache = false;
          _modelCatalogLoadStage = ModelCatalogLoadStage.loading;
          _messages.add(MessageItem(
              AppI18n.t(context, AppTextKey.modelCatalogLoadFromNetwork),
              type: MessageType.system));
        }
      });
      if (cached == null) {
        _startCapabilitiesLoadSequence();
      }
      _armCapabilitiesLoadTimeout();
      await _sendCommand('get_runtime_capabilities',
          clientId: _currentClientId);
      if (_connectionType == ConnectionType.relay) {
        Future.delayed(const Duration(milliseconds: 120), () {
          unawaited(_pollRelayMessagesOnce());
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cancelCapabilitiesSequenceTimers();
        _capabilitiesLoading = false;
        _modelCatalogLoadStage = ModelCatalogLoadStage.failed;
        _runtimeCapabilitiesRequestedAt = null;
        _messages.add(MessageItem(
            AppI18n.tWithParams(
              context,
              AppTextKey.modelCatalogLoadFailed,
              {'error': '$e'},
            ),
            type: MessageType.system));
      });
    }
  }

  Future<void> _refreshCommandMetaIfStale(
      {Duration minInterval = const Duration(seconds: 6)}) async {
    if (_isDemoMode) return;
    if (!_isConnected || _connectionType != ConnectionType.relay) return;
    final now = DateTime.now();
    if (_lastCommandMetaRefreshAt != null &&
        now.difference(_lastCommandMetaRefreshAt!) < minInterval) {
      return;
    }
    _lastCommandMetaRefreshAt = now;
    await _loadCommandApprovals(silent: true);
    await _loadCommandEvents(silent: true);
  }

  Future<void> _loadCommandApprovals({bool silent = false}) async {
    if (_isDemoMode) return;
    if (!_isConnected || _sessionId == null) return;
    if (_connectionType != ConnectionType.relay) return;
    if (!_isNetworkReachable) {
      if (!silent && mounted) {
        setState(() {
          _messages.add(MessageItem('📡 오프라인 상태에서는 승인 목록을 불러올 수 없어요.',
              type: MessageType.system));
        });
        _scrollToBottom();
      }
      return;
    }
    if (_loadingCommandApprovals) return;

    if (mounted) {
      setState(() => _loadingCommandApprovals = true);
    }

    try {
      final uri = _relayUri('/api/command-approvals', {
        'sessionId': _sessionId!,
      });
      final response = await http.get(uri);
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final approvals = List<Map<String, dynamic>>.from(
            (data['approvals'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map)));
        var newRelayApprovals = 0;

        setState(() {
          _pendingCommandApprovals = approvals;
          for (final approval in approvals) {
            final approvalId = approval['approval_id']?.toString() ?? '';
            if (approvalId.isEmpty ||
                _seenCommandApprovalIds.contains(approvalId)) {
              continue;
            }

            _seenCommandApprovalIds.add(approvalId);
            newRelayApprovals++;
            final policy = approval['policy'] as Map<String, dynamic>? ?? {};
            final riskLevel = policy['risk_level']?.toString() ?? 'unknown';
            final commandRaw = _truncateForLog(_approvalCommandRaw(approval));
            final requestType = _approvalRequestTypeLabel(approval);
            final requestedBy = _approvalRequestedBy(approval);

            _messages.add(MessageItem(
                '🔐 승인 요청 도착: $requestType · $commandRaw · by $requestedBy (risk: $riskLevel)',
                type: MessageType.system));
          }
          _loadingCommandApprovals = false;
        });

        if (!silent) {
          setState(() {
            _messages.add(MessageItem(
                '🔐 Pending approvals: ${approvals.length}',
                type: MessageType.system));
          });
          _scrollToBottom();
        }
        unawaited(_maybeNotifyApprovalArrival(
          newRelayApprovals: newRelayApprovals,
        ));
      } else {
        setState(() => _loadingCommandApprovals = false);
        if (!silent) {
          setState(() {
            _messages.add(MessageItem(
                '❌ approvals 조회 실패: ${body['error'] ?? 'HTTP ${response.statusCode}'}',
                type: MessageType.system));
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCommandApprovals = false);
      if (!silent) {
        setState(() {
          _messages.add(
              MessageItem('❌ approvals 조회 오류: $e', type: MessageType.system));
        });
        _scrollToBottom();
      }
    }
  }

  LogLevel _parseLogLevel(dynamic rawLevel) {
    switch (rawLevel?.toString().toLowerCase()) {
      case 'error':
        return LogLevel.error;
      case 'warn':
      case 'warning':
        return LogLevel.warning;
      default:
        return LogLevel.info;
    }
  }

  String _normalizeLogSource(dynamic rawSource) {
    final source = rawSource?.toString().trim().toLowerCase() ?? '';
    if (source.isEmpty) return 'system';
    if (source == 'codex') return 'codex';
    if (source == 'extension') return 'extension';
    if (source == 'relay') return 'relay';
    return source;
  }

  String _prettifyLogBody(String rawMessage) {
    var text = rawMessage.trim();
    if (text.isEmpty) return '(empty)';

    text = text.replaceFirst(RegExp(r'^\[(CODEX|Relay|Extension)\]\s*'), '');

    final ignoredRpcMatch = RegExp(
            r'ignored rpc notification method=([^,]+), params=(.+)$',
            caseSensitive: false)
        .firstMatch(text);
    if (ignoredRpcMatch != null) {
      final method = ignoredRpcMatch.group(1)?.trim() ?? 'unknown';
      final params = ignoredRpcMatch.group(2)?.trim() ?? '';
      return 'Ignored RPC: $method\nparams: ${_truncateForLog(params, maxLength: 180)}';
    }

    return text;
  }

  void _appendPrettyLogMessage(dynamic payload, {required String channel}) {
    final map = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final level = _parseLogLevel(map['level']);
    final source = _normalizeLogSource(map['source']);
    final body = _prettifyLogBody(map['message']?.toString() ?? '');
    final errorText = map['error']?.toString().trim() ?? '';
    final composed = errorText.isNotEmpty ? '$body\nerror: $errorText' : body;

    _messages.add(MessageItem(composed,
        type: MessageType.log,
        logLevel: level,
        logSource: source,
        logChannel: channel));
  }

  String _logSourceLabel(String source) {
    switch (source) {
      case 'codex':
        return 'Codex';
      case 'extension':
        return 'Extension';
      case 'relay':
        return 'Relay';
      case 'system':
        return 'System';
      default:
        return source;
    }
  }

  String _logLevelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.info:
        return 'INFO';
    }
  }

  Color _logLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Theme.of(context).colorScheme.error;
      case LogLevel.warning:
        return const Color(0xFFEF8B00);
      case LogLevel.info:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  IconData _logLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.info:
        return Icons.info_outline;
    }
  }

  String _truncateForLog(String value, {int maxLength = 72}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}…';
  }

  String _safeJsonSnippet(dynamic payload, {int maxLength = 240}) {
    try {
      final encoded = jsonEncode(payload);
      return _truncateForLog(encoded, maxLength: maxLength);
    } catch (_) {
      return _truncateForLog(payload?.toString() ?? '(empty)',
          maxLength: maxLength);
    }
  }

  Widget _approvalMetaChip({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _codexEventKind(String method) {
    final normalized = method.toLowerCase();
    if (normalized.contains('plan/')) return 'plan';
    if (normalized.contains('approval')) return 'approval';
    if (normalized.contains('agent_message_content_delta') ||
        normalized.contains('agentmessage') ||
        normalized.contains('reasoning')) {
      return 'reasoning';
    }
    if (normalized.contains('tool/')) return 'tool';
    if (normalized.contains('turn/')) return 'turn';
    if (normalized.contains('error')) return 'error';
    return 'event';
  }

  String _statusBadge(String rawStatus) {
    final status = rawStatus.toLowerCase();
    if (status == 'completed' || status == 'done') return '✅';
    if (status == 'inprogress' || status == 'in_progress') return '⏳';
    if (status == 'pending' || status == 'todo') return '🕓';
    if (status == 'failed' || status == 'error') return '❌';
    return '•';
  }

  String _formatPlanUpdateDetail(dynamic params) {
    final map =
        params is Map ? Map<String, dynamic>.from(params) : <String, dynamic>{};
    final explanation = map['explanation']?.toString().trim() ?? '';
    final rawPlan = map['plan'] as List? ?? const [];
    final steps = rawPlan
        .map((item) => item is Map ? Map<String, dynamic>.from(item) : null)
        .whereType<Map<String, dynamic>>()
        .toList();

    final parts = <String>[];
    if (explanation.isNotEmpty) {
      parts.add(_truncateForLog(explanation, maxLength: 160));
    }
    if (steps.isNotEmpty) {
      final formattedSteps = steps
          .map((step) {
            final status = step['status']?.toString() ?? 'pending';
            final title = step['step']?.toString().trim() ?? '(untitled)';
            return '${_statusBadge(status)} ${_truncateForLog(title, maxLength: 82)}';
          })
          .take(3)
          .toList();
      parts.add(formattedSteps.join(' | '));
      if (steps.length > 3) {
        parts.add('… +${steps.length - 3} more step(s)');
      }
    }

    if (parts.isEmpty) {
      return _safeJsonSnippet(params, maxLength: 220);
    }
    return parts.join('\n');
  }

  Map<String, String> _parseCodexRawEventText(String text) {
    final regex = RegExp(r'^📡 \[(.+?)\] (.+?) :: ([\s\S]+)$');
    final match = regex.firstMatch(text.trim());
    if (match == null) {
      return {
        'channel': 'unknown',
        'method': 'unknown',
        'detail': text,
      };
    }
    return {
      'channel': match.group(1) ?? 'unknown',
      'method': match.group(2) ?? 'unknown',
      'detail': match.group(3) ?? '',
    };
  }

  String _extractCodexEventText(dynamic value, {int depth = 0}) {
    if (value == null || depth > 4) return '';

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return '';
      return trimmed;
    }

    if (value is Map) {
      const preferredKeys = [
        'delta',
        'text',
        'message',
        'content',
        'reasoning',
        'summary'
      ];
      for (final key in preferredKeys) {
        final extracted = _extractCodexEventText(value[key], depth: depth + 1);
        if (extracted.isNotEmpty) return extracted;
      }
      for (final entry in value.entries) {
        final extracted = _extractCodexEventText(entry.value, depth: depth + 1);
        if (extracted.isNotEmpty) return extracted;
      }
      return '';
    }

    if (value is List) {
      for (final item in value) {
        final extracted = _extractCodexEventText(item, depth: depth + 1);
        if (extracted.isNotEmpty) return extracted;
      }
      return '';
    }

    return '';
  }

  String _formatCodexEventDetail(String method, dynamic params) {
    final normalized = method.toLowerCase();
    if (normalized.contains('turn/plan/updated')) {
      return _formatPlanUpdateDetail(params);
    }
    if (normalized.contains('agent_message_content_delta')) {
      final text = _extractCodexEventText(params);
      if (text.isNotEmpty) {
        return 'Δ ${_truncateForLog(text, maxLength: 180)}';
      }
    }

    final text = _extractCodexEventText(params);
    return text.isNotEmpty
        ? _truncateForLog(text, maxLength: 220)
        : _safeJsonSnippet(params, maxLength: 220);
  }

  void _recordCodexRawNotification(dynamic payload, {required String channel}) {
    final map = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final method = map['method']?.toString().trim() ??
        map['eventMethod']?.toString().trim() ??
        'unknown';
    final params = map['params'] ?? map['eventParams'] ?? payload;
    final kind = _codexEventKind(method);
    final detail = _formatCodexEventDetail(method, params);

    _messages.add(MessageItem('📡 [$channel] $method/$kind :: $detail',
        type: MessageType.codexRawEvent, logLevel: LogLevel.info));
  }

  void _recordUnhandledIncomingMessage(
      String type, dynamic payload, String channel) {
    final detail = _safeJsonSnippet(payload, maxLength: 220);
    _messages.add(MessageItem('🧩 [$channel] unhandled type=$type → $detail',
        type: MessageType.codexRawEvent, logLevel: LogLevel.warning));
  }

  String _approvalCommandRaw(Map<String, dynamic> approval) {
    final commandData = _approvalCommandData(approval);
    return commandData['command']?.toString() ??
        commandData['raw']?.toString() ??
        '(unknown)';
  }

  Map<String, dynamic> _approvalCommandData(Map<String, dynamic> approval) {
    final commandMessage =
        approval['command_message'] as Map<String, dynamic>? ?? {};
    return commandMessage['data'] as Map<String, dynamic>? ?? {};
  }

  String _approvalRequestTypeLabel(Map<String, dynamic> approval) {
    final commandMessage =
        approval['command_message'] as Map<String, dynamic>? ?? {};
    final type = commandMessage['type']?.toString().toLowerCase() ?? '';
    switch (type) {
      case 'command':
        return 'Command execution';
      case 'chat':
        return 'Chat request';
      case 'prompt':
        return 'Prompt request';
      default:
        return type.isEmpty ? 'Approval request' : type;
    }
  }

  String _approvalRequestedBy(Map<String, dynamic> approval) {
    final commandMessage =
        approval['command_message'] as Map<String, dynamic>? ?? {};
    final sender = commandMessage['senderDeviceId']?.toString().trim() ?? '';
    final requestedBy = approval['requested_by']?.toString().trim() ?? '';
    return sender.isNotEmpty
        ? sender
        : (requestedBy.isNotEmpty ? requestedBy : '(unknown)');
  }

  String _approvalWorkingDirectory(Map<String, dynamic> approval) {
    final commandData = _approvalCommandData(approval);
    return commandData['cwd']?.toString().trim() ?? '';
  }

  String _approvalPolicyRule(Map<String, dynamic> approval) {
    final policy = approval['policy'] as Map<String, dynamic>? ?? {};
    return policy['rule_id']?.toString().trim() ?? '';
  }

  bool _approvalNeedsAssistantResponse(Map<String, dynamic> approval) {
    final commandData = _approvalCommandData(approval);
    final isPrompt = commandData['prompt'] == true;
    final shouldExecute = commandData['execute'] == true;
    return isPrompt && shouldExecute;
  }

  String _approvalHistoryStatusKey(String? approvalId, String status) {
    final normalizedId = approvalId?.trim() ?? '';
    if (normalizedId.isEmpty) return '';
    return '${normalizedId}_${status.toLowerCase()}';
  }

  String _normalizeApprovalStatusFromEvent(Map<String, dynamic> event) {
    final approval = event['approval'] as Map<String, dynamic>? ?? {};
    final rawStatus = approval['status']?.toString().toLowerCase().trim() ?? '';
    switch (rawStatus) {
      case 'accept':
      case 'accepted':
      case 'approve':
      case 'approved':
        return 'approved';
      case 'deny':
      case 'denied':
      case 'reject':
      case 'rejected':
        return 'rejected';
      default:
        return rawStatus;
    }
  }

  String? _deriveApprovalStatusFromEvent(Map<String, dynamic> event) {
    final approval = event['approval'] as Map<String, dynamic>? ?? {};
    final metadata = event['metadata'] as Map<String, dynamic>? ?? {};
    final result = event['result'] as Map<String, dynamic>? ?? {};

    final normalizedStatus = _normalizeApprovalStatusFromEvent(event);
    if (normalizedStatus == 'approved' || normalizedStatus == 'rejected') {
      return normalizedStatus;
    }

    final approvalRequired = approval['required'] == true ||
        _extractApprovalIdFromCommandEvent(event) != null;
    if (!approvalRequired) return null;

    final rawAction = metadata['action']?.toString().toLowerCase().trim() ?? '';
    if (rawAction == 'approve' || rawAction == 'approved') return 'approved';
    if (rawAction == 'reject' || rawAction == 'rejected') return 'rejected';

    final resultStatus =
        result['status']?.toString().toLowerCase().trim() ?? '';
    switch (resultStatus) {
      case 'success':
      case 'error':
      case 'timeout':
        return 'approved';
      case 'cancelled':
        return 'rejected';
      default:
        break;
    }

    final approvedBy = approval['approved_by']?.toString().trim() ?? '';
    if (approvedBy.isNotEmpty) return 'approved';

    return null;
  }

  void _upsertResolvedApprovalEventFallback(
    Map<String, dynamic> approval, {
    required String status,
  }) {
    final approvalId = approval['approval_id']?.toString() ?? '';
    final normalizedApprovalId = approvalId.trim();
    if (normalizedApprovalId.isEmpty) return;

    final key = _approvalHistoryStatusKey(normalizedApprovalId, status);
    if (key.isEmpty) return;
    final policy = approval['policy'] as Map<String, dynamic>? ?? {};
    final reasons = List<String>.from((policy['reasons'] as List? ?? []));

    final commandData = _approvalCommandData(approval);

    final fallback = {
      'event_id': 'mobile-fallback-${DateTime.now().millisecondsSinceEpoch}',
      'session_id': _sessionId ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'tool': {
        'provider': 'codex',
        'name': 'mobile-approval-fallback',
      },
      'command': {
        'raw': commandData['command']?.toString() ??
            commandData['raw']?.toString() ??
            '-',
        'cwd': commandData['cwd']?.toString(),
      },
      'risk': {
        'level': policy['risk_level']?.toString() ?? 'unknown',
        'reasons': reasons,
      },
      'policy': {
        'decision': 'approval_required',
        'rule_id': policy['rule_id']?.toString() ?? 'approval_required',
      },
      'approval': {
        'required': true,
        'status': status,
        'approved_by': status == 'approved' ? _deviceId : null,
        'approved_at':
            status == 'approved' ? DateTime.now().millisecondsSinceEpoch : null,
        'reason': 'resolved via mobile app',
      },
      'result': {
        'status': status == 'approved' ? 'pending' : 'cancelled',
        'exit_code': null,
        'duration_ms': 0,
        'error_message': status == 'approved' ? null : 'Rejected by approver',
      },
      'metadata': {
        'approval_id': approvalId,
        'action': status,
        'resolved_by': _deviceId,
        'resolved_at': DateTime.now().millisecondsSinceEpoch,
      },
    };

    _resolvedApprovalEventFallbacks[key] = Map<String, dynamic>.from(fallback);
  }

  List<Map<String, dynamic>> _buildResolvedApprovalHistoryEntries(
      {int limit = 20}) {
    final entries = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final event in _recentCommandEvents) {
      final approval = event['approval'] as Map<String, dynamic>? ?? {};
      final status = _deriveApprovalStatusFromEvent(event) ?? '';
      if (status != 'approved' && status != 'rejected') continue;

      final approvalId = _extractApprovalIdFromCommandEvent(event) ?? '';
      final dedupeKey = '${approvalId}_$status';
      if (approvalId.isNotEmpty && seen.contains(dedupeKey)) continue;
      if (approvalId.isNotEmpty) seen.add(dedupeKey);

      final command = event['command'] as Map<String, dynamic>? ?? {};
      final risk = event['risk'] as Map<String, dynamic>? ?? {};
      final commandRaw = _truncateForLog(
          command['raw']?.toString() ?? '(unknown)',
          maxLength: 88);
      final riskLevel = risk['level']?.toString() ?? 'unknown';
      final resolvedBy = approval['approved_by']?.toString().trim();
      final byLabel = (resolvedBy != null && resolvedBy.isNotEmpty)
          ? resolvedBy
          : (event['metadata'] as Map<String, dynamic>? ?? {})['resolved_by']
                  ?.toString()
                  .trim() ??
              '-';
      final timeLabel = _timestampLabelFromMap(event, preferredKeys: const [
        'resolved_at',
        'resolvedAt',
        'timestamp',
        'created_at',
        'createdAt'
      ]);

      entries.add({
        'status': status,
        'title': status == 'approved' ? '허용됨' : '거부됨',
        'command': commandRaw,
        'riskLevel': riskLevel,
        'approvalId': approvalId,
        'resolvedBy': byLabel,
        'timeLabel': timeLabel,
        'sortTs': (_parseTimestampValue(event['resolved_at']) ??
                _parseTimestampValue(event['resolvedAt']) ??
                _parseTimestampValue(event['timestamp']) ??
                _parseTimestampValue(event['created_at']) ??
                _parseTimestampValue(event['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0))
            .millisecondsSinceEpoch,
      });
    }

    for (final historyEntry in _codexRequestHistory) {
      final item = toApprovalHistoryItem(historyEntry);
      final dedupeKey =
          '${item['approvalId']}_${item['status']}_${item['title']}';
      if (seen.contains(dedupeKey)) continue;
      seen.add(dedupeKey);
      entries.add(item);
    }

    entries.sort((a, b) {
      final at = a['sortTs'] is int ? a['sortTs'] as int : 0;
      final bt = b['sortTs'] is int ? b['sortTs'] as int : 0;
      return bt.compareTo(at);
    });

    final sliced = entries.take(limit).map((entry) {
      final next = Map<String, dynamic>.from(entry);
      next.remove('sortTs');
      return next;
    }).toList();
    return sliced;
  }

  String _describeDecisionPayload(Map<String, dynamic> responsePayload) {
    const candidateKeys = ['decision', 'action', 'status', 'choice', 'result'];
    for (final key in candidateKeys) {
      final value = responsePayload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    if (responsePayload.containsKey('answers')) {
      return 'answers_submitted';
    }

    if (responsePayload.isEmpty) return 'submitted';
    return _truncateForLog(jsonEncode(responsePayload), maxLength: 56);
  }

  String _autoDecisionModeLabel(AutoDecisionMode mode) {
    switch (mode) {
      case AutoDecisionMode.approve:
        return 'auto-approve';
      case AutoDecisionMode.reject:
        return 'auto-reject';
      case AutoDecisionMode.off:
        return 'manual';
    }
  }

  void _cancelAutoDecisionTimer(String requestId) {
    final timer = _autoDecisionTimers.remove(requestId);
    timer?.cancel();
  }

  void _cancelAllAutoDecisionTimers() {
    for (final timer in _autoDecisionTimers.values) {
      timer.cancel();
    }
    _autoDecisionTimers.clear();
  }

  DateTime? _parseTimestampValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final asInt = int.tryParse(trimmed);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      return DateTime.tryParse(trimmed);
    }
    return null;
  }

  String _timestampLabelFromMap(Map<String, dynamic> payload,
      {List<String> preferredKeys = const [
        'created_at',
        'createdAt',
        'timestamp',
        'resolved_at',
        'resolvedAt'
      ]}) {
    for (final key in preferredKeys) {
      final parsed = _parseTimestampValue(payload[key]);
      if (parsed != null) return _formatTime(parsed);
    }
    return '-';
  }

  Map<String, dynamic>? _pickAutoDecisionPayload(Map<String, dynamic> request) {
    final choices = List<Map<String, dynamic>>.from(
        (request['choices'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));
    if (choices.isEmpty) return null;

    final wantsApprove = _autoDecisionMode == AutoDecisionMode.approve;
    final positiveKeywords = <String>[
      'approve',
      'allow',
      'accept',
      'continue',
      'proceed',
      'yes'
    ];
    final negativeKeywords = <String>[
      'reject',
      'deny',
      'block',
      'cancel',
      'decline',
      'no'
    ];

    bool matches(Map<String, dynamic> choice, List<String> keywords) {
      final label = choice['label']?.toString().toLowerCase() ?? '';
      final style = choice['style']?.toString().toLowerCase() ?? '';
      final response =
          Map<String, dynamic>.from(choice['response'] as Map? ?? {});
      final responseText = [
        response['decision'],
        response['action'],
        response['status'],
        response['result']
      ].where((e) => e != null).join(' ').toLowerCase();
      final haystack = '$label $style $responseText';
      return keywords.any((kw) => haystack.contains(kw));
    }

    final exact = choices.where((choice) {
      if (wantsApprove) return matches(choice, positiveKeywords);
      return matches(choice, negativeKeywords);
    }).toList();
    if (exact.isNotEmpty) {
      return Map<String, dynamic>.from(exact.first['response'] as Map? ?? {});
    }

    if (wantsApprove) {
      final primary = choices.firstWhere(
          (choice) => choice['style']?.toString().toLowerCase() == 'primary',
          orElse: () => choices.first);
      return Map<String, dynamic>.from(primary['response'] as Map? ?? {});
    }

    final danger = choices.firstWhere(
        (choice) => choice['style']?.toString().toLowerCase() == 'danger',
        orElse: () => choices.last);
    return Map<String, dynamic>.from(danger['response'] as Map? ?? {});
  }

  void _scheduleAutoDecisionForCodexRequest(Map<String, dynamic> request) {
    if (_autoDecisionMode == AutoDecisionMode.off) return;

    final requestId = request['requestId']?.toString() ?? '';
    if (requestId.isEmpty) return;

    final requestKind = request['requestKind']?.toString() ?? '';
    if (requestKind == 'user_input') return;

    _cancelAutoDecisionTimer(requestId);
    _autoDecisionTimers[requestId] =
        Timer(Duration(seconds: _autoDecisionTimeoutSec), () async {
      if (!mounted) return;

      final stillPending = _pendingCodexServerRequests
          .any((item) => item['requestId']?.toString() == requestId);
      if (!stillPending) {
        _cancelAutoDecisionTimer(requestId);
        return;
      }

      final autoPayload = _pickAutoDecisionPayload(request);
      final modeLabel = _autoDecisionModeLabel(_autoDecisionMode);
      if (autoPayload == null) {
        setState(() {
          _messages.add(MessageItem('⚠️ $requestId 자동 응답 실패: 선택 가능한 응답이 없습니다.',
              type: MessageType.system));
        });
        _scrollToBottom();
        _cancelAutoDecisionTimer(requestId);
        return;
      }

      setState(() {
        _messages.add(MessageItem(
            '⏱️ ${_autoDecisionTimeoutSec}초 무응답 → $modeLabel 실행',
            type: MessageType.system));
      });
      _scrollToBottom();
      _cancelAutoDecisionTimer(requestId);
      await _submitCodexDecision(request, autoPayload);
    });
  }

  Future<void> _confirmAndResolveApproval(
      Map<String, dynamic> approval, String action) async {
    final approvalId = approval['approval_id']?.toString() ?? '';
    if (approvalId.isEmpty) return;

    final policy = approval['policy'] as Map<String, dynamic>? ?? {};
    final riskLevel =
        policy['risk_level']?.toString().toLowerCase().trim() ?? 'unknown';
    final commandRaw = _approvalCommandRaw(approval);
    final requestType = _approvalRequestTypeLabel(approval);
    final requestedBy = _approvalRequestedBy(approval);
    final cwd = _approvalWorkingDirectory(approval);
    final isHighRisk = riskLevel == 'high' || riskLevel == 'critical';
    final reasons = List<String>.from(
        (policy['reasons'] as List? ?? []).map((e) => e.toString()));
    final actionLabel = action == 'approve' ? '허용' : '거부';

    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) {
            final scheme = Theme.of(sheetContext).colorScheme;
            final accentColor = action == 'approve'
                ? scheme.primary
                : Theme.of(sheetContext).colorScheme.error;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$actionLabel 하시겠어요?',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '승인 대상 명령을 확인한 뒤 결정해 주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _approvalMetaChip(
                            label: 'Risk',
                            value: riskLevel,
                            valueColor: _riskColor(riskLevel),
                          ),
                          _approvalMetaChip(label: 'Type', value: requestType),
                          _approvalMetaChip(label: 'By', value: requestedBy),
                          if (cwd.isNotEmpty)
                            _approvalMetaChip(label: 'CWD', value: cwd),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: SelectableText(
                          _truncateForLog(commandRaw, maxLength: 480),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            fontFamily: 'monospace',
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...reasons.map((reason) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $reason',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )),
                      ],
                      if (action == 'approve' && isHighRisk) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(sheetContext)
                                .colorScheme
                                .errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '고위험 명령입니다. 신뢰 가능한 요청인지 다시 확인하세요.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(sheetContext)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(false),
                              child: const Text('취소'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: accentColor,
                              ),
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(true),
                              child: Text(actionLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;

    if (!confirmed) {
      setState(() {
        _messages.add(MessageItem('🕒 승인 결정을 취소했어요: $approvalId',
            type: MessageType.system));
      });
      _scrollToBottom();
      return;
    }

    await _resolveCommandApproval(approvalId, action);
  }

  Future<void> _showRelayApprovalDetailSheet(
      Map<String, dynamic> approval) async {
    if (!mounted) return;

    final approvalId = approval['approval_id']?.toString() ?? '(unknown)';
    final commandRaw = _approvalCommandRaw(approval);
    final policy = approval['policy'] as Map<String, dynamic>? ?? {};
    final riskLevel = policy['risk_level']?.toString() ?? 'unknown';
    final reasons = List<String>.from(
        (policy['reasons'] as List? ?? []).map((e) => e.toString()));
    final createdAt = _timestampLabelFromMap(approval);
    final requestType = _approvalRequestTypeLabel(approval);
    final requestedBy = _approvalRequestedBy(approval);
    final cwd = _approvalWorkingDirectory(approval);
    final ruleId = _approvalPolicyRule(approval);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Approval detail',
                      style: Theme.of(sheetContext)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('ID: $approvalId',
                      style: TextStyle(fontSize: 12, color: scheme.onSurface)),
                  Text('Created: $createdAt',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  Text('Type: $requestType',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  Text('Requested by: $requestedBy',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (cwd.isNotEmpty)
                    Text('CWD: $cwd',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (ruleId.isNotEmpty)
                    Text('Policy rule: $ruleId',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Text(
                    commandRaw,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text('Risk: $riskLevel',
                      style: TextStyle(
                          color: _riskColor(riskLevel),
                          fontWeight: FontWeight.w700)),
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...reasons.map((reason) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $reason',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant)),
                        )),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCodexRequestDetailSheet(
      Map<String, dynamic> request) async {
    if (!mounted) return;

    final requestId = request['requestId']?.toString() ?? '(unknown)';
    final summary = _codexRequestSummary(request);
    final detailLines = List<String>.from(
        (request['detailLines'] as List? ?? []).map((e) => e.toString()));
    final choices = List<Map<String, dynamic>>.from(
        (request['choices'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));
    final timestamp = _timestampLabelFromMap(request,
        preferredKeys: const ['timestamp', 'created_at', 'createdAt']);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_codexRequestTitle(request),
                      style: Theme.of(sheetContext)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('ID: $requestId',
                      style: TextStyle(fontSize: 12, color: scheme.onSurface)),
                  Text('Time: $timestamp',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SelectableText(summary,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12)),
                  ],
                  if (detailLines.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...detailLines.map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(line,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant)),
                        )),
                  ],
                  if (choices.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Choices',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: choices
                          .map((choice) => Chip(
                                label: Text(choice['label']?.toString() ?? '-'),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadCommandEvents({int limit = 20, bool silent = false}) async {
    if (_isDemoMode) return;
    if (!_isConnected || _sessionId == null) return;
    if (_connectionType != ConnectionType.relay) return;
    if (!_isNetworkReachable) {
      if (!silent && mounted) {
        setState(() {
          _messages.add(MessageItem('📡 오프라인 상태에서는 이벤트 목록을 불러올 수 없어요.',
              type: MessageType.system));
        });
        _scrollToBottom();
      }
      return;
    }
    if (_loadingCommandEvents) return;

    if (mounted) {
      setState(() => _loadingCommandEvents = true);
    }

    try {
      final uri = _relayUri('/api/command-events', {
        'sessionId': _sessionId!,
        'limit': '$limit',
      });
      final response = await http.get(uri);
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final events = List<Map<String, dynamic>>.from(
            (data['events'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map)));
        final mergedEvents = _mergeCommandEvents(events);
        setState(() {
          _recentCommandEvents = mergedEvents;
          _pruneResolvedApprovalEventFallbacks(events);
          _loadingCommandEvents = false;
        });

        if (!silent) {
          setState(() {
            _messages.add(MessageItem('📚 Command events: ${events.length}',
                type: MessageType.system));
          });
          _scrollToBottom();
        }
      } else {
        setState(() => _loadingCommandEvents = false);
        if (!silent) {
          setState(() {
            _messages.add(MessageItem(
                '❌ command-events 조회 실패: ${body['error'] ?? 'HTTP ${response.statusCode}'}',
                type: MessageType.system));
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCommandEvents = false);
      if (!silent) {
        setState(() {
          _messages.add(MessageItem('❌ command-events 조회 오류: $e',
              type: MessageType.system));
        });
        _scrollToBottom();
      }
    }
  }

  List<Map<String, dynamic>> _mergeCommandEvents(
      List<Map<String, dynamic>> events) {
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addIfNew(Map<String, dynamic> event) {
      final approvalId = _extractApprovalIdFromCommandEvent(event);
      final status = _deriveApprovalStatusFromEvent(event) ?? '';
      final key = _approvalHistoryStatusKey(approvalId, status);
      if (key.isNotEmpty && seen.contains(key)) return;
      if (key.isNotEmpty) seen.add(key);
      merged.add(event);
    }

    for (final event in events) {
      addIfNew(event);
    }

    for (final fallback in _resolvedApprovalEventFallbacks.values) {
      addIfNew(Map<String, dynamic>.from(fallback));
    }

    merged.sort((a, b) {
      final at = _parseTimestampValue(a['timestamp']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bt = _parseTimestampValue(b['timestamp']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return merged;
  }

  void _pruneResolvedApprovalEventFallbacks(List<Map<String, dynamic>> events) {
    final seen = <String>{};
    for (final event in events) {
      final approvalId = _extractApprovalIdFromCommandEvent(event);
      final status = _deriveApprovalStatusFromEvent(event) ?? '';
      final key = _approvalHistoryStatusKey(approvalId, status);
      if (key.isNotEmpty) {
        seen.add(key);
      }
    }
    _resolvedApprovalEventFallbacks.removeWhere(
      (key, _) => seen.contains(key),
    );
  }

  Future<void> _waitForApprovalResolution(
    String approvalId, {
    required String expectedStatus,
    int attempts = 5,
    Duration interval = const Duration(milliseconds: 700),
  }) async {
    var remaining = attempts;
    while (remaining > 0 && mounted) {
      remaining -= 1;
      await Future<void>.delayed(interval);
      await _loadCommandEvents(silent: true);
      final matched = _recentCommandEvents.any((event) {
        final approvalIdFromEvent = _extractApprovalIdFromCommandEvent(event);
        if (approvalIdFromEvent != approvalId) return false;
        return _deriveApprovalStatusFromEvent(event) == expectedStatus;
      });
      if (matched) return;
    }
  }

  Future<void> _resolveCommandApproval(String approvalId, String action) async {
    if (_isDemoMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppI18n.t(
                  context, AppTextKey.demoModeDemoApprovalActionSampleMessage),
            ),
          ),
        );
      }
      return;
    }
    if (!_isConnected || _sessionId == null) return;
    if (_connectionType != ConnectionType.relay) return;
    final normalizedAction = action == 'deny' ? 'reject' : action;

    Map<String, dynamic>? approvalSnapshot;
    for (final approval in _pendingCommandApprovals) {
      if (approval['approval_id']?.toString() == approvalId) {
        approvalSnapshot = approval;
        break;
      }
    }
    final commandRaw = approvalSnapshot != null
        ? _truncateForLog(_approvalCommandRaw(approvalSnapshot), maxLength: 54)
        : '';
    final needsAssistantResponse = approvalSnapshot != null
        ? _approvalNeedsAssistantResponse(approvalSnapshot)
        : false;
    final resolvedHistoryStatus = normalizedAction == 'approve'
        ? 'approved'
        : normalizedAction == 'reject'
            ? 'rejected'
            : normalizedAction;

    try {
      final response = await http.post(
        _relayUri('/api/resolve-command-approval'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': _sessionId,
          'approvalId': approvalId,
          'action': normalizedAction,
          'resolvedBy': _deviceId,
          'reason': 'resolved via mobile app',
        }),
      );
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;
      if (response.statusCode == 200 && body['success'] == true) {
        final status =
            (body['data'] as Map<String, dynamic>? ?? {})['status'] ??
                normalizedAction;
        final normalizedStatus = status is String
            ? _normalizeApprovalStatusFromEvent({
                'approval': {'status': status},
              })
            : resolvedHistoryStatus;
        if (approvalSnapshot != null) {
          _upsertResolvedApprovalEventFallback(
            approvalSnapshot,
            status: normalizedStatus,
          );
          setState(() {
            _recentCommandEvents = _mergeCommandEvents(_recentCommandEvents);
          });
        }
        setState(() {
          if (normalizedAction == 'approve' && needsAssistantResponse) {
            _isWaitingForResponse = true;
          } else if (normalizedAction != 'approve') {
            _isWaitingForResponse = false;
          }
          _messages.add(MessageItem(
              normalizedAction == 'approve' && needsAssistantResponse
                  ? '✅ Approval 응답: $approvalId → $status · 응답 대기 유지${commandRaw.isNotEmpty ? ' · $commandRaw' : ''}'
                  : '✅ Approval 응답: $approvalId → $status${commandRaw.isNotEmpty ? ' · $commandRaw' : ''}',
              type: MessageType.system));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval $normalizedAction 완료')),
        );
        _scrollToBottom();
        await _loadCommandApprovals(silent: true);
        await _loadCommandEvents(silent: true);
        if (approvalSnapshot != null) {
          unawaited(_waitForApprovalResolution(approvalId,
              expectedStatus: normalizedStatus));
        }
      } else {
        setState(() {
          _messages.add(MessageItem(
              '❌ Approval 처리 실패($normalizedAction): ${body['error'] ?? 'HTTP ${response.statusCode}'}',
              type: MessageType.system));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages
            .add(MessageItem('❌ Approval 처리 오류: $e', type: MessageType.system));
      });
      _scrollToBottom();
    }
  }

  void _markRelayApprovalLater(Map<String, dynamic> approval) {
    final approvalId = approval['approval_id']?.toString() ?? '(unknown)';
    final commandRaw =
        _truncateForLog(_approvalCommandRaw(approval), maxLength: 54);

    if (!mounted) return;
    setState(() {
      _messages.add(MessageItem(
          '🕒 Approval 보류(Later): $approvalId${commandRaw.isNotEmpty ? ' · $commandRaw' : ''}',
          type: MessageType.system));
    });
    _scrollToBottom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppI18n.t(context, AppTextKey.demoModeDeferredApprovalNotice),
        ),
      ),
    );
  }

  bool _isTargetedToThisMobile(Map<String, dynamic> payload) {
    final targetDeviceId = payload['targetDeviceId']?.toString().trim() ?? '';
    return targetDeviceId.isEmpty || targetDeviceId == _deviceId;
  }

  void _upsertPendingCodexServerRequest(Map<String, dynamic> request) {
    final requestId = request['requestId']?.toString() ?? '';
    if (requestId.isEmpty) return;

    final next = Map<String, dynamic>.from(request);
    final existingIndex = _pendingCodexServerRequests
        .indexWhere((item) => item['requestId']?.toString() == requestId);
    if (existingIndex >= 0) {
      _pendingCodexServerRequests[existingIndex] = next;
    } else {
      _pendingCodexServerRequests.insert(0, next);
    }
  }

  void _removePendingCodexServerRequest(String requestId) {
    _pendingCodexServerRequests
        .removeWhere((item) => item['requestId']?.toString() == requestId);
    _submittingCodexRequestIds.remove(requestId);
    _cancelAutoDecisionTimer(requestId);
  }

  String _codexRequestTitle(Map<String, dynamic> request) {
    final title = request['title']?.toString().trim() ?? '';
    if (title.isNotEmpty) return title;
    switch (request['requestKind']) {
      case 'command_execution':
        return 'Codex wants to run a command';
      case 'file_change':
        return 'Codex wants to modify files';
      case 'user_input':
        return 'Codex needs more input';
      default:
        return 'Codex request';
    }
  }

  String _codexRequestSummary(Map<String, dynamic> request) {
    final summary = request['summary']?.toString().trim() ?? '';
    if (summary.isNotEmpty) return summary;
    final detailLines = List<String>.from(
        (request['detailLines'] as List? ?? []).map((e) => e.toString()));
    return detailLines.isNotEmpty ? detailLines.first : '';
  }

  Color _codexRequestAccentColor(
      BuildContext context, Map<String, dynamic> request) {
    final kind = request['requestKind']?.toString() ?? '';
    final scheme = Theme.of(context).colorScheme;
    switch (kind) {
      case 'command_execution':
      case 'file_change':
        return scheme.error;
      case 'user_input':
        return scheme.tertiary;
      default:
        return scheme.primary;
    }
  }

  Future<void> _showCodexServerRequestDialog(
      Map<String, dynamic> request) async {
    if (!mounted) return;

    final requestId = request['requestId']?.toString() ?? '';
    if (requestId.isEmpty) return;

    final requestKind = request['requestKind']?.toString() ?? '';
    final summary = _codexRequestSummary(request);
    final detailLines = List<String>.from(
        (request['detailLines'] as List? ?? []).map((e) => e.toString()));
    final choices = List<Map<String, dynamic>>.from(
        (request['choices'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));

    bool decisionSubmitted = false;
    bool deferredByLaterButton = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final accentColor = _codexRequestAccentColor(dialogContext, request);
        final scheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          icon: Icon(Icons.notification_important_rounded,
              color: accentColor, size: 32),
          title: Text(_codexRequestTitle(request)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.28)),
                  ),
                  child: Text(
                    AppI18n.t(
                        context, AppTextKey.demoModeNeedsMobileActionNotice),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                if (_autoDecisionMode != AutoDecisionMode.off &&
                    requestKind != 'user_input') ...[
                  const SizedBox(height: 10),
                  Text(
                    '응답이 ${_autoDecisionTimeoutSec}초 없으면 ${_autoDecisionModeLabel(_autoDecisionMode)}가 실행됩니다.',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SelectableText(
                    summary,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (detailLines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...detailLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                deferredByLaterButton = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Later'),
            ),
            if (requestKind == 'user_input')
              FilledButton(
                onPressed: () {
                  decisionSubmitted = true;
                  Navigator.of(dialogContext).pop();
                  _openCodexUserInputDialog(request);
                },
                child: const Text('Respond now'),
              )
            else
              ...choices.map((choice) {
                final label = choice['label']?.toString() ?? 'Respond';
                final style = choice['style']?.toString() ?? 'secondary';
                final responsePayload =
                    Map<String, dynamic>.from(choice['response'] as Map? ?? {});
                final onPressed = () {
                  decisionSubmitted = true;
                  Navigator.of(dialogContext).pop();
                  _submitCodexDecision(request, responsePayload);
                };

                if (style == 'primary') {
                  return FilledButton(
                    onPressed: onPressed,
                    child: Text(label),
                  );
                }

                return OutlinedButton(
                  onPressed: onPressed,
                  style: style == 'danger'
                      ? OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                        )
                      : null,
                  child: Text(label),
                );
              }),
          ],
        );
      },
    );

    if (!mounted || decisionSubmitted) return;
    final deferredReason = deferredByLaterButton ? 'later' : 'dismissed';
    setState(() {
      _messages.add(MessageItem(
          '🕒 ${_codexRequestTitle(request)} 보류됨 ($deferredReason)',
          type: MessageType.system));
    });
    _scrollToBottom();
  }

  Future<void> _handleCodexServerRequest(Map<String, dynamic> payload) async {
    if (!_isTargetedToThisMobile(payload)) return;

    final requestId = payload['requestId']?.toString() ?? '';
    if (requestId.isEmpty) return;
    final isNewRequest = _seenCodexRequestIds.add(requestId);
    final summary =
        _truncateForLog(_codexRequestSummary(payload), maxLength: 56);
    final requestTitle = _codexRequestTitle(payload);
    final requestKind = payload['requestKind']?.toString() ?? 'codex';
    final timestamp =
        _parseTimestampValue(payload['timestamp'])?.millisecondsSinceEpoch;

    if (!mounted) return;
    setState(() {
      _upsertPendingCodexServerRequest(payload);
      _recordCodexRequestHistory(
        requestId: requestId,
        status: 'pending',
        title: requestTitle,
        summary: summary,
        requestKind: requestKind,
        timestampMs: timestamp,
      );
      if (isNewRequest) {
        _messages.add(MessageItem(
            '📩 $requestTitle 요청 도착${summary.isNotEmpty ? ' · $summary' : ''}',
            type: MessageType.system));
      }
      _isWaitingForResponse = false;
    });
    _scrollToBottom();
    HapticFeedback.heavyImpact();
    if (isNewRequest) {
      unawaited(_maybeNotifyApprovalArrival(newCodexRequests: 1));
    }
    _scheduleAutoDecisionForCodexRequest(payload);
    unawaited(_showCodexServerRequestDialog(payload));
  }

  void _handleCodexServerRequestStatus(Map<String, dynamic> payload) {
    if (!_isTargetedToThisMobile(payload)) return;

    final requestId = payload['requestId']?.toString() ?? '';
    final status = payload['status']?.toString() ?? 'unknown';
    final message = payload['message']?.toString() ?? '';
    if (requestId.isEmpty || !mounted) return;

    setState(() {
      _removePendingCodexServerRequest(requestId);
      _recordCodexRequestHistory(
        requestId: requestId,
        status: status,
        title: _codexRequestTitle(payload),
        summary: message.isNotEmpty ? message : _codexRequestSummary(payload),
        requestKind: payload['requestKind']?.toString() ?? 'codex',
        timestampMs: _parseTimestampValue(payload['timestamp'])
                ?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      );
      final statusText = message.isNotEmpty ? message : status;
      _messages.add(MessageItem(
          'ℹ️ ${_codexRequestTitle(payload)} 상태: $statusText',
          type: MessageType.system));
    });
    _scrollToBottom();

    if (message.isNotEmpty &&
        (status == 'timed_out' || status == 'fallback_to_desktop')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _sendCodexServerRequestResponse(Map<String, dynamic> request,
      Map<String, dynamic> responsePayload) async {
    if (_isDemoMode) return;
    final requestId = request['requestId']?.toString() ?? '';
    final method = request['method']?.toString() ?? '';
    if (requestId.isEmpty || method.isEmpty) {
      throw Exception('requestId/method missing');
    }

    final message = {
      'type': 'codex_server_request_response',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'requestId': requestId,
      'method': method,
      'response': responsePayload,
      if (_currentClientId != null) 'clientId': _currentClientId,
    };

    if (_connectionType == ConnectionType.local) {
      if (_localWebSocket == null) {
        throw Exception('Local WebSocket not connected');
      }
      _localWebSocket!.sink.add(jsonEncode(message));
      return;
    }

    if (_sessionId == null) {
      throw Exception('Session ID is required for relay connection');
    }

    final response = await http.post(
      _relayUri('/api/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': _sessionId,
        'deviceId': _deviceId,
        'deviceType': 'mobile',
        'type': 'codex_server_request_response',
        'data': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    if (response.body.isNotEmpty) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) {
        throw Exception(body['error']?.toString() ?? 'Relay send failed');
      }
    }
  }

  Future<void> _submitCodexDecision(Map<String, dynamic> request,
      Map<String, dynamic> responsePayload) async {
    if (_isDemoMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppI18n.t(
                  context, AppTextKey.demoModeDemoRequestActionSampleMessage),
            ),
          ),
        );
      }
      return;
    }
    final requestId = request['requestId']?.toString() ?? '';
    if (requestId.isEmpty || !mounted) return;
    _cancelAutoDecisionTimer(requestId);
    final decisionLabel = _describeDecisionPayload(responsePayload);

    setState(() {
      _submittingCodexRequestIds.add(requestId);
    });

    try {
      await _sendCodexServerRequestResponse(request, responsePayload);
      if (!mounted) return;
      setState(() {
        _removePendingCodexServerRequest(requestId);
        _recordCodexRequestHistory(
          requestId: requestId,
          status: 'submitted',
          title: _codexRequestTitle(request),
          summary: decisionLabel,
          requestKind: request['requestKind']?.toString() ?? 'codex',
          resolvedBy: _deviceId,
        );
        _messages.add(MessageItem(
            '✅ ${_codexRequestTitle(request)} 응답 전송됨 → $decisionLabel',
            type: MessageType.system));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submittingCodexRequestIds.remove(requestId);
        _messages.add(MessageItem('❌ 요청 응답 실패($decisionLabel): $e',
            type: MessageType.system));
      });
      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('응답 전송 실패: $e')),
      );
    }
  }

  Future<void> _openCodexUserInputDialog(Map<String, dynamic> request) async {
    final requestId = request['requestId']?.toString() ?? '';
    final rawQuestions = List<Map<String, dynamic>>.from(
        (request['questions'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));
    if (requestId.isEmpty || rawQuestions.isEmpty || !mounted) return;

    final textControllers = <String, TextEditingController>{};
    final selectedValues = <String, String>{};

    for (final question in rawQuestions) {
      final id = question['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final options = List<Map<String, dynamic>>.from(
          (question['options'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));
      if (options.isEmpty) {
        textControllers[id] = TextEditingController();
      } else {
        final firstLabel = options.first['label']?.toString() ?? '';
        if (firstLabel.isNotEmpty) {
          selectedValues[id] = firstLabel;
        }
      }
    }

    final submitted = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setLocalState) {
          return AlertDialog(
            title: Text(_codexRequestTitle(request)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rawQuestions.map((question) {
                  final id = question['id']?.toString() ?? '';
                  final header =
                      question['header']?.toString() ?? 'Input required';
                  final prompt = question['question']?.toString() ?? '';
                  final isSecret = question['isSecret'] == true;
                  final options = List<Map<String, dynamic>>.from(
                      (question['options'] as List? ?? [])
                          .map((e) => Map<String, dynamic>.from(e as Map)));

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(header,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (prompt.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(prompt, style: const TextStyle(fontSize: 12)),
                        ],
                        const SizedBox(height: 8),
                        if (options.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: selectedValues[id],
                            items: options
                                .map((option) => DropdownMenuItem<String>(
                                      value: option['label']?.toString() ?? '',
                                      child: Text(
                                          option['label']?.toString() ?? ''),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setLocalState(() {
                                if (value != null) {
                                  selectedValues[id] = value;
                                }
                              });
                            },
                          )
                        else
                          TextField(
                            controller: textControllers[id],
                            obscureText: isSecret,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final answers = <String, dynamic>{};
                  for (final question in rawQuestions) {
                    final id = question['id']?.toString() ?? '';
                    if (id.isEmpty) continue;
                    final options = List<Map<String, dynamic>>.from(
                        (question['options'] as List? ?? [])
                            .map((e) => Map<String, dynamic>.from(e as Map)));
                    final value = options.isNotEmpty
                        ? (selectedValues[id] ?? '')
                        : textControllers[id]?.text.trim() ?? '';
                    if (value.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('모든 입력을 채워주세요')),
                      );
                      return;
                    }
                    answers[id] = {
                      'answers': [value]
                    };
                  }
                  Navigator.of(dialogContext).pop({'answers': answers});
                },
                child: const Text('Submit'),
              ),
            ],
          );
        });
      },
    );

    for (final controller in textControllers.values) {
      controller.dispose();
    }

    if (submitted == null) return;
    await _submitCodexDecision(request, submitted);
  }

  Color _riskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  List<Map<String, dynamic>> _buildDecisionTimelineEntries() {
    final entries = <Map<String, dynamic>>[];

    for (final approval in _pendingCommandApprovals) {
      final commandRaw = _approvalCommandRaw(approval);
      final requestedBy = _approvalRequestedBy(approval);
      final policy = approval['policy'] as Map<String, dynamic>? ?? {};
      final riskLevel = policy['risk_level']?.toString() ?? 'unknown';
      final when =
          _parseTimestampValue(approval['created_at']) ?? DateTime.now();

      entries.add({
        'kind': 'approval_pending',
        'time': when,
        'title': '승인 대기: $commandRaw',
        'subtitle': 'by $requestedBy · risk: $riskLevel',
        'approvalId': approval['approval_id']?.toString(),
        'payload': approval,
      });
    }

    for (final request in _pendingCodexServerRequests) {
      final title = _codexRequestTitle(request);
      final summary = _codexRequestSummary(request);
      final when = _parseTimestampValue(request['timestamp']) ?? DateTime.now();

      entries.add({
        'kind': 'codex_request_pending',
        'time': when,
        'title': '요청 대기: $title',
        'subtitle': summary.isNotEmpty ? summary : '모바일 응답 필요',
        'approvalId': null,
        'payload': request,
      });
    }

    for (final event in _recentCommandEvents) {
      final result = event['result'] as Map<String, dynamic>? ?? {};
      final command = event['command'] as Map<String, dynamic>? ?? {};
      final approval = event['approval'] as Map<String, dynamic>? ?? {};
      final status = result['status']?.toString() ?? 'unknown';
      final raw = command['raw']?.toString() ?? '(unknown)';
      final approvalStatus = approval['status']?.toString() ?? 'not_required';
      final when = _parseTimestampValue(event['timestamp']) ??
          _parseTimestampValue(event['created_at']) ??
          DateTime.now();

      entries.add({
        'kind': 'command_event',
        'time': when,
        'title': '실행 결과: $status • $raw',
        'subtitle': 'approval: $approvalStatus',
        'approvalId': _extractApprovalIdFromCommandEvent(event),
        'payload': event,
      });
    }

    entries.sort((a, b) {
      final at = a['time'] as DateTime;
      final bt = b['time'] as DateTime;
      return bt.compareTo(at);
    });
    return entries;
  }

  String? _extractApprovalIdFromCommandEvent(Map<String, dynamic> event) {
    final direct = event['approval_id']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final metadata = event['metadata'] as Map<String, dynamic>? ?? {};
    final metadataId = metadata['approval_id']?.toString().trim();
    if (metadataId != null && metadataId.isNotEmpty) return metadataId;

    final approval = event['approval'] as Map<String, dynamic>? ?? {};
    final approvalId = approval['approval_id']?.toString().trim();
    if (approvalId != null && approvalId.isNotEmpty) return approvalId;

    return null;
  }

  IconData _timelineIcon(String kind, String title) {
    if (kind == 'approval_pending') return Icons.lock_clock;
    if (kind == 'codex_request_pending') return Icons.pending_actions;
    if (title.contains('success')) return Icons.check_circle_outline;
    if (title.contains('error') || title.contains('cancelled')) {
      return Icons.error_outline;
    }
    return Icons.timeline;
  }

  String _prettyJson(dynamic payload) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(payload);
    } catch (_) {
      return payload?.toString() ?? '(empty)';
    }
  }

  Future<void> _showTimelineEntryDetailSheet(Map<String, dynamic> entry) async {
    if (!mounted) return;
    final kind = entry['kind']?.toString() ?? 'unknown';
    final title = entry['title']?.toString() ?? '(untitled)';
    final subtitle = entry['subtitle']?.toString() ?? '';
    final time = entry['time'] as DateTime? ?? DateTime.now();
    final approvalId = entry['approvalId']?.toString();
    final payload = entry['payload'];
    final prettyPayload = _prettyJson(payload);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text('kind: $kind',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  Text('time: ${_formatTime(time)}',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (subtitle.isNotEmpty)
                    Text('summary: $subtitle',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (approvalId != null && approvalId.isNotEmpty)
                    Text('approvalId: $approvalId',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: prettyPayload));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('타임라인 payload가 복사되었습니다.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy payload'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    prettyPayload,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: scheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 대화 메시지만 제거 (시스템/로그 메시지는 유지) - 현재 세션만 표시할 때 사용
  void _clearConversationMessages() {
    _messages.removeWhere((m) {
      switch (m.type) {
        case MessageType.userPrompt:
        case MessageType.chatResponse:
        case MessageType.chatResponseHeader:
        case MessageType.chatResponseDivider:
        case MessageType.chatResponseChunk:
        case MessageType.chatResponseComplete:
          return true;
        default:
          return false;
      }
    });
  }

  /// get_chat_history 응답 entries를 메인 메시지 목록(_messages)에 반영
  /// [skipIfExists] true면 이미 같은 userMessage가 있으면 해당 entry 건너뜀 (중복 방지)
  void _applyChatHistoryToMessages(List<Map<String, dynamic>> entries,
      {bool skipIfExists = false, bool replaceConversation = false}) {
    if (replaceConversation) _clearConversationMessages();
    if (entries.isEmpty) return;
    final oldestFirst = List<Map<String, dynamic>>.from(entries.reversed);
    for (final entry in oldestFirst) {
      final userMsg = entry['userMessage'] as String? ?? '';
      final assistantMsg = entry['assistantResponse'] as String? ?? '';
      if (skipIfExists &&
          _messages.any(
              (m) => m.type == MessageType.userPrompt && m.text == userMsg)) {
        continue;
      }
      final agentMode = entry['agentMode'] as String?;
      _messages.add(MessageItem(userMsg,
          type: MessageType.userPrompt, agentMode: agentMode));
      _messages.add(MessageItem('', type: MessageType.chatResponseDivider));
      _messages.add(MessageItem('🤖 Codex Response',
          type: MessageType.chatResponseHeader));
      _messages.add(MessageItem(assistantMsg, type: MessageType.chatResponse));
      _messages.add(MessageItem('', type: MessageType.chatResponseDivider));
    }
  }

  // 연결 상태 확인 및 필요시 재연결
  void _checkConnectionState() {
    if (_isDemoMode) return;
    if (_connectionType == ConnectionType.local) {
      // 로컬 연결: WebSocket 상태 확인
      if (_localWebSocket == null && _isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _messages.add(MessageItem(
                '⚠️ Local connection lost, please reconnect',
                type: MessageType.system));
          });
        }
      }
    } else {
      // 릴레이 연결: 세션 ID 확인
      if (_sessionId == null && _isConnected) {
        // 세션이 null인데 연결 상태가 true면 상태 불일치
        if (mounted) {
          setState(() {
            _isConnected = false;
            _messages.add(MessageItem('⚠️ Connection lost, please reconnect',
                type: MessageType.system));
          });
        }
      } else if (_sessionId != null && !_isConnected) {
        // 세션이 있는데 연결 상태가 false면 상태 불일치
        if (mounted) {
          setState(() {
            _isConnected = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtonVisibility);
    WidgetsBinding.instance.removeObserver(this);
    AppSettings().removeListener(_onAppSettingsChanged);
    _cancelCapabilitiesSequenceTimers();
    _connectivitySubscription?.cancel();
    _stopPolling();
    _setTraceAutoRefresh(false);
    _localWebSocket?.sink.close();
    _commandController.dispose();
    _sessionIdController.dispose();
    _localIpController.dispose();
    _localPortController.dispose();
    _traceIdController.dispose();
    _scrollController.dispose();
    _sessionIdFocusNode.dispose();
    _localIpFocusNode.dispose();
    _commandFocusNode.dispose();
    super.dispose();
  }

  /// 메시지 리스트 위젯 (필터·검색 적용된 목록, 컴팩트/일반 뷰 공용)
  Widget _buildMessageList() {
    if (_displayMessages.isEmpty && !_isWaitingForResponse) {
      final isSearchActive = _searchQuery.trim().isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _messages.isEmpty
                  ? Icons.chat_bubble_outline
                  : (isSearchActive ? Icons.search_off : Icons.filter_alt),
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isSearchActive
                  ? AppI18n.t(
                      context, AppTextKey.connectionMessageNoSearchResults)
                  : AppI18n.t(context, AppTextKey.connectionMessageNoMessages),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_messages.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                AppI18n.t(context, AppTextKey.connectionMessageStartHint),
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _displayMessages.length + (_isWaitingForResponse ? 1 : 0),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) {
        if (index == _displayMessages.length && _isWaitingForResponse) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppI18n.t(
                    context,
                    _responseIndicatorState == ResponseIndicatorState.receiving
                        ? AppTextKey.messageReceiving
                        : AppTextKey.messageWaiting,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        final message = _displayMessages[index];
        return GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('메시지가 클립보드에 복사되었습니다'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: _buildMessageItem(message),
        );
      },
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// 메시지 리스트 + 맨 위/맨 아래 스크롤 버튼 (스크롤 가능할 때만, 위/아래 각각 배치)
  Widget _buildMessageListWithScrollButtons() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateScrollButtonVisibility());
    return Stack(
      children: [
        _buildMessageList(),
        // 맨 위로: 상단 오른쪽, 위로 스크롤 가능할 때만
        if (_canScrollUp)
          Positioned(
            top: 8,
            right: 8,
            child: Tooltip(
              message: '맨 위로',
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _scrollToTop,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_upward, size: 22),
                  ),
                ),
              ),
            ),
          ),
        // 맨 아래로: 하단 오른쪽, 아래로 스크롤 가능할 때만
        if (_canScrollDown)
          Positioned(
            bottom: 8,
            right: 8,
            child: Tooltip(
              message: '맨 아래로',
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _scrollToBottom,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_downward, size: 22),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 컴팩트 뷰: 메시지 영역 크게 + 한줄 프롬프트만 (앱바 아이콘으로 전체 화면 복귀)
  Widget _buildCompactBody() {
    return Column(
      children: [
        Expanded(child: _buildMessageListWithScrollButtons()),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commandController,
                  focusNode: _commandFocusNode,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText:
                        AppI18n.t(context, AppTextKey.chatPromptInputHint),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onSubmitted: (value) {
                    unawaited(_submitPromptFromInput(newSession: false));
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  unawaited(_submitPromptFromInput(newSession: false));
                },
                icon: const Icon(Icons.send),
                tooltip: AppI18n.t(context, AppTextKey.chatSendTooltip),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatGptLikeBody() {
    final selectedModelValue = _selectedModel == 'auto' ||
            _availableModels.any((item) =>
                (item['model'] ?? '').toString().trim() == _selectedModel)
        ? _selectedModel
        : 'auto';
    final selectedReasoningValue = _selectedReasoningEffort == 'auto' ||
            _getAvailableReasoningEffortsForModel(_selectedModel)
                .contains(_selectedReasoningEffort)
        ? _selectedReasoningEffort
        : 'auto';
    final modelItems = <PromptOptionItem>[
      const PromptOptionItem(value: 'auto', label: 'Auto (기본값)'),
      ..._availableModels.map((item) {
        final model = (item['model'] ?? '').toString().trim();
        return PromptOptionItem(
          value: model,
          label: _getModelDisplayName(model),
        );
      }),
    ];
    final reasoningItems = <PromptOptionItem>[
      const PromptOptionItem(value: 'auto', label: 'Auto'),
      ..._getAvailableReasoningEffortsForModel(_selectedModel).map(
        (effort) => PromptOptionItem(
          value: effort,
          label: _getReasoningEffortDisplayName(effort),
        ),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: _buildMessageListWithScrollButtons(),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChatPromptOptionsBar(
                  showLoading: _capabilitiesLoading && !_capabilitiesLoaded,
                  loadingLabel: _modelCatalogLoadingText,
                  selectedModelLabel: _getModelDisplayName(selectedModelValue),
                  selectedReasoningLabel:
                      _getReasoningEffortDisplayName(selectedReasoningValue),
                  modelItems: modelItems,
                  reasoningItems: reasoningItems,
                  onModelSelected: (value) {
                    setState(() {
                      _selectedModel = _normalizeModel(value);
                      _selectedReasoningEffort = _normalizeReasoningEffort(
                          _selectedReasoningEffort, _selectedModel);
                    });
                    unawaited(AppSettings().setDefaultModel(_selectedModel));
                  },
                  onReasoningSelected: (value) {
                    setState(() {
                      _selectedReasoningEffort =
                          _normalizeReasoningEffort(value, _selectedModel);
                    });
                    unawaited(
                      AppSettings()
                          .setDefaultReasoningEffort(_selectedReasoningEffort),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commandController,
                        focusNode: _commandFocusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: _isWaitingForResponse
                              ? AppI18n.t(context,
                                  AppTextKey.chatPromptInputHintGenerating)
                              : AppI18n.t(
                                  context, AppTextKey.chatPromptInputHint),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(26),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) {
                          unawaited(_submitPromptFromInput(newSession: false));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isWaitingForResponse
                          ? null
                          : () {
                              unawaited(
                                  _submitPromptFromInput(newSession: false));
                            },
                      icon: const Icon(Icons.arrow_upward),
                      tooltip: AppI18n.t(context, AppTextKey.chatSendTooltip),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionFirstScaffold() {
    final history = AppSettings().connectionHistory;
    final isBusy = _isReconnecting || _isConnectionActionInProgress;
    final actionLabel = _connectionActionLabel ??
        (_connectionType == ConnectionType.local
            ? AppI18n.t(context, AppTextKey.connectionActionLocalConnecting)
            : AppI18n.t(context, AppTextKey.connectionActionRelayConnecting));
    return Scaffold(
      appBar: AppBar(
        title: Text(AppI18n.t(context, AppTextKey.homeConnectionTitle)),
        actions: [
          _buildExitDemoModeButton(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppI18n.t(context, AppTextKey.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDemoMode: _isDemoMode,
                    onExitDemoMode: widget.onExitDemoMode,
                    onEnterDemoMode: widget.onEnterDemoMode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        children: [
          _buildDemoModeGuideBanner(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppI18n.t(context, AppTextKey.connectionIntroTitle),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppI18n.t(context, AppTextKey.connectionIntroDescription),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<ConnectionType>(
                  segments: [
                    ButtonSegment<ConnectionType>(
                      value: ConnectionType.local,
                      label: Text(
                        AppI18n.t(context, AppTextKey.localServerMode),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                      icon: Icon(Icons.computer, size: 18),
                    ),
                    ButtonSegment<ConnectionType>(
                      value: ConnectionType.relay,
                      label: Text(
                        AppI18n.t(context, AppTextKey.relayServerMode),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                      icon: Icon(Icons.cloud, size: 18),
                    ),
                  ],
                  selected: {_connectionType},
                  style: SegmentedButton.styleFrom(
                    selectedForegroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    selectedBackgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.4),
                    ),
                  ),
                  showSelectedIcon: true,
                  onSelectionChanged: isBusy
                      ? null
                      : (selection) {
                          setState(() {
                            _connectionType = selection.first;
                          });
                        },
                ),
                const SizedBox(height: 14),
                if (_connectionType == ConnectionType.local)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _localIpController,
                          focusNode: _localIpFocusNode,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'PC IP',
                            hintText: '192.168.0.10',
                            prefixIcon: Icon(Icons.lan_outlined),
                          ),
                          enabled: !isBusy,
                          onSubmitted: (_) => unawaited(_connect()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 104,
                        child: TextField(
                          controller: _localPortController,
                          decoration: const InputDecoration(
                            labelText: '포트',
                            hintText: '8766',
                          ),
                          keyboardType: TextInputType.number,
                          enabled: !isBusy,
                          onSubmitted: (_) => unawaited(_connect()),
                        ),
                      ),
                    ],
                  )
                else
                  TextField(
                    controller: _sessionIdController,
                    focusNode: _sessionIdFocusNode,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Session ID',
                      hintText: 'ABC123',
                      prefixIcon: Icon(Icons.cloud_outlined),
                    ),
                    enabled: !isBusy,
                    onSubmitted: (_) => unawaited(_connect()),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isBusy
                        ? null
                        : () {
                            unawaited(_connect());
                          },
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(isBusy
                        ? AppI18n.t(context, AppTextKey.connectingAction)
                        : AppI18n.t(context, AppTextKey.connectAction)),
                  ),
                ),
                if (!_isDemoMode) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(
                              isDemoMode: _isDemoMode,
                              onExitDemoMode: widget.onExitDemoMode,
                              onEnterDemoMode: widget.onEnterDemoMode,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(
                          AppI18n.t(context, AppTextKey.quickOpenSettings)),
                    ),
                  ),
                ],
                if (_isConnectionActionInProgress) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_isReconnecting) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _forceStopReconnect,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(
                          AppI18n.t(context, AppTextKey.forceStopReconnect)),
                    ),
                  ),
                ],
                if (_lastConnectionError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${AppI18n.t(context, AppTextKey.lastErrorLabel)}: $_lastConnectionError',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              AppI18n.t(context, AppTextKey.recentConnections),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: history.map((item) {
                  return ListTile(
                    leading: Icon(
                      item.type == ConnectionType.local
                          ? Icons.computer_outlined
                          : Icons.cloud_outlined,
                    ),
                    title: Text(item.displayText),
                    subtitle: Text(item.relativeTimeForLanguage(
                        isEnglish: AppI18n.isEnglish(context))),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: isBusy ? null : () => _connectFromHistory(item),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _homeTabTitle(HomeTab tab) {
    switch (tab) {
      case HomeTab.chat:
        return AppI18n.t(context, AppTextKey.homeTabChatTitle);
      case HomeTab.approvals:
        return AppI18n.t(context, AppTextKey.homeTabApprovalsTitle);
      case HomeTab.sessions:
        return AppI18n.t(context, AppTextKey.homeTabSessionsTitle);
      case HomeTab.settings:
        return AppI18n.t(context, AppTextKey.homeTabSettingsTitle);
    }
  }

  String _homeTabSubtitle(HomeTab tab) {
    switch (tab) {
      case HomeTab.chat:
        return _isConnected
            ? AppI18n.t(context, AppTextKey.homeTabChatSubtitleConnected)
            : AppI18n.t(context, AppTextKey.homeTabChatSubtitleDisconnected);
      case HomeTab.approvals:
        return AppI18n.t(context, AppTextKey.homeTabApprovalsSubtitle);
      case HomeTab.sessions:
        return AppI18n.t(context, AppTextKey.homeTabSessionsSubtitle);
      case HomeTab.settings:
        return AppI18n.t(context, AppTextKey.homeTabSettingsSubtitle);
    }
  }

  Future<void> _selectHomeTab(HomeTab tab) async {
    if (!mounted) return;
    setState(() {
      _selectedHomeTab = tab;
      if (tab != HomeTab.approvals && _traceAutoRefresh) {
        _setTraceAutoRefresh(false);
      }
    });

    if (!_isConnected) return;
    if (tab == HomeTab.approvals && _connectionType == ConnectionType.relay) {
      unawaited(_loadCommandApprovals(silent: true));
      unawaited(_loadCommandEvents(silent: true));
      unawaited(_loadRecentTraceIds());
      if (_traceIdController.text.trim().isNotEmpty) {
        unawaited(_loadTraceTimeline(silent: true));
      }
    }
    if (tab == HomeTab.sessions) {
      unawaited(_loadSessionInfo());
    }
  }

  Widget _buildApprovalsTabBody() {
    return ApprovalsTabView(
      isConnected: _isConnected,
      isRelayMode: _connectionType == ConnectionType.relay,
      pendingCodexServerRequests: _pendingCodexServerRequests,
      pendingCommandApprovals: _pendingCommandApprovals,
      processedCommandApprovals: _buildResolvedApprovalHistoryEntries(),
      submittingCodexRequestIds: _submittingCodexRequestIds,
      subtitle: _homeTabSubtitle(HomeTab.approvals),
      onOpenChat: () {
        unawaited(_selectHomeTab(HomeTab.chat));
      },
      onRefresh: () async {
        await _loadCommandApprovals(silent: true);
        await _loadCommandEvents(silent: true);
        await _loadRecentTraceIds();
        if (_traceIdController.text.trim().isNotEmpty) {
          await _loadTraceTimeline(silent: true);
        }
      },
      codexRequestTitle: _codexRequestTitle,
      codexRequestSummary: _codexRequestSummary,
      codexRequestAccentColor: _codexRequestAccentColor,
      onShowCodexRequestDetail: _showCodexRequestDetailSheet,
      onOpenCodexUserInputDialog: _openCodexUserInputDialog,
      onSubmitCodexDecision: _submitCodexDecision,
      approvalRequestTypeLabel: _approvalRequestTypeLabel,
      approvalCommandRaw: _approvalCommandRaw,
      approvalRequestedBy: _approvalRequestedBy,
      onResolveCommandApproval: (approval, action) {
        unawaited(_confirmAndResolveApproval(approval, action));
      },
      onMarkRelayApprovalLater: _markRelayApprovalLater,
      truncateForLog: _truncateForLog,
      tracePanel: TraceTimelinePanel(
        enabled: _isConnected && _connectionType == ConnectionType.relay,
        traceIdController: _traceIdController,
        recentTraceIds: _recentTraceIds,
        loading: _loadingTraceTimeline,
        autoRefresh: _traceAutoRefresh,
        error: _traceTimelineError,
        timeline: _traceTimeline,
        onRefreshRecent: () {
          unawaited(_loadRecentTraceIds());
        },
        onFetchTimeline: () {
          unawaited(_loadTraceTimeline());
        },
        onSelectRecent: (traceId) {
          _traceIdController.text = traceId;
          unawaited(_loadTraceTimeline(traceId: traceId));
        },
        onAutoRefreshChanged: (enabled) {
          setState(() {
            _setTraceAutoRefresh(enabled);
          });
        },
        onCopyReport: () {
          unawaited(_copyTraceTimelineReport());
        },
      ),
    );
  }

  Widget _buildSessionsTabBody() {
    return SessionsTabView(
      isConnected: _isConnected,
      connectionType: _connectionType,
      sessionId: _sessionId,
      currentCodexSessionId: _currentCodexSessionId,
      connectionHistory: AppSettings().connectionHistory,
      subtitle: _homeTabSubtitle(HomeTab.sessions),
      onRefresh: () {
        unawaited(_loadSessionInfo());
      },
      onDisconnect: _disconnect,
      onOpenChat: () {
        unawaited(_selectHomeTab(HomeTab.chat));
      },
      onConnectFromHistory: _connectFromHistory,
    );
  }

  Widget _buildSettingsTabBody() {
    return SettingsTabView(
      settings: AppSettings(),
      subtitle: _homeTabSubtitle(HomeTab.settings),
      onOpenSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SettingsPage(
              isDemoMode: _isDemoMode,
              onExitDemoMode: widget.onExitDemoMode,
              onEnterDemoMode: widget.onEnterDemoMode,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return _buildConnectionFirstScaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'images/app_icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Codex Remote',
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _homeTabTitle(_selectedHomeTab),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _buildExitDemoModeButton(),
          // 응답 대기 중 인디케이터
          if (_isWaitingForResponse)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppI18n.t(
                        context,
                        _responseIndicatorState ==
                                ResponseIndicatorState.receiving
                            ? AppTextKey.homeTabReceivingResponse
                            : AppTextKey.homeTabPendingResponse,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 설정 버튼
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: _selectedHomeTab == HomeTab.settings
                ? AppI18n.t(context, AppTextKey.openFullSettings)
                : AppI18n.t(context, AppTextKey.settingsTabHint),
            onPressed: () {
              if (_selectedHomeTab == HomeTab.settings) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      isDemoMode: _isDemoMode,
                      onExitDemoMode: widget.onExitDemoMode,
                      onEnterDemoMode: widget.onEnterDemoMode,
                    ),
                  ),
                );
                return;
              }
              unawaited(_selectHomeTab(HomeTab.settings));
            },
          ),
        ],
      ),
      body: _wrapWithDemoModeGuide(
        _selectedHomeTab == HomeTab.chat
            ? (_isCompactView && _isConnected
                ? _buildChatGptLikeBody()
                : Column(
                    children: [
                      // 최상단: 연결 상태 및 설정 카드
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Card(
                          child: ExpansionTile(
                            controller: _expansionTileController,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isConnected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isConnected
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                color: _isConnected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              _isConnected
                                  ? AppI18n.t(
                                      context, AppTextKey.statusConnected)
                                  : AppI18n.t(
                                      context, AppTextKey.statusNotConnected),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isConnected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                            subtitle: Text(
                              _isConnected
                                  ? (_connectionType == ConnectionType.local
                                      ? AppI18n.t(
                                          context, AppTextKey.localServerMode)
                                      : (_sessionId != null
                                          ? '${AppI18n.t(context, AppTextKey.relayServerMode)} • ${AppI18n.t(context, AppTextKey.sessionLabel)} $_sessionId'
                                          : AppI18n.t(context,
                                              AppTextKey.relayServerMode)))
                                  : AppI18n.t(
                                      context, AppTextKey.setConnectionHint),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            initiallyExpanded: !_isConnected, // 연결 안 됨일 때만 펼침
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // 연결 타입 선택
                                    Text(
                                      AppI18n.t(context,
                                          AppTextKey.connectionTypeLabel),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SegmentedButton<ConnectionType>(
                                      segments: [
                                        ButtonSegment<ConnectionType>(
                                          value: ConnectionType.local,
                                          label: Text(
                                            AppI18n.t(context,
                                                AppTextKey.localServerMode),
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.fade,
                                          ),
                                          icon: Icon(Icons.computer, size: 18),
                                        ),
                                        ButtonSegment<ConnectionType>(
                                          value: ConnectionType.relay,
                                          label: Text(
                                            AppI18n.t(context,
                                                AppTextKey.relayServerMode),
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.fade,
                                          ),
                                          icon: Icon(Icons.cloud, size: 18),
                                        ),
                                      ],
                                      selected: {_connectionType},
                                      style: SegmentedButton.styleFrom(
                                        selectedForegroundColor:
                                            Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                        selectedBackgroundColor:
                                            Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                      showSelectedIcon: true,
                                      onSelectionChanged: _isConnected
                                          ? null
                                          : (Set<ConnectionType> newSelection) {
                                              setState(() {
                                                _connectionType =
                                                    newSelection.first;
                                              });
                                            },
                                    ),
                                    const SizedBox(height: 16),
                                    // 로컬 서버 연결 UI
                                    if (_connectionType ==
                                        ConnectionType.local) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _localIpController,
                                              focusNode: _localIpFocusNode,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'PC IP (Extension이 실행 중인 PC)',
                                                hintText: '192.168.0.10',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.all(12),
                                                prefixIcon:
                                                    Icon(Icons.computer),
                                                helperText:
                                                    '이전에 사용한 IP 주소가 자동으로 표시됩니다',
                                              ),
                                              enabled: !_isConnected,
                                              keyboardType:
                                                  TextInputType.number,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onSubmitted: (value) {
                                                if (!_isConnected) {
                                                  unawaited(_connect());
                                                }
                                              },
                                              onChanged: (value) {
                                                if (value.trim().isNotEmpty) {
                                                  _saveConnectionSettings();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 110,
                                            child: TextField(
                                              controller: _localPortController,
                                              decoration: const InputDecoration(
                                                labelText: '포트',
                                                hintText: '8766',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.all(12),
                                              ),
                                              enabled: !_isConnected,
                                              keyboardType:
                                                  TextInputType.number,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onSubmitted: (value) {
                                                if (!_isConnected) {
                                                  unawaited(_connect());
                                                }
                                              },
                                              onChanged: (value) {
                                                if (value.trim().isNotEmpty) {
                                                  _saveConnectionSettings();
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer
                                              .withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiary),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'PC와 모바일이 같은 네트워크에 있어야 합니다 (기본 포트 8766)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      // 릴레이 서버 연결 UI
                                      TextField(
                                        controller: _sessionIdController,
                                        focusNode: _sessionIdFocusNode,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Session ID (PC에서 먼저 생성·연결한 ID)',
                                          hintText: 'ABC123',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.all(12),
                                          prefixIcon: Icon(Icons.cloud),
                                          helperText:
                                              'PC(익스텐션) 상태줄 클릭 → 세션 ID 생성 후 같은 ID 입력',
                                        ),
                                        enabled: !_isConnected,
                                        keyboardType: TextInputType.text,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (value) {
                                          if (!_isConnected) {
                                            unawaited(_connect());
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '먼저 PC(익스텐션)에서 상태줄을 클릭해 세션 ID를 생성·연결한 뒤, 여기에 같은 ID를 입력하세요.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    // 최근 연결 목록
                                    if (!_isConnected &&
                                        AppSettings()
                                            .connectionHistory
                                            .isNotEmpty) ...[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppI18n.t(
                                                    context,
                                                    AppTextKey
                                                        .recentConnections),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              Text(
                                                AppI18n.t(
                                                    context,
                                                    AppTextKey
                                                        .tapReconnectHint),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('전체 삭제'),
                                                  content: const Text(
                                                    '최근 연결 목록을 모두 삭제하시겠습니까?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(false),
                                                      child: const Text('취소'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(true),
                                                      child:
                                                          const Text('전체 삭제'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await AppSettings()
                                                    .clearConnectionHistory();
                                              }
                                            },
                                            icon: const Icon(Icons.delete_sweep,
                                                size: 18),
                                            label: const Text('전체 삭제'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: AppSettings()
                                              .connectionHistory
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final index = entry.key;
                                            final item = entry.value;
                                            final isLast = index ==
                                                AppSettings()
                                                        .connectionHistory
                                                        .length -
                                                    1;
                                            return Column(
                                              children: [
                                                Tooltip(
                                                  message: '탭하여 재연결',
                                                  child: InkWell(
                                                    onTap: () =>
                                                        _connectFromHistory(
                                                            item),
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                      top: index == 0
                                                          ? const Radius
                                                              .circular(12)
                                                          : Radius.zero,
                                                      bottom: isLast
                                                          ? const Radius
                                                              .circular(12)
                                                          : Radius.zero,
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 10),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(6),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: item.type ==
                                                                      ConnectionType
                                                                          .local
                                                                  ? Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .secondaryContainer
                                                                  : Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primaryContainer,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Icon(
                                                              item.type ==
                                                                      ConnectionType
                                                                          .local
                                                                  ? Icons
                                                                      .computer
                                                                  : Icons.cloud,
                                                              size: 14,
                                                              color: item.type ==
                                                                      ConnectionType
                                                                          .local
                                                                  ? Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSecondaryContainer
                                                                  : Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onPrimaryContainer,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  item.displayText,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface,
                                                                    fontFamily:
                                                                        'monospace',
                                                                  ),
                                                                ),
                                                                Text(
                                                                  item.relativeTimeForLanguage(
                                                                      isEnglish:
                                                                          AppI18n.isEnglish(
                                                                              context)),
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .settings_ethernet,
                                                            size: 20,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              size: 20,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .error,
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              final confirm =
                                                                  await showDialog<
                                                                      bool>(
                                                                context:
                                                                    context,
                                                                builder: (ctx) =>
                                                                    AlertDialog(
                                                                  title: const Text(
                                                                      '연결 삭제'),
                                                                  content: Text(
                                                                    '${item.displayText} 항목을 삭제하시겠습니까?',
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(ctx).pop(false),
                                                                      child: const Text(
                                                                          '취소'),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(ctx).pop(true),
                                                                      child: const Text(
                                                                          '삭제'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                              if (confirm ==
                                                                  true) {
                                                                await AppSettings()
                                                                    .removeConnectionHistory(
                                                                        item);
                                                              }
                                                            },
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints(
                                                                    minWidth:
                                                                        32,
                                                                    minHeight:
                                                                        32),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (!isLast)
                                                  Divider(
                                                    height: 1,
                                                    indent: 12,
                                                    endIndent: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline
                                                        .withOpacity(0.2),
                                                  ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    // 재연결 중 상태 표시
                                    if (_isReconnecting) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer
                                              .withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '재연결 시도 중... ($_reconnectAttempts회)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _forceStopReconnect,
                                              child: const Text('취소',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    // 연결 에러 표시
                                    if (_lastConnectionError != null &&
                                        !_isConnected &&
                                        !_isReconnecting) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .errorContainer
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '연결 실패: ${_lastConnectionError!.length > 50 ? '${_lastConnectionError!.substring(0, 50)}...' : _lastConnectionError}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onErrorContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: _isConnected ||
                                                    _isReconnecting ||
                                                    _isConnectionActionInProgress
                                                ? null
                                                : () {
                                                    unawaited(_connect());
                                                  },
                                            icon: Icon(
                                              _connectionType ==
                                                      ConnectionType.local
                                                  ? Icons.computer
                                                  : Icons.cloud,
                                              size: 18,
                                            ),
                                            label: Text(
                                              _connectionType ==
                                                      ConnectionType.local
                                                  ? '연결'
                                                  : (_sessionIdController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? '생성 & 연결'
                                                      : '연결'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!_isConnected &&
                                            _lastConnectionError != null) ...[
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _isReconnecting
                                                  ? null
                                                  : _manualReconnect,
                                              icon: const Icon(Icons.refresh,
                                                  size: 18),
                                              label: const Text('재연결'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _isConnected
                                                ? _disconnect
                                                : null,
                                            child: const Text('연결 해제'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // 연결 상태 표시
                                    if (_isConnected) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _connectionType ==
                                                            ConnectionType.local
                                                        ? AppI18n.t(
                                                            context,
                                                            AppTextKey
                                                                .sessionsLocalConnectedText,
                                                          )
                                                        : AppI18n.t(
                                                            context,
                                                            AppTextKey
                                                                .sessionsRelayConnectedText,
                                                          ),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                  if (_connectionType ==
                                                          ConnectionType
                                                              .relay &&
                                                      _sessionId != null) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '${AppI18n.t(context, AppTextKey.sessionLabel)} ID: $_sessionId',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                              fontFamily:
                                                                  'monospace',
                                                            ),
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.copy,
                                                              size: 16),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(),
                                                          onPressed: () {
                                                            Clipboard.setData(
                                                                ClipboardData(
                                                                    text:
                                                                        _sessionId!));
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    '세션 ID가 클립보드에 복사되었습니다'),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            1),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (!_isConnected &&
                                        !_isReconnecting) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.cloud_off,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '연결되지 않음',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 가운데: 메시지 로그 (가장 많은 공간 차지)
                      Expanded(
                        child: Card(
                          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Messages 헤더 및 필터
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '메시지',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // 표시/전체, 과거 메시지 불러오기 - 잠시 숨김
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // 검색: 범위(전체/답변만) + 입력창
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              minWidth: 200),
                                          child: SegmentedButton<String>(
                                            segments: const [
                                              ButtonSegment<String>(
                                                value: _searchScopeAll,
                                                label: Text('전체',
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.clip),
                                                icon:
                                                    Icon(Icons.chat, size: 14),
                                              ),
                                              ButtonSegment<String>(
                                                value: _searchScopeAnswerOnly,
                                                label: Text('답변만',
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.clip),
                                                icon: Icon(Icons.smart_toy,
                                                    size: 14),
                                              ),
                                            ],
                                            selected: {_searchScope},
                                            onSelectionChanged:
                                                (Set<String> s) {
                                              setState(
                                                  () => _searchScope = s.first);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            onChanged: (v) => setState(
                                                () => _searchQuery = v),
                                            decoration: InputDecoration(
                                              hintText: '메시지 검색',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              prefixIcon: const Icon(
                                                  Icons.search,
                                                  size: 20),
                                              suffixIcon: _searchQuery
                                                      .isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Icons.clear,
                                                          size: 18),
                                                      onPressed: () => setState(
                                                          () => _searchQuery =
                                                              ''),
                                                    )
                                                  : null,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // 필터 칩들
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: [
                                        FilterChip(
                                          label: _buildFilterChipLabel(
                                            icon: Icons.smart_toy,
                                            text: 'AI Response',
                                            textColor: (_activeFilters[
                                                        MessageFilter
                                                            .aiResponse] ??
                                                    true)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onTertiaryContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                          selected: _activeFilters[
                                                  MessageFilter.aiResponse] ??
                                              true,
                                          selectedColor: Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer,
                                          checkmarkColor: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                          onSelected: (selected) {
                                            setState(() {
                                              _activeFilters[MessageFilter
                                                  .aiResponse] = selected;
                                            });
                                          },
                                        ),
                                        FilterChip(
                                          label: _buildFilterChipLabel(
                                            icon: Icons.person,
                                            text: 'User Prompt',
                                            textColor: (_activeFilters[
                                                        MessageFilter
                                                            .userPrompt] ??
                                                    true)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                          selected: _activeFilters[
                                                  MessageFilter.userPrompt] ??
                                              true,
                                          selectedColor: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          checkmarkColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          onSelected: (selected) {
                                            setState(() {
                                              _activeFilters[MessageFilter
                                                  .userPrompt] = selected;
                                            });
                                          },
                                        ),
                                        FilterChip(
                                          label: _buildFilterChipLabel(
                                            icon: Icons.bug_report,
                                            text: 'Logs',
                                            textColor: (_activeFilters[
                                                        MessageFilter.log] ??
                                                    false)
                                                ? const Color(0xFF7A4B00)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                            iconColor: (_activeFilters[
                                                        MessageFilter.log] ??
                                                    false)
                                                ? const Color(0xFFFF9800)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                          selected: _activeFilters[
                                                  MessageFilter.log] ??
                                              false,
                                          selectedColor:
                                              const Color(0xFFFFF3E0), // 오렌지 배경
                                          checkmarkColor:
                                              const Color(0xFFFF9800), // 오렌지
                                          onSelected: (selected) {
                                            setState(() {
                                              _activeFilters[
                                                  MessageFilter.log] = selected;
                                              // 로그 필터 활성화 시 레벨 필터 모두 체크
                                              if (selected) {
                                                _logLevelFilters[
                                                    LogLevel.error] = true;
                                                _logLevelFilters[
                                                    LogLevel.warning] = true;
                                                _logLevelFilters[
                                                    LogLevel.info] = true;
                                              }
                                            });
                                          },
                                        ),
                                        // 로그 레벨 필터 (로그 필터 활성화 시에만 표시)
                                        if (_activeFilters[MessageFilter.log] ??
                                            false) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            height: 24,
                                            width: 1,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          FilterChip(
                                            label: _buildFilterChipLabel(
                                              icon: Icons.error,
                                              text: 'Error',
                                              textColor: (_logLevelFilters[
                                                          LogLevel.error] ??
                                                      true)
                                                  ? const Color(0xFF8B1E2D)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              iconColor:
                                                  const Color(0xFFDC3545),
                                              iconSize: 12,
                                              fontSize: 10,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            selected: _logLevelFilters[
                                                    LogLevel.error] ??
                                                true,
                                            selectedColor:
                                                const Color(0xFFFFEBEE),
                                            checkmarkColor:
                                                const Color(0xFFDC3545),
                                            onSelected: (selected) {
                                              setState(() {
                                                _logLevelFilters[
                                                    LogLevel.error] = selected;
                                              });
                                            },
                                          ),
                                          FilterChip(
                                            label: _buildFilterChipLabel(
                                              icon: Icons.warning,
                                              text: 'Warn',
                                              textColor: (_logLevelFilters[
                                                          LogLevel.warning] ??
                                                      true)
                                                  ? const Color(0xFF8A4B00)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              iconColor:
                                                  const Color(0xFFFF9800),
                                              iconSize: 12,
                                              fontSize: 10,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            selected: _logLevelFilters[
                                                    LogLevel.warning] ??
                                                true,
                                            selectedColor:
                                                const Color(0xFFFFF3E0),
                                            checkmarkColor:
                                                const Color(0xFFFF9800),
                                            onSelected: (selected) {
                                              setState(() {
                                                _logLevelFilters[LogLevel
                                                    .warning] = selected;
                                              });
                                            },
                                          ),
                                          FilterChip(
                                            label: _buildFilterChipLabel(
                                              icon: Icons.info,
                                              text: 'Info',
                                              textColor: (_logLevelFilters[
                                                          LogLevel.info] ??
                                                      true)
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onTertiaryContainer
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              iconColor: (_logLevelFilters[
                                                          LogLevel.info] ??
                                                      true)
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onTertiaryContainer
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                              iconSize: 12,
                                              fontSize: 10,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            selected: _logLevelFilters[
                                                    LogLevel.info] ??
                                                true,
                                            selectedColor: Theme.of(context)
                                                .colorScheme
                                                .tertiaryContainer,
                                            checkmarkColor: Theme.of(context)
                                                .colorScheme
                                                .tertiary,
                                            onSelected: (selected) {
                                              setState(() {
                                                _logLevelFilters[
                                                    LogLevel.info] = selected;
                                              });
                                            },
                                          ),
                                        ],
                                        FilterChip(
                                          label: _buildFilterChipLabel(
                                            icon: Icons.info_outline,
                                            text: 'System',
                                            textColor: (_activeFilters[
                                                        MessageFilter.system] ??
                                                    true)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                            iconColor: (_activeFilters[
                                                        MessageFilter.system] ??
                                                    true)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                          selected: _activeFilters[
                                                  MessageFilter.system] ??
                                              true,
                                          selectedColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          checkmarkColor: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          onSelected: (selected) {
                                            setState(() {
                                              _activeFilters[MessageFilter
                                                  .system] = selected;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                  child: _buildMessageListWithScrollButtons()),
                            ],
                          ),
                        ),
                      ),
                      // 맨 아래: 명령 입력 섹션
                      if (_isConnected) ...[
                        const Divider(height: 1),
                        Card(
                          margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.tune,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '모델 설정',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (_capabilitiesLoading &&
                                    !_capabilitiesLoaded)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _modelCatalogLoadingText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedModel == 'auto' ||
                                                    _availableModels.any(
                                                        (item) =>
                                                            (item['model'] ??
                                                                    '')
                                                                .toString()
                                                                .trim() ==
                                                            _selectedModel)
                                                ? _selectedModel
                                                : 'auto',
                                            isExpanded: true,
                                            isDense: true,
                                            underline: Container(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                            dropdownColor: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: 'auto',
                                                child: Text('Model: Auto (기본값)',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ),
                                              ..._availableModels.map((item) {
                                                final model =
                                                    (item['model'] ?? '')
                                                        .toString();
                                                final displayName =
                                                    _getModelDisplayName(
                                                        model.trim());
                                                return DropdownMenuItem(
                                                  value: model.trim(),
                                                  child: Text(
                                                    'Model: $displayName',
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                );
                                              }),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _selectedModel =
                                                      _normalizeModel(value);
                                                  _selectedReasoningEffort =
                                                      _normalizeReasoningEffort(
                                                          _selectedReasoningEffort,
                                                          _selectedModel);
                                                });
                                                unawaited(AppSettings()
                                                    .setDefaultModel(
                                                        _selectedModel));
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedReasoningEffort ==
                                                        'auto' ||
                                                    _getAvailableReasoningEffortsForModel(
                                                            _selectedModel)
                                                        .contains(
                                                            _selectedReasoningEffort)
                                                ? _selectedReasoningEffort
                                                : 'auto',
                                            isExpanded: true,
                                            isDense: true,
                                            underline: Container(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                            dropdownColor: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: 'auto',
                                                child: Text('Reasoning: Auto',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ),
                                              ..._getAvailableReasoningEffortsForModel(
                                                      _selectedModel)
                                                  .map((effort) =>
                                                      DropdownMenuItem(
                                                        value: effort,
                                                        child: Text(
                                                          'Reasoning: ${effort[0].toUpperCase()}${effort.substring(1)}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        ),
                                                      )),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _selectedReasoningEffort =
                                                      _normalizeReasoningEffort(
                                                          value,
                                                          _selectedModel);
                                                });
                                                unawaited(AppSettings()
                                                    .setDefaultReasoningEffort(
                                                        _selectedReasoningEffort));
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      'Models: ${_availableModels.length} · Selected: ${_getModelDisplayName(_selectedModel)} · Reasoning options: ${_getAvailableReasoningEffortsForModel(_selectedModel).join(", ")}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _capabilitiesFromCache
                                              ? 'Using cached capabilities'
                                              : _capabilitiesLoaded
                                                  ? 'Capabilities loaded'
                                                  : 'Using fallback capabilities',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      if (_supportsIdeContext)
                                        FilterChip(
                                          label: const Text('IDE Context'),
                                          selected: _useIdeContext,
                                          onSelected: (selected) {
                                            setState(() {
                                              _useIdeContext = selected;
                                            });
                                          },
                                        ),
                                      if (_supportsFlatMode)
                                        FilterChip(
                                          label: const Text('Flat Mode'),
                                          selected: _useFlatMode,
                                          onSelected: (selected) {
                                            setState(() {
                                              _useFlatMode = selected;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                // Enter=전송 / Shift+Enter=줄바꿈
                                // IME 조합 안정성을 위해 Focus(onKeyEvent) + KeyUp 전송으로 처리
                                Focus(
                                  onKeyEvent: _handlePromptInputKeyEvent,
                                  // ValueListenableBuilder로 입력창 감싸기 (전체 UI 리빌드 방지)
                                  child:
                                      ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _commandController,
                                    builder: (context, textValue, child) {
                                      final hasText =
                                          textValue.text.trim().isNotEmpty;
                                      return TextField(
                                        controller: _commandController,
                                        focusNode: _commandFocusNode,
                                        decoration: InputDecoration(
                                          labelText: '프롬프트 입력',
                                          hintText: 'Codex에게 요청할 내용을 입력하세요...',
                                          prefixIcon:
                                              const Icon(Icons.edit_note),
                                          suffixIcon: hasText
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.clear,
                                                    size: 20,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  onPressed: _clearCommandInput,
                                                )
                                              : null,
                                        ),
                                        textInputAction:
                                            TextInputAction.newline,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: 3,
                                        minLines: 2,
                                        enableSuggestions: true,
                                        autocorrect: true,
                                        textCapitalization:
                                            TextCapitalization.none,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // 버튼 영역도 ValueListenableBuilder로 감싸기
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _commandController,
                                  builder: (context, textValue, child) {
                                    final hasText =
                                        textValue.text.trim().isNotEmpty;
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: _isConnected &&
                                                    hasText &&
                                                    !_isWaitingForResponse
                                                ? () {
                                                    unawaited(
                                                        _submitPromptFromInput(
                                                            newSession: false));
                                                  }
                                                : null,
                                            icon: _isWaitingForResponse
                                                ? SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary,
                                                      ),
                                                    ),
                                                  )
                                                : const Icon(Icons.send,
                                                    size: 18),
                                            label: Text(_isWaitingForResponse
                                                ? (_responseIndicatorState ==
                                                        ResponseIndicatorState
                                                            .receiving
                                                    ? '응답 받는 중...'
                                                    : '전송 중...')
                                                : '전송'),
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (_isWaitingForResponse) ...[
                                          OutlinedButton.icon(
                                            onPressed: _isConnected
                                                ? () {
                                                    if (!mounted) return;
                                                    setState(() {
                                                      _isWaitingForResponse =
                                                          false;
                                                    });
                                                    _sendCommand('stop_prompt');
                                                  }
                                                : null,
                                            icon: const Icon(Icons.stop,
                                                size: 18),
                                            label: const Text('중지'),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 16),
                                            ),
                                          ),
                                        ] else ...[
                                          OutlinedButton.icon(
                                            onPressed: _isConnected && hasText
                                                ? () {
                                                    unawaited(
                                                        _submitPromptFromInput(
                                                            newSession: true));
                                                  }
                                                : null,
                                            icon: const Icon(Icons.refresh,
                                                size: 18),
                                            label: const Text('새 대화'),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 16),
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                // 세션 정보 및 대화 히스토리 표시 (설정에서 활성화한 경우만)
                                if (_isConnected &&
                                    AppSettings().showHistory) ...[
                                  // 현재 세션 정보
                                  if (_currentCodexSessionId != null)
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      margin:
                                          const EdgeInsets.only(bottom: 8.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '현재 세션: ${_currentCodexSessionId!.substring(0, 8)}...',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // 세션 목록 및 대화 히스토리
                                  Container(
                                    margin: const EdgeInsets.only(top: 8.0),
                                    child: Card(
                                      child: ExpansionTile(
                                        title: Text(
                                          '세션 및 대화 히스토리',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                        leading: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.history,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                        children: [
                                          // 세션 목록
                                          if (_availableSessions
                                              .isNotEmpty) ...[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Text(
                                                '사용 가능한 세션',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                            ..._availableSessions
                                                .map((sessionId) => ListTile(
                                                      dense: true,
                                                      leading: const Icon(
                                                          Icons.chat,
                                                          size: 16),
                                                      title: Text(
                                                        sessionId.length > 20
                                                            ? '${sessionId.substring(0, 20)}...'
                                                            : sessionId,
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                      trailing: IconButton(
                                                        icon: const Icon(
                                                            Icons.refresh,
                                                            size: 16),
                                                        onPressed: () =>
                                                            _loadChatHistory(
                                                                sessionId:
                                                                    sessionId),
                                                        tooltip:
                                                            '이 세션의 대화 히스토리 조회',
                                                      ),
                                                    )),
                                            const Divider(),
                                          ],

                                          // 대화 히스토리
                                          if (_chatHistory.isNotEmpty) ...[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Text(
                                                '대화 히스토리',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 200,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: _chatHistory.length,
                                                itemBuilder: (context, index) {
                                                  final entry =
                                                      _chatHistory[index];
                                                  final userMsg =
                                                      entry['userMessage']
                                                              as String? ??
                                                          '';
                                                  final assistantMsg =
                                                      entry['assistantResponse']
                                                              as String? ??
                                                          '';
                                                  final timestamp =
                                                      entry['timestamp']
                                                              as String? ??
                                                          '';
                                                  final agentMode =
                                                      entry['agentMode']
                                                          as String?;

                                                  // 디버깅: 모든 항목 로그 출력 (문제 확인용)
                                                  print(
                                                      '📋 History entry[$index] - agentMode: $agentMode, userMsg: ${userMsg.length > 20 ? '${userMsg.substring(0, 20)}...' : userMsg}');
                                                  print(
                                                      '📋 Full entry keys: ${entry.keys.toList()}');

                                                  return Card(
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 4.0),
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      side: BorderSide(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outline
                                                            .withOpacity(0.1),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (userMsg
                                                              .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      bottom:
                                                                          4.0),
                                                              child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      '👤 $userMsg',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                    ),
                                                                  ),
                                                                  // 에이전트 모드 표시 (null이 아니고 비어있지 않은 경우, auto도 표시)
                                                                  if (agentMode !=
                                                                          null &&
                                                                      agentMode
                                                                          .isNotEmpty) ...[
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              6,
                                                                          vertical:
                                                                              3),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .primaryContainer,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                        border:
                                                                            Border.all(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .primary
                                                                              .withOpacity(0.3),
                                                                          width:
                                                                              1,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            _getModeIcon(agentMode),
                                                                            size:
                                                                                12,
                                                                            color:
                                                                                Theme.of(context).colorScheme.onPrimaryContainer,
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 4),
                                                                          Text(
                                                                            _getModeDisplayName(agentMode),
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            ),
                                                          if (assistantMsg
                                                              .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      bottom:
                                                                          4.0),
                                                              child: Text(
                                                                '🤖 ${assistantMsg.length > 50 ? "${assistantMsg.substring(0, 50)}..." : assistantMsg}',
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            11),
                                                              ),
                                                            ),
                                                          if (timestamp
                                                              .isNotEmpty)
                                                            Text(
                                                              _formatTime(
                                                                  DateTime.parse(
                                                                      timestamp)),
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ] else ...[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(24.0),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.history,
                                                    size: 48,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withOpacity(0.4),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    '대화 히스토리가 없습니다',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          // 새로고침 버튼
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                _loadSessionInfo();
                                                _loadChatHistory();
                                              },
                                              icon: const Icon(Icons.refresh,
                                                  size: 18),
                                              label: const Text('새로고침'),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 8.0),
                                    child: Card(
                                      child: ExpansionTile(
                                        title: Text(
                                          'Approvals & actions',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'codex: ${_pendingCodexServerRequests.length} · relay: ${_pendingCommandApprovals.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        leading: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.security,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onTertiaryContainer,
                                          ),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            child: Wrap(
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: _isConnected
                                                      ? () {
                                                          _loadCommandApprovals();
                                                          _loadCommandEvents();
                                                        }
                                                      : null,
                                                  icon: const Icon(
                                                      Icons.refresh,
                                                      size: 16),
                                                  label: const Text('새로고침'),
                                                ),
                                                const SizedBox(width: 8),
                                                PopupMenuButton<
                                                    AutoDecisionMode>(
                                                  tooltip: 'Auto response mode',
                                                  onSelected: (mode) {
                                                    setState(() {
                                                      _autoDecisionMode = mode;
                                                    });
                                                    final label =
                                                        _autoDecisionModeLabel(
                                                            mode);
                                                    _messages.add(MessageItem(
                                                        '⚙️ 승인 자동응답 모드: $label',
                                                        type: MessageType
                                                            .system));
                                                    _scrollToBottom();
                                                  },
                                                  itemBuilder: (context) =>
                                                      const [
                                                    PopupMenuItem(
                                                      value:
                                                          AutoDecisionMode.off,
                                                      child: Text('Manual'),
                                                    ),
                                                    PopupMenuItem(
                                                      value: AutoDecisionMode
                                                          .approve,
                                                      child:
                                                          Text('Auto-approve'),
                                                    ),
                                                    PopupMenuItem(
                                                      value: AutoDecisionMode
                                                          .reject,
                                                      child:
                                                          Text('Auto-reject'),
                                                    ),
                                                  ],
                                                  child: Chip(
                                                    label: Text(
                                                        _autoDecisionModeLabel(
                                                            _autoDecisionMode),
                                                        style: const TextStyle(
                                                            fontSize: 11)),
                                                    avatar: const Icon(
                                                        Icons.timer,
                                                        size: 14),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                PopupMenuButton<int>(
                                                  tooltip:
                                                      'Auto response timeout',
                                                  onSelected: (seconds) {
                                                    setState(() {
                                                      _autoDecisionTimeoutSec =
                                                          seconds;
                                                    });
                                                    _messages.add(MessageItem(
                                                        '⚙️ 자동응답 대기시간: ${seconds}s',
                                                        type: MessageType
                                                            .system));
                                                    _scrollToBottom();
                                                  },
                                                  itemBuilder: (context) =>
                                                      const [
                                                    PopupMenuItem(
                                                        value: 10,
                                                        child: Text('10s')),
                                                    PopupMenuItem(
                                                        value: 30,
                                                        child: Text('30s')),
                                                    PopupMenuItem(
                                                        value: 60,
                                                        child: Text('60s')),
                                                  ],
                                                  child: Chip(
                                                    label: Text(
                                                        '${_autoDecisionTimeoutSec}s',
                                                        style: const TextStyle(
                                                            fontSize: 11)),
                                                    avatar: const Icon(
                                                        Icons.schedule,
                                                        size: 14),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (_loadingCommandApprovals ||
                                                    _loadingCommandEvents)
                                                  const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Pending Codex requests',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_pendingCodexServerRequests
                                              .isEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      12, 0, 12, 8),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '대기 중인 Codex 요청이 없습니다.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            ..._pendingCodexServerRequests
                                                .take(5)
                                                .map((request) {
                                              final requestId =
                                                  request['requestId']
                                                          ?.toString() ??
                                                      '';
                                              final requestKind =
                                                  request['requestKind']
                                                          ?.toString() ??
                                                      '';
                                              final summary =
                                                  _codexRequestSummary(request);
                                              final detailLines =
                                                  List<String>.from(
                                                      (request['detailLines']
                                                                  as List? ??
                                                              [])
                                                          .map((e) =>
                                                              e.toString()));
                                              final requestTimeLabel =
                                                  _timestampLabelFromMap(
                                                      request,
                                                      preferredKeys: const [
                                                    'timestamp',
                                                    'created_at',
                                                    'createdAt'
                                                  ]);
                                              final choices = List<
                                                  Map<String,
                                                      dynamic>>.from((request[
                                                          'choices'] as List? ??
                                                      [])
                                                  .map((e) =>
                                                      Map<String, dynamic>.from(
                                                          e as Map)));
                                              final isSubmitting =
                                                  _submittingCodexRequestIds
                                                      .contains(requestId);
                                              final accentColor =
                                                  _codexRequestAccentColor(
                                                      context, request);

                                              return Card(
                                                margin:
                                                    const EdgeInsets.fromLTRB(
                                                        12, 4, 12, 4),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  side: BorderSide(
                                                    color: accentColor
                                                        .withOpacity(0.35),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: accentColor
                                                              .withOpacity(
                                                                  0.10),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      999),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .notification_important_rounded,
                                                              size: 14,
                                                              color:
                                                                  accentColor,
                                                            ),
                                                            const SizedBox(
                                                                width: 6),
                                                            Text(
                                                              'Action required',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    accentColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              _codexRequestTitle(
                                                                  request),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            requestTimeLabel,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons
                                                                    .open_in_new,
                                                                size: 16),
                                                            tooltip: 'Detail',
                                                            visualDensity:
                                                                VisualDensity
                                                                    .compact,
                                                            onPressed: () {
                                                              _showCodexRequestDetailSheet(
                                                                  request);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      if (summary
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          summary,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                            fontFamily:
                                                                'monospace',
                                                          ),
                                                        ),
                                                      ],
                                                      if (detailLines
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 6),
                                                        ...detailLines
                                                            .take(3)
                                                            .map(
                                                              (line) => Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            2),
                                                                child: Text(
                                                                  line,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                      ],
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '모바일에서 버튼을 눌러야 계속 진행됩니다.',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: accentColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      if (requestKind ==
                                                          'user_input')
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child:
                                                                  FilledButton(
                                                                onPressed:
                                                                    isSubmitting
                                                                        ? null
                                                                        : () {
                                                                            _openCodexUserInputDialog(request);
                                                                          },
                                                                child: Text(isSubmitting
                                                                    ? 'Sending...'
                                                                    : 'Respond'),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      else
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children: choices
                                                              .map((choice) {
                                                            final label = choice[
                                                                        'label']
                                                                    ?.toString() ??
                                                                'Respond';
                                                            final style = choice[
                                                                        'style']
                                                                    ?.toString() ??
                                                                'secondary';
                                                            final responsePayload = Map<
                                                                    String,
                                                                    dynamic>.from(
                                                                choice['response']
                                                                        as Map? ??
                                                                    {});
                                                            final buttonChild =
                                                                Text(isSubmitting
                                                                    ? 'Sending...'
                                                                    : label);
                                                            if (style ==
                                                                'primary') {
                                                              return FilledButton(
                                                                onPressed:
                                                                    isSubmitting
                                                                        ? null
                                                                        : () {
                                                                            _submitCodexDecision(request,
                                                                                responsePayload);
                                                                          },
                                                                child:
                                                                    buttonChild,
                                                              );
                                                            }
                                                            return OutlinedButton(
                                                              onPressed:
                                                                  isSubmitting
                                                                      ? null
                                                                      : () {
                                                                          _submitCodexDecision(
                                                                              request,
                                                                              responsePayload);
                                                                        },
                                                              style: style ==
                                                                      'danger'
                                                                  ? OutlinedButton
                                                                      .styleFrom(
                                                                      foregroundColor: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .error,
                                                                    )
                                                                  : null,
                                                              child:
                                                                  buttonChild,
                                                            );
                                                          }).toList(),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          const Divider(height: 20),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Pending approvals',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_pendingCommandApprovals.isEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      12, 0, 12, 8),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '대기 중인 승인 요청이 없습니다.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            ..._pendingCommandApprovals
                                                .take(5)
                                                .map((approval) {
                                              final commandRaw =
                                                  _approvalCommandRaw(approval);
                                              final requestType =
                                                  _approvalRequestTypeLabel(
                                                      approval);
                                              final requestedBy =
                                                  _approvalRequestedBy(
                                                      approval);
                                              final cwd =
                                                  _approvalWorkingDirectory(
                                                      approval);
                                              final policy = approval['policy']
                                                      as Map<String,
                                                          dynamic>? ??
                                                  {};
                                              final createdAtLabel =
                                                  _timestampLabelFromMap(
                                                      approval);
                                              final riskLevel =
                                                  policy['risk_level']
                                                          ?.toString() ??
                                                      'unknown';
                                              final reasons =
                                                  (policy['reasons'] as List? ??
                                                          [])
                                                      .map((e) => e.toString())
                                                      .join(', ');
                                              return Card(
                                                margin:
                                                    const EdgeInsets.fromLTRB(
                                                        12, 4, 12, 4),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  side: BorderSide(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  requestType,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 2),
                                                                Text(
                                                                  commandRaw,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontFamily:
                                                                        'monospace',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 2),
                                                                Text(
                                                                  createdAtLabel,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 2),
                                                                Text(
                                                                  'by $requestedBy${cwd.isNotEmpty ? ' · $cwd' : ''}',
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: _riskColor(
                                                                      riskLevel)
                                                                  .withOpacity(
                                                                      0.14),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              riskLevel,
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: _riskColor(
                                                                    riskLevel),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (reasons
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          reasons,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: TextButton.icon(
                                                          onPressed: () {
                                                            _showRelayApprovalDetailSheet(
                                                                approval);
                                                          },
                                                          icon: const Icon(
                                                              Icons.open_in_new,
                                                              size: 16),
                                                          label: const Text(
                                                              'Detail'),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextButton(
                                                              onPressed: () {
                                                                _markRelayApprovalLater(
                                                                    approval);
                                                              },
                                                              child: const Text(
                                                                  'Later'),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                OutlinedButton(
                                                              onPressed:
                                                                  () async {
                                                                await _confirmAndResolveApproval(
                                                                    approval,
                                                                    'reject');
                                                              },
                                                              child: const Text(
                                                                  'Reject'),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: FilledButton(
                                                              onPressed:
                                                                  () async {
                                                                await _confirmAndResolveApproval(
                                                                    approval,
                                                                    'approve');
                                                              },
                                                              child: const Text(
                                                                  'Approve'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          const Divider(height: 20),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Recent command events',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_recentCommandEvents.isEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      12, 0, 12, 12),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '표시할 command event가 없습니다.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            ..._recentCommandEvents
                                                .take(5)
                                                .map((event) {
                                              final result = event['result']
                                                      as Map<String,
                                                          dynamic>? ??
                                                  {};
                                              final command = event['command']
                                                      as Map<String,
                                                          dynamic>? ??
                                                  {};
                                              final approval = event['approval']
                                                      as Map<String,
                                                          dynamic>? ??
                                                  {};
                                              final risk = event['risk'] as Map<
                                                      String, dynamic>? ??
                                                  {};
                                              final status = result['status']
                                                      ?.toString() ??
                                                  'unknown';
                                              final raw =
                                                  command['raw']?.toString() ??
                                                      '(unknown)';
                                              final approvalStatus =
                                                  _deriveApprovalStatusFromEvent(
                                                        event,
                                                      ) ??
                                                      approval['status']
                                                          ?.toString()
                                                          .toLowerCase()
                                                          .trim() ??
                                                      'not_required';
                                              final riskLevel =
                                                  risk['level']?.toString() ??
                                                      'low';
                                              Color statusColor;
                                              switch (status) {
                                                case 'success':
                                                  statusColor = Colors.green;
                                                  break;
                                                case 'error':
                                                case 'cancelled':
                                                  statusColor = Colors.red;
                                                  break;
                                                default:
                                                  statusColor = Colors.orange;
                                              }

                                              return ListTile(
                                                dense: true,
                                                leading: Icon(Icons.bolt,
                                                    size: 16,
                                                    color: statusColor),
                                                title: Text(
                                                  '$status • $raw',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                subtitle: Text(
                                                  'risk: $riskLevel · approval: $approvalStatus',
                                                  style: const TextStyle(
                                                      fontSize: 11),
                                                ),
                                              );
                                            }),
                                          const Divider(height: 20),
                                          Builder(builder: (context) {
                                            final timelineEntries =
                                                _buildDecisionTimelineEntries()
                                                    .take(8)
                                                    .toList();
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 4),
                                                  child: Text(
                                                    'Decision timeline',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                ),
                                                if (timelineEntries.isEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(12, 0, 12, 8),
                                                    child: Text(
                                                      '표시할 타임라인이 없습니다.',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  ...timelineEntries
                                                      .map((entry) {
                                                    final kind = entry['kind']
                                                            ?.toString() ??
                                                        '';
                                                    final title = entry['title']
                                                            ?.toString() ??
                                                        '';
                                                    final subtitle =
                                                        entry['subtitle']
                                                                ?.toString() ??
                                                            '';
                                                    final time = entry['time']
                                                            as DateTime? ??
                                                        DateTime.now();
                                                    return ListTile(
                                                      dense: true,
                                                      onTap: () {
                                                        _showTimelineEntryDetailSheet(
                                                            entry);
                                                      },
                                                      leading: Icon(
                                                        _timelineIcon(
                                                            kind, title),
                                                        size: 16,
                                                      ),
                                                      title: Text(
                                                        title,
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      subtitle: Text(
                                                        '$subtitle · ${_formatTime(time)}',
                                                        style: const TextStyle(
                                                            fontSize: 11),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    );
                                                  }),
                                              ],
                                            );
                                          }),
                                          const Divider(height: 20),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Trace timeline',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ),
                                          TraceTimelinePanel(
                                            enabled: _isConnected &&
                                                _connectionType ==
                                                    ConnectionType.relay,
                                            traceIdController:
                                                _traceIdController,
                                            recentTraceIds: _recentTraceIds,
                                            loading: _loadingTraceTimeline,
                                            autoRefresh: _traceAutoRefresh,
                                            error: _traceTimelineError,
                                            timeline: _traceTimeline,
                                            onRefreshRecent: () {
                                              unawaited(_loadRecentTraceIds());
                                            },
                                            onFetchTimeline: () {
                                              unawaited(_loadTraceTimeline());
                                            },
                                            onSelectRecent: (traceId) {
                                              _traceIdController.text = traceId;
                                              unawaited(_loadTraceTimeline(
                                                  traceId: traceId));
                                            },
                                            onAutoRefreshChanged: (enabled) {
                                              setState(() {
                                                _setTraceAutoRefresh(enabled);
                                              });
                                            },
                                            onCopyReport: () {
                                              unawaited(
                                                  _copyTraceTimelineReport());
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ))
            : _selectedHomeTab == HomeTab.approvals
                ? _buildApprovalsTabBody()
                : _selectedHomeTab == HomeTab.sessions
                    ? _buildSessionsTabBody()
                    : _buildSettingsTabBody(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: HomeTab.values.indexOf(_selectedHomeTab),
        onDestinationSelected: (index) {
          unawaited(_selectHomeTab(HomeTab.values[index]));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.gpp_good_outlined),
            selectedIcon: Icon(Icons.gpp_good),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
