import 'package:flutter/foundation.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_reporting/reporting.dart';
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

  ConversationController({
    STTProvider? sttProvider,
    TTSProvider? ttsProvider,
    TranslationProvider? translationProvider,
    ExplanationEngine? explanationEngineInstance,
    ConversationExtractor? extractorInstance,
    InterviewEvaluator? interviewEvaluatorInstance,
    ReportGenerator? reportGeneratorInstance,
    StorageProvider? storageProvider,
  })  : stt = sttProvider ?? LocalSTTProvider(isModelInstalled: true),
        tts = ttsProvider ?? OfflineAudioSynthesizer(),
        translator = translationProvider ?? OfflineTranslationEngine(),
        explanationEngine = explanationEngineInstance ?? ExplanationEngine(),
        extractor = extractorInstance ?? ConversationExtractor(),
        interviewEvaluator = interviewEvaluatorInstance ?? InterviewEvaluator(),
        reportGenerator = reportGeneratorInstance ?? ReportGenerator(),
        storage = storageProvider ?? LocalStorageProvider() {
    _startNewSession();
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

  void setExecutionMode(ExecutionMode mode) {
    _executionMode = mode;
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

  void selectExplanation(ExplanationResult? explanation) {
    _selectedExplanation = explanation;
    notifyListeners();
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
