import 'dart:async';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import '../providers/ai_provider_router.dart';
import 'rag_retrieval_provider.dart';

/// Structured response from KnowledgeEngine separating all components cleanly.
class KnowledgeResponse {
  final String id;
  final String question;
  final String generativeAnswer;
  final String? explanation;
  final String? translatedAnswer;
  final String? targetLanguage;
  final String? aiSummary;
  final List<RetrievalDocument> groundedSources;
  final List<String> citations;
  final bool hasSufficientContext;
  final bool hasConflictingSources;
  final List<String> conflicts;
  final String providerId;
  final String executionMode;
  final int latencyMs;
  final DateTime createdAt;

  const KnowledgeResponse({
    required this.id,
    required this.question,
    required this.generativeAnswer,
    this.explanation,
    this.translatedAnswer,
    this.targetLanguage,
    this.aiSummary,
    this.groundedSources = const [],
    this.citations = const [],
    this.hasSufficientContext = true,
    this.hasConflictingSources = false,
    this.conflicts = const [],
    required this.providerId,
    required this.executionMode,
    required this.latencyMs,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'generativeAnswer': generativeAnswer,
        if (explanation != null) 'explanation': explanation,
        if (translatedAnswer != null) 'translatedAnswer': translatedAnswer,
        if (targetLanguage != null) 'targetLanguage': targetLanguage,
        if (aiSummary != null) 'aiSummary': aiSummary,
        'groundedSources': groundedSources.map((s) => s.toJson()).toList(),
        'citations': citations,
        'hasSufficientContext': hasSufficientContext,
        'hasConflictingSources': hasConflictingSources,
        'conflicts': conflicts,
        'providerId': providerId,
        'executionMode': executionMode,
        'latencyMs': latencyMs,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KnowledgeResponse.fromJson(Map<String, dynamic> json) =>
      KnowledgeResponse(
        id: json['id'] as String,
        question: json['question'] as String,
        generativeAnswer: json['generativeAnswer'] as String,
        explanation: json['explanation'] as String?,
        translatedAnswer: json['translatedAnswer'] as String?,
        targetLanguage: json['targetLanguage'] as String?,
        aiSummary: json['aiSummary'] as String?,
        groundedSources: (json['groundedSources'] as List<dynamic>?)
                ?.map((e) =>
                    RetrievalDocument.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        citations: (json['citations'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        hasSufficientContext: json['hasSufficientContext'] as bool? ?? true,
        hasConflictingSources: json['hasConflictingSources'] as bool? ?? false,
        conflicts: (json['conflicts'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        providerId: json['providerId'] as String,
        executionMode: json['executionMode'] as String,
        latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  /// Formatted text output with clear visual separation
  String toStructuredMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('### VERBATIM QUESTION');
    buffer.writeln(question);
    buffer.writeln();

    buffer.writeln('### GENERATIVE ANSWER');
    buffer.writeln(generativeAnswer);
    buffer.writeln();

    if (citations.isNotEmpty) {
      buffer.writeln('### CITATIONS');
      for (final cit in citations) {
        buffer.writeln('- $cit');
      }
      buffer.writeln();
    }

    if (hasConflictingSources && conflicts.isNotEmpty) {
      buffer.writeln('### CONFLICTING EVIDENCE DETECTED');
      for (final conflict in conflicts) {
        buffer.writeln('> ⚠️ $conflict');
      }
      buffer.writeln();
    }

    if (explanation != null && explanation!.isNotEmpty) {
      buffer.writeln('### EXPLANATION');
      buffer.writeln(explanation);
      buffer.writeln();
    }

    if (translatedAnswer != null && translatedAnswer!.isNotEmpty) {
      buffer.writeln(
          '### TRANSLATION (${targetLanguage?.toUpperCase() ?? "TARGET"})');
      buffer.writeln(translatedAnswer);
      buffer.writeln();
    }

    if (aiSummary != null && aiSummary!.isNotEmpty) {
      buffer.writeln('### AI SUMMARY');
      buffer.writeln(aiSummary);
      buffer.writeln();
    }

    if (groundedSources.isNotEmpty) {
      buffer.writeln('### GROUNDED SOURCES');
      for (final src in groundedSources) {
        buffer.writeln(
            '- **${src.title}** (relevance: ${(src.score * 100).toStringAsFixed(1)}%)');
        if (src.sourceUri != null) buffer.writeln('  Source: ${src.sourceUri}');
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln(
        '*Provenance: Provider `$providerId` | Mode `$executionMode` | Latency `${latencyMs}ms`*');
    return buffer.toString();
  }
}

/// Knowledge and Q&A Engine for arbitrary general knowledge, technical concepts,
/// science, mathematics, literature, and general inquiry with RAG grounding.
class KnowledgeEngine {
  final AIProviderRouter router;
  final RagRetrievalProvider? retrievalProvider;
  final TranslationProvider? translationProvider;
  final LanguageDetectionProvider? detectionProvider;
  final PrivacyLogger _logger =
      const PrivacyLogger(context: 'KNOWLEDGE_ENGINE');

  KnowledgeEngine({
    required this.router,
    this.retrievalProvider,
    this.translationProvider,
    this.detectionProvider,
  });

  /// Ask arbitrary questions with optional grounding, explanation style, and translation.
  Future<KnowledgeResponse> ask({
    required String question,
    ExplanationPersona? persona,
    String? targetLanguage,
    bool retrieveContext = true,
  }) async {
    final sw = Stopwatch()..start();
    final id = 'qa-${DateTime.now().millisecondsSinceEpoch}';

    _logger.info(
        'Processing knowledge query', {'questionLength': question.length});

    // 1. Context retrieval / RAG
    List<RetrievalDocument> groundedSources = [];
    List<String> citations = [];
    bool hasSufficient = true;
    bool hasConflicts = false;
    List<String> conflicts = [];
    String prompt = question;

    if (retrieveContext && retrievalProvider != null) {
      final ragResult = await retrievalProvider!.query(question, topK: 3);
      groundedSources = ragResult.documents;
      hasSufficient = ragResult.hasSufficientContext;
      hasConflicts = ragResult.hasConflictingSources;
      conflicts = ragResult.detectedConflicts;

      if (groundedSources.isNotEmpty) {
        citations = groundedSources
            .map((d) => d.sourceUri != null
                ? '[Source: ${d.title}] (${d.sourceUri})'
                : '[Source: ${d.title}]')
            .toList();
        final contextSnippet = groundedSources
            .map((d) => 'Source [${d.title}]:\n${d.content}')
            .join('\n\n');
        prompt = 'Retrieved Reference Documentation:\n$contextSnippet\n\n'
            'Question: $question\n\n'
            'Strict Grounding Instructions: Answer based strictly on the provided references. '
            'Cite sources where applicable. If references do not contain enough information, state so clearly.';
      }
    }

    // 2. Select provider & complete LLM answer
    final provider = await router.selectProvider();
    String generativeAnswer;

    // Check if sources completely lack an answer
    if (retrieveContext &&
        retrievalProvider != null &&
        groundedSources.isNotEmpty &&
        !hasSufficient) {
      generativeAnswer =
          'The provided reference documents do not contain sufficient information to answer the question: "$question".';
    } else {
      generativeAnswer = await provider.complete(prompt);
    }

    // Append conflict disclaimer if detected
    if (hasConflicts && conflicts.isNotEmpty) {
      generativeAnswer +=
          '\n\n*Note: Conflicting information detected across sources: ${conflicts.join("; ")}*';
    }

    // 3. Optional Explanation
    String? explanation;
    if (persona != null) {
      explanation = await _generateExplanation(
          question, generativeAnswer, persona, provider);
    }

    // 4. Optional Translation
    String? translatedAnswer;
    if (targetLanguage != null &&
        targetLanguage.isNotEmpty &&
        translationProvider != null) {
      final transResult = await translationProvider!.translate(
        generativeAnswer,
        options: TranslationOptions(targetLanguage: targetLanguage),
      );
      translatedAnswer = transResult.translatedText;
    }

    // 5. Short AI Summary
    final aiSummary = generativeAnswer.length > 120
        ? '${generativeAnswer.substring(0, 117)}...'
        : generativeAnswer;

    sw.stop();

    return KnowledgeResponse(
      id: id,
      question: question,
      generativeAnswer: generativeAnswer,
      explanation: explanation,
      translatedAnswer: translatedAnswer,
      targetLanguage: targetLanguage,
      aiSummary: aiSummary,
      groundedSources: groundedSources,
      citations: citations,
      hasSufficientContext: hasSufficient,
      hasConflictingSources: hasConflicts,
      conflicts: conflicts,
      providerId: provider.id,
      executionMode: router.executionMode.name,
      latencyMs: sw.elapsedMilliseconds,
      createdAt: DateTime.now(),
    );
  }

  /// Stream answers for real-time interaction
  Stream<String> askStream({
    required String question,
  }) async* {
    final provider = await router.selectProvider();
    yield* provider.completeStream(question);
  }

  Future<KnowledgeResponse> explainSimply(String topic) {
    return ask(question: topic, persona: ExplanationPersona.childFriendly);
  }

  Future<KnowledgeResponse> explainDeeply(String topic) {
    return ask(question: topic, persona: ExplanationPersona.detailed);
  }

  Future<KnowledgeResponse> giveExample(String topic) {
    return ask(question: topic, persona: ExplanationPersona.examples);
  }

  Future<String> _generateExplanation(
    String question,
    String answer,
    ExplanationPersona persona,
    LLMProvider provider,
  ) async {
    final expPrompt =
        'Explain the following in "${persona.toJson()}" persona:\n'
        'Question: $question\n'
        'Answer: $answer';
    return provider.complete(expPrompt,
        systemPrompt: 'You are an adaptive educational tutor.');
  }
}
