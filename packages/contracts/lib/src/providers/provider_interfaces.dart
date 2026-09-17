import 'dart:typed_data';
import '../models/enums.dart';
import '../models/domain_models.dart';

class TranscriptionOptions {
  final String? language;
  final bool detectLanguage;
  final int sampleRate;

  const TranscriptionOptions({
    this.language,
    this.detectLanguage = true,
    this.sampleRate = 16000,
  });
}

class TranscriptionResult {
  final String text;
  final String? language;
  final double confidence;
  final bool isFinal;

  const TranscriptionResult({
    required this.text,
    this.language,
    this.confidence = 1.0,
    this.isFinal = true,
  });
}

abstract class STTProvider {
  String get id;
  String get name;
  bool get isOfflineCapable;

  Future<TranscriptionResult> transcribe(
    Uint8List audioBytes, {
    TranscriptionOptions options = const TranscriptionOptions(),
  });

  void cancel();
}

class SynthesisOptions {
  final String? language;
  final String? voiceId;
  final double pitch;
  final double rate;
  final double volume;

  const SynthesisOptions({
    this.language,
    this.voiceId,
    this.pitch = 1.0,
    this.rate = 1.0,
    this.volume = 1.0,
  });
}

class SynthesisResult {
  final Uint8List audioBytes;
  final String mimeType;
  final int durationMs;

  const SynthesisResult({
    required this.audioBytes,
    required this.mimeType,
    required this.durationMs,
  });
}

abstract class TTSProvider {
  String get id;
  String get name;
  bool get isOfflineCapable;

  Future<SynthesisResult> synthesize(
    String text, {
    SynthesisOptions options = const SynthesisOptions(),
  });
}

class LanguageDetectionResult {
  final String language;
  final double confidence;
  final bool supported;
  final List<Map<String, dynamic>> alternatives;

  const LanguageDetectionResult({
    required this.language,
    required this.confidence,
    this.supported = true,
    this.alternatives = const [],
  });
}

abstract class LanguageDetectionProvider {
  String get id;
  String get name;
  bool get isOfflineCapable;

  Future<LanguageDetectionResult> detectLanguage(String text);
}

class TranslationOptions {
  final String? sourceLanguage;
  final String targetLanguage;
  final String formality; // default, more, less
  final String? context;

  const TranslationOptions({
    this.sourceLanguage,
    required this.targetLanguage,
    this.formality = 'default',
    this.context,
  });
}

class TranslationResult {
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final String? detectedSourceLanguage;
  final double confidence;
  final String provider;

  const TranslationResult({
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.detectedSourceLanguage,
    this.confidence = 1.0,
    required this.provider,
  });
}

abstract class TranslationProvider {
  String get id;
  String get name;
  bool get isOfflineCapable;

  Future<TranslationResult> translate(
    String text, {
    required TranslationOptions options,
  });
}

abstract class LLMProvider {
  String get id;
  String get name;
  bool get isOfflineCapable;

  Future<String> complete(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  });

  Stream<String> completeStream(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  });
}

abstract class EmbeddingProvider {
  String get id;
  String get name;
  bool get isOfflineCapable;

  Future<List<double>> embed(String text);
  Future<List<List<double>>> embedBatch(List<String> texts);
}

abstract class OCRProvider {
  String get id;
  String get name;
  bool get isOfflineCapable;

  Future<String> extractText(Uint8List imageBytes);
}

abstract class StorageProvider {
  String get id;
  String get name;

  Future<void> saveConversation(Conversation conversation);
  Future<Conversation?> getConversation(String id);
  Future<List<Conversation>> listConversations({
    String? query,
    ApplicationMode? mode,
    ExecutionMode? executionMode,
    int limit = 50,
    int offset = 0,
  });
  Future<bool> deleteConversation(String id);
  Future<void> saveReport(GeneratedReport report);
  Future<List<GeneratedReport>> getReportsByConversationId(String conversationId);
  Future<List<Conversation>> searchConversations(String query, {int limit = 20});
}

abstract class ModelManagerProvider {
  Future<List<ModelMetadata>> listModels();
  Future<ModelMetadata?> getModel(String id);
  Future<ModelMetadata> downloadModel(
    String id, {
    void Function(double percent)? onProgress,
  });
  Future<bool> verifyChecksum(String id);
  Future<bool> activateModel(String id);
  Future<bool> removeModel(String id);
}

class RetrievalDocument {
  final String id;
  final String title;
  final String content;
  final String? sourceUri;
  final double score;
  final Map<String, dynamic>? metadata;

  const RetrievalDocument({
    required this.id,
    required this.title,
    required this.content,
    this.sourceUri,
    this.score = 1.0,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        if (sourceUri != null) 'sourceUri': sourceUri,
        'score': score,
        if (metadata != null) 'metadata': metadata,
      };

  factory RetrievalDocument.fromJson(Map<String, dynamic> json) =>
      RetrievalDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        sourceUri: json['sourceUri'] as String?,
        score: (json['score'] as num?)?.toDouble() ?? 1.0,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

abstract class RetrievalProvider {
  String get id;
  String get name;
  bool get isOfflineCapable;

  Future<List<RetrievalDocument>> retrieve(String query, {int topK = 5});
  Future<void> indexDocument(RetrievalDocument doc);
  Future<bool> deleteDocument(String id);
}

