import 'package:flutter/foundation.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_reporting/reporting.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
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

  late final AndroidAICoreProvider androidAICore;
  late final LocalLLMProvider localLLM;
  late final CloudLLMProvider cloudLLM;
  late final AIProviderRouter router;
  late final RagRetrievalProvider ragRetrieval;
  late final KnowledgeEngine knowledgeEngine;

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
        Participant(id: 'p1', name: 'You', isHost: true, preferredLanguage: _sourceLanguage),
        Participant(id: 'p2', name: 'Partner', preferredLanguage: _targetLanguage),
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

  void setCloudConfig({
    String? apiKey,
    String? modelName,
    double? temperature,
    int? maxTokens,
    int? timeoutMs,
  }) {
    if (apiKey != null) _cloudApiKey = apiKey;
    if (modelName != null) _cloudModelName = modelName;
    if (temperature != null) _cloudTemperature = temperature;
    if (maxTokens != null) _cloudMaxTokens = maxTokens;
    if (timeoutMs != null) _cloudTimeoutMs = timeoutMs;
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

    final updatedSegments = List<ConversationSegment>.from(_currentConversation.segments)..add(newSegment);
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

  Future<void> sendTextInput(String text, {String speakerName = 'You', String? speakerId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _state = ConversationState.translating;
    notifyListeners();

    // 1. Translate
    final transResult = await translator.translate(
      trimmed,
      options: TranslationOptions(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      ),
    );

    _state = ConversationState.ready;

    // 2. Generate Explanations across all 7 personas
    final expResult = await explanationEngine.generateExplanations(
      trimmed,
      translatedText: transResult.translatedText,
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      context: _mode.toJson(),
    );

    // 3. Create segment
    final newSegment = ConversationSegment(
      id: 'seg_${_currentConversation.segments.length + 1}',
      speakerId: speakerId ?? 'p1',
      speakerName: speakerName,
      startTime: DateTime.now().millisecondsSinceEpoch,
      originalText: trimmed,
      originalLanguage: transResult.sourceLanguage,
      translatedText: transResult.translatedText,
      targetLanguage: transResult.targetLanguage,
      confidence: transResult.confidence,
      explanation: expResult,
      isFinal: true,
    );

    final updatedSegments = List<ConversationSegment>.from(_currentConversation.segments)..add(newSegment);

    // 4. Extract Questions, Decisions, Topics, Action Items
    final questions = extractor.extractQuestions(updatedSegments);
    final decisions = extractor.extractDecisions(updatedSegments);
    final topics = extractor.extractTopics(updatedSegments);
    final actionItems = extractor.extractActionItems(updatedSegments);
    final unresolved = extractor.extractUnresolvedQuestions(questions);

    // 5. If Interview Mode, evaluate answer
    List<InterviewAssessment> assessments = List.from(_currentConversation.assessments);
    if (_mode == ApplicationMode.interviewPractice && updatedSegments.length >= 2) {
      final lastQ = questions.isNotEmpty ? questions.last.questionText : 'Tell me about a complex project.';
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
  }

  Future<void> startVoiceInput() async {
    _state = ConversationState.listening;
    notifyListeners();

    // Simulate audio capture
    await Future.delayed(const Duration(milliseconds: 200));
    _state = ConversationState.transcribing;
    notifyListeners();

    final result = await stt.transcribe(
      Uint8List(100),
      options: TranscriptionOptions(language: _sourceLanguage),
    );

    if (result.text.isNotEmpty) {
      await sendTextInput(result.text);
    } else {
      _state = ConversationState.idle;
      notifyListeners();
    }
  }

  Future<void> speakText(String text) async {
    _state = ConversationState.speaking;
    notifyListeners();

    await tts.synthesize(text, options: SynthesisOptions(language: _targetLanguage));

    _state = ConversationState.idle;
    notifyListeners();
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
    stt.cancel();
    _state = ConversationState.idle;
    notifyListeners();
  }
}
