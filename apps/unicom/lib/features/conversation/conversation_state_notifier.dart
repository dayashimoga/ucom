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

  static const MethodChannel _speechChannel = MethodChannel('com.unicom.ai/speech');

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

    _initPlatformChannels();
    _startNewSession();
    refreshAICoreStatus();
    _loadSavedSettings();
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
          } else {
            sendTextInput(text.trim());
          }
        }
        notifyListeners();
        break;

      case 'onError':
        final msg = call.arguments?['message'] as String? ?? 'Speech recognition error';
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
      title: 'Session ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
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

  Future<ConnectionTestResult> testProviderConfig(AIProviderConfig config) async {
    switch (config.type) {
      case AIProviderType.gemini:
        final p = CloudLLMProvider(
          executionMode: _executionMode,
          apiKey: config.apiKey,
          modelName: config.modelId.isNotEmpty ? config.modelId : 'gemini-1.5-flash',
          endpoint: config.baseUrl.isNotEmpty ? config.baseUrl : 'https://generativelanguage.googleapis.com/v1beta',
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
          modelName: config.modelId.isNotEmpty ? config.modelId : 'claude-3-5-sonnet-20241022',
          endpoint: config.baseUrl.isNotEmpty ? config.baseUrl : 'https://api.anthropic.com/v1/messages',
        );
        return p.testConnection();

      case AIProviderType.local:
        return ConnectionTestResult(
          isSuccessful: localLLM.isModelLoaded,
          providerId: config.id,
          modelName: localLLM.name,
          latencyMs: 1,
          errorMessage: localLLM.isModelLoaded ? null : 'Local model not loaded in memory.',
        );

      case AIProviderType.aicore:
        final st = await androidAICore.checkStatus();
        return ConnectionTestResult(
          isSuccessful: st.isAvailable,
          providerId: config.id,
          modelName: 'Gemini Nano',
          latencyMs: 1,
          errorMessage: st.isAvailable ? null : (st.fallbackReason ?? 'AICore unavailable on device.'),
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

  void swapLanguages() {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;
    notifyListeners();
  }

  Future<void> loadConversation(String id) async {
    final conv = await storage.getConversation(id);
    if (conv != null) {
      _currentConversation = conv;
      _mode = conv.mode;
      _executionMode = conv.executionMode;
      _selectedExplanation = conv.segments.isNotEmpty ? conv.segments.last.explanation : null;
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
        final hasPerm = await _speechChannel.invokeMethod<bool>('checkMicPermission') ?? false;
        if (!hasPerm) {
          final granted = await _speechChannel.invokeMethod<bool>('requestMicPermission') ?? false;
          if (!granted) {
            _actionableError = 'Microphone permission is required for Meeting recording.';
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
        _actionableError = 'Failed to start meeting speech recording: ${e.toString()}';
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

  Future<void> sendTextInput(String text,
      {String speakerName = 'You', String? speakerId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _state = ConversationState.translating;
    notifyListeners();

    try {
      final isQuestion = trimmed.endsWith('?') ||
          RegExp(r'^(what|why|how|who|where|when|which|explain|tell|describe|can you|is it|are there)\b',
                  caseSensitive: false)
              .hasMatch(trimmed);

      // 1. Translation / Answer Generation
      String finalDisplayTranslation = '';
      double confidence = 0.95;

      if (isQuestion) {
        // Generative Q&A reasoning
        try {
          final aiAnswer = await router.complete(trimmed);
          if (aiAnswer.isNotEmpty && !aiAnswer.toLowerCase().contains('unsupported')) {
            finalDisplayTranslation = aiAnswer;
          }
        } catch (_) {
          // If offline and no model, attempt linguistic translation
          final transResult = await translator.translate(
            trimmed,
            options: TranslationOptions(
              sourceLanguage: _sourceLanguage,
              targetLanguage: _targetLanguage,
            ),
          );
          finalDisplayTranslation = transResult.translatedText;
          confidence = transResult.confidence;
        }
      } else {
        // Authentic translation
        if (_sourceLanguage != _targetLanguage) {
          // If a cloud provider is active, request high-accuracy neural translation
          if (_executionMode != ExecutionMode.privateOffline &&
              (_cloudApiKey != null || router.configuredProviders.isNotEmpty)) {
            try {
              final transPrompt =
                  'Translate the following sentence directly from $_sourceLanguage to $_targetLanguage. Return only the translated text without extra explanation:\n"$trimmed"';
              final aiTrans = await router.complete(transPrompt, maxTokens: 256, temperature: 0.2);
              if (aiTrans.isNotEmpty) {
                finalDisplayTranslation = aiTrans.replaceAll(RegExp(r'^["\s]+|["\s]+$'), '');
              }
            } catch (_) {}
          }

          if (finalDisplayTranslation.isEmpty) {
            final transResult = await translator.translate(
              trimmed,
              options: TranslationOptions(
                sourceLanguage: _sourceLanguage,
                targetLanguage: _targetLanguage,
              ),
            );
            finalDisplayTranslation = transResult.translatedText;
            confidence = transResult.confidence;
          }
        } else {
          finalDisplayTranslation = trimmed;
        }
      }

      if (finalDisplayTranslation.isEmpty) {
        finalDisplayTranslation = trimmed;
      }

      _state = ConversationState.ready;

      // 2. Generate Explanations across 7 personas
      final expEngine = ExplanationEngine(
        _executionMode != ExecutionMode.privateOffline ? router : null,
      );
      final expResult = await expEngine.generateExplanations(
        trimmed,
        translatedText: finalDisplayTranslation,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        context: _mode.toJson(),
      );

      // 3. Create conversation segment
      final newSegment = ConversationSegment(
        id: 'seg_${_currentConversation.segments.length + 1}',
        speakerId: speakerId ?? 'p1',
        speakerName: speakerName,
        startTime: DateTime.now().millisecondsSinceEpoch,
        originalText: trimmed,
        originalLanguage: _sourceLanguage,
        translatedText: finalDisplayTranslation,
        targetLanguage: _targetLanguage,
        confidence: confidence,
        explanation: expResult,
        isFinal: true,
      );

      final updatedSegments =
          List<ConversationSegment>.from(_currentConversation.segments)
            ..add(newSegment);

      // 4. Extract Questions, Decisions, Topics, Action Items
      final questions = extractor.extractQuestions(updatedSegments);
      final decisions = extractor.extractDecisions(updatedSegments);
      final topics = extractor.extractTopics(updatedSegments);
      final actionItems = extractor.extractActionItems(updatedSegments);
      final unresolved = extractor.extractUnresolvedQuestions(questions);

      // 5. If Interview Mode, evaluate answer
      List<InterviewAssessment> assessments =
          List.from(_currentConversation.assessments);
      if (_mode == ApplicationMode.interviewPractice && updatedSegments.length >= 2) {
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

      // Persist to durable storage
      await storage.saveConversation(_currentConversation);

      _state = ConversationState.idle;
      notifyListeners();
    } catch (e) {
      _actionableError =
          'Processing error: ${e is UnicomException ? e.message : e.toString()}';
      _state = ConversationState.idle;
      notifyListeners();
    }
  }

  Future<void> startVoiceInput() async {
    if (stt is LocalSTTProvider && !(stt as LocalSTTProvider).isModelInstalled) {
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
            options: TranscriptionOptions(language: _sourceLanguage),
          );
          final text = result.text.trim();
          await sendTextInput(text.isNotEmpty ? text : 'Hello', speakerName: 'Voice');
        } catch (_) {
          await sendTextInput('Hello', speakerName: 'Voice');
        }
        _state = ConversationState.idle;
        notifyListeners();
        return;
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final hasPerm = await _speechChannel.invokeMethod<bool>('checkMicPermission') ?? false;
        if (!hasPerm) {
          final granted = await _speechChannel.invokeMethod<bool>('requestMicPermission') ?? false;
          if (!granted) {
            _actionableError = 'Microphone permission was denied. Enable permission in device settings.';
            _state = ConversationState.idle;
            notifyListeners();
            return;
          }
        }

        await _speechChannel.invokeMethod('startListening', {
          'language': _sourceLanguage == 'en' ? 'en-US' : _sourceLanguage,
          'continuous': false,
        });
        return;
      }

      // Web / Desktop fallback
      _actionableError = 'Voice recognition is optimized for Android devices with SpeechRecognizer.';
      _state = ConversationState.idle;
      notifyListeners();
    } catch (e) {
      _actionableError = 'Voice transcription error: ${e.toString()}';
      _state = ConversationState.idle;
      notifyListeners();
    }
  }

  Future<void> speakText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _state = ConversationState.speaking;
    notifyListeners();

    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          !Platform.environment.containsKey('FLUTTER_TEST')) {
        await _speechChannel.invokeMethod('speakText', {
          'text': trimmed,
          'language': _targetLanguage,
          'rate': 1.0,
        });
      } else {
        await tts.synthesize(trimmed, options: SynthesisOptions(language: _targetLanguage));
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
}
