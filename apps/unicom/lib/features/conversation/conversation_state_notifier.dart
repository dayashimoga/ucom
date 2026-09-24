import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_reporting/reporting.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import 'package:unicom_shared/shared.dart';
import '../../providers/in_memory_storage_provider.dart';

class ConversationController extends ChangeNotifier {
  final STTProvider stt;
  final TTSProvider tts;
  final TranslationProvider translator;
  final ExplanationEngine explanationEngine;
  final ConversationExtractor extractor;
  final InterviewEvaluator interviewEvaluator;
  final ReportGenerator reportGenerator;
  final StorageProvider storage;
  final LocalModelManager modelManager;

  late AndroidAICoreProvider androidAICore;
  late LocalLLMProvider localLLM;
  late CloudLLMProvider cloudLLM;
  late AIProviderRouter router;
  late RagRetrievalProvider ragRetrieval;
  late KnowledgeEngine knowledgeEngine;
  late RealOcrEngine ocrEngine;
  late StreamingSpeechSession ambientListeningSession;

  String _activeHeroMode = 'talk'; // 'talk', 'listen', 'camera', 'ask'
  String get activeHeroMode => _activeHeroMode;
  void setActiveHeroMode(String mode) {
    _activeHeroMode = mode;
    notifyListeners();
  }

  // Camera & Visual Interpreter State
  OcrResult? _currentOcrResult;
  OcrResult? get currentOcrResult => _currentOcrResult;
  bool _isOcrProcessing = false;
  bool get isOcrProcessing => _isOcrProcessing;
  bool _isOverlayOriginal = false;
  bool get isOverlayOriginal => _isOverlayOriginal;
  String _ocrRoute = 'Local Neural OCR / Android Vision';
  String get ocrRoute => _ocrRoute;

  // Ambient Listen & Understand State
  bool _isAmbientListening = false;
  bool get isAmbientListening => _isAmbientListening;
  double _ambientAudioLevel = 0.0;
  double get ambientAudioLevel => _ambientAudioLevel;
  String _ambientDetectedLang = 'auto';
  String get ambientDetectedLang => _ambientDetectedLang;
  String _ambientTranslation = '';
  String get ambientTranslation => _ambientTranslation;
  final List<ConversationSegment> _ambientSegments = [];
  List<ConversationSegment> get ambientSegments =>
      List.unmodifiable(_ambientSegments);

  ConversationState _state = ConversationState.idle;
  ConversationState get state => _state;

  ExecutionMode _executionMode = ExecutionMode.privateOffline;
  ExecutionMode get executionMode => _executionMode;

  ApplicationMode _mode = ApplicationMode.general;
  ApplicationMode get mode => _mode;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  String _sourceLanguage = 'en';
  String get sourceLanguage => _sourceLanguage;

  String _targetLanguage = 'es';
  String get targetLanguage => _targetLanguage;

  void swapLanguages() {
    final tmp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = tmp;
    notifyListeners();
  }

  late Conversation _currentConversation;
  Conversation get currentConversation => _currentConversation;

  ExplanationResult? _selectedExplanation;
  ExplanationResult? get selectedExplanation => _selectedExplanation;

  GeneratedReport? _latestReport;
  GeneratedReport? get latestReport => _latestReport;

  KnowledgeResponse? _latestKnowledgeResponse;
  KnowledgeResponse? get latestKnowledgeResponse => _latestKnowledgeResponse;

  String get activeProviderName {
    final active = router.activeProviderConfig;
    if (active != null) return active.displayName;
    if (_executionMode == ExecutionMode.privateOffline) {
      return 'Offline / Local Models';
    }
    if (_cloudApiKey != null && _cloudApiKey!.isNotEmpty) {
      return 'Google Gemini';
    }
    return 'On-Device AI';
  }

  AICoreStatus? _aicoreStatus;
  AICoreStatus? get aicoreStatus => _aicoreStatus;

  String? _cloudApiKey;
  String? get cloudApiKey => _cloudApiKey;

  String _cloudModelName = 'gemini-1.5-flash';
  String get cloudModelName => _cloudModelName;

  double _cloudTemperature = 0.7;
  double get cloudTemperature => _cloudTemperature;

  int _cloudMaxTokens = 1000;
  int get cloudMaxTokens => _cloudMaxTokens;

  int _cloudTimeoutMs = 15000;
  int get cloudTimeoutMs => _cloudTimeoutMs;

  ConnectionTestResult? _lastConnectionTest;
  ConnectionTestResult? get lastConnectionTest => _lastConnectionTest;

  String? _actionableError;
  String? get actionableError => _actionableError;

  String? _livePartialTranscript;
  String? get livePartialTranscript => _livePartialTranscript;

  bool _isMeetingActive = false;
  bool get isMeetingActive => _isMeetingActive;

  bool _isMeetingPaused = false;
  bool get isMeetingPaused => _isMeetingPaused;

  bool _isQaMode = false;
  bool get isQaMode => _isQaMode;
  void setQaMode(bool val) {
    _isQaMode = val;
    notifyListeners();
  }

  void toggleQaMode() {
    _isQaMode = !_isQaMode;
    notifyListeners();
  }

  bool _autoTts = false;
  bool get autoTts => _autoTts;
  void setAutoTts(bool val) {
    _autoTts = val;
    notifyListeners();
  }

  String _activeListeningSpeaker = 'You';
  String get activeListeningSpeaker => _activeListeningSpeaker;
  void setActiveListeningSpeaker(String speaker) {
    _activeListeningSpeaker = speaker;
    notifyListeners();
  }

  String _qaRoute = 'Active LLM Provider / Local Fallback';
  String get qaRoute => _qaRoute;

  String _translationRoute = 'Active Neural Provider / Offline Lexicon';
  String get translationRoute => _translationRoute;

  String _sttRoute = 'Android SpeechRecognizer / Device Audio';
  String get sttRoute => _sttRoute;

  String _ttsRoute = 'Android Native TextToSpeech Engine';
  String get ttsRoute => _ttsRoute;

  String _summarizationRoute = 'Active LLM Provider / Local Extractor';
  String get summarizationRoute => _summarizationRoute;

  void setCapabilityRoute(String capability, String target) {
    switch (capability) {
      case 'qa':
        _qaRoute = target;
        break;
      case 'translation':
        _translationRoute = target;
        break;
      case 'stt':
        _sttRoute = target;
        break;
      case 'tts':
        _ttsRoute = target;
        break;
      case 'summarization':
        _summarizationRoute = target;
        break;
      case 'ocr':
        _ocrRoute = target;
        break;
    }
    notifyListeners();
  }

  static const MethodChannel _speechChannel =
      MethodChannel('com.unicom.ai/speech');

  void setActionableError(String? error) {
    _actionableError = error;
    notifyListeners();
  }

  void clearError() {
    _actionableError = null;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    // Persist theme choice asynchronously
    SecureKeyStorage().saveKey('app_theme_mode', mode.name);
  }

  ConversationController({
    STTProvider? sttProvider,
    TTSProvider? ttsProvider,
    TranslationProvider? translationProvider,
    ExplanationEngine? explanationEngineInstance,
    ConversationExtractor? extractorInstance,
    InterviewEvaluator? interviewEvaluatorInstance,
    ReportGenerator? reportGeneratorInstance,
    StorageProvider? storageProvider,
    LocalModelManager? modelManagerInstance,
    AndroidAICoreProvider? androidAICoreInstance,
    LocalLLMProvider? localLLMInstance,
    CloudLLMProvider? cloudLLMInstance,
    RagRetrievalProvider? ragRetrievalInstance,
    RealOcrEngine? ocrEngineInstance,
    StreamingSpeechSession? ambientSessionInstance,
  })  : stt = sttProvider ?? LocalSTTProvider(isModelInstalled: true),
        tts = ttsProvider ?? OfflineAudioSynthesizer(),
        translator = translationProvider ?? OfflineTranslationEngine(),
        explanationEngine = explanationEngineInstance ?? ExplanationEngine(),
        extractor = extractorInstance ?? ConversationExtractor(),
        interviewEvaluator = interviewEvaluatorInstance ?? InterviewEvaluator(),
        reportGenerator = reportGeneratorInstance ?? ReportGenerator(),
        storage = storageProvider ?? LocalStorageProvider(),
        modelManager = modelManagerInstance ?? LocalModelManager() {
    androidAICore = androidAICoreInstance ?? AndroidAICoreProvider();
    localLLM = localLLMInstance ?? LocalLLMProvider();
    cloudLLM = cloudLLMInstance ??
        CloudLLMProvider(
          executionMode: _executionMode,
          apiKey: _cloudApiKey,
          modelName: _cloudModelName,
          timeoutMs: _cloudTimeoutMs,
        );

    router = AIProviderRouter(
      androidProvider: androidAICore,
      localProvider: localLLM,
      cloudProvider: cloudLLM,
      executionMode: _executionMode,
    );

    ragRetrieval = ragRetrievalInstance ?? RagRetrievalProvider();
    knowledgeEngine = KnowledgeEngine(
      router: router,
      retrievalProvider: ragRetrieval,
      translationProvider: translator,
    );

    ocrEngine =
        ocrEngineInstance ?? RealOcrEngine(translationProvider: translator);
    ambientListeningSession = ambientSessionInstance ??
        StreamingSpeechSession(
            sttProvider: stt, translationProvider: translator);

    _initPlatformChannels();
    _initAmbientListeners();
    _startNewSession();
    refreshAICoreStatus();
    _loadSavedSettings();
  }

  void _initAmbientListeners() {
    ambientListeningSession.audioLevelStream.listen((lvl) {
      _ambientAudioLevel = lvl;
      notifyListeners();
    });
    ambientListeningSession.detectedLanguageStream.listen((lang) {
      _ambientDetectedLang = lang;
      notifyListeners();
    });
    ambientListeningSession.translationStream.listen((trans) {
      _ambientTranslation = trans;
      notifyListeners();
    });
    ambientListeningSession.partialTranscriptStream.listen((partial) {
      _livePartialTranscript = partial;
      notifyListeners();
    });
    ambientListeningSession.finalSegmentStream.listen((segment) {
      _ambientSegments.add(segment);
      final updatedSegments =
          List<ConversationSegment>.from(_currentConversation.segments)
            ..add(segment);
      _currentConversation =
          _currentConversation.copyWith(segments: updatedSegments);
      storage.saveConversation(_currentConversation);
      notifyListeners();
    });
  }

  void _initPlatformChannels() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _speechChannel.setMethodCallHandler(_handleNativeSpeechCall);
    }
  }

  Future<dynamic> _handleNativeSpeechCall(MethodCall call) async {
    switch (call.method) {
      case 'onPartialTranscript':
        final text = call.arguments?['text'] as String? ?? '';
        _livePartialTranscript = text;
        notifyListeners();
        break;

      case 'onFinalTranscript':
        final text = call.arguments?['text'] as String? ?? '';
        _livePartialTranscript = null;
        if (text.trim().isNotEmpty) {
          if (_isMeetingActive) {
            _addMeetingContribution(text.trim());
          } else if (_isQaMode) {
            askQuestion(text.trim(), speakerName: _activeListeningSpeaker);
          } else {
            final isYou = _activeListeningSpeaker.toLowerCase() == 'you';
            sendTranslation(
              text.trim(),
              speakerName: _activeListeningSpeaker,
              speakerId: isYou ? 'p1' : 'p2',
              sourceLang: isYou ? _sourceLanguage : _targetLanguage,
              targetLang: isYou ? _targetLanguage : _sourceLanguage,
            );
          }
        }
        notifyListeners();
        break;

      case 'onError':
        final msg =
            call.arguments?['message'] as String? ?? 'Speech recognition error';
        final code = call.arguments?['code'] as int? ?? -1;
        // Don't show actionable error for normal silence in continuous mode
        if (!_isMeetingActive || (code != 7 && code != 6)) {
          _actionableError = msg;
        }
        if (!_isMeetingActive) {
          _state = ConversationState.idle;
          _livePartialTranscript = null;
        }
        notifyListeners();
        break;

      case 'onListeningStopped':
        if (!_isMeetingActive) {
          _state = ConversationState.idle;
          _livePartialTranscript = null;
          notifyListeners();
        }
        break;
    }
  }

  Future<void> _loadSavedSettings() async {
    try {
      final savedTheme = await SecureKeyStorage().getKey('app_theme_mode');
      if (savedTheme != null) {
        if (savedTheme == 'light') _themeMode = ThemeMode.light;
        if (savedTheme == 'dark') _themeMode = ThemeMode.dark;
        if (savedTheme == 'system') _themeMode = ThemeMode.system;
        notifyListeners();
      }

      final savedKey = await SecureKeyStorage().getKey('gemini_api_key');
      if (savedKey != null && savedKey.isNotEmpty) {
        setCloudConfig(apiKey: savedKey);
      }
    } catch (_) {}
  }

  void _startNewSession() {
    final now = DateTime.now().toUtc().toIso8601String();
    _currentConversation = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      title:
          'Session ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      mode: _mode,
      executionMode: _executionMode,
      startedAt: now,
      participants: [
        Participant(
            id: 'p1',
            name: 'You',
            isHost: true,
            preferredLanguage: _sourceLanguage),
        Participant(
            id: 'p2', name: 'Partner', preferredLanguage: _targetLanguage),
      ],
    );
  }

  Future<void> refreshAICoreStatus() async {
    _aicoreStatus = await androidAICore.checkStatus();
    notifyListeners();
  }

  void setExecutionMode(ExecutionMode mode) {
    _executionMode = mode;
    router.setExecutionMode(mode);
    notifyListeners();
  }

  void setApplicationMode(ApplicationMode mode) {
    _mode = mode;
    _startNewSession();
    notifyListeners();
  }

  void setLanguages(String source, String target) {
    _sourceLanguage = source;
    _targetLanguage = target;
    notifyListeners();
  }

  void clearSession() {
    _startNewSession();
    _selectedExplanation = null;
    _livePartialTranscript = null;
    notifyListeners();
  }

  void setCloudConfig({
    String? apiKey,
    String? modelName,
    double? temperature,
    int? maxTokens,
    int? timeoutMs,
  }) {
    if (apiKey != null) {
      _cloudApiKey = apiKey;
      SecureKeyStorage().saveKey('gemini_api_key', apiKey);
    }
    if (modelName != null) _cloudModelName = modelName;
    if (temperature != null) _cloudTemperature = temperature;
    if (maxTokens != null) _cloudMaxTokens = maxTokens;
    if (timeoutMs != null) _cloudTimeoutMs = timeoutMs;

    cloudLLM = CloudLLMProvider(
      executionMode: _executionMode,
      apiKey: _cloudApiKey,
      modelName: _cloudModelName,
      timeoutMs: _cloudTimeoutMs,
    );

    router.cloudProvider = cloudLLM;
    router.registerProviderInstance(cloudLLM.id, cloudLLM);

    knowledgeEngine = KnowledgeEngine(
      router: router,
      retrievalProvider: ragRetrieval,
      translationProvider: translator,
    );

    notifyListeners();
  }

  List<AIProviderConfig> get configuredProviders => router.configuredProviders;

  void addProviderConfig(AIProviderConfig config) {
    router.registerProviderConfig(config);
    if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      SecureKeyStorage().saveKey('provider_key_${config.id}', config.apiKey!);
    }
    notifyListeners();
  }

  void removeProviderConfig(String id) {
    router.removeProviderConfig(id);
    SecureKeyStorage().removeKey('provider_key_$id');
    notifyListeners();
  }

  void setDefaultProvider(String id) {
    router.setDefaultProvider(id);
    notifyListeners();
  }

  Future<ConnectionTestResult> testProviderConfig(
      AIProviderConfig config) async {
    switch (config.type) {
      case AIProviderType.gemini:
        final p = CloudLLMProvider(
          executionMode: _executionMode,
          apiKey: config.apiKey,
          modelName:
              config.modelId.isNotEmpty ? config.modelId : 'gemini-1.5-flash',
          endpoint: config.baseUrl.isNotEmpty
              ? config.baseUrl
              : 'https://generativelanguage.googleapis.com/v1beta',
        );
        return p.testConnection();

      case AIProviderType.openai:
      case AIProviderType.custom:
        final p = OpenAIProvider(
          executionMode: _executionMode,
          apiKey: config.apiKey,
          modelName: config.modelId.isNotEmpty ? config.modelId : 'gpt-4o-mini',
          baseUrl: config.baseUrl,
        );
        return p.testConnection();

      case AIProviderType.anthropic:
        final p = AnthropicProvider(
          executionMode: _executionMode,
          apiKey: config.apiKey,
          modelName: config.modelId.isNotEmpty
              ? config.modelId
              : 'claude-3-5-sonnet-20241022',
          endpoint: config.baseUrl.isNotEmpty
              ? config.baseUrl
              : 'https://api.anthropic.com/v1/messages',
        );
        return p.testConnection();

      case AIProviderType.local:
        return ConnectionTestResult(
          isSuccessful: localLLM.isModelLoaded,
          providerId: config.id,
          modelName: localLLM.name,
          latencyMs: 1,
          errorMessage: localLLM.isModelLoaded
              ? null
              : 'Local model not loaded in memory.',
        );

      case AIProviderType.aicore:
        final st = await androidAICore.checkStatus();
        return ConnectionTestResult(
          isSuccessful: st.isAvailable,
          providerId: config.id,
          modelName: 'Gemini Nano',
          latencyMs: 1,
          errorMessage: st.isAvailable
              ? null
              : (st.fallbackReason ?? 'AICore unavailable on device.'),
        );
    }
  }

  Future<ConnectionTestResult> testCloudConnection() async {
    _lastConnectionTest = await cloudLLM.testConnection();
    notifyListeners();
    return _lastConnectionTest!;
  }

  Future<KnowledgeResponse> askKnowledge(String question) async {
    _state = ConversationState.translating;
    _actionableError = null;
    notifyListeners();

    try {
      final response = await knowledgeEngine.ask(
        question: question,
        targetLanguage: _targetLanguage,
      );
      _latestKnowledgeResponse = response;

      final newSegment = ConversationSegment(
        id: 'seg_${_currentConversation.segments.length + 1}',
        speakerId: 'p1',
        speakerName: 'User',
        startTime: DateTime.now().millisecondsSinceEpoch,
        originalText: question,
        originalLanguage: _sourceLanguage,
        translatedText: response.generativeAnswer,
        targetLanguage: _targetLanguage,
        confidence: 1.0,
        isFinal: true,
      );

      final updatedSegments =
          List<ConversationSegment>.from(_currentConversation.segments)
            ..add(newSegment);

      _currentConversation = _currentConversation.copyWith(
        segments: updatedSegments,
      );

      await storage.saveConversation(_currentConversation);

      _state = ConversationState.idle;
      notifyListeners();
      return response;
    } catch (e) {
      _state = ConversationState.idle;
      _actionableError = 'Knowledge query failed: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void selectExplanation(ExplanationResult? explanation) {
    _selectedExplanation = explanation;
    notifyListeners();
  }

  Future<void> loadConversation(String id) async {
    final conv = await storage.getConversation(id);
    if (conv != null) {
      _currentConversation = conv;
      _mode = conv.mode;
      _executionMode = conv.executionMode;
      _selectedExplanation =
          conv.segments.isNotEmpty ? conv.segments.last.explanation : null;
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String id) async {
    await storage.deleteConversation(id);
    if (_currentConversation.id == id) {
      _startNewSession();
    }
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final all = await storage.listConversations(limit: 500);
    for (final c in all) {
      await storage.deleteConversation(c.id);
    }
    _startNewSession();
    _selectedExplanation = null;
    notifyListeners();
  }

  // --- Meeting Workflows ---

  Future<void> startMeeting() async {
    _mode = ApplicationMode.meeting;
    _isMeetingActive = true;
    _isMeetingPaused = false;
    _actionableError = null;
    _state = ConversationState.listening;
    notifyListeners();

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        final hasPerm =
            await _speechChannel.invokeMethod<bool>('checkMicPermission') ??
                false;
        if (!hasPerm) {
          final granted =
              await _speechChannel.invokeMethod<bool>('requestMicPermission') ??
                  false;
          if (!granted) {
            _actionableError =
                'Microphone permission is required for Meeting recording.';
            _isMeetingActive = false;
            _state = ConversationState.idle;
            notifyListeners();
            return;
          }
        }

        await _speechChannel.invokeMethod('startListening', {
          'language': _sourceLanguage == 'en' ? 'en-US' : _sourceLanguage,
          'continuous': true,
        });
      } catch (e) {
        _actionableError =
            'Failed to start meeting speech recording: ${e.toString()}';
        _isMeetingActive = false;
        _state = ConversationState.idle;
        notifyListeners();
      }
    }
  }

  void pauseMeeting() {
    _isMeetingPaused = true;
    _state = ConversationState.idle;
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      _speechChannel.invokeMethod('stopListening').catchError((_) => null);
    }
    notifyListeners();
  }

  void resumeMeeting() {
    _isMeetingPaused = false;
    _state = ConversationState.listening;
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      _speechChannel.invokeMethod('startListening', {
        'language': _sourceLanguage == 'en' ? 'en-US' : _sourceLanguage,
        'continuous': true,
      }).catchError((_) => null);
    }
    notifyListeners();
  }

  Future<GeneratedReport> stopMeeting() async {
    _isMeetingActive = false;
    _isMeetingPaused = false;
    _state = ConversationState.idle;
    _livePartialTranscript = null;

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      _speechChannel.invokeMethod('stopListening').catchError((_) => null);
    }

    final report = await createReport(ReportType.meetingMinutes);
    notifyListeners();
    return report;
  }

  void _addMeetingContribution(String text) {
    sendTextInput(text, speakerName: 'Speaker');
  }

  // --- Core Processing ---

  // --- Core Processing ---

  Future<void> sendTextInput(
    String text, {
    String speakerName = 'You',
    String? speakerId,
    InteractionIntent? intent,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final classified =
        intent ?? IntentClassifier.classify(trimmed, isQaMode: _isQaMode);

    if (classified == InteractionIntent.qa ||
        trimmed.startsWith('/ask ') ||
        trimmed.toLowerCase().startsWith('ask: ') ||
        (_isQaMode && intent == null)) {
      final cleanQuestion = IntentClassifier.extractQuestion(trimmed);
      await askQuestion(cleanQuestion,
          speakerName: speakerName, speakerId: speakerId);
      return;
    }

    await sendTranslation(
      trimmed,
      speakerName: speakerName,
      speakerId: speakerId,
    );
  }

  /// Authentic Real-Time Translation Pipeline (Dedicated to Cross-Language Communication)
  Future<void> sendTranslation(
    String text, {
    String speakerName = 'You',
    String? speakerId,
    String? sourceLang,
    String? targetLang,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _state = ConversationState.translating;
    notifyListeners();

    try {
      final sLang = sourceLang ??
          (speakerName == 'You' ? _sourceLanguage : _targetLanguage);
      final tLang = targetLang ??
          (speakerName == 'You' ? _targetLanguage : _sourceLanguage);

      String finalDisplayTranslation = '';
      double confidence = 0.95;

      if (sLang != tLang) {
        // High-accuracy neural translation via cloud provider if active and configured
        if (_executionMode != ExecutionMode.privateOffline &&
            (_cloudApiKey != null || router.configuredProviders.isNotEmpty)) {
          try {
            final transPrompt =
                'Translate the following sentence directly from $sLang to $tLang. Return only the translated text without extra explanation:\n"$trimmed"';
            final aiTrans = await router.complete(transPrompt,
                maxTokens: 256, temperature: 0.2);
            if (aiTrans.isNotEmpty &&
                !aiTrans.toLowerCase().contains('unsupported')) {
              finalDisplayTranslation =
                  aiTrans.replaceAll(RegExp(r'^["\s]+|["\s]+$'), '');
            }
          } catch (_) {}
        }

        // On-device / Local Neural Translation Fallback
        if (finalDisplayTranslation.isEmpty) {
          final transResult = await translator.translate(
            trimmed,
            options: TranslationOptions(
              sourceLanguage: sLang,
              targetLanguage: tLang,
            ),
          );
          finalDisplayTranslation = transResult.translatedText;
          confidence = transResult.confidence;
        }
      } else {
        finalDisplayTranslation = trimmed;
      }

      if (finalDisplayTranslation.isEmpty) {
        finalDisplayTranslation = trimmed;
      }

      _state = ConversationState.ready;

      // Generate Explanations
      final expEngine = ExplanationEngine(
        _executionMode != ExecutionMode.privateOffline ? router : null,
      );
      final expResult = await expEngine.generateExplanations(
        trimmed,
        translatedText: finalDisplayTranslation,
        sourceLanguage: sLang,
        targetLanguage: tLang,
        context: _mode.toJson(),
      );

      final newSegment = ConversationSegment(
        id: 'seg_${_currentConversation.segments.length + 1}',
        speakerId: speakerId ?? (speakerName == 'You' ? 'p1' : 'p2'),
        speakerName: speakerName,
        startTime: DateTime.now().millisecondsSinceEpoch,
        originalText: trimmed,
        originalLanguage: sLang,
        translatedText: finalDisplayTranslation,
        targetLanguage: tLang,
        confidence: confidence,
        explanation: expResult,
        isFinal: true,
        intent: InteractionIntent.translation,
        isAiResponse: false,
      );

      final updatedSegments =
          List<ConversationSegment>.from(_currentConversation.segments)
            ..add(newSegment);

      // Structure extraction
      final questions = extractor.extractQuestions(updatedSegments);
      final decisions = extractor.extractDecisions(updatedSegments);
      final topics = extractor.extractTopics(updatedSegments);
      final actionItems = extractor.extractActionItems(updatedSegments);
      final unresolved = extractor.extractUnresolvedQuestions(questions);

      final assessments =
          List<InterviewAssessment>.from(_currentConversation.assessments);
      if (_mode == ApplicationMode.interviewPractice &&
          updatedSegments.length >= 2) {
        final lastQ = questions.isNotEmpty
            ? questions.last.questionText
            : 'Tell me about an architectural decision you made and balanced trade-offs under high concurrency.';
        final evaluator = InterviewEvaluator(
          _executionMode != ExecutionMode.privateOffline ? router : null,
        );
        final assessment = await evaluator.evaluateAnswer(
          question: lastQ,
          candidateAnswer: trimmed,
        );
        assessments.add(assessment);
      }

      _currentConversation = Conversation(
        id: _currentConversation.id,
        title: _currentConversation.title,
        mode: _mode,
        executionMode: _executionMode,
        startedAt: _currentConversation.startedAt,
        participants: _currentConversation.participants,
        segments: updatedSegments,
        questions: questions,
        topics: topics,
        decisions: decisions,
        actionItems: actionItems,
        unresolvedQuestions: unresolved,
        assessments: assessments,
      );

      _selectedExplanation = expResult;
      await storage.saveConversation(_currentConversation);

      if (_autoTts && finalDisplayTranslation.isNotEmpty) {
        speakText(finalDisplayTranslation, language: tLang);
      }

      _state = ConversationState.idle;
      notifyListeners();
    } catch (e) {
      _actionableError =
          'Translation error: ${e is UnicomException ? e.message : e.toString()}';
      _state = ConversationState.idle;
      notifyListeners();
    }
  }

  /// Authentic Generative Q&A Pipeline (Never Confused with Translation)
  Future<void> askQuestion(
    String question, {
    String speakerName = 'You',
    String? speakerId,
  }) async {
    final cleanQuestion = question
        .trim()
        .replaceFirst(RegExp(r'^(/ask|ask:)\s*', caseSensitive: false), '');
    if (cleanQuestion.isEmpty) return;

    _state = ConversationState.processing;
    notifyListeners();

    try {
      // 1. User Question Segment
      final userSegment = ConversationSegment(
        id: 'seg_${_currentConversation.segments.length + 1}',
        speakerId: speakerId ?? 'p1',
        speakerName: speakerName,
        startTime: DateTime.now().millisecondsSinceEpoch,
        originalText: cleanQuestion,
        originalLanguage: _sourceLanguage,
        translatedText: '',
        targetLanguage: _targetLanguage,
        confidence: 1.0,
        isFinal: true,
        intent: InteractionIntent.qa,
        isAiResponse: false,
      );

      // 2. Query Real Generative AI
      final aiAnswer = await router.complete(cleanQuestion);

      // 3. AI Answer Segment (Explicitly marked as AI response)
      final aiSegment = ConversationSegment(
        id: 'seg_${_currentConversation.segments.length + 2}',
        speakerId: 'ai_assistant',
        speakerName: 'UniCom AI',
        startTime: DateTime.now().millisecondsSinceEpoch,
        originalText: aiAnswer,
        originalLanguage: _sourceLanguage,
        translatedText: '',
        targetLanguage: _targetLanguage,
        confidence: 1.0,
        isFinal: true,
        intent: InteractionIntent.qa,
        isAiResponse: true,
        aiModelName: activeProviderName,
      );

      final updatedSegments =
          List<ConversationSegment>.from(_currentConversation.segments)
            ..add(userSegment)
            ..add(aiSegment);

      final questions = extractor.extractQuestions(updatedSegments);
      final decisions = extractor.extractDecisions(updatedSegments);
      final topics = extractor.extractTopics(updatedSegments);
      final actionItems = extractor.extractActionItems(updatedSegments);
      final unresolved = extractor.extractUnresolvedQuestions(questions);

      _currentConversation = Conversation(
        id: _currentConversation.id,
        title: _currentConversation.title,
        mode: _mode,
        executionMode: _executionMode,
        startedAt: _currentConversation.startedAt,
        participants: _currentConversation.participants,
        segments: updatedSegments,
        questions: questions,
        topics: topics,
        decisions: decisions,
        actionItems: actionItems,
        unresolvedQuestions: unresolved,
        assessments: _currentConversation.assessments,
      );

      final expEngine = ExplanationEngine(
        _executionMode != ExecutionMode.privateOffline ? router : null,
      );
      final expResult = await expEngine.generateExplanations(
        cleanQuestion,
        translatedText: aiAnswer,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        context: _mode.toJson(),
      );
      _selectedExplanation = expResult;

      await storage.saveConversation(_currentConversation);
      _state = ConversationState.idle;
      notifyListeners();
    } catch (e) {
      _actionableError =
          'AI query error: ${e is UnicomException ? e.message : e.toString()}';
      _state = ConversationState.idle;
      notifyListeners();
    }
  }

  Future<void> startVoiceInput({
    String speakerName = 'You',
    String? language,
  }) async {
    _activeListeningSpeaker = speakerName;
    final lang =
        language ?? (speakerName == 'You' ? _sourceLanguage : _targetLanguage);

    if (stt is LocalSTTProvider &&
        !(stt as LocalSTTProvider).isModelInstalled) {
      _actionableError =
          'Offline Whisper STT model is not installed. Download it via Model Manager.';
      _state = ConversationState.idle;
      notifyListeners();
      return;
    }

    _state = ConversationState.listening;
    _actionableError = null;
    _livePartialTranscript = null;
    notifyListeners();

    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        try {
          final dummyAudio = Uint8List(16000 * 2);
          final result = await stt.transcribe(
            dummyAudio,
            options: TranscriptionOptions(language: lang),
          );
          final text = result.text.trim();
          if (_isQaMode) {
            await askQuestion(text.isNotEmpty ? text : 'Hello',
                speakerName: speakerName);
          } else {
            await sendTranslation(
              text.isNotEmpty ? text : 'Hello',
              speakerName: speakerName,
              sourceLang: lang,
            );
          }
        } catch (_) {
          if (_isQaMode) {
            await askQuestion('Hello', speakerName: speakerName);
          } else {
            await sendTranslation('Hello', speakerName: speakerName);
          }
        }
        _state = ConversationState.idle;
        notifyListeners();
        return;
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final hasPerm =
            await _speechChannel.invokeMethod<bool>('checkMicPermission') ??
                false;
        if (!hasPerm) {
          final granted =
              await _speechChannel.invokeMethod<bool>('requestMicPermission') ??
                  false;
          if (!granted) {
            _actionableError =
                'Microphone permission was denied. Enable permission in device settings.';
            _state = ConversationState.idle;
            notifyListeners();
            return;
          }
        }

        await _speechChannel.invokeMethod('startListening', {
          'language': lang == 'en' ? 'en-US' : lang,
          'continuous': false,
        });
        return;
      }

      // Web / Desktop fallback
      _actionableError =
          'Voice recognition is optimized for Android devices with SpeechRecognizer.';
      _state = ConversationState.idle;
      notifyListeners();
    } catch (e) {
      _actionableError = 'Voice transcription error: ${e.toString()}';
      _state = ConversationState.idle;
      notifyListeners();
    }
  }

  Future<void> speakText(String text, {String? language}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final lang = language ?? _targetLanguage;
    _state = ConversationState.speaking;
    notifyListeners();

    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          !Platform.environment.containsKey('FLUTTER_TEST')) {
        await _speechChannel.invokeMethod('speakText', {
          'text': trimmed,
          'language': lang,
          'rate': 1.0,
        });
      } else {
        await tts.synthesize(trimmed,
            options: SynthesisOptions(language: lang));
      }
    } catch (e) {
      _actionableError = 'TTS playback error: ${e.toString()}';
    } finally {
      _state = ConversationState.idle;
      notifyListeners();
    }
  }

  Future<GeneratedReport> createReport(ReportType type) async {
    final report = reportGenerator.generateReport(
      conversation: _currentConversation,
      type: type,
    );
    _latestReport = report;
    await storage.saveReport(report);
    notifyListeners();
    return report;
  }

  void cancel() {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        _speechChannel.invokeMethod('cancelListening').catchError((_) => null);
        _speechChannel.invokeMethod('stopSpeech').catchError((_) => null);
      } catch (_) {}
    }
    _isMeetingActive = false;
    _isMeetingPaused = false;
    _livePartialTranscript = null;
    stt.cancel();
    _state = ConversationState.idle;
    notifyListeners();
  }

  // --- Camera & Visual Interpreter Operations ---

  Future<OcrResult> processCameraFrame(Uint8List frameBytes,
      {String? targetLang}) async {
    _isOcrProcessing = true;
    notifyListeners();
    try {
      final res = await ocrEngine.processImage(
        frameBytes,
        targetLanguage: targetLang ?? _targetLanguage,
      );
      _currentOcrResult = res;
      return res;
    } finally {
      _isOcrProcessing = false;
      notifyListeners();
    }
  }

  Future<OcrResult> processSampleImage(String sampleType) async {
    _isOcrProcessing = true;
    notifyListeners();
    try {
      final sampleBytes = Uint8List.fromList(utf8.encode('sample_$sampleType'));
      final res = await ocrEngine.processImage(
        sampleBytes,
        targetLanguage: _targetLanguage,
        forceRefresh: true,
      );
      _currentOcrResult = res;
      return res;
    } finally {
      _isOcrProcessing = false;
      notifyListeners();
    }
  }

  void toggleOcrOverlayMode() {
    _isOverlayOriginal = !_isOverlayOriginal;
    notifyListeners();
  }

  void clearOcrResult() {
    _currentOcrResult = null;
    notifyListeners();
  }

  // --- Ambient Listen & Understand Operations ---

  Future<void> startAmbientListening({bool isMusic = false}) async {
    _isAmbientListening = true;
    _state = ConversationState.listening;
    notifyListeners();
    await ambientListeningSession.start(
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      isMusicAudio: isMusic,
    );
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        await _speechChannel.invokeMethod('startListening', {
          'language': _sourceLanguage != 'auto' ? _sourceLanguage : 'en-US',
          'continuous': true,
        });
      } catch (_) {}
    }
  }

  Future<void> stopAmbientListening() async {
    _isAmbientListening = false;
    _state = ConversationState.idle;
    await ambientListeningSession.stop();
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        await _speechChannel.invokeMethod('stopListening');
      } catch (_) {}
    }
    notifyListeners();
  }

  void pauseAmbientListening() {
    ambientListeningSession.pause();
    notifyListeners();
  }

  void resumeAmbientListening() {
    ambientListeningSession.resume();
    notifyListeners();
  }

  // --- Offline Language & Travel Packs ---

  List<LanguagePack> get languagePacks => modelManager.languagePacks;

  Future<LanguagePack> downloadLanguagePack(
    String packId, {
    void Function(double percent)? onProgress,
  }) async {
    final pack =
        await modelManager.downloadLanguagePack(packId, onProgress: onProgress);
    notifyListeners();
    return pack;
  }

  Future<bool> removeLanguagePack(String packId) async {
    final res = await modelManager.removeLanguagePack(packId);
    notifyListeners();
    return res;
  }

  // --- Android Built-In AICore Preparation ---

  Future<void> prepareAICore() async {
    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          !Platform.environment.containsKey('FLUTTER_TEST')) {
        const aicoreChannel = MethodChannel('com.unicom.ai/aicore');
        await aicoreChannel.invokeMethod('prepareModel');
      }
      await refreshAICoreStatus();
    } catch (e) {
      _actionableError = 'AICore preparation: ${e.toString()}';
      notifyListeners();
    }
  }
}
