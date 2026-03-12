import 'package:flutter/material.dart';

import 'app_settings.dart';

enum AppTextKey {
  settings,
  demoMode,
  demoModeStart,
  demoModeStartSub,
  demoModeStop,
  demoModeStopSub,
  demoModeStartDialogTitle,
  demoModeStartDialogContent,
  demoModeStopDialogTitle,
  demoModeStopDialogContent,
  demoModeStartButton,
  demoModeStopButton,
  dialogCancel,
  startDemo,
  leaveDemo,
  settingsAppearance,
  settingsFunction,
  settingsInfo,
  theme,
  themeLight,
  themeDark,
  themeSystem,
  themeSelect,
  showHistoryTitle,
  showHistorySub,
  aboutTitle,
  appVersion,
  appVersionSub,
  language,
  languageSystem,
  languageKorean,
  languageEnglish,
  languageSelectTitle,
  languageSub,
  releaseSoonTitle,
  releaseSoonMessage,
  quickOpenSettings,
  demoModeTooltipStart,
  demoModeTooltipStop,
  connectionReadyText,
  recentConnections,
  refreshTooltip,
  statusConnected,
  statusNotConnected,
  connectAction,
  disconnectAction,
  connectingAction,
  sessionsTitle,
  sessionsLocalConnectedText,
  sessionsRelayConnectedText,
  sessionsDisconnectedHint,
  currentCodexSessionLabel,
  sessionsNoHistoryTitle,
  sessionsNoHistoryMessage,
  homeTabChatTitle,
  homeTabApprovalsTitle,
  homeTabSessionsTitle,
  homeTabSettingsTitle,
  homeTabChatSubtitleConnected,
  homeTabChatSubtitleDisconnected,
  homeTabApprovalsSubtitle,
  homeTabSessionsSubtitle,
  homeTabSettingsSubtitle,
  homeTabPendingResponse,
  openFullSettings,
  settingsTabHint,
  localServerMode,
  relayServerMode,
  sessionLabel,
  setConnectionHint,
  connectionTypeLabel,
  tapReconnectHint,
  onboardingTitle,
  onboardingSubtitle,
  onboardingFeatureConnection,
  onboardingFeatureConnectionDesc,
  onboardingFeatureApprovals,
  onboardingFeatureApprovalsDesc,
  onboardingFeatureChat,
  onboardingFeatureChatDesc,
  onboardingStartButton,
  onboardingDemoButton,
  approvalsTitle,
  approvalsNotReadyTitle,
  approvalsNotReadyMessage,
  openChatScreen,
  approvalsCodexRequestMetric,
  approvalsRelayApprovalMetric,
  approvalsPendingCodexSection,
  approvalsNoPendingCodexTitle,
  approvalsNoPendingCodexMessage,
  approvalsPendingRelaySection,
  approvalsNoPendingRelayTitle,
  approvalsNoPendingRelayMessage,
  approvalsHistorySection,
  approvalsNoHistoryTitle,
  approvalsNoHistoryMessage,
  sending,
  respond,
  requesterLabel,
  approvalIdLabel,
  approvalAllow,
  approvalLater,
  approvalReject,
  promptModelSelectorTooltip,
  promptModelLabel,
  promptReasoningSelectorTooltip,
  promptReasoningLabel,
  homeConnectionTitle,
  connectionIntroTitle,
  connectionIntroDescription,
  connectionActionLocalConnecting,
  connectionActionRelayConnecting,
  connectionActionLocalPreparing,
  connectionActionRelayPreparing,
  connectionActionNotCompleted,
  connectionActionPendingPin,
  connectionActionConnectingWithPin,
  connectionActionPinRejected,
  connectionActionConnect,
  connectionActionCreateAndConnect,
  connectionActionReconnect,
  connectionActionInProgress,
  connectionFailurePrefix,
  connectionHistoryLabel,
  connectionHistoryDelete,
  connectionHistoryDeleteTitle,
  connectionHistoryDeleteMessage,
  connectionHistoryDeleteCancel,
  connectionHistoryDeleteConfirm,
  connectionMessageNoSearchResults,
  connectionMessageNoMessages,
  connectionMessageStartHint,
  chatPromptInputHint,
  chatPromptInputHintGenerating,
  chatPromptInputLabel,
  chatPromptInputHintDetailed,
  chatSendTooltip,
  chatSendButton,
  chatStopButton,
  chatCopyLabel,
  chatStopLabel,
  chatNewConversationLabel,
  messageSectionTitle,
  messageFilterAll,
  messageFilterAnswerOnly,
  messageSearchHint,
  messageFilterAiResponse,
  messageFilterUserPrompt,
  messageFilterLogs,
  messageFilterSystem,
  messageFilterError,
  messageFilterWarn,
  messageFilterInfo,
  messageWaiting,
  demoModePopupTitleExit,
  demoModePopupContentExit,
  demoModeSampleIntro,
  demoModeSampleSessionSummary,
  demoModeSampleRelaySessionLine,
  demoModeSamplePromptStart,
  demoModeSampleAssistantStart,
  demoModeSamplePromptReview,
  demoModeSampleAssistantReview,
  demoModeDemoApprovalActionSampleMessage,
  demoModeDemoRequestActionSampleMessage,
  demoModeNeedsMobileActionNotice,
  demoModeDeferredApprovalNotice,
  demoModeDisconnectActionSampleMessage,
  demoModeResponseFallback,
  demoModeReviewModeDescription,
  demoModeSessionAutoConfiguredMessage,
  demoModeApprovalGuideMessage,
  demoModeFeatureGuideMessage,
  modelCatalogLoadingLabelLoading,
  modelCatalogLoadingLabelDefaultReady,
  modelCatalogLoadingLabelSyncing,
  modelCatalogLoadingLabelDelayed,
  modelCatalogLoadingLabelFailed,
  modelCatalogSyncDelayNotice,
  modelCatalogSyncDelayNoticeWithElapsed,
  modelCatalogDefaultModelLoaded,
  modelCatalogSyncingModels,
  modelCatalogAllLoaded,
  modelCatalogAllLoadedWithElapsed,
  modelCatalogListRefreshed,
  modelCatalogCacheApplied,
  modelCatalogSyncLatestLoading,
  modelCatalogLoadFromNetwork,
  modelCatalogLoadFailed,
  modelCatalogCapabilitiesCached,
  modelCatalogCapabilitiesLoaded,
  modelCatalogCapabilitiesFallback,
  modelCatalogRuntimeCapabilitiesSummary,
  modelSettingsTitle,
  modelDropdownAutoLabel,
  modelDropdownModelLabel,
  reasoningDropdownAutoLabel,
  reasoningDropdownValueLabel,
  modelCatalogSummaryLine,
  modelCatalogIdeContextFilter,
  modelCatalogFlatModeFilter,
  pinDialogTitle,
  pinDialogDescription,
  pinDialogInputLabel,
  pinDialogInputHint,
  pinDialogConfirm,
  pinDialogConfirming,
  pinDialogErrorTitle,
  pinDialogErrorMessage,
  pinDialogInvalidMessage,
  forceStopReconnect,
  lastErrorLabel,
  sessionHistoryTitle,
  currentSessionLabel,
  availableSessionsTitle,
  viewSessionHistoryAction,
  chatHistoryTitle,
  chatHistoryNoMessages,
}

class AppI18n {
  AppI18n._();

  static const Map<AppLanguageSetting, Map<AppTextKey, String>> _ko = {
    AppLanguageSetting.korean: {
      AppTextKey.settings: '설정',
      AppTextKey.demoMode: '앱 둘러보기',
      AppTextKey.demoModeStart: '앱 둘러보기',
      AppTextKey.demoModeStartSub: '실제 연결 없이도 화면 흐름을 확인할 수 있는 심사 모드로 전환합니다.',
      AppTextKey.demoModeStartDialogContent:
          '실제 연결 없이 화면/기능 흐름을 확인하는 둘러보기 모드로 전환합니다.',
      AppTextKey.demoModeStop: '앱 둘러보기 모드',
      AppTextKey.demoModeStopSub:
          '현재 둘러보기 모드입니다. 실제 연결 기능은 제외된 상태로 UI/기능 흐름만 확인 가능합니다.',
      AppTextKey.demoModeStartDialogTitle: '앱 둘러보기 시작',
      AppTextKey.demoModeStopDialogContent:
          '심사용 둘러보기 모드를 종료하고 실제 연결 화면으로 이동합니다.',
      AppTextKey.demoModeStopDialogTitle: '둘러보기 모드 종료',
      AppTextKey.demoModeStartButton: '시작',
      AppTextKey.demoModeStopButton: '종료하기',
      AppTextKey.dialogCancel: '취소',
      AppTextKey.startDemo: '둘러보기 시작',
      AppTextKey.leaveDemo: '둘러보기 나가기',
      AppTextKey.settingsAppearance: '외관',
      AppTextKey.settingsFunction: '기능',
      AppTextKey.settingsInfo: '정보',
      AppTextKey.theme: '테마',
      AppTextKey.themeLight: '라이트 모드',
      AppTextKey.themeDark: '다크 모드',
      AppTextKey.themeSystem: '시스템 설정',
      AppTextKey.themeSelect: '테마 선택',
      AppTextKey.showHistoryTitle: '세션 및 대화 히스토리',
      AppTextKey.showHistorySub: '메인 화면에 히스토리 섹션 표시',
      AppTextKey.aboutTitle: 'Codex Remote',
      AppTextKey.appVersion: '버전 0.2.0',
      AppTextKey.appVersionSub: '모바일에서 Codex를 원격으로 제어하세요.',
      AppTextKey.releaseSoonTitle: '0.2.0 준비 중',
      AppTextKey.releaseSoonMessage:
          '여기에는 출시형 설정, 진단, 브랜딩, 알림 옵션이 단계적으로 추가될 예정입니다.',
      AppTextKey.language: '언어',
      AppTextKey.languageSystem: '시스템 기본값',
      AppTextKey.languageKorean: '한국어',
      AppTextKey.languageEnglish: 'English',
      AppTextKey.languageSelectTitle: '언어 선택',
      AppTextKey.languageSub: '앱 표시 언어를 선택하세요',
      AppTextKey.quickOpenSettings: '전체 설정 열기',
      AppTextKey.demoModeTooltipStart: '둘러보기 시작',
      AppTextKey.demoModeTooltipStop: '둘러보기 나가기',
      AppTextKey.connectionReadyText: '연결 준비 중...',
      AppTextKey.recentConnections: '최근 연결',
      AppTextKey.refreshTooltip: '새로고침',
      AppTextKey.statusConnected: '현재 연결됨',
      AppTextKey.statusNotConnected: '연결 안 됨',
      AppTextKey.connectAction: '연결하기',
      AppTextKey.disconnectAction: '연결 해제',
      AppTextKey.connectingAction: '처리 중...',
      AppTextKey.sessionsTitle: '세션',
      AppTextKey.sessionsLocalConnectedText: '로컬 서버에 연결되어 있습니다.',
      AppTextKey.sessionsRelayConnectedText: '릴레이 세션',
      AppTextKey.sessionsDisconnectedHint: '채팅 탭에서 로컬 또는 릴레이 연결을 시작하세요.',
      AppTextKey.currentCodexSessionLabel: '현재 Codex 세션:',
      AppTextKey.sessionsNoHistoryTitle: '최근 연결이 없어요',
      AppTextKey.sessionsNoHistoryMessage: '세션에 연결하면 최근 연결 목록이 여기에 저장됩니다.',
      AppTextKey.homeTabChatTitle: '채팅',
      AppTextKey.homeTabApprovalsTitle: '승인',
      AppTextKey.homeTabSessionsTitle: '세션',
      AppTextKey.homeTabSettingsTitle: '설정',
      AppTextKey.homeTabChatSubtitleConnected: '대화를 이어가고 Codex 진행 상황을 확인하세요.',
      AppTextKey.homeTabChatSubtitleDisconnected: '연결 후 바로 프롬프트를 보낼 수 있어요.',
      AppTextKey.homeTabApprovalsSubtitle: '모바일 승인 요청과 대기 중인 액션을 한곳에서 처리합니다.',
      AppTextKey.homeTabSessionsSubtitle: '연결 상태와 최근 연결 정보를 확인합니다.',
      AppTextKey.homeTabSettingsSubtitle: '앱 환경설정과 기본 동작을 정리합니다.',
      AppTextKey.homeTabPendingResponse: '응답 대기 중',
      AppTextKey.openFullSettings: '전체 설정',
      AppTextKey.settingsTabHint: '설정 탭',
      AppTextKey.localServerMode: '로컬 서버 모드',
      AppTextKey.relayServerMode: '릴레이 모드',
      AppTextKey.sessionLabel: '세션',
      AppTextKey.setConnectionHint: '연결을 설정하세요',
      AppTextKey.connectionTypeLabel: '연결 타입',
      AppTextKey.tapReconnectHint: '탭하면 재연결됩니다',
      AppTextKey.onboardingTitle: 'Codex Remote 시작하기',
      AppTextKey.onboardingSubtitle: '모바일에서 승인 요청과 세션 상태를 빠르게 확인하세요.',
      AppTextKey.onboardingFeatureConnection: '빠른 연결',
      AppTextKey.onboardingFeatureConnectionDesc:
          '로컬/릴레이 연결을 설정하고 Codex 세션에 즉시 접속',
      AppTextKey.onboardingFeatureApprovals: '모바일 승인',
      AppTextKey.onboardingFeatureApprovalsDesc: '승인 요청 도착 시 앱에서 바로 확인하고 처리',
      AppTextKey.onboardingFeatureChat: '대화 이어가기',
      AppTextKey.onboardingFeatureChatDesc: 'Chat 탭에서 프롬프트/응답 흐름을 간결하게 관리',
      AppTextKey.onboardingStartButton: '시작하기',
      AppTextKey.onboardingDemoButton: '앱 둘러보기',
      AppTextKey.approvalsTitle: '승인',
      AppTextKey.approvalsNotReadyTitle: '승인 요청을 받을 준비가 필요해요',
      AppTextKey.approvalsNotReadyMessage:
          '릴레이 세션에 연결되면 모바일 승인 요청과 Codex 액션을 여기서 처리할 수 있어요.',
      AppTextKey.openChatScreen: '채팅 화면으로 이동',
      AppTextKey.approvalsCodexRequestMetric: 'Codex 요청',
      AppTextKey.approvalsRelayApprovalMetric: '릴레이 승인',
      AppTextKey.approvalsPendingCodexSection: '대기 중인 Codex 액션',
      AppTextKey.approvalsNoPendingCodexTitle: '대기 중인 Codex 요청이 없어요',
      AppTextKey.approvalsNoPendingCodexMessage:
          '명령 실행, 파일 변경, 추가 입력 요청이 오면 이곳에 표시됩니다.',
      AppTextKey.approvalsPendingRelaySection: '릴레이 승인 요청',
      AppTextKey.approvalsNoPendingRelayTitle: '대기 중인 승인 요청이 없어요',
      AppTextKey.approvalsNoPendingRelayMessage:
          '릴레이 서버를 통한 실행 승인 요청이 생기면 여기에 표시됩니다.',
      AppTextKey.approvalsHistorySection: '처리 히스토리',
      AppTextKey.approvalsNoHistoryTitle: '처리된 승인 기록이 아직 없어요',
      AppTextKey.approvalsNoHistoryMessage:
          '승인/거부한 요청은 여기에서 최근 기록으로 확인할 수 있어요.',
      AppTextKey.sending: '전송 중...',
      AppTextKey.respond: '응답하기',
      AppTextKey.requesterLabel: '요청자',
      AppTextKey.approvalIdLabel: 'ID',
      AppTextKey.approvalAllow: '허용',
      AppTextKey.approvalLater: '나중에',
      AppTextKey.approvalReject: '거부',
      AppTextKey.promptModelSelectorTooltip: '모델 선택',
      AppTextKey.promptModelLabel: '모델',
      AppTextKey.promptReasoningSelectorTooltip: '이성 선택',
      AppTextKey.promptReasoningLabel: '이성',
      AppTextKey.homeConnectionTitle: '연결',
      AppTextKey.connectionIntroTitle: '첫 연결을 시작해요',
      AppTextKey.connectionIntroDescription:
          '연결이 완료되면 Chat/Approvals/Sessions/Settings를 사용할 수 있어요.',
      AppTextKey.connectionActionLocalConnecting: '로컬 서버 연결 요청 중...',
      AppTextKey.connectionActionRelayConnecting: '릴레이 세션 연결 요청 중...',
      AppTextKey.connectionActionLocalPreparing: '로컬 서버 연결 준비 중...',
      AppTextKey.connectionActionRelayPreparing: '릴레이 세션 연결 준비 중...',
      AppTextKey.connectionActionNotCompleted: '연결 요청이 완료되지 않았습니다.',
      AppTextKey.connectionActionPendingPin: 'PIN 입력 대기 중...',
      AppTextKey.connectionActionConnectingWithPin: 'PIN 확인 후 연결 중...',
      AppTextKey.connectionActionPinRejected: 'PIN을 입력하지 않아 연결하지 않았습니다.',
      AppTextKey.connectionActionConnect: '연결',
      AppTextKey.connectionActionCreateAndConnect: '생성 & 연결',
      AppTextKey.connectionActionReconnect: '재연결',
      AppTextKey.connectionActionInProgress: '처리 중...',
      AppTextKey.connectionFailurePrefix: '연결 실패:',
      AppTextKey.connectionHistoryLabel: '최근 연결 목록',
      AppTextKey.connectionHistoryDelete: '삭제',
      AppTextKey.connectionHistoryDeleteTitle: '최근 연결 삭제',
      AppTextKey.connectionHistoryDeleteMessage: '최근 연결 항목을 삭제하시겠습니까?',
      AppTextKey.connectionHistoryDeleteCancel: '취소',
      AppTextKey.connectionHistoryDeleteConfirm: '삭제',
      AppTextKey.connectionMessageNoSearchResults: '검색 결과가 없습니다',
      AppTextKey.connectionMessageNoMessages: '메시지가 없습니다',
      AppTextKey.connectionMessageStartHint: '프롬프트를 입력하여 시작하세요',
      AppTextKey.chatPromptInputHint: '메시지를 입력하세요',
      AppTextKey.chatPromptInputHintGenerating: '응답 생성 중...',
      AppTextKey.chatPromptInputLabel: '프롬프트 입력',
      AppTextKey.chatPromptInputHintDetailed: 'Codex에게 요청할 내용을 입력하세요...',
      AppTextKey.chatCopyLabel: '메시지가 클립보드에 복사되었습니다',
      AppTextKey.chatStopLabel: '중지',
      AppTextKey.chatNewConversationLabel: '새 대화',
      AppTextKey.messageSectionTitle: '메시지',
      AppTextKey.messageFilterAll: '전체',
      AppTextKey.messageFilterAnswerOnly: '답변만',
      AppTextKey.messageSearchHint: '메시지 검색',
      AppTextKey.messageFilterAiResponse: 'AI Response',
      AppTextKey.messageFilterUserPrompt: 'User Prompt',
      AppTextKey.messageFilterLogs: 'Logs',
      AppTextKey.messageFilterSystem: 'System',
      AppTextKey.messageFilterError: 'Error',
      AppTextKey.messageFilterWarn: 'Warn',
      AppTextKey.messageFilterInfo: 'Info',
      AppTextKey.messageWaiting: '응답을 기다리는 중...',
      AppTextKey.chatSendTooltip: '보내기',
      AppTextKey.chatSendButton: '전송',
      AppTextKey.chatStopButton: '중지',
      AppTextKey.modelCatalogLoadingLabelLoading: '모델 목록을 불러오는 중...',
      AppTextKey.modelCatalogLoadingLabelDefaultReady:
          '기본 모델 로딩 성공. 전체 모델을 준비 중...',
      AppTextKey.modelCatalogLoadingLabelSyncing: '이후 모든 모델을 불러오고 있습니다...',
      AppTextKey.modelCatalogLoadingLabelDelayed:
          '전체 모델 동기화가 지연되어 기본 모델을 사용 중입니다.',
      AppTextKey.modelCatalogLoadingLabelFailed: '모델 목록 로딩에 실패했어요. 다시 시도해 주세요.',
      AppTextKey.modelCatalogSyncDelayNotice:
          '⚠️ 전체 모델 로딩이 지연되어 기본 모델로 먼저 사용할게요.',
      AppTextKey.modelCatalogSyncDelayNoticeWithElapsed:
          '⚠️ 전체 모델 로딩이 {elapsed}초 이상 지연되어 기본 모델로 먼저 사용할게요.',
      AppTextKey.modelCatalogDefaultModelLoaded: '✅ 기본 모델 로딩 성공: {model}',
      AppTextKey.modelCatalogSyncingModels: '🔄 이후 모든 모델을 불러오고 있습니다...',
      AppTextKey.modelCatalogAllLoaded:
          '🔔 전체 모델 로딩 완료: {count}개 (기본: {model})',
      AppTextKey.modelCatalogAllLoadedWithElapsed:
          '🔔 전체 모델 로딩 완료: {count}개 (기본: {model}, {elapsed}ms)',
      AppTextKey.modelCatalogListRefreshed:
          '🔁 모델 목록 갱신: {previous}개 → {next}개',
      AppTextKey.modelCatalogCacheApplied:
          '📦 캐시된 모델 {count}개 적용 (약 {minutes}분 전)',
      AppTextKey.modelCatalogSyncLatestLoading: '🔄 최신 모델 목록을 동기화하는 중...',
      AppTextKey.modelCatalogLoadFromNetwork: '🛰️ 모델 목록을 불러오는 중...',
      AppTextKey.modelCatalogLoadFailed: '❌ 모델 목록 로딩 실패: {error}',
      AppTextKey.modelCatalogCapabilitiesCached: '🧩 캐시된 모델 기능으로 동작 중입니다.',
      AppTextKey.modelCatalogCapabilitiesLoaded: '🧩 런타임 기능을 로드했습니다.',
      AppTextKey.modelCatalogCapabilitiesFallback:
          '🧩 기본 모델 기능을 사용합니다.',
      AppTextKey.modelCatalogRuntimeCapabilitiesSummary:
          '🧩 런타임 기능 로드 완료: {count}개 모델, IDE Context {ide}, Flat Mode {flat}',
      AppTextKey.modelSettingsTitle: '모델 설정',
      AppTextKey.modelDropdownAutoLabel: 'Model: Auto (기본값)',
      AppTextKey.modelDropdownModelLabel: 'Model: {model}',
      AppTextKey.reasoningDropdownAutoLabel: 'Reasoning: Auto',
      AppTextKey.reasoningDropdownValueLabel: 'Reasoning: {reasoning}',
      AppTextKey.modelCatalogSummaryLine:
          'Models: {count} · Selected: {selected} · Reasoning options: {reasoning}',
      AppTextKey.modelCatalogIdeContextFilter: 'IDE Context',
      AppTextKey.modelCatalogFlatModeFilter: 'Flat Mode',
      AppTextKey.demoModePopupTitleExit: '둘러보기 모드 종료',
      AppTextKey.demoModePopupContentExit:
          '심사용 둘러보기 모드를 종료하고 실제 연결 중심 화면으로 이동합니다.',
      AppTextKey.demoModeSampleIntro: '🔎 심사/둘러보기 모드가 활성화되어 샘플 데이터로 진입했어요.',
      AppTextKey.demoModeSampleSessionSummary:
          '📡 PC 세션 없이도 Chat/Approvals/Sessions/Settings 화면을 확인할 수 있습니다.',
      AppTextKey.demoModeSampleRelaySessionLine: '✅ 릴레이 세션: {sessionId}',
      AppTextKey.demoModeSamplePromptStart:
          '세션 ID 입력 없이도 심사 모드로 바로 시연할 수 있어요.\n\n'
              '아래 입력창에서 프롬프트를 보내면 데모 응답이 표시됩니다.',
      AppTextKey.demoModeSampleAssistantStart:
          '요청하신 내용이 데모 챗으로 들어왔습니다. 현재는 실제 모델이 아닌 샘플 응답이므로 동작 예시를 보여드리기 위한 응답입니다.',
      AppTextKey.demoModeSamplePromptReview: '승인 요청은 어디서 보나요?',
      AppTextKey.demoModeSampleAssistantReview:
          'Approvals 탭에서 Codex 요청/릴레이 승인 목록을 확인하고 반응 버튼을 눌러 응답할 수 있어요.',
      AppTextKey.demoModeDemoApprovalActionSampleMessage:
          '심사 모드에서는 승인 응답이 샘플 동작입니다.',
      AppTextKey.demoModeDemoRequestActionSampleMessage:
          '심사 모드에서는 요청 응답이 샘플 동작입니다.',
      AppTextKey.demoModeNeedsMobileActionNotice: '모바일에서 선택해야 Codex가 계속 진행됩니다.',
      AppTextKey.demoModeDeferredApprovalNotice: '승인 요청을 나중에 처리하도록 남겨뒀어요.',
      AppTextKey.demoModeDisconnectActionSampleMessage:
          '심사 모드에서는 연결 종료 버튼이 샘플 동작입니다.',
      AppTextKey.demoModeResponseFallback:
          '[{fallback}] 데모 모드에서는 실제 서버 전송 없이 샘플 메시지로 응답합니다.',
      AppTextKey.demoModeReviewModeDescription:
          '심사/둘러보기 모드는 실제 네트워크 연결 없이 화면 확인만 가능합니다. 핵심 기능(연결 상태/채팅/승인/세션 탭)을 검토하실 수 있습니다.',
      AppTextKey.demoModeSessionAutoConfiguredMessage:
          '현재는 리뷰 데모 모드이므로 자동으로 demo-session-id로 세션이 구성되어 있습니다. 릴레이/로컬 연결은 실제 연동이 필요할 때만 수행하세요.',
      AppTextKey.demoModeApprovalGuideMessage:
          'Approvals 탭에서 Pendings를 확인하고 승인/거부 동작을 처리할 수 있습니다. 현재는 샘플 데이터/샘플 흐름을 보여주는 모드입니다.',
      AppTextKey.demoModeFeatureGuideMessage:
          '예시 질문: "승인 요청은 어디서 보나요?" 또는 "모바일에서 무엇을 할 수 있나요?" 같은 안내를 통해 앱 흐름을 확인해 보세요.',
      AppTextKey.pinDialogTitle: 'PIN 입력',
      AppTextKey.pinDialogDescription:
          '이 세션은 PC에서 PIN 보호가 설정되어 있습니다.\nPC에서 설정한 4~6자리 숫자 PIN을 입력하세요.',
      AppTextKey.pinDialogInputLabel: 'PIN',
      AppTextKey.pinDialogInputHint: '4~6자리 숫자',
      AppTextKey.pinDialogConfirm: '확인',
      AppTextKey.pinDialogConfirming: '확인 중...',
      AppTextKey.pinDialogErrorTitle: 'PIN 오류',
      AppTextKey.pinDialogErrorMessage:
          'PIN이 올바르지 않습니다.\nPC(익스텐션)에서 설정한 4~6자리 PIN을 확인하세요.',
      AppTextKey.pinDialogInvalidMessage:
          'PIN이 올바르지 않습니다. PC에서 설정한 PIN을 확인하세요.',
      AppTextKey.forceStopReconnect: '자동 재연결 중지',
      AppTextKey.lastErrorLabel: '마지막 오류',
      AppTextKey.sessionHistoryTitle: '세션 및 대화 히스토리',
      AppTextKey.currentSessionLabel: '현재 세션',
      AppTextKey.availableSessionsTitle: '사용 가능한 세션',
      AppTextKey.viewSessionHistoryAction: '이 세션의 대화 히스토리 조회',
      AppTextKey.chatHistoryTitle: '대화 히스토리',
      AppTextKey.chatHistoryNoMessages: '대화 히스토리가 없습니다',
    },
  };

  static const Map<AppLanguageSetting, Map<AppTextKey, String>> _en = {
    AppLanguageSetting.english: {
      AppTextKey.settings: 'Settings',
      AppTextKey.demoMode: 'Demo Mode',
      AppTextKey.demoModeStart: 'Demo Mode',
      AppTextKey.demoModeStartSub:
          'Switch to review mode to check app flow without actual connectivity.',
      AppTextKey.demoModeStartDialogContent:
          'Switch to demo mode to check app flow and UI without real connection.',
      AppTextKey.demoModeStop: 'Demo mode active',
      AppTextKey.demoModeStopSub:
          'Currently in demo mode. Only UI and workflow are available.',
      AppTextKey.demoModeStartDialogTitle: 'Start Demo Mode',
      AppTextKey.demoModeStopDialogContent:
          'Exit demo mode and return to the actual connection flow.',
      AppTextKey.demoModeStopDialogTitle: 'Exit Demo Mode',
      AppTextKey.demoModeStartButton: 'Start',
      AppTextKey.demoModeStopButton: 'Exit',
      AppTextKey.dialogCancel: 'Cancel',
      AppTextKey.startDemo: 'Start Demo',
      AppTextKey.leaveDemo: 'Leave Demo',
      AppTextKey.settingsAppearance: 'Appearance',
      AppTextKey.settingsFunction: 'Features',
      AppTextKey.settingsInfo: 'About',
      AppTextKey.theme: 'Theme',
      AppTextKey.themeLight: 'Light mode',
      AppTextKey.themeDark: 'Dark mode',
      AppTextKey.themeSystem: 'System',
      AppTextKey.themeSelect: 'Select Theme',
      AppTextKey.showHistoryTitle: 'Session and chat history',
      AppTextKey.showHistorySub: 'Show history section on the main screen',
      AppTextKey.aboutTitle: 'Codex Remote',
      AppTextKey.appVersion: 'Version 0.2.0',
      AppTextKey.appVersionSub:
          'Control Codex remotely from your mobile device.',
      AppTextKey.releaseSoonTitle: 'Preparing 0.2.0',
      AppTextKey.releaseSoonMessage:
          'Production-ready settings, diagnostics, branding, and notification options will be added gradually.',
      AppTextKey.language: 'Language',
      AppTextKey.languageSystem: 'System default',
      AppTextKey.languageKorean: '한국어',
      AppTextKey.languageEnglish: 'English',
      AppTextKey.languageSelectTitle: 'Select Language',
      AppTextKey.languageSub: 'Choose app display language',
      AppTextKey.quickOpenSettings: 'Open Full Settings',
      AppTextKey.demoModeTooltipStart: 'Start Demo',
      AppTextKey.demoModeTooltipStop: 'Leave Demo',
      AppTextKey.connectionReadyText: 'Preparing connection...',
      AppTextKey.recentConnections: 'Recent connections',
      AppTextKey.refreshTooltip: 'Refresh',
      AppTextKey.statusConnected: 'Connected',
      AppTextKey.statusNotConnected: 'Not connected',
      AppTextKey.connectAction: 'Connect',
      AppTextKey.disconnectAction: 'Disconnect',
      AppTextKey.connectingAction: 'Processing...',
      AppTextKey.sessionsTitle: 'Sessions',
      AppTextKey.sessionsLocalConnectedText: 'Connected to local server.',
      AppTextKey.sessionsRelayConnectedText: 'Relay session',
      AppTextKey.sessionsDisconnectedHint:
          'Start local or relay connection from Chat tab.',
      AppTextKey.currentCodexSessionLabel: 'Current Codex session:',
      AppTextKey.sessionsNoHistoryTitle: 'No recent connections',
      AppTextKey.sessionsNoHistoryMessage:
          'Recent connections are saved here after sessions are connected.',
      AppTextKey.homeTabChatTitle: 'Chat',
      AppTextKey.homeTabApprovalsTitle: 'Approvals',
      AppTextKey.homeTabSessionsTitle: 'Sessions',
      AppTextKey.homeTabSettingsTitle: 'Settings',
      AppTextKey.homeTabChatSubtitleConnected:
          'Continue conversation and check Codex status.',
      AppTextKey.homeTabChatSubtitleDisconnected:
          'You can send prompts right after connection.',
      AppTextKey.homeTabApprovalsSubtitle:
          'Handle mobile approval requests and pending actions in one place.',
      AppTextKey.homeTabSessionsSubtitle:
          'Check connection status and recent history.',
      AppTextKey.homeTabSettingsSubtitle:
          'Configure app preferences and default behavior.',
      AppTextKey.homeTabPendingResponse: 'Response pending',
      AppTextKey.openFullSettings: 'Open full settings',
      AppTextKey.settingsTabHint: 'Settings tab',
      AppTextKey.localServerMode: 'Local server mode',
      AppTextKey.relayServerMode: 'Relay mode',
      AppTextKey.sessionLabel: 'Session',
      AppTextKey.setConnectionHint: 'Set up connection',
      AppTextKey.connectionTypeLabel: 'Connection type',
      AppTextKey.tapReconnectHint: 'Tap to reconnect',
      AppTextKey.onboardingTitle: 'Get started with Codex Remote',
      AppTextKey.onboardingSubtitle:
          'Quickly check approvals and session status from mobile.',
      AppTextKey.onboardingFeatureConnection: 'Quick connect',
      AppTextKey.onboardingFeatureConnectionDesc:
          'Set up local/relay connection and jump into Codex session instantly.',
      AppTextKey.onboardingFeatureApprovals: 'Mobile approvals',
      AppTextKey.onboardingFeatureApprovalsDesc:
          'See approval requests immediately and process them in the app.',
      AppTextKey.onboardingFeatureChat: 'Continue chat',
      AppTextKey.onboardingFeatureChatDesc:
          'Manage prompts and responses clearly on the Chat tab.',
      AppTextKey.onboardingStartButton: 'Get started',
      AppTextKey.onboardingDemoButton: 'Start demo mode',
      AppTextKey.approvalsTitle: 'Approvals',
      AppTextKey.approvalsNotReadyTitle: 'Approval setup is needed',
      AppTextKey.approvalsNotReadyMessage:
          'Connect to a relay session to process mobile approval requests and Codex actions.',
      AppTextKey.openChatScreen: 'Go to chat',
      AppTextKey.approvalsCodexRequestMetric: 'Codex requests',
      AppTextKey.approvalsRelayApprovalMetric: 'Relay approvals',
      AppTextKey.approvalsPendingCodexSection: 'Pending Codex actions',
      AppTextKey.approvalsNoPendingCodexTitle: 'No pending Codex requests',
      AppTextKey.approvalsNoPendingCodexMessage:
          'Command execute, file changes, and input-required requests appear here.',
      AppTextKey.approvalsPendingRelaySection: 'Pending relay approvals',
      AppTextKey.approvalsNoPendingRelayTitle: 'No pending approval requests',
      AppTextKey.approvalsNoPendingRelayMessage:
          'Execution approval requests from relay server will appear here.',
      AppTextKey.approvalsHistorySection: 'History',
      AppTextKey.approvalsNoHistoryTitle: 'No approval history yet',
      AppTextKey.approvalsNoHistoryMessage:
          'Recently approved/rejected items are shown here.',
      AppTextKey.sending: 'Sending...',
      AppTextKey.respond: 'Respond',
      AppTextKey.requesterLabel: 'Requester',
      AppTextKey.approvalIdLabel: 'ID',
      AppTextKey.approvalAllow: 'Allow',
      AppTextKey.approvalLater: 'Later',
      AppTextKey.approvalReject: 'Reject',
      AppTextKey.promptModelSelectorTooltip: 'Select model',
      AppTextKey.promptModelLabel: 'Model',
      AppTextKey.promptReasoningSelectorTooltip: 'Select reasoning',
      AppTextKey.promptReasoningLabel: 'Reasoning',
      AppTextKey.homeConnectionTitle: 'Connect',
      AppTextKey.connectionIntroTitle: 'Start your first connection',
      AppTextKey.connectionIntroDescription:
          'After connected, you can use Chat / Approvals / Sessions / Settings.',
      AppTextKey.connectionActionLocalConnecting:
          'Connecting to local server...',
      AppTextKey.connectionActionRelayConnecting: 'Connecting relay session...',
      AppTextKey.connectionActionLocalPreparing:
          'Preparing local server connection...',
      AppTextKey.connectionActionRelayPreparing:
          'Preparing relay session connection...',
      AppTextKey.connectionActionNotCompleted:
          'Connection request was not completed.',
      AppTextKey.connectionActionPendingPin: 'Waiting for PIN input...',
      AppTextKey.connectionActionConnectingWithPin:
          'Connecting after PIN check...',
      AppTextKey.connectionActionPinRejected:
          'Did not connect because no PIN was entered.',
      AppTextKey.connectionActionConnect: 'Connect',
      AppTextKey.connectionActionCreateAndConnect: 'Create & Connect',
      AppTextKey.connectionActionReconnect: 'Reconnect',
      AppTextKey.connectionActionInProgress: 'Processing...',
      AppTextKey.connectionFailurePrefix: 'Connection failed:',
      AppTextKey.connectionHistoryLabel: 'Recent connections',
      AppTextKey.connectionHistoryDelete: 'Delete',
      AppTextKey.connectionHistoryDeleteTitle: 'Delete recent connection',
      AppTextKey.connectionHistoryDeleteMessage:
          'Do you want to delete this connection entry?',
      AppTextKey.connectionHistoryDeleteCancel: 'Cancel',
      AppTextKey.connectionHistoryDeleteConfirm: 'Delete',
      AppTextKey.connectionMessageNoSearchResults: 'No search results',
      AppTextKey.connectionMessageNoMessages: 'No messages',
      AppTextKey.connectionMessageStartHint: 'Enter a prompt to start',
      AppTextKey.chatPromptInputHint: 'Type your message',
      AppTextKey.chatPromptInputHintGenerating: 'Generating response...',
      AppTextKey.chatPromptInputLabel: 'Prompt input',
      AppTextKey.chatPromptInputHintDetailed:
          'Enter what you want to ask Codex...',
      AppTextKey.chatCopyLabel: 'Message copied to clipboard',
      AppTextKey.chatStopLabel: 'Stop',
      AppTextKey.chatNewConversationLabel: 'New conversation',
      AppTextKey.messageSectionTitle: 'Messages',
      AppTextKey.messageFilterAll: 'All',
      AppTextKey.messageFilterAnswerOnly: 'AI Responses only',
      AppTextKey.messageSearchHint: 'Search messages',
      AppTextKey.messageFilterAiResponse: 'AI Response',
      AppTextKey.messageFilterUserPrompt: 'User Prompt',
      AppTextKey.messageFilterLogs: 'Logs',
      AppTextKey.messageFilterSystem: 'System',
      AppTextKey.messageFilterError: 'Error',
      AppTextKey.messageFilterWarn: 'Warn',
      AppTextKey.messageFilterInfo: 'Info',
      AppTextKey.messageWaiting: 'Waiting for response...',
      AppTextKey.chatSendTooltip: 'Send',
      AppTextKey.chatSendButton: 'Send',
      AppTextKey.chatStopButton: 'Stop',
      AppTextKey.modelCatalogLoadingLabelLoading: 'Loading model list...',
      AppTextKey.modelCatalogLoadingLabelDefaultReady:
          'Default model loaded. Preparing all models...',
      AppTextKey.modelCatalogLoadingLabelSyncing: 'Loading all models next...',
      AppTextKey.modelCatalogLoadingLabelDelayed:
          'Model sync is delayed, so default model is used first.',
      AppTextKey.modelCatalogLoadingLabelFailed:
          'Model list failed to load. Please try again.',
      AppTextKey.modelCatalogSyncDelayNotice:
          '⚠️ Full model loading is delayed. The default model will be used first.',
      AppTextKey.modelCatalogSyncDelayNoticeWithElapsed:
          '⚠️ Full model loading has been delayed by {elapsed} seconds, so default model is used first.',
      AppTextKey.modelCatalogDefaultModelLoaded:
          '✅ Default model loaded successfully: {model}',
      AppTextKey.modelCatalogSyncingModels:
          '🔄 Loading all remaining models...',
      AppTextKey.modelCatalogAllLoaded:
          '🔔 All models loaded: {count} (default: {model})',
      AppTextKey.modelCatalogAllLoadedWithElapsed:
          '🔔 All models loaded: {count} (default: {model}, {elapsed}ms)',
      AppTextKey.modelCatalogListRefreshed:
          '🔁 Model list updated: {previous} → {next}',
      AppTextKey.modelCatalogCacheApplied:
          '📦 Applied cached {count} models ({minutes} minutes ago)',
      AppTextKey.modelCatalogSyncLatestLoading:
          '🔄 Synchronizing latest model list...',
      AppTextKey.modelCatalogLoadFromNetwork:
          '🛰️ Loading model list from network...',
      AppTextKey.modelCatalogLoadFailed: '❌ Failed to load model list: {error}',
      AppTextKey.modelCatalogCapabilitiesCached:
          '🧩 Running with cached capabilities.',
      AppTextKey.modelCatalogCapabilitiesLoaded: '🧩 Runtime capabilities loaded.',
      AppTextKey.modelCatalogCapabilitiesFallback:
          '🧩 Using fallback capabilities.',
      AppTextKey.modelCatalogRuntimeCapabilitiesSummary:
          '🧩 Runtime capabilities loaded: {count} model(s), IDE context {ide}, flat mode {flat}',
      AppTextKey.modelSettingsTitle: 'Model settings',
      AppTextKey.modelDropdownAutoLabel: 'Model: Auto (default)',
      AppTextKey.modelDropdownModelLabel: 'Model: {model}',
      AppTextKey.reasoningDropdownAutoLabel: 'Reasoning: Auto',
      AppTextKey.reasoningDropdownValueLabel: 'Reasoning: {reasoning}',
      AppTextKey.modelCatalogSummaryLine:
          'Models: {count} · Selected: {selected} · Reasoning options: {reasoning}',
      AppTextKey.modelCatalogIdeContextFilter: 'IDE Context',
      AppTextKey.modelCatalogFlatModeFilter: 'Flat Mode',
      AppTextKey.demoModePopupTitleExit: 'Exit Demo Mode',
      AppTextKey.demoModePopupContentExit:
          'Exit review mode and return to the actual connection-centered screen.',
      AppTextKey.demoModeSampleIntro:
          '🔎 Demo mode is active and entered with sample data.',
      AppTextKey.demoModeSampleSessionSummary:
          '📡 You can inspect Chat/Approvals/Sessions/Settings screens without a PC session.',
      AppTextKey.demoModeSampleRelaySessionLine: '✅ Relay session: {sessionId}',
      AppTextKey.demoModeSamplePromptStart:
          'You can use App Demo mode immediately without entering a session ID.\n\n'
              'Send a prompt in the input box and you will see a sample response.',
      AppTextKey.demoModeSampleAssistantStart:
          'Your request has arrived as a demo chat message. Because this is demo mode, '
              'this is a sample response showing expected behavior.',
      AppTextKey.demoModeSamplePromptReview:
          'Where can I check approval requests?',
      AppTextKey.demoModeSampleAssistantReview:
          'You can check Codex and relay-approval requests in the Approvals tab and respond with action buttons.',
      AppTextKey.demoModeDemoApprovalActionSampleMessage:
          'In review mode, approval responses are simulated.',
      AppTextKey.demoModeDemoRequestActionSampleMessage:
          'In review mode, request responses are sample actions.',
      AppTextKey.demoModeNeedsMobileActionNotice:
          'Codex will continue only after a decision is made from mobile.',
      AppTextKey.demoModeDeferredApprovalNotice:
          'Deferred this approval for later.',
      AppTextKey.demoModeDisconnectActionSampleMessage:
          'In review mode, disconnect is a sample action.',
      AppTextKey.demoModeResponseFallback:
          '[{fallback}] In demo mode, responses are sample messages and are not sent to the real server.',
      AppTextKey.demoModeReviewModeDescription:
          'Review/demo mode only checks UI flow without actual network connection. Core functions (connection status, chat, approvals, sessions) can be reviewed here.',
      AppTextKey.demoModeSessionAutoConfiguredMessage:
          'Currently in review demo mode, a session is configured automatically as demo-session-id. Perform relay/local connection only when real integration is needed.',
      AppTextKey.demoModeApprovalGuideMessage:
          'In the Approvals tab, you can check pending items and process allow/reject actions. This mode currently displays mock data and mock flow.',
      AppTextKey.demoModeFeatureGuideMessage:
          'Check app flow with sample prompts such as “Where can I see approval requests?” or “What can I do on mobile?”',
      AppTextKey.pinDialogTitle: 'Enter PIN',
      AppTextKey.pinDialogDescription:
          'This session is protected by a PIN set on PC.\nPlease enter 4~6 digit PIN configured on the PC.',
      AppTextKey.pinDialogInputLabel: 'PIN',
      AppTextKey.pinDialogInputHint: '4~6 digits',
      AppTextKey.pinDialogConfirm: 'Confirm',
      AppTextKey.pinDialogConfirming: 'Confirming...',
      AppTextKey.pinDialogErrorTitle: 'PIN Error',
      AppTextKey.pinDialogErrorMessage:
          'PIN is invalid.\nPlease check the 4~6 digit PIN set in the PC extension.',
      AppTextKey.pinDialogInvalidMessage:
          'PIN is invalid. Please verify the PIN configured on PC.',
      AppTextKey.forceStopReconnect: 'Stop auto reconnect',
      AppTextKey.lastErrorLabel: 'Last error',
      AppTextKey.sessionHistoryTitle: 'Session and chat history',
      AppTextKey.currentSessionLabel: 'Current Session',
      AppTextKey.availableSessionsTitle: 'Available sessions',
      AppTextKey.viewSessionHistoryAction: 'View this session history',
      AppTextKey.chatHistoryTitle: 'Conversation history',
      AppTextKey.chatHistoryNoMessages: 'No conversation history',
    },
    AppLanguageSetting.korean: {},
    AppLanguageSetting.system: {
      AppTextKey.settings: 'Settings',
      AppTextKey.demoMode: 'Demo Mode',
      AppTextKey.demoModeStart: 'Demo Mode',
      AppTextKey.demoModeStartSub:
          'Switch to review mode to check app flow without actual connectivity.',
      AppTextKey.demoModeStartDialogContent:
          'Switch to demo mode to check app flow and UI without real connection.',
      AppTextKey.demoModeStop: 'Demo mode active',
      AppTextKey.demoModeStopSub:
          'Currently in demo mode. Only UI and workflow are available.',
      AppTextKey.demoModeStartDialogTitle: 'Start Demo Mode',
      AppTextKey.demoModeStopDialogContent:
          'Exit demo mode and return to the actual connection flow.',
      AppTextKey.demoModeStopDialogTitle: 'Exit Demo Mode',
      AppTextKey.demoModeStartButton: 'Start',
      AppTextKey.demoModeStopButton: 'Exit',
      AppTextKey.dialogCancel: 'Cancel',
      AppTextKey.startDemo: 'Start Demo',
      AppTextKey.leaveDemo: 'Leave Demo',
      AppTextKey.settingsAppearance: 'Appearance',
      AppTextKey.settingsFunction: 'Features',
      AppTextKey.settingsInfo: 'About',
      AppTextKey.theme: 'Theme',
      AppTextKey.themeLight: 'Light mode',
      AppTextKey.themeDark: 'Dark mode',
      AppTextKey.themeSystem: 'System',
      AppTextKey.themeSelect: 'Select Theme',
      AppTextKey.showHistoryTitle: 'Session and chat history',
      AppTextKey.showHistorySub: 'Show history section on the main screen',
      AppTextKey.aboutTitle: 'Codex Remote',
      AppTextKey.appVersion: 'Version 0.2.0',
      AppTextKey.appVersionSub:
          'Control Codex remotely from your mobile device.',
      AppTextKey.releaseSoonTitle: 'Preparing 0.2.0',
      AppTextKey.releaseSoonMessage:
          'Production-ready settings, diagnostics, branding, and notification options will be added gradually.',
      AppTextKey.language: 'Language',
      AppTextKey.languageSystem: 'System default',
      AppTextKey.languageKorean: '한국어',
      AppTextKey.languageEnglish: 'English',
      AppTextKey.languageSelectTitle: 'Select Language',
      AppTextKey.languageSub: 'Choose app display language',
      AppTextKey.quickOpenSettings: 'Open Full Settings',
      AppTextKey.demoModeTooltipStart: 'Start Demo',
      AppTextKey.demoModeTooltipStop: 'Leave Demo',
      AppTextKey.connectionReadyText: 'Preparing connection...',
      AppTextKey.recentConnections: 'Recent connections',
      AppTextKey.refreshTooltip: 'Refresh',
      AppTextKey.statusConnected: 'Connected',
      AppTextKey.statusNotConnected: 'Not connected',
      AppTextKey.connectAction: 'Connect',
      AppTextKey.disconnectAction: 'Disconnect',
      AppTextKey.connectingAction: 'Processing...',
      AppTextKey.sessionsTitle: 'Sessions',
      AppTextKey.sessionsLocalConnectedText: 'Connected to local server.',
      AppTextKey.sessionsRelayConnectedText: 'Relay session',
      AppTextKey.sessionsDisconnectedHint:
          'Start local or relay connection from Chat tab.',
      AppTextKey.currentCodexSessionLabel: 'Current Codex session:',
      AppTextKey.sessionsNoHistoryTitle: 'No recent connections',
      AppTextKey.sessionsNoHistoryMessage:
          'Recent connections are saved here after sessions are connected.',
      AppTextKey.homeTabChatTitle: 'Chat',
      AppTextKey.homeTabApprovalsTitle: 'Approvals',
      AppTextKey.homeTabSessionsTitle: 'Sessions',
      AppTextKey.homeTabSettingsTitle: 'Settings',
      AppTextKey.homeTabChatSubtitleConnected:
          'Continue conversation and check Codex status.',
      AppTextKey.homeTabChatSubtitleDisconnected:
          'You can send prompts right after connection.',
      AppTextKey.homeTabApprovalsSubtitle:
          'Handle mobile approval requests and pending actions in one place.',
      AppTextKey.homeTabSessionsSubtitle:
          'Check connection status and recent history.',
      AppTextKey.homeTabSettingsSubtitle:
          'Configure app preferences and default behavior.',
      AppTextKey.homeTabPendingResponse: 'Response pending',
      AppTextKey.openFullSettings: 'Open full settings',
      AppTextKey.settingsTabHint: 'Settings tab',
      AppTextKey.localServerMode: 'Local server mode',
      AppTextKey.relayServerMode: 'Relay mode',
      AppTextKey.sessionLabel: 'Session',
      AppTextKey.setConnectionHint: 'Set up connection',
      AppTextKey.connectionTypeLabel: 'Connection type',
      AppTextKey.tapReconnectHint: 'Tap to reconnect',
      AppTextKey.onboardingTitle: 'Get started with Codex Remote',
      AppTextKey.onboardingSubtitle:
          'Quickly check approvals and session status from mobile.',
      AppTextKey.onboardingFeatureConnection: 'Quick connect',
      AppTextKey.onboardingFeatureConnectionDesc:
          'Set up local/relay connection and jump into Codex session instantly.',
      AppTextKey.onboardingFeatureApprovals: 'Mobile approvals',
      AppTextKey.onboardingFeatureApprovalsDesc:
          'See approval requests immediately and process them in the app.',
      AppTextKey.onboardingFeatureChat: 'Continue chat',
      AppTextKey.onboardingFeatureChatDesc:
          'Manage prompts and responses clearly on the Chat tab.',
      AppTextKey.onboardingStartButton: 'Get started',
      AppTextKey.onboardingDemoButton: 'Start demo mode',
      AppTextKey.approvalsTitle: 'Approvals',
      AppTextKey.approvalsNotReadyTitle: 'Approval setup is needed',
      AppTextKey.approvalsNotReadyMessage:
          'Connect to a relay session to process mobile approval requests and Codex actions.',
      AppTextKey.openChatScreen: 'Go to chat',
      AppTextKey.approvalsCodexRequestMetric: 'Codex requests',
      AppTextKey.approvalsRelayApprovalMetric: 'Relay approvals',
      AppTextKey.approvalsPendingCodexSection: 'Pending Codex actions',
      AppTextKey.approvalsNoPendingCodexTitle: 'No pending Codex requests',
      AppTextKey.approvalsNoPendingCodexMessage:
          'Command execute, file changes, and input-required requests appear here.',
      AppTextKey.approvalsPendingRelaySection: 'Pending relay approvals',
      AppTextKey.approvalsNoPendingRelayTitle: 'No pending approval requests',
      AppTextKey.approvalsNoPendingRelayMessage:
          'Execution approval requests from relay server will appear here.',
      AppTextKey.approvalsHistorySection: 'History',
      AppTextKey.approvalsNoHistoryTitle: 'No approval history yet',
      AppTextKey.approvalsNoHistoryMessage:
          'Recently approved/rejected items are shown here.',
      AppTextKey.sending: 'Sending...',
      AppTextKey.respond: 'Respond',
      AppTextKey.requesterLabel: 'Requester',
      AppTextKey.approvalIdLabel: 'ID',
      AppTextKey.approvalAllow: 'Allow',
      AppTextKey.approvalLater: 'Later',
      AppTextKey.approvalReject: 'Reject',
      AppTextKey.promptModelSelectorTooltip: 'Select model',
      AppTextKey.promptModelLabel: 'Model',
      AppTextKey.promptReasoningSelectorTooltip: 'Select reasoning',
      AppTextKey.promptReasoningLabel: 'Reasoning',
      AppTextKey.homeConnectionTitle: 'Connect',
      AppTextKey.connectionIntroTitle: 'Start your first connection',
      AppTextKey.connectionIntroDescription:
          'After connected, you can use Chat / Approvals / Sessions / Settings.',
      AppTextKey.connectionActionLocalConnecting:
          'Connecting to local server...',
      AppTextKey.connectionActionRelayConnecting: 'Connecting relay session...',
      AppTextKey.connectionActionLocalPreparing:
          'Preparing local server connection...',
      AppTextKey.connectionActionRelayPreparing:
          'Preparing relay session connection...',
      AppTextKey.connectionActionNotCompleted:
          'Connection request was not completed.',
      AppTextKey.connectionActionPendingPin: 'Waiting for PIN input...',
      AppTextKey.connectionActionConnectingWithPin:
          'Connecting after PIN check...',
      AppTextKey.connectionActionPinRejected:
          'Did not connect because no PIN was entered.',
      AppTextKey.connectionActionConnect: 'Connect',
      AppTextKey.connectionActionCreateAndConnect: 'Create & Connect',
      AppTextKey.connectionActionReconnect: 'Reconnect',
      AppTextKey.connectionActionInProgress: 'Processing...',
      AppTextKey.connectionFailurePrefix: 'Connection failed:',
      AppTextKey.connectionHistoryLabel: 'Recent connections',
      AppTextKey.connectionHistoryDelete: 'Delete',
      AppTextKey.connectionHistoryDeleteTitle: 'Delete recent connection',
      AppTextKey.connectionHistoryDeleteMessage:
          'Do you want to delete this connection entry?',
      AppTextKey.connectionHistoryDeleteCancel: 'Cancel',
      AppTextKey.connectionHistoryDeleteConfirm: 'Delete',
      AppTextKey.connectionMessageNoSearchResults: 'No search results',
      AppTextKey.connectionMessageNoMessages: 'No messages',
      AppTextKey.connectionMessageStartHint: 'Enter a prompt to start',
      AppTextKey.chatPromptInputHint: 'Type your message',
      AppTextKey.chatPromptInputHintGenerating: 'Generating response...',
      AppTextKey.chatPromptInputLabel: 'Prompt input',
      AppTextKey.chatPromptInputHintDetailed: 'Enter what you want to ask Codex...',
      AppTextKey.chatCopyLabel: 'Message copied to clipboard',
      AppTextKey.chatStopLabel: 'Stop',
      AppTextKey.chatNewConversationLabel: 'New conversation',
      AppTextKey.messageSectionTitle: 'Messages',
      AppTextKey.messageFilterAll: 'All',
      AppTextKey.messageFilterAnswerOnly: 'AI Responses only',
      AppTextKey.messageSearchHint: 'Search messages',
      AppTextKey.messageFilterAiResponse: 'AI Response',
      AppTextKey.messageFilterUserPrompt: 'User Prompt',
      AppTextKey.messageFilterLogs: 'Logs',
      AppTextKey.messageFilterSystem: 'System',
      AppTextKey.messageFilterError: 'Error',
      AppTextKey.messageFilterWarn: 'Warn',
      AppTextKey.messageFilterInfo: 'Info',
      AppTextKey.messageWaiting: 'Waiting for response...',
      AppTextKey.chatSendTooltip: 'Send',
      AppTextKey.chatSendButton: 'Send',
      AppTextKey.chatStopButton: 'Stop',
      AppTextKey.demoModeResponseFallback:
          '[{fallback}] In demo mode, responses are sample messages and are not sent to the real server.',
      AppTextKey.demoModeReviewModeDescription:
          'Review/demo mode only checks UI flow without actual network connection. Core functions (connection status, chat, approvals, sessions) can be reviewed here.',
      AppTextKey.demoModeSessionAutoConfiguredMessage:
          'Currently in review demo mode, a session is configured automatically as demo-session-id. Perform relay/local connection only when real integration is needed.',
      AppTextKey.demoModeApprovalGuideMessage:
          'In the Approvals tab, you can check pending items and process allow/reject actions. This mode currently displays mock data and mock flow.',
      AppTextKey.demoModeFeatureGuideMessage:
          'Check app flow with sample prompts such as “Where can I see approval requests?” or “What can I do on mobile?”',
      AppTextKey.modelCatalogLoadingLabelLoading: 'Loading model list...',
      AppTextKey.modelCatalogLoadingLabelDefaultReady:
          'Default model loaded. Preparing all models...',
      AppTextKey.modelCatalogLoadingLabelSyncing: 'Loading all models next...',
      AppTextKey.modelCatalogLoadingLabelDelayed:
          'Model sync is delayed, so default model is used first.',
      AppTextKey.modelCatalogLoadingLabelFailed:
          'Model list failed to load. Please try again.',
      AppTextKey.modelCatalogSyncDelayNotice:
          '⚠️ Full model loading is delayed. The default model will be used first.',
      AppTextKey.modelCatalogSyncDelayNoticeWithElapsed:
          '⚠️ Full model loading has been delayed by {elapsed} seconds, so default model is used first.',
      AppTextKey.modelCatalogDefaultModelLoaded:
          '✅ Default model loaded successfully: {model}',
      AppTextKey.modelCatalogSyncingModels:
          '🔄 Loading all remaining models...',
      AppTextKey.modelCatalogAllLoaded:
          '🔔 All models loaded: {count} (default: {model})',
      AppTextKey.modelCatalogAllLoadedWithElapsed:
          '🔔 All models loaded: {count} (default: {model}, {elapsed}ms)',
      AppTextKey.modelCatalogListRefreshed:
          '🔁 Model list updated: {previous} → {next}',
      AppTextKey.modelCatalogCacheApplied:
          '📦 Applied cached {count} models ({minutes} minutes ago)',
      AppTextKey.modelCatalogSyncLatestLoading:
          '🔄 Synchronizing latest model list...',
      AppTextKey.modelCatalogLoadFromNetwork:
          '🛰️ Loading model list from network...',
      AppTextKey.modelCatalogLoadFailed: '❌ Failed to load model list: {error}',
      AppTextKey.modelCatalogCapabilitiesCached:
          '🧩 Running with cached capabilities.',
      AppTextKey.modelCatalogCapabilitiesLoaded: '🧩 Runtime capabilities loaded.',
      AppTextKey.modelCatalogCapabilitiesFallback:
          '🧩 Using fallback capabilities.',
      AppTextKey.modelCatalogRuntimeCapabilitiesSummary:
          '🧩 Runtime capabilities loaded: {count} model(s), IDE context {ide}, flat mode {flat}',
      AppTextKey.demoModePopupTitleExit: 'Exit Demo Mode',
      AppTextKey.demoModePopupContentExit:
          'Exit review mode and return to the actual connection-centered screen.',
      AppTextKey.demoModeSampleIntro:
          '🔎 Demo mode is active and entered with sample data.',
      AppTextKey.demoModeSampleSessionSummary:
          '📡 You can inspect Chat/Approvals/Sessions/Settings screens without a PC session.',
      AppTextKey.demoModeSampleRelaySessionLine: '✅ Relay session: {sessionId}',
      AppTextKey.demoModeSamplePromptStart:
          'You can use App Demo mode immediately without entering a session ID.\n\n'
              'Send a prompt in the input box and you will see a sample response.',
      AppTextKey.demoModeSampleAssistantStart:
          'Your request has arrived as a demo chat message. Because this is demo mode, '
              'this is a sample response showing expected behavior.',
      AppTextKey.demoModeSamplePromptReview:
          'Where can I check approval requests?',
      AppTextKey.demoModeSampleAssistantReview:
          'You can check Codex and relay-approval requests in the Approvals tab and respond with action buttons.',
      AppTextKey.demoModeDemoApprovalActionSampleMessage:
          'In review mode, approval responses are simulated.',
      AppTextKey.demoModeDemoRequestActionSampleMessage:
          'In review mode, request responses are sample actions.',
      AppTextKey.demoModeNeedsMobileActionNotice:
          'Codex will continue only after a decision is made from mobile.',
      AppTextKey.demoModeDeferredApprovalNotice:
          'Deferred this approval for later.',
      AppTextKey.demoModeDisconnectActionSampleMessage:
          'In review mode, disconnect is a sample action.',
      AppTextKey.pinDialogTitle: 'Enter PIN',
      AppTextKey.pinDialogDescription:
          'This session is protected by a PIN set on PC.\nPlease enter 4~6 digit PIN configured on the PC.',
      AppTextKey.pinDialogInputLabel: 'PIN',
      AppTextKey.pinDialogInputHint: '4~6 digits',
      AppTextKey.pinDialogConfirm: 'Confirm',
      AppTextKey.pinDialogConfirming: 'Confirming...',
      AppTextKey.pinDialogErrorTitle: 'PIN Error',
      AppTextKey.pinDialogErrorMessage:
          'PIN is invalid.\nPlease check the 4~6 digit PIN set in the PC extension.',
      AppTextKey.pinDialogInvalidMessage:
          'PIN is invalid. Please verify the PIN configured on PC.',
      AppTextKey.forceStopReconnect: 'Stop auto reconnect',
      AppTextKey.lastErrorLabel: 'Last error',
      AppTextKey.sessionHistoryTitle: 'Session and chat history',
      AppTextKey.currentSessionLabel: 'Current Session',
      AppTextKey.availableSessionsTitle: 'Available sessions',
      AppTextKey.viewSessionHistoryAction: 'View this session history',
      AppTextKey.chatHistoryTitle: 'Conversation history',
      AppTextKey.chatHistoryNoMessages: 'No conversation history',
    },
  };

  static AppLanguageSetting _systemLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode.toLowerCase().startsWith('en')
        ? AppLanguageSetting.english
        : AppLanguageSetting.korean;
  }

  static AppLanguageSetting _resolveLanguage(
    AppLanguageSetting setting,
    BuildContext context,
  ) {
    if (setting == AppLanguageSetting.system) {
      return _systemLanguage(context);
    }
    return setting;
  }

  static String t(BuildContext context, AppTextKey key) {
    final setting = AppSettings().appLanguage;
    final language = _resolveLanguage(setting, context);

    final direct = language == AppLanguageSetting.english
        ? _en[AppLanguageSetting.english]![key]
        : _ko[AppLanguageSetting.korean]![key];

    if (direct != null) return direct;

    // 마지막 안전 장치: 동일 언어 값이 누락되면 fallback
    if (language == AppLanguageSetting.english) {
      return _ko[AppLanguageSetting.korean]![key] ?? key.name;
    }
    return _en[AppLanguageSetting.english]![key] ?? key.name;
  }

  static String tWithParams(
    BuildContext context,
    AppTextKey key,
    Map<String, String> params,
  ) {
    var text = t(context, key);
    params.forEach((placeholder, value) {
      text = text.replaceAll('{$placeholder}', value);
    });
    return text;
  }

  static bool isEnglish(BuildContext context) {
    final setting = AppSettings().appLanguage;
    return _resolveLanguage(setting, context) == AppLanguageSetting.english;
  }
}
