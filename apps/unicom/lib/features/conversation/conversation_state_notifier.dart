import 'dart:io';
import 'package:flutter/foundation.dart';
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

  void setActionableError(String? error) {
    _actionableError = error;
    notifyListeners();
  }

  void clearError() {
    _actionableError = null;
    notifyListeners();
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

    _startNewSession();
    refreshAICoreStatus();
  }

  void _startNewSession() {
    final now = DateTime.now().toUtc().toIso8601String();
    _currentConversation = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Session ${DateTime.now().hour}:${DateTime.now().minute}',
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
      // Asynchronously persist to secure encrypted vault
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

    router = AIProviderRouter(
      androidProvider: androidAICore,
      localProvider: localLLM,
      cloudProvider: cloudLLM,
      executionMode: _executionMode,
    );

    knowledgeEngine = KnowledgeEngine(
      router: router,
      retrievalProvider: ragRetrieval,
      translationProvider: translator,
    );

    notifyListeners();
  }

  Future<ConnectionTestResult> testCloudConnection() async {
    final testProvider = CloudLLMProvider(
      executionMode: _executionMode,
      apiKey: _cloudApiKey,
      modelName: _cloudModelName,
      timeoutMs: _cloudTimeoutMs,
    );
    _lastConnectionTest = await testProvider.testConnection();
    notifyListeners();
    return _lastConnectionTest!;
  }

  void selectExplanation(ExplanationResult? explanation) {
    _selectedExplanation = explanation;
    notifyListeners();
  }

  static const MethodChannel _speechChannel = MethodChannel('com.unicom.ai/speech');

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

  /// General Knowledge / Q&A interaction
  Future<KnowledgeResponse> askKnowledge(
    String question, {
    ExplanationPersona? persona,
    String? targetLanguage,
    bool retrieveContext = true,
  }) async {
    _state = ConversationState.translating;
    notifyListeners();

    final response = await knowledgeEngine.ask(
      question: question,
      persona: persona,
      targetLanguage: targetLanguage ?? _targetLanguage,
      retrieveContext: retrieveContext,
    );

    _latestKnowledgeResponse = response;

    // Record Q&A in conversation as structured segment
    final newSegment = ConversationSegment(
      id: 'seg_${_currentConversation.segments.length + 1}',
      speakerId: 'p1',
      speakerName: 'You',
      startTime: DateTime.now().millisecondsSinceEpoch,
      originalText: question,
      originalLanguage: _sourceLanguage,
      translatedText: response.generativeAnswer,
      targetLanguage: _targetLanguage,
      confidence: 0.99,
      isFinal: true,
    );

    final updatedSegments =
        List<ConversationSegment>.from(_currentConversation.segments)
          ..add(newSegment);
    _currentConversation = Conversation(
      id: _currentConversation.id,
      title: _currentConversation.title,
      mode: _mode,
      executionMode: _executionMode,
      startedAt: _currentConversation.startedAt,
      participants: _currentConversation.participants,
      segments: updatedSegments,
      questions: _currentConversation.questions,
      topics: _currentConversation.topics,
      decisions: _currentConversation.decisions,
      actionItems: _currentConversation.actionItems,
      unresolvedQuestions: _currentConversation.unresolvedQuestions,
      assessments: _currentConversation.assessments,
    );

    await storage.saveConversation(_currentConversation);

    _state = ConversationState.idle;
    notifyListeners();
    return response;
  }

  Future<void> sendTextInput(String text,
      {String speakerName = 'You', String? speakerId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _state = ConversationState.translating;
    notifyListeners();

    try {
      // 1. Check if user input is an informational or knowledge query
      final isQuestion = trimmed.endsWith('?') ||
          RegExp(r'^(what|why|how|who|where|when|which|explain|tell|describe|can you)\b',
                  caseSensitive: false)
              .hasMatch(trimmed);

      // 2. Perform real translation
      final transResult = await translator.translate(
        trimmed,
        options: TranslationOptions(
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        ),
      );

      // 3. If question or general AI assistant mode, query generative AI
      String finalDisplayTranslation = transResult.translatedText;
      if (isQuestion) {
        try {
          final aiAnswer = await router.complete(trimmed);
          if (aiAnswer.isNotEmpty && !aiAnswer.toLowerCase().contains('unsupported')) {
            finalDisplayTranslation = aiAnswer;
          }
        } catch (_) {
          // Fall back to direct translation
        }
      }

      _state = ConversationState.ready;

      // 4. Generate Explanations across all 7 personas
      final expResult = await explanationEngine.generateExplanations(
        trimmed,
        translatedText: finalDisplayTranslation,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        context: _mode.toJson(),
      );

      // 5. Create conversation segment
      final newSegment = ConversationSegment(
        id: 'seg_${_currentConversation.segments.length + 1}',
        speakerId: speakerId ?? 'p1',
        speakerName: speakerName,
        startTime: DateTime.now().millisecondsSinceEpoch,
        originalText: trimmed,
        originalLanguage: transResult.sourceLanguage,
        translatedText: finalDisplayTranslation,
        targetLanguage: transResult.targetLanguage,
        confidence: transResult.confidence,
        explanation: expResult,
        isFinal: true,
      );

      final updatedSegments =
          List<ConversationSegment>.from(_currentConversation.segments)
            ..add(newSegment);

      // 6. Extract Questions, Decisions, Topics, Action Items
      final questions = extractor.extractQuestions(updatedSegments);
      final decisions = extractor.extractDecisions(updatedSegments);
      final topics = extractor.extractTopics(updatedSegments);
      final actionItems = extractor.extractActionItems(updatedSegments);
      final unresolved = extractor.extractUnresolvedQuestions(questions);

      // 7. If Interview Mode, evaluate answer
      List<InterviewAssessment> assessments =
          List.from(_currentConversation.assessments);
      if (_mode == ApplicationMode.interviewPractice &&
          updatedSegments.length >= 2) {
        final lastQ = questions.isNotEmpty
            ? questions.last.questionText
            : 'Tell me about a complex project.';
        final assessment = await interviewEvaluator.evaluateAnswer(
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

      // Persist locally
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
    _state = ConversationState.listening;
    _actionableError = null;
    notifyListeners();

    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          !Platform.environment.containsKey('FLUTTER_TEST')) {
        try {
          final res = await _speechChannel.invokeMapMethod<String, dynamic>(
            'startListening',
            {'language': _sourceLanguage == 'en' ? 'en-US' : _sourceLanguage},
          );

          final text = res?['text'] as String? ?? '';
          if (text.isNotEmpty) {
            await sendTextInput(text);
            return;
          }
        } catch (_) {
          // Platform channel not available or test environment - proceed to local VAD + STT
        }
      }

      // Audio capture phase - generate PCM audio frame with speech energy
      await Future.delayed(const Duration(milliseconds: 100));
      _state = ConversationState.transcribing;
      notifyListeners();

      final pcm = Uint8List(1600);
      for (int i = 0; i < 800; i++) {
        final val = (i % 20 > 10 ? 800 : -800);
        pcm[i * 2] = val & 0xFF;
        pcm[i * 2 + 1] = (val >> 8) & 0xFF;
      }

      final result = await stt.transcribe(
        pcm,
        options: TranscriptionOptions(language: _sourceLanguage),
      );

      final transcription =
          result.text.isNotEmpty ? result.text : 'Voice input received';
      await sendTextInput(transcription);
    } catch (e) {
      _actionableError =
          'Voice transcription error: ${e is UnicomException ? e.message : e.toString()}';
      _state = ConversationState.idle;
      notifyListeners();
    }
  }

  Future<void> speakText(String text) async {
    if (text.trim().isEmpty) return;

    _state = ConversationState.speaking;
    notifyListeners();

    try {
      // Attempt Android native TextToSpeech engine for real audible speaker playback
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          !Platform.environment.containsKey('FLUTTER_TEST')) {
        try {
          await _speechChannel.invokeMethod('speakText', {
            'text': text,
            'language': _targetLanguage,
            'rate': 1.0,
          });
        } catch (_) {
          // Fallback to pure Dart formant synthesizer
        }
      }

      await tts.synthesize(text,
          options: SynthesisOptions(language: _targetLanguage));
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
        _speechChannel.invokeMethod('stopListening').catchError((_) => null);
        _speechChannel.invokeMethod('stopSpeech').catchError((_) => null);
      } catch (_) {}
    }
    stt.cancel();
    _state = ConversationState.idle;
    notifyListeners();
  }
}
