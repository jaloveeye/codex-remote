import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/connection_models.dart';
import 'services/app_settings.dart';

// Relay 서버 URL (빌드 시 --dart-define=RELAY_SERVER_URL=... 으로 덮어쓸 수 있음)
const String RELAY_SERVER_URL = String.fromEnvironment(
  'RELAY_SERVER_URL',
  defaultValue: 'https://relay.example.com',
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
  @override
  void initState() {
    super.initState();
    AppSettings().addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    AppSettings().removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codex Remote',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: AppSettings().themeModeValue,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

class MessageItem {
  final String text;
  final String type; // MessageType 상수 사용
  final DateTime timestamp;
  String? agentMode; // 에이전트 모드 (userPrompt 타입일 때만 사용)
  LogLevel? logLevel; // 로그 레벨 (log 타입일 때만 사용)

  MessageItem(this.text,
      {this.type = MessageType.normal, this.agentMode, this.logLevel})
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
  bool _isRelayPollInFlight = false;

  // 스트리밍 관련
  int? _streamingMessageIndex; // 현재 스트리밍 중인 메시지의 인덱스
  String _streamingText = ''; // 스트리밍 중인 텍스트

  // 세션 및 대화 히스토리
  Map<String, dynamic>? _sessionInfo; // 현재 세션 정보
  List<Map<String, dynamic>> _chatHistory = []; // 대화 히스토리 목록
  List<String> _availableSessions = []; // 사용 가능한 세션 목록
  List<Map<String, dynamic>> _pendingCommandApprovals = [];
  List<Map<String, dynamic>> _pendingCodexServerRequests = [];
  List<Map<String, dynamic>> _recentCommandEvents = [];
  final Set<String> _seenCommandApprovalIds = <String>{};
  final Set<String> _seenCodexRequestIds = <String>{};
  AutoDecisionMode _autoDecisionMode = AutoDecisionMode.off;
  int _autoDecisionTimeoutSec = 30;
  final Map<String, Timer> _autoDecisionTimers = <String, Timer>{};
  bool _loadingCommandApprovals = false;
  bool _loadingCommandEvents = false;
  final Set<String> _submittingCodexRequestIds = <String>{};
  DateTime? _lastCommandMetaRefreshAt;

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
  String? _lastConnectionError;

  // 런타임 옵션 관련
  String _selectedAgentMode = 'auto'; // 내부는 auto 유지
  String _selectedModel = 'auto';
  String _selectedReasoningEffort = 'auto';
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
  static const List<Map<String, dynamic>> _fallbackModels = [
    {
      'model': 'gpt-5',
      'displayName': 'GPT-5',
      'isDefault': true,
      'defaultReasoningEffort': 'medium',
      'supportedReasoningEfforts': ['low', 'medium', 'high'],
    },
    {
      'model': 'gpt-5-mini',
      'displayName': 'GPT-5 mini',
      'isDefault': false,
      'defaultReasoningEffort': 'medium',
      'supportedReasoningEfforts': ['low', 'medium', 'high'],
    },
  ];
  List<String> _availableAgentModes = List<String>.from(_fallbackAgentModes);
  List<Map<String, dynamic>> _availableModels =
      List<Map<String, dynamic>>.from(_fallbackModels);
  bool _supportsIdeContext = false;
  bool _supportsFlatMode = false;
  String? _actualSelectedMode; // 자동 모드로 선택된 경우 실제 선택된 모드 (null이면 사용자가 직접 선택)
  MessageItem? _lastUserPrompt; // 마지막 User Prompt 메시지 (모드 업데이트용)

  final List<MessageItem> _messages = [];
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _sessionIdController = TextEditingController();

  // 입력창 상태 관리
  int _textFieldKey = 0; // TextField 재생성용 Key
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
  bool _isCompactView = false;

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
        _supportsIdeContext = false;
        _supportsFlatMode = false;
        _useIdeContext = false;
        _useFlatMode = false;
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
              _capabilitiesLoadTimer?.cancel();
              _capabilitiesLoading = false;
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
          // 실시간 로그 메시지 처리
          final logLevelStr = data['level'] ?? 'info';
          final logMessage = data['message'] ?? '';
          final logSource = data['source'] ?? 'unknown';
          final logError = data['error'];

          // 로그 레벨 파싱
          LogLevel parsedLogLevel;
          switch (logLevelStr) {
            case 'error':
              parsedLogLevel = LogLevel.error;
              break;
            case 'warn':
            case 'warning':
              parsedLogLevel = LogLevel.warning;
              break;
            default:
              parsedLogLevel = LogLevel.info;
          }

          String logPrefix = '';
          switch (logSource) {
            case 'extension':
              logPrefix = '🔌 [Extension]';
              break;
            default:
              logPrefix = '📝 [Log]';
          }

          String logText = '$logPrefix $logMessage';
          if (logError != null) {
            logText += ' - Error: $logError';
          }

          _messages.add(MessageItem(logText,
              type: MessageType.log, logLevel: parsedLogLevel));
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('PIN 입력'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이 세션은 PC에서 PIN 보호가 설정되어 있습니다.\nPC에서 설정한 4~6자리 숫자 PIN을 입력하세요.',
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
                onSubmitted: (_) => navigator.pop(controller.text.trim()),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  hintText: '4~6자리 숫자',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(null),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => navigator.pop(controller.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 기존 세션에 연결 (PIN은 PC가 설정한 경우에만 전달)
  Future<void> _connectToSession(String sessionId, [String? pin]) async {
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
        setState(() {
          _sessionId = sessionId;
          _isConnected = true;
          _isReconnecting = false;
          _reconnectAttempts = 0;
          _lastConnectionError = null;
          _lastCommandMetaRefreshAt = null;
          _capabilitiesLoaded = false;
          _capabilitiesLoading = false;
          _supportsIdeContext = false;
          _supportsFlatMode = false;
          _useIdeContext = false;
          _useFlatMode = false;
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
          _messages.add(MessageItem('이 세션은 PIN이 필요합니다. PIN을 입력하세요.',
              type: MessageType.system));
        });
        final enteredPin = await _showPinDialog();
        if (!mounted) return;
        if (enteredPin != null && enteredPin.isNotEmpty) {
          await _connectToSession(sessionId, enteredPin);
        } else {
          setState(() {
            _messages.add(MessageItem('PIN을 입력하지 않아 연결하지 않았습니다.',
                type: MessageType.system));
          });
        }
      } else if (response.statusCode == 403 &&
          (errorCode == 'INVALID_PIN' ||
              errorMessage.toLowerCase().contains('invalid pin'))) {
        setState(() {
          _messages.add(MessageItem('❌ PIN이 올바르지 않습니다. PC에서 설정한 PIN을 확인하세요.',
              type: MessageType.system));
        });
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('PIN 오류'),
              content: const Text(
                'PIN이 올바르지 않습니다.\nPC(익스텐션)에서 설정한 4~6자리 PIN을 확인하세요.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('확인'),
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

  void _connect() {
    if (_connectionType == ConnectionType.local) {
      // 로컬 서버 연결
      _connectToLocal();
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
        }
        return;
      }
      _connectToSession(sessionId);
    }
  }

  // 히스토리에서 연결
  void _connectFromHistory(ConnectionHistoryItem item) {
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
    _connect();
  }

  // 메시지 폴링 시작
  void _startPolling() {
    _stopPolling(); // 기존 타이머 정지

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _pollRelayMessagesOnce();
    });
  }

  Future<void> _pollRelayMessagesOnce() async {
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
          for (final msg in messages) {
            _handleRelayMessage(msg);
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
  }

  // relay 서버에서 받은 메시지 처리
  void _handleRelayMessage(Map<String, dynamic> msg) {
    if (!mounted) return;

    final type = msg['type'] ?? msg['data']?['type'];
    final messageData = msg['data'] ?? msg;

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
            _capabilitiesLoadTimer?.cancel();
            _capabilitiesLoading = false;
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

        final chunkText = messageData['text'] ?? '';
        final fullText = messageData['fullText'] ?? chunkText;
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
          // 첫 번째 청크인 경우 메시지 추가
          if (_streamingMessageIndex == null) {
            _messages
                .add(MessageItem('', type: MessageType.chatResponseDivider));
            _messages.add(MessageItem('🤖 Codex Response',
                type: MessageType.chatResponseHeader));
            _streamingText = isReplace ? fullText : chunkText;
            _messages.add(MessageItem(_streamingText,
                type: MessageType.chatResponseChunk));
            _streamingMessageIndex = _messages.length - 1;
          } else {
            // 기존 스트리밍 메시지 업데이트
            if (isReplace) {
              _streamingText = fullText;
            } else {
              _streamingText += chunkText;
            }
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
        setState(() {
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
        // 실시간 로그 메시지 처리
        final logLevelStr = messageData['level'] ?? 'info';
        final logMessage = messageData['message'] ?? '';
        final logSource = messageData['source'] ?? 'unknown';
        final logError = messageData['error'];

        // 로그 레벨 파싱
        LogLevel parsedLogLevel;
        switch (logLevelStr) {
          case 'error':
            parsedLogLevel = LogLevel.error;
            break;
          case 'warn':
          case 'warning':
            parsedLogLevel = LogLevel.warning;
            break;
          default:
            parsedLogLevel = LogLevel.info;
        }

        String logPrefix = '';
        switch (logSource) {
          case 'extension':
            logPrefix = '🔌 [Extension]';
            break;
          default:
            logPrefix = '📝 [Log]';
        }

        String logText = '$logPrefix $logMessage';
        if (logError != null) {
          logText += ' - Error: $logError';
        }

        setState(() {
          _messages.add(MessageItem(logText,
              type: MessageType.log, logLevel: parsedLogLevel));
        });
        _scrollToBottom();
      } else if (type == 'codex_raw_notification' ||
          type == 'codex_notification') {
        _recordCodexRawNotification(messageData, channel: 'relay');
      } else {
        _recordUnhandledIncomingMessage(type.toString(), messageData, 'relay');
      }
    });
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
    final normalized = model.trim();
    if (normalized.isEmpty || normalized == 'auto') return 'auto';
    final exists = _availableModels.any(
      (item) => (item['model'] ?? '').toString().trim() == normalized,
    );
    return exists ? normalized : _getDefaultModelFromCapabilities();
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

    _capabilitiesLoadTimer?.cancel();
    _capabilitiesLoading = false;
    _applyRuntimeCapabilities(data);
    _messages.add(MessageItem(
      '🧩 Runtime capabilities loaded: ${_availableModels.length} model(s), '
      'IDE context ${_supportsIdeContext ? 'enabled' : 'unsupported'}, '
      'flat mode ${_supportsFlatMode ? 'enabled' : 'unsupported'}',
      type: MessageType.system,
    ));
  }

  // 텍스트 내용을 분석하여 적절한 에이전트 모드 자동 선택 (Extension의 detectAgentMode와 동일한 로직)
  String? _detectAgentMode(String text) {
    final lowerText = text.toLowerCase();

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
    _stopPolling();
    _cancelAllAutoDecisionTimers();
    _stopReconnect(); // 재연결 중지
    _capabilitiesLoadTimer?.cancel();

    // 로컬 WebSocket 연결 종료
    _localWebSocket?.sink.close();
    _localWebSocket = null;

    if (mounted) {
      setState(() {
        _isConnected = false;
        _sessionId = null;
        _isReconnecting = false;
        _reconnectAttempts = 0;
        _pendingCommandApprovals = [];
        _pendingCodexServerRequests = [];
        _recentCommandEvents = [];
        _loadingCommandApprovals = false;
        _loadingCommandEvents = false;
        _lastCommandMetaRefreshAt = null;
        _capabilitiesLoaded = false;
        _capabilitiesLoading = false;
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

  // 수동 재연결
  void _manualReconnect() {
    _stopReconnect();
    _reconnectAttempts = 0;
    _connect();
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

      final commandData = {
        'type': type,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
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
                      '⏳ 승인 필요: $approvalId (risk: $riskLevel)',
                      type: MessageType.system));
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

    // 로그 메시지 스타일
    if (message.type == MessageType.log) {
      // 로그 레벨에 따라 색상 결정
      Color logColor;
      IconData logIcon;

      switch (message.logLevel ?? LogLevel.info) {
        case LogLevel.error:
          logColor = Theme.of(context).colorScheme.error;
          logIcon = Icons.error;
        case LogLevel.warning:
          logColor = const Color(0xFFFF9800); // 오렌지
          logIcon = Icons.warning;
        case LogLevel.info:
          logColor = Theme.of(context).colorScheme.tertiary;
          logIcon = Icons.info;
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: logColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: logColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              logIcon,
              size: 14,
              color: logColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                message.text,
                style: TextStyle(
                  fontSize: 11,
                  color: logColor.withOpacity(0.9),
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
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
    _loadConnectionSettings();
    // 설정에서 기본 프롬프트 옵션 적용
    _selectedAgentMode = 'auto';
    _selectedModel = _normalizeModel(AppSettings().defaultModel);
    _selectedReasoningEffort =
        _normalizeReasoningEffort(AppSettings().defaultReasoningEffort);
    // 설정 변경 리스너 추가
    AppSettings().addListener(_onAppSettingsChanged);
    _scrollController.addListener(_updateScrollButtonVisibility);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateScrollButtonVisibility());
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
        _selectedModel = _normalizeModel(settings.defaultModel);
        _selectedReasoningEffort =
            _normalizeReasoningEffort(settings.defaultReasoningEffort);
      });
    }
  }

  // 입력창 클리어 (한글 IME composing 버퍼 완전 초기화)
  void _clearCommandInput() {
    // Controller 텍스트 클리어
    _commandController.clear();

    // Key를 변경하여 TextField 완전 재생성 (IME 상태 완전 리셋)
    setState(() {
      _textFieldKey++;
    });

    // 새 TextField에 포커스 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _commandFocusNode.requestFocus();
      }
    });
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
    } else if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 갔을 때는 특별한 처리가 필요 없음
    }
  }

  // 세션 정보 조회
  Future<void> _loadSessionInfo() async {
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

  Future<void> _loadRuntimeCapabilities() async {
    if (!_isConnected) return;

    try {
      setState(() {
        _capabilitiesLoading = true;
        _messages.add(MessageItem(
            '🛰️ Requesting runtime capabilities from extension...',
            type: MessageType.system));
      });
      _capabilitiesLoadTimer?.cancel();
      _capabilitiesLoadTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted || !_capabilitiesLoading || _capabilitiesLoaded) return;
        setState(() {
          _capabilitiesLoading = false;
          _messages.add(MessageItem(
              '⚠️ Capability load delayed. Falling back to cached/default UI.',
              type: MessageType.system));
        });
      });
      await _sendCommand('get_runtime_capabilities',
          clientId: _currentClientId);
      if (_connectionType == ConnectionType.relay) {
        Future.delayed(const Duration(milliseconds: 120), () {
          unawaited(_pollRelayMessagesOnce());
        });
      }
    } catch (e) {
      // 에러는 조용히 무시
    }
  }

  Future<void> _refreshCommandMetaIfStale(
      {Duration minInterval = const Duration(seconds: 6)}) async {
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
    if (!_isConnected || _sessionId == null) return;
    if (_connectionType != ConnectionType.relay) return;
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

        setState(() {
          _pendingCommandApprovals = approvals;
          for (final approval in approvals) {
            final approvalId = approval['approval_id']?.toString() ?? '';
            if (approvalId.isEmpty ||
                _seenCommandApprovalIds.contains(approvalId)) {
              continue;
            }

            _seenCommandApprovalIds.add(approvalId);
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

  void _recordCodexRawNotification(dynamic payload, {required String channel}) {
    final map = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final method = map['method']?.toString().trim() ??
        map['eventMethod']?.toString().trim() ??
        'unknown';
    final params = map['params'] ?? map['eventParams'] ?? payload;
    final text = _extractCodexEventText(params);
    final detail = text.isNotEmpty
        ? _truncateForLog(text, maxLength: 220)
        : _safeJsonSnippet(params, maxLength: 220);

    _messages.add(MessageItem('📡 [$channel] $method → $detail',
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

    if (action == 'approve' && isHighRisk && mounted) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('고위험 명령 승인 확인'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('risk: $riskLevel'),
                  Text('type: $requestType'),
                  Text('requested by: $requestedBy'),
                  if (cwd.isNotEmpty) Text('cwd: $cwd'),
                  const SizedBox(height: 8),
                  SelectableText(
                    _truncateForLog(commandRaw, maxLength: 240),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('그래도 승인'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) {
        setState(() {
          _messages.add(MessageItem('🛑 고위험 승인 취소: $approvalId',
              type: MessageType.system));
        });
        _scrollToBottom();
        return;
      }
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
    if (!_isConnected || _sessionId == null) return;
    if (_connectionType != ConnectionType.relay) return;
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
        setState(() {
          _recentCommandEvents = events;
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

  Future<void> _resolveCommandApproval(String approvalId, String action) async {
    if (!_isConnected || _sessionId == null) return;
    if (_connectionType != ConnectionType.relay) return;

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

    try {
      final response = await http.post(
        _relayUri('/api/resolve-command-approval'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': _sessionId,
          'approvalId': approvalId,
          'action': action,
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
            (body['data'] as Map<String, dynamic>? ?? {})['status'] ?? action;
        setState(() {
          _messages.add(MessageItem(
              '✅ Approval 응답: $approvalId → $status${commandRaw.isNotEmpty ? ' · $commandRaw' : ''}',
              type: MessageType.system));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval $action 완료')),
        );
        _scrollToBottom();
        await _loadCommandApprovals(silent: true);
        await _loadCommandEvents(silent: true);
      } else {
        setState(() {
          _messages.add(MessageItem(
              '❌ Approval 처리 실패($action): ${body['error'] ?? 'HTTP ${response.statusCode}'}',
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
      const SnackBar(content: Text('승인 요청을 나중에 처리하도록 남겨뒀어요.')),
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
                    '모바일에서 선택해야 Codex가 계속 진행됩니다.',
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

    if (!mounted) return;
    setState(() {
      _upsertPendingCodexServerRequest(payload);
      if (_seenCodexRequestIds.add(requestId)) {
        final summary =
            _truncateForLog(_codexRequestSummary(payload), maxLength: 56);
        _messages.add(MessageItem(
            '📩 ${_codexRequestTitle(payload)} 요청 도착${summary.isNotEmpty ? ' · $summary' : ''}',
            type: MessageType.system));
      }
      _isWaitingForResponse = false;
    });
    _scrollToBottom();
    HapticFeedback.heavyImpact();
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
    _capabilitiesLoadTimer?.cancel();
    _stopPolling();
    _localWebSocket?.sink.close();
    _commandController.dispose();
    _sessionIdController.dispose();
    _localIpController.dispose();
    _localPortController.dispose();
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
              isSearchActive ? '검색 결과가 없습니다' : '메시지가 없습니다',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_messages.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '프롬프트를 입력하여 시작하세요',
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
                  '응답을 기다리는 중...',
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
                    hintText: '프롬프트 입력...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onSubmitted: (value) {
                    final text = value.trim();
                    if (text.isEmpty ||
                        !_isConnected ||
                        _isWaitingForResponse) {
                      return;
                    }
                    _sendCommand('insert_text',
                        text: text,
                        prompt: true,
                        execute: true,
                        newSession: false,
                        agentMode: _selectedAgentMode);
                    _clearCommandInput();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  final text = _commandController.text.trim();
                  if (text.isEmpty || !_isConnected || _isWaitingForResponse) {
                    return;
                  }
                  _sendCommand('insert_text',
                      text: text,
                      prompt: true,
                      execute: true,
                      newSession: false,
                      agentMode: _selectedAgentMode);
                  _clearCommandInput();
                },
                icon: const Icon(Icons.send),
                tooltip: '전송',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text(
                'Codex Remote',
                style: Theme.of(context).appBarTheme.titleTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
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
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '응답 대기 중',
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
          // 컴팩트 뷰 전환 (연결됐을 때만)
          if (_isConnected)
            IconButton(
              icon: Icon(
                _isCompactView ? Icons.fullscreen : Icons.compress,
                size: 22,
              ),
              tooltip: _isCompactView ? '전체 화면으로' : '컴팩트 보기 (메시지 크게)',
              onPressed: () {
                setState(() => _isCompactView = !_isCompactView);
              },
            ),
          // 설정 버튼
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isCompactView && _isConnected
          ? _buildCompactBody()
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
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: _isConnected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _isConnected ? '연결됨' : '연결 안 됨',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isConnected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: Text(
                        _isConnected
                            ? (_connectionType == ConnectionType.local
                                ? '로컬 서버 모드'
                                : (_sessionId != null
                                    ? '릴레이 모드 • 세션: $_sessionId'
                                    : '릴레이 모드'))
                            : '연결을 설정하세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      initiallyExpanded: !_isConnected, // 연결 안 됨일 때만 펼침
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 연결 타입 선택
                              Text(
                                '연결 타입',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<ConnectionType>(
                                segments: const [
                                  ButtonSegment<ConnectionType>(
                                    value: ConnectionType.local,
                                    label: Text('로컬 서버'),
                                    icon: Icon(Icons.computer, size: 18),
                                  ),
                                  ButtonSegment<ConnectionType>(
                                    value: ConnectionType.relay,
                                    label: Text('릴레이 서버'),
                                    icon: Icon(Icons.cloud, size: 18),
                                  ),
                                ],
                                selected: {_connectionType},
                                onSelectionChanged: _isConnected
                                    ? null
                                    : (Set<ConnectionType> newSelection) {
                                        setState(() {
                                          _connectionType = newSelection.first;
                                        });
                                      },
                              ),
                              const SizedBox(height: 16),
                              // 로컬 서버 연결 UI
                              if (_connectionType == ConnectionType.local) ...[
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
                                          contentPadding: EdgeInsets.all(12),
                                          prefixIcon: Icon(Icons.computer),
                                          helperText:
                                              '이전에 사용한 IP 주소가 자동으로 표시됩니다',
                                        ),
                                        enabled: !_isConnected,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (value) {
                                          if (!_isConnected) {
                                            _connect();
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
                                          contentPadding: EdgeInsets.all(12),
                                        ),
                                        enabled: !_isConnected,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (value) {
                                          if (!_isConnected) {
                                            _connect();
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
                                    borderRadius: BorderRadius.circular(8),
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
                                    labelText: 'Session ID (PC에서 먼저 생성·연결한 ID)',
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
                                      _connect();
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
                                    borderRadius: BorderRadius.circular(8),
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
                                          '최근 연결',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                        Text(
                                          '탭하면 재연결됩니다',
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
                                        final confirm = await showDialog<bool>(
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
                                                    Navigator.of(ctx).pop(true),
                                                child: const Text('전체 삭제'),
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
                                    borderRadius: BorderRadius.circular(12),
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
                                                  _connectFromHistory(item),
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: index == 0
                                                    ? const Radius.circular(12)
                                                    : Radius.zero,
                                                bottom: isLast
                                                    ? const Radius.circular(12)
                                                    : Radius.zero,
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                        color: item.type ==
                                                                ConnectionType
                                                                    .local
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .secondaryContainer
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .primaryContainer,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Icon(
                                                        item.type ==
                                                                ConnectionType
                                                                    .local
                                                            ? Icons.computer
                                                            : Icons.cloud,
                                                        size: 14,
                                                        color: item.type ==
                                                                ConnectionType
                                                                    .local
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .onSecondaryContainer
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onPrimaryContainer,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item.displayText,
                                                            style: TextStyle(
                                                              fontSize: 13,
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
                                                            item.relativeTime,
                                                            style: TextStyle(
                                                              fontSize: 11,
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
                                                      Icons.settings_ethernet,
                                                      size: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.delete_outline,
                                                        size: 20,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .error,
                                                      ),
                                                      onPressed: () async {
                                                        final confirm =
                                                            await showDialog<
                                                                bool>(
                                                          context: context,
                                                          builder: (ctx) =>
                                                              AlertDialog(
                                                            title: const Text(
                                                                '연결 삭제'),
                                                            content: Text(
                                                              '${item.displayText} 항목을 삭제하시겠습니까?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            ctx)
                                                                        .pop(
                                                                            false),
                                                                child:
                                                                    const Text(
                                                                        '취소'),
                                                              ),
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            ctx)
                                                                        .pop(
                                                                            true),
                                                                child:
                                                                    const Text(
                                                                        '삭제'),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirm == true) {
                                                          await AppSettings()
                                                              .removeConnectionHistory(
                                                                  item);
                                                        }
                                                      },
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                              minWidth: 32,
                                                              minHeight: 32),
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
                                    borderRadius: BorderRadius.circular(8),
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
                                              AlwaysStoppedAnimation<Color>(
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
                                        onPressed: _stopReconnect,
                                        child: const Text('취소',
                                            style: TextStyle(fontSize: 12)),
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
                                    borderRadius: BorderRadius.circular(12),
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
                                        color:
                                            Theme.of(context).colorScheme.error,
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
                                      onPressed: _isConnected || _isReconnecting
                                          ? null
                                          : _connect,
                                      icon: Icon(
                                        _connectionType == ConnectionType.local
                                            ? Icons.computer
                                            : Icons.cloud,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _connectionType == ConnectionType.local
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
                                        icon:
                                            const Icon(Icons.refresh, size: 18),
                                        label: const Text('재연결'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _isConnected ? _disconnect : null,
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
                                                  ? '로컬 서버에 연결됨'
                                                  : '릴레이 서버에 연결됨',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            if (_connectionType ==
                                                    ConnectionType.relay &&
                                                _sessionId != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '세션 ID: $_sessionId',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontFamily: 'monospace',
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.copy,
                                                        size: 16),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                          ClipboardData(
                                                              text:
                                                                  _sessionId!));
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              '세션 ID가 클립보드에 복사되었습니다'),
                                                          duration: Duration(
                                                              seconds: 1),
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
                              ] else if (!_isConnected && !_isReconnecting) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minWidth: 200),
                                    child: SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment<String>(
                                          value: _searchScopeAll,
                                          label: Text('전체',
                                              softWrap: false,
                                              overflow: TextOverflow.clip),
                                          icon: Icon(Icons.chat, size: 14),
                                        ),
                                        ButtonSegment<String>(
                                          value: _searchScopeAnswerOnly,
                                          label: Text('답변만',
                                              softWrap: false,
                                              overflow: TextOverflow.clip),
                                          icon: Icon(Icons.smart_toy, size: 14),
                                        ),
                                      ],
                                      selected: {_searchScope},
                                      onSelectionChanged: (Set<String> s) {
                                        setState(() => _searchScope = s.first);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (v) =>
                                          setState(() => _searchQuery = v),
                                      decoration: InputDecoration(
                                        hintText: '메시지 검색',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                        prefixIcon:
                                            const Icon(Icons.search, size: 20),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear,
                                                    size: 18),
                                                onPressed: () => setState(
                                                    () => _searchQuery = ''),
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
                                                  MessageFilter.aiResponse] ??
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
                                    checkmarkColor:
                                        Theme.of(context).colorScheme.tertiary,
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
                                                  MessageFilter.userPrompt] ??
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
                                    checkmarkColor:
                                        Theme.of(context).colorScheme.secondary,
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
                                      textColor:
                                          (_activeFilters[MessageFilter.log] ??
                                                  false)
                                              ? const Color(0xFF7A4B00)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                      iconColor:
                                          (_activeFilters[MessageFilter.log] ??
                                                  false)
                                              ? const Color(0xFFFF9800)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                    ),
                                    selected:
                                        _activeFilters[MessageFilter.log] ??
                                            false,
                                    selectedColor:
                                        const Color(0xFFFFF3E0), // 오렌지 배경
                                    checkmarkColor:
                                        const Color(0xFFFF9800), // 오렌지
                                    onSelected: (selected) {
                                      setState(() {
                                        _activeFilters[MessageFilter.log] =
                                            selected;
                                        // 로그 필터 활성화 시 레벨 필터 모두 체크
                                        if (selected) {
                                          _logLevelFilters[LogLevel.error] =
                                              true;
                                          _logLevelFilters[LogLevel.warning] =
                                              true;
                                          _logLevelFilters[LogLevel.info] =
                                              true;
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
                                        textColor:
                                            (_logLevelFilters[LogLevel.error] ??
                                                    true)
                                                ? const Color(0xFF8B1E2D)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                        iconColor: const Color(0xFFDC3545),
                                        iconSize: 12,
                                        fontSize: 10,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      selected:
                                          _logLevelFilters[LogLevel.error] ??
                                              true,
                                      selectedColor: const Color(0xFFFFEBEE),
                                      checkmarkColor: const Color(0xFFDC3545),
                                      onSelected: (selected) {
                                        setState(() {
                                          _logLevelFilters[LogLevel.error] =
                                              selected;
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
                                        iconColor: const Color(0xFFFF9800),
                                        iconSize: 12,
                                        fontSize: 10,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      selected:
                                          _logLevelFilters[LogLevel.warning] ??
                                              true,
                                      selectedColor: const Color(0xFFFFF3E0),
                                      checkmarkColor: const Color(0xFFFF9800),
                                      onSelected: (selected) {
                                        setState(() {
                                          _logLevelFilters[LogLevel.warning] =
                                              selected;
                                        });
                                      },
                                    ),
                                    FilterChip(
                                      label: _buildFilterChipLabel(
                                        icon: Icons.info,
                                        text: 'Info',
                                        textColor:
                                            (_logLevelFilters[LogLevel.info] ??
                                                    true)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onTertiaryContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                        iconColor:
                                            (_logLevelFilters[LogLevel.info] ??
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
                                      visualDensity: VisualDensity.compact,
                                      selected:
                                          _logLevelFilters[LogLevel.info] ??
                                              true,
                                      selectedColor: Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer,
                                      checkmarkColor: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      onSelected: (selected) {
                                        setState(() {
                                          _logLevelFilters[LogLevel.info] =
                                              selected;
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
                                    selected:
                                        _activeFilters[MessageFilter.system] ??
                                            true,
                                    selectedColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    checkmarkColor: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    onSelected: (selected) {
                                      setState(() {
                                        _activeFilters[MessageFilter.system] =
                                            selected;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(child: _buildMessageListWithScrollButtons()),
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_capabilitiesLoading && !_capabilitiesLoaded)
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
                                      '모델 목록을 불러오는 중...',
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
                                      borderRadius: BorderRadius.circular(12),
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
                                              _availableModels.any((item) =>
                                                  (item['model'] ?? '')
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
                                      dropdownColor:
                                          Theme.of(context).colorScheme.surface,
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
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        ..._availableModels.map((item) {
                                          final model =
                                              (item['model'] ?? '').toString();
                                          final displayName =
                                              _getModelDisplayName(
                                                  model.trim());
                                          return DropdownMenuItem(
                                            value: model.trim(),
                                            child: Text(
                                              'Model: $displayName',
                                              style:
                                                  const TextStyle(fontSize: 12),
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
                                              .setDefaultModel(_selectedModel));
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
                                      borderRadius: BorderRadius.circular(12),
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
                                      dropdownColor:
                                          Theme.of(context).colorScheme.surface,
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
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        ..._getAvailableReasoningEffortsForModel(
                                                _selectedModel)
                                            .map((effort) => DropdownMenuItem(
                                                  value: effort,
                                                  child: Text(
                                                    'Reasoning: ${effort[0].toUpperCase()}${effort.substring(1)}',
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                )),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedReasoningEffort =
                                                _normalizeReasoningEffort(
                                                    value, _selectedModel);
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _capabilitiesLoaded
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
                          // KeyboardListener: Enter 전송. 컨트롤러에서 읽고 debounce + 전송 후 한 프레임 뒤 재정리로 IME 중복 전송 방지.
                          // (Focus+동일 FocusNode는 focus_manager assertion 유발로 사용 안 함)
                          KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) {
                              if (event is! KeyDownEvent ||
                                  event.logicalKey !=
                                      LogicalKeyboardKey.enter ||
                                  HardwareKeyboard.instance.isShiftPressed ||
                                  !_commandFocusNode.hasFocus ||
                                  !_isConnected) {
                                return;
                              }
                              final now = DateTime.now();
                              if (_lastPromptSubmitTime != null &&
                                  now
                                          .difference(_lastPromptSubmitTime!)
                                          .inMilliseconds <
                                      400) {
                                return;
                              }
                              final text = _commandController.text.trim();
                              if (text.isEmpty) return;
                              _lastPromptSubmitTime = now;
                              _sendCommand('insert_text',
                                  text: text,
                                  prompt: true,
                                  execute: true,
                                  newSession: false,
                                  agentMode: _selectedAgentMode);
                              _clearCommandInput();
                            },
                            // ValueListenableBuilder로 입력창 감싸기 (전체 UI 리빌드 방지)
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _commandController,
                              builder: (context, textValue, child) {
                                final hasText =
                                    textValue.text.trim().isNotEmpty;
                                return TextField(
                                  key: ValueKey(_textFieldKey),
                                  controller: _commandController,
                                  focusNode: _commandFocusNode,
                                  decoration: InputDecoration(
                                    labelText: '프롬프트 입력',
                                    hintText: 'Codex에게 요청할 내용을 입력하세요...',
                                    prefixIcon: const Icon(Icons.edit_note),
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
                                  textInputAction: TextInputAction.newline,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 3,
                                  minLines: 2,
                                  enableSuggestions: true,
                                  autocorrect: true,
                                  textCapitalization: TextCapitalization.none,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 버튼 영역도 ValueListenableBuilder로 감싸기
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _commandController,
                            builder: (context, textValue, child) {
                              final hasText = textValue.text.trim().isNotEmpty;
                              return Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _isConnected &&
                                              hasText &&
                                              !_isWaitingForResponse
                                          ? () {
                                              if (!mounted) return;
                                              final text = _commandController
                                                  .text
                                                  .trim();
                                              if (text.isNotEmpty) {
                                                _sendCommand('insert_text',
                                                    text: text,
                                                    prompt: true,
                                                    execute: true,
                                                    newSession: false,
                                                    agentMode:
                                                        _selectedAgentMode);
                                                _clearCommandInput();
                                              }
                                            }
                                          : null,
                                      icon: _isWaitingForResponse
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
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
                                          : const Icon(Icons.send, size: 18),
                                      label: Text(_isWaitingForResponse
                                          ? '전송 중...'
                                          : '전송'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
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
                                                _isWaitingForResponse = false;
                                              });
                                              _sendCommand('stop_prompt');
                                            }
                                          : null,
                                      icon: const Icon(Icons.stop, size: 18),
                                      label: const Text('중지'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 16),
                                      ),
                                    ),
                                  ] else ...[
                                    OutlinedButton.icon(
                                      onPressed: _isConnected && hasText
                                          ? () {
                                              if (!mounted) return;
                                              final text = _commandController
                                                  .text
                                                  .trim();
                                              if (text.isNotEmpty) {
                                                _sendCommand('insert_text',
                                                    text: text,
                                                    prompt: true,
                                                    execute: true,
                                                    newSession: true,
                                                    agentMode:
                                                        _selectedAgentMode);
                                                _clearCommandInput();
                                              }
                                            }
                                          : null,
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('새 대화'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 16),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          // 세션 정보 및 대화 히스토리 표시 (설정에서 활성화한 경우만)
                          if (_isConnected && AppSettings().showHistory) ...[
                            // 현재 세션 정보
                            if (_currentCodexSessionId != null)
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                margin: const EdgeInsets.only(bottom: 8.0),
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                                      borderRadius: BorderRadius.circular(8),
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
                                    if (_availableSessions.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
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
                                      ..._availableSessions.map((sessionId) =>
                                          ListTile(
                                            dense: true,
                                            leading: const Icon(Icons.chat,
                                                size: 16),
                                            title: Text(
                                              sessionId.length > 20
                                                  ? '${sessionId.substring(0, 20)}...'
                                                  : sessionId,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.refresh,
                                                  size: 16),
                                              onPressed: () => _loadChatHistory(
                                                  sessionId: sessionId),
                                              tooltip: '이 세션의 대화 히스토리 조회',
                                            ),
                                          )),
                                      const Divider(),
                                    ],

                                    // 대화 히스토리
                                    if (_chatHistory.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
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
                                            final entry = _chatHistory[index];
                                            final userMsg = entry['userMessage']
                                                    as String? ??
                                                '';
                                            final assistantMsg =
                                                entry['assistantResponse']
                                                        as String? ??
                                                    '';
                                            final timestamp =
                                                entry['timestamp'] as String? ??
                                                    '';
                                            final agentMode =
                                                entry['agentMode'] as String?;

                                            // 디버깅: 모든 항목 로그 출력 (문제 확인용)
                                            print(
                                                '📋 History entry[$index] - agentMode: $agentMode, userMsg: ${userMsg.length > 20 ? '${userMsg.substring(0, 20)}...' : userMsg}');
                                            print(
                                                '📋 Full entry keys: ${entry.keys.toList()}');

                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 4.0),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                    const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (userMsg.isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 4.0),
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
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            ),
                                                            // 에이전트 모드 표시 (null이 아니고 비어있지 않은 경우, auto도 표시)
                                                            if (agentMode !=
                                                                    null &&
                                                                agentMode
                                                                    .isNotEmpty) ...[
                                                              const SizedBox(
                                                                  width: 4),
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        3),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primaryContainer,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border
                                                                      .all(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                        .withOpacity(
                                                                            0.3),
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                      _getModeIcon(
                                                                          agentMode),
                                                                      size: 12,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .onPrimaryContainer,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Text(
                                                                      _getModeDisplayName(
                                                                          agentMode),
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .onPrimaryContainer,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                    if (assistantMsg.isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 4.0),
                                                        child: Text(
                                                          '🤖 ${assistantMsg.length > 50 ? "${assistantMsg.substring(0, 50)}..." : assistantMsg}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 11),
                                                        ),
                                                      ),
                                                    if (timestamp.isNotEmpty)
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
                                        padding: const EdgeInsets.all(24.0),
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
                                                fontWeight: FontWeight.w500,
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
                                        icon:
                                            const Icon(Icons.refresh, size: 18),
                                        label: const Text('새로고침'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
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
                                      borderRadius: BorderRadius.circular(8),
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
                                            icon: const Icon(Icons.refresh,
                                                size: 16),
                                            label: const Text('새로고침'),
                                          ),
                                          const SizedBox(width: 8),
                                          PopupMenuButton<AutoDecisionMode>(
                                            tooltip: 'Auto response mode',
                                            onSelected: (mode) {
                                              setState(() {
                                                _autoDecisionMode = mode;
                                              });
                                              final label =
                                                  _autoDecisionModeLabel(mode);
                                              _messages.add(MessageItem(
                                                  '⚙️ 승인 자동응답 모드: $label',
                                                  type: MessageType.system));
                                              _scrollToBottom();
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: AutoDecisionMode.off,
                                                child: Text('Manual'),
                                              ),
                                              PopupMenuItem(
                                                value: AutoDecisionMode.approve,
                                                child: Text('Auto-approve'),
                                              ),
                                              PopupMenuItem(
                                                value: AutoDecisionMode.reject,
                                                child: Text('Auto-reject'),
                                              ),
                                            ],
                                            child: Chip(
                                              label: Text(
                                                  _autoDecisionModeLabel(
                                                      _autoDecisionMode),
                                                  style: const TextStyle(
                                                      fontSize: 11)),
                                              avatar: const Icon(Icons.timer,
                                                  size: 14),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          PopupMenuButton<int>(
                                            tooltip: 'Auto response timeout',
                                            onSelected: (seconds) {
                                              setState(() {
                                                _autoDecisionTimeoutSec =
                                                    seconds;
                                              });
                                              _messages.add(MessageItem(
                                                  '⚙️ 자동응답 대기시간: ${seconds}s',
                                                  type: MessageType.system));
                                              _scrollToBottom();
                                            },
                                            itemBuilder: (context) => const [
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
                                              avatar: const Icon(Icons.schedule,
                                                  size: 14),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (_loadingCommandApprovals ||
                                              _loadingCommandEvents)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
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
                                    if (_pendingCodexServerRequests.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
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
                                            request['requestId']?.toString() ??
                                                '';
                                        final requestKind =
                                            request['requestKind']
                                                    ?.toString() ??
                                                '';
                                        final summary =
                                            _codexRequestSummary(request);
                                        final detailLines = List<String>.from(
                                            (request['detailLines'] as List? ??
                                                    [])
                                                .map((e) => e.toString()));
                                        final requestTimeLabel =
                                            _timestampLabelFromMap(request,
                                                preferredKeys: const [
                                              'timestamp',
                                              'created_at',
                                              'createdAt'
                                            ]);
                                        final choices = List<
                                                Map<String, dynamic>>.from(
                                            (request['choices'] as List? ?? [])
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
                                          margin: const EdgeInsets.fromLTRB(
                                              12, 4, 12, 4),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            side: BorderSide(
                                              color:
                                                  accentColor.withOpacity(0.35),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: accentColor
                                                        .withOpacity(0.10),
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                        color: accentColor,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Action required',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: accentColor,
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
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      requestTimeLabel,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.open_in_new,
                                                          size: 16),
                                                      tooltip: 'Detail',
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      onPressed: () {
                                                        _showCodexRequestDetailSheet(
                                                            request);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                if (summary.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    summary,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ],
                                                if (detailLines.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  ...detailLines.take(3).map(
                                                        (line) => Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 2),
                                                          child: Text(
                                                            line,
                                                            style: TextStyle(
                                                              fontSize: 11,
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
                                                    fontWeight: FontWeight.w600,
                                                    color: accentColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                if (requestKind == 'user_input')
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: FilledButton(
                                                          onPressed:
                                                              isSubmitting
                                                                  ? null
                                                                  : () {
                                                                      _openCodexUserInputDialog(
                                                                          request);
                                                                    },
                                                          child: Text(
                                                              isSubmitting
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
                                                    children:
                                                        choices.map((choice) {
                                                      final label = choice[
                                                                  'label']
                                                              ?.toString() ??
                                                          'Respond';
                                                      final style = choice[
                                                                  'style']
                                                              ?.toString() ??
                                                          'secondary';
                                                      final responsePayload =
                                                          Map<String,
                                                                  dynamic>.from(
                                                              choice['response']
                                                                      as Map? ??
                                                                  {});
                                                      final buttonChild = Text(
                                                          isSubmitting
                                                              ? 'Sending...'
                                                              : label);
                                                      if (style == 'primary') {
                                                        return FilledButton(
                                                          onPressed:
                                                              isSubmitting
                                                                  ? null
                                                                  : () {
                                                                      _submitCodexDecision(
                                                                          request,
                                                                          responsePayload);
                                                                    },
                                                          child: buttonChild,
                                                        );
                                                      }
                                                      return OutlinedButton(
                                                        onPressed: isSubmitting
                                                            ? null
                                                            : () {
                                                                _submitCodexDecision(
                                                                    request,
                                                                    responsePayload);
                                                              },
                                                        style: style == 'danger'
                                                            ? OutlinedButton
                                                                .styleFrom(
                                                                foregroundColor:
                                                                    Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .error,
                                                              )
                                                            : null,
                                                        child: buttonChild,
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
                                        padding: const EdgeInsets.fromLTRB(
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
                                            _approvalRequestTypeLabel(approval);
                                        final requestedBy =
                                            _approvalRequestedBy(approval);
                                        final cwd =
                                            _approvalWorkingDirectory(approval);
                                        final policy = approval['policy']
                                                as Map<String, dynamic>? ??
                                            {};
                                        final createdAtLabel =
                                            _timestampLabelFromMap(approval);
                                        final riskLevel =
                                            policy['risk_level']?.toString() ??
                                                'unknown';
                                        final reasons =
                                            (policy['reasons'] as List? ?? [])
                                                .map((e) => e.toString())
                                                .join(', ');
                                        return Card(
                                          margin: const EdgeInsets.fromLTRB(
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
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                            style: TextStyle(
                                                              fontSize: 10,
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
                                                              fontSize: 12,
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
                                                            style: TextStyle(
                                                              fontSize: 10,
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
                                                            style: TextStyle(
                                                              fontSize: 10,
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _riskColor(
                                                                riskLevel)
                                                            .withOpacity(0.14),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        riskLevel,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: _riskColor(
                                                              riskLevel),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (reasons.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    reasons,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton.icon(
                                                    onPressed: () {
                                                      _showRelayApprovalDetailSheet(
                                                          approval);
                                                    },
                                                    icon: const Icon(
                                                        Icons.open_in_new,
                                                        size: 16),
                                                    label: const Text('Detail'),
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
                                                        child:
                                                            const Text('Later'),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: () async {
                                                          await _confirmAndResolveApproval(
                                                              approval,
                                                              'reject');
                                                        },
                                                        child: const Text(
                                                            'Reject'),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: FilledButton(
                                                        onPressed: () async {
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
                                        padding: const EdgeInsets.fromLTRB(
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
                                                as Map<String, dynamic>? ??
                                            {};
                                        final command = event['command']
                                                as Map<String, dynamic>? ??
                                            {};
                                        final approval = event['approval']
                                                as Map<String, dynamic>? ??
                                            {};
                                        final risk = event['risk']
                                                as Map<String, dynamic>? ??
                                            {};
                                        final status =
                                            result['status']?.toString() ??
                                                'unknown';
                                        final raw =
                                            command['raw']?.toString() ??
                                                '(unknown)';
                                        final approvalStatus =
                                            approval['status']?.toString() ??
                                                'not_required';
                                        final riskLevel =
                                            risk['level']?.toString() ?? 'low';
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
                                              size: 16, color: statusColor),
                                          title: Text(
                                            '$status • $raw',
                                            style:
                                                const TextStyle(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            'risk: $riskLevel · approval: $approvalStatus',
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        );
                                      }),
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
            ),
    );
  }
}

// ============================================================
// 설정 화면
// ============================================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettings _settings = AppSettings();

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
      ),
      body: ListView(
        children: [
          // 외관 섹션
          _buildSectionHeader('외관'),
          _buildThemeModeTile(),
          const Divider(),

          // 기능 섹션
          _buildSectionHeader('기능'),
          _buildShowHistoryTile(),
          const Divider(),

          // 정보 섹션
          _buildSectionHeader('정보'),
          _buildAboutTile(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildThemeModeTile() {
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
      onTap: () => _showThemeModeDialog(),
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

  void _showThemeModeDialog() {
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

  Widget _buildShowHistoryTile() {
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

  Widget _buildAboutTile() {
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
      subtitle: const Text('버전 0.1.5'),
      onTap: () => _showAboutDialog(),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Codex Remote',
      applicationVersion: '0.1.5',
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
        const Text(
          '모바일에서 Codex를 원격으로 제어하세요.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '© 2026 jaloveeye',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
