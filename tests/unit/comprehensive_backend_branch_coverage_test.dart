import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_model_runtime/model_runtime.dart';

class _FakeLLMProvider implements LLMProvider {
  final Future<String> Function(String prompt) onComplete;
  final bool offline;

  _FakeLLMProvider({required this.onComplete, this.offline = true});

  @override
  String get id => 'fake_llm';

  @override
  String get name => 'Fake LLM';

  @override
  bool get isOfflineCapable => offline;

  @override
  Future<String> complete(
    String prompt, {
    int maxTokens = 500,
    double temperature = 0.7,
    String? systemPrompt,
  }) async {
    return onComplete(prompt);
  }

  @override
  Stream<String> completeStream(
    String prompt, {
    int maxTokens = 500,
    double temperature = 0.7,
    String? systemPrompt,
  }) async* {
    yield await onComplete(prompt);
  }
}

class _IdentityNeuralEngine extends NeuralTranslationEngine {
  @override
  Future<TranslationResult> translate(
    String text, {
    required TranslationOptions options,
  }) async {
    return TranslationResult(
      translatedText: text,
      sourceLanguage: options.sourceLanguage ?? 'en',
      targetLanguage: options.targetLanguage,
      provider: 'identity',
    );
  }
}

void main() {
  group('Comprehensive Backend Branch Coverage Tests', () {
    test('InterviewEvaluator LLM provider success, missing fields, and error fallback', () async {
      // 1. LLM provider returning full valid JSON
      final fullJsonProvider = _FakeLLMProvider(
        onComplete: (prompt) async => jsonEncode({
          'overallScore': 9,
          'rubrics': [
            {'criterion': 'clarity', 'score': 9, 'feedback': 'Excellent clarity'},
            {'criterion': 'technical_depth', 'score': 9, 'feedback': 'Deep insights'},
          ],
          'strengths': ['Strong architecture knowledge', 'Clear communication'],
          'areasForImprovement': ['Elaborate on cost implications'],
          'recommendedFollowUps': ['How does this scale to 1M QPS?'],
          'studyPlan': ['Study multi-region replication'],
        }),
      );

      final evaluatorWithLLM = InterviewEvaluator(fullJsonProvider);
      final assessment1 = await evaluatorWithLLM.evaluateAnswer(
        question: 'Design a distributed rate limiter',
        candidateAnswer: 'I would use a token bucket algorithm with Redis and Lua scripts for atomic updates.',
        roleOrTopic: 'Staff Systems Architect',
      );

      expect(assessment1.overallScore, equals(9));
      expect(assessment1.rubrics.length, equals(2));
      expect(assessment1.rubrics.first.criterion, equals('clarity'));
      expect(assessment1.strengths.first, contains('Strong architecture'));
      expect(assessment1.areasForImprovement.first, contains('cost implications'));
      expect(assessment1.recommendedFollowUps.first, contains('1M QPS'));
      expect(assessment1.studyPlan.first, contains('multi-region'));

      // 2. LLM provider returning JSON with null / missing lists
      final partialJsonProvider = _FakeLLMProvider(
        onComplete: (prompt) async => 'Some preamble {"overallScore": null} postamble',
      );
      final evaluatorWithPartial = InterviewEvaluator(partialJsonProvider);
      final assessment2 = await evaluatorWithPartial.evaluateAnswer(
        question: 'What is ACID?',
        candidateAnswer: 'Atomicity, Consistency, Isolation, Durability in databases.',
      );
      expect(assessment2.overallScore, equals(8));
      expect(assessment2.rubrics, isEmpty);
      expect(assessment2.strengths, isEmpty);

      // 3. LLM provider throwing exception -> falls back to heuristic scoring
      final errorProvider = _FakeLLMProvider(
        onComplete: (prompt) async => throw Exception('LLM failure'),
      );
      final evaluatorWithError = InterviewEvaluator(errorProvider);
      final assessment3 = await evaluatorWithError.evaluateAnswer(
        question: 'Explain cache invalidation',
        candidateAnswer: 'First, we invalidate on write because stale data degrades user experience. Result is consistent cache.',
      );
      expect(assessment3.overallScore, greaterThan(0));
      expect(assessment3.rubrics.length, equals(5));
    });

    test('InterviewEvaluator heuristic scoring edge cases and branches', () async {
      final evaluator = InterviewEvaluator();

      // Short answer: wordCount < 10 (clarity=4), wordCount < 25 (depth=5), no transitions (structure=6)
      // strengths should fall back to 'Addressed the question promptly.' because all scores < 7
      final shortAnswer = await evaluator.evaluateAnswer(
        question: 'What is DNS?',
        candidateAnswer: 'Domain Name System.',
      );
      expect(shortAnswer.rubrics.firstWhere((r) => r.criterion == 'clarity').score, equals(4));
      expect(shortAnswer.rubrics.firstWhere((r) => r.criterion == 'technical_depth').score, equals(5));
      expect(shortAnswer.rubrics.firstWhere((r) => r.criterion == 'structure').score, equals(6));
      expect(shortAnswer.strengths, contains('Addressed the question promptly.'));
      expect(shortAnswer.areasForImprovement, contains('Expand upon real-world examples and measurable outcomes.'));
      expect(shortAnswer.areasForImprovement, contains('Mention potential failure modes and trade-offs.'));
      expect(shortAnswer.areasForImprovement, contains('Explicitly outline the Situation, Action taken, and Business Result.'));

      // Very long answer: wordCount > 400 (clarity=6)
      final longText = List.generate(450, (i) => 'word$i').join(' ');
      final longAnswer = await evaluator.evaluateAnswer(
        question: 'Explain everything',
        candidateAnswer: longText,
      );
      expect(longAnswer.rubrics.firstWhere((r) => r.criterion == 'clarity').score, equals(6));

      // Comprehensive answer: wordCount >= 40, depth >= 8 (with terms: architecture, scale, database, latency, tradeoff, security, cache, test, api), structure=9 (with first, then, because, result)
      final fullAnswer = await evaluator.evaluateAnswer(
        question: 'Describe your microservice migration',
        candidateAnswer: 'First, our team redesigned the architecture to scale across multiple regions. '
            'Then, we migrated the database to reduce latency and evaluated the tradeoff between consistency and availability. '
            'Because security was paramount, we introduced mutual TLS and a distributed cache to optimize api throughput. '
            'Finally, comprehensive test suites ensured that the result was highly resilient under production load. '
            'Overall, this strategy delivered a 40% improvement in response times across all services.',
      );
      expect(fullAnswer.rubrics.firstWhere((r) => r.criterion == 'clarity').score, equals(9));
      expect(fullAnswer.rubrics.firstWhere((r) => r.criterion == 'technical_depth').score, equals(10));
      expect(fullAnswer.rubrics.firstWhere((r) => r.criterion == 'structure').score, equals(9));
      expect(fullAnswer.strengths, contains('Articulated core message directly.'));
      expect(fullAnswer.strengths, contains('Incorporated specific technical concepts and terminology.'));
      expect(fullAnswer.strengths, contains('Maintained logical progression and flow.'));
      expect(fullAnswer.areasForImprovement, isEmpty);
    });

    test('ExplanationEngine LLM provider and all persona fallback branches', () async {
      // 1. LLM provider returning full JSON for personas
      final llmProvider = _FakeLLMProvider(
        onComplete: (prompt) async => jsonEncode({
          'simple': {'content': 'LLM simple explanation', 'keyPoints': ['point1']},
          'detailed': {'content': 'LLM detailed explanation', 'keyPoints': null},
        }),
      );

      final engineWithLLM = ExplanationEngine(llmProvider);
      final result1 = await engineWithLLM.generateExplanations(
        'What is distributed computing?',
        targetLanguage: 'es',
        personas: [ExplanationPersona.simple, ExplanationPersona.detailed],
      );
      expect(result1.explanations[ExplanationPersona.simple]?.content, equals('LLM simple explanation'));
      expect(result1.explanations[ExplanationPersona.simple]?.keyPoints, equals(['point1']));
      expect(result1.explanations[ExplanationPersona.detailed]?.content, equals('LLM detailed explanation'));
      expect(result1.explanations[ExplanationPersona.detailed]?.keyPoints, isEmpty);

      // 2. LLM provider throwing exception -> falls back to template
      final errorEngine = ExplanationEngine(_FakeLLMProvider(onComplete: (_) async => throw Exception('error')));
      final resultError = await errorEngine.generateExplanations(
        'System architecture is robust.',
        personas: [ExplanationPersona.simple],
      );
      expect(resultError.explanations[ExplanationPersona.simple]?.content, contains('System architecture is robust.'));

      // 3. Template fallback for ALL 7 personas (both question and declarative)
      final templateEngine = ExplanationEngine();

      // Question variant with context and target language
      final qResult = await templateEngine.generateExplanations(
        'Can you explain how this works?',
        context: 'System Design',
        targetLanguage: 'es',
        personas: ExplanationPersona.values,
      );
      expect(qResult.explanations[ExplanationPersona.simple]?.content, contains('direct question'));
      expect(qResult.explanations[ExplanationPersona.detailed]?.content, contains('structured inquiry'));
      expect(qResult.explanations[ExplanationPersona.detailed]?.content, contains('System Design'));
      expect(qResult.explanations[ExplanationPersona.detailed]?.keyPoints, contains('Target language: es'));
      expect(qResult.explanations[ExplanationPersona.terminology]?.content, contains('Key terminology analyzed'));
      expect(qResult.explanations[ExplanationPersona.grammar]?.content, contains('Interrogative clause'));
      expect(qResult.explanations[ExplanationPersona.culturalContext]?.content, contains('respectful and open'));
      expect(qResult.explanations[ExplanationPersona.examples]?.content, contains('Real-world usage examples'));
      expect(qResult.explanations[ExplanationPersona.childFriendly]?.content, contains('Can you tell me more'));

      // Declarative variant without context or target language, short words
      final dResult = await templateEngine.generateExplanations(
        'It is ok.',
        personas: ExplanationPersona.values,
      );
      expect(dResult.explanations[ExplanationPersona.simple]?.content, contains('clear statement'));
      expect(dResult.explanations[ExplanationPersona.detailed]?.content, contains('declarative statement'));
      expect(dResult.explanations[ExplanationPersona.terminology]?.content, contains('Standard conversational vocabulary'));
      expect(dResult.explanations[ExplanationPersona.grammar]?.content, contains('Declarative clause'));
      expect(dResult.explanations[ExplanationPersona.culturalContext]?.content, contains('professional and neutral'));
      expect(dResult.explanations[ExplanationPersona.childFriendly]?.content, contains('Here is something fun'));
    });

    test('SecureKeyStorage all branches: resolution, empty keys, tampering, corruption', () async {
      final tempDir = Directory.systemTemp.createTempSync('secure_key_test_');
      try {
        final storage = SecureKeyStorage(storageDir: tempDir);

        // Save and get valid key
        await storage.saveKey('api_key_1', 'secret_token_123');
        expect(await storage.hasKey('api_key_1'), isTrue);
        expect(await storage.getKey('api_key_1'), equals('secret_token_123'));

        // Save empty/whitespace key -> removes key
        await storage.saveKey('api_key_1', '   ');
        expect(await storage.hasKey('api_key_1'), isFalse);
        expect(await storage.getKey('api_key_1'), isNull);

        // Non-existent key
        expect(await storage.getKey('non_existent'), isNull);
        expect(await storage.hasKey('non_existent'), isFalse);

        // Remove non-existent key
        await storage.removeKey('non_existent');

        // Tampered HMAC or payload in vault file
        await storage.saveKey('api_key_2', 'my_secret');
        final vaultFile = File('${tempDir.path}/.secure_vault.dat');
        expect(await vaultFile.exists(), isTrue);

        final vaultContent = jsonDecode(await vaultFile.readAsString()) as Map<String, dynamic>;
        // Tamper with HMAC
        vaultContent['api_key_2']['hmac'] = 'invalid_tampered_hmac';
        await vaultFile.writeAsString(jsonEncode(vaultContent));
        expect(await storage.getKey('api_key_2'), isNull);

        // Missing fields in entry
        vaultContent['api_key_2'] = {'payload': null, 'hmac': null};
        await vaultFile.writeAsString(jsonEncode(vaultContent));
        expect(await storage.getKey('api_key_2'), isNull);

        // Entry is not a Map
        vaultContent['api_key_2'] = 'not_a_map';
        await vaultFile.writeAsString(jsonEncode(vaultContent));
        expect(await storage.getKey('api_key_2'), isNull);

        // Corrupted base64 payload
        vaultContent['api_key_2'] = {'payload': '!!!not-base-64!!!', 'hmac': 'some_hmac'};
        await vaultFile.writeAsString(jsonEncode(vaultContent));
        expect(await storage.getKey('api_key_2'), isNull);

        // Corrupted non-JSON vault file
        await vaultFile.writeAsString('{{{ invalid json');
        expect(await storage.getKey('api_key_2'), isNull);
        expect(await storage.hasKey('api_key_2'), isFalse);

        // Clear vault
        await storage.clearVault();
        expect(await vaultFile.exists(), isFalse);

        // Clear already deleted vault
        await storage.clearVault();

        // Remove key when vault does not exist
        await storage.removeKey('any_key');

        // Default storageDir resolution test
        final defaultStorage = SecureKeyStorage();
        expect(defaultStorage, isNotNull);
      } finally {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      }
    });

    test('OfflineTranslationEngine formality, reverse checks, and phrasebook fallback', () async {
      final engine = OfflineTranslationEngine(null, _IdentityNeuralEngine());

      // 1. Empty string
      final emptyResult = await engine.translate('', options: const TranslationOptions(targetLanguage: 'es'));
      expect(emptyResult.translatedText, isEmpty);

      // 2. Same language with formality 'more' (Spanish: tú -> usted)
      final sameEsResult = await engine.translate(
        'tú eres mi amigo',
        options: const TranslationOptions(sourceLanguage: 'es', targetLanguage: 'es', formality: 'more'),
      );
      expect(sameEsResult.translatedText, contains('usted'));

      // 3. Same language with formality 'more' (German: du -> Sie)
      final sameDeResult = await engine.translate(
        'du bist hier',
        options: const TranslationOptions(sourceLanguage: 'de', targetLanguage: 'de', formality: 'more'),
      );
      expect(sameDeResult.translatedText, contains('Sie'));

      // 4. Same language standard formality
      final sameStandardResult = await engine.translate(
        'hello world',
        options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'en'),
      );
      expect(sameStandardResult.translatedText, equals('hello world'));

      // 5. Reverse check from non-English to English
      final reverseResult = await engine.translate(
        'gracias',
        options: const TranslationOptions(sourceLanguage: 'es', targetLanguage: 'en'),
      );
      expect(reverseResult.translatedText.toLowerCase(), contains('thank you'));

      // 6. Reverse check from non-English to third language (es -> fr)
      final crossResult = await engine.translate(
        'gracias',
        options: const TranslationOptions(sourceLanguage: 'es', targetLanguage: 'fr'),
      );
      expect(crossResult.translatedText.isNotEmpty, isTrue);

      // 7. Lexical alignment with formality 'more' (es with tú -> usted, de with du -> Sie)
      final formEsResult = await engine.translate(
        'tú',
        options: const TranslationOptions(sourceLanguage: 'fr', targetLanguage: 'es', formality: 'more'),
      );
      expect(formEsResult.translatedText, contains('usted'));

      final formDeResult = await engine.translate(
        'du',
        options: const TranslationOptions(sourceLanguage: 'fr', targetLanguage: 'de', formality: 'more'),
      );
      expect(formDeResult.translatedText, contains('Sie'));
    });

    test('Domain Models full property coverage and serialization roundtrips', () {
      // ModelMetadata full properties
      final meta = ModelMetadata(
        id: 'model_1',
        name: 'Whisper Large',
        version: 'v2.0',
        type: 'stt',
        sizeBytes: 150000000,
        sha256: 'abcdef1234567890',
        license: 'MIT',
        isInstalled: true,
        isActive: true,
        isDownloadable: false,
        downloadUrl: 'https://models.unicom.ai/whisper-large.bin',
        supportedLanguages: ['en', 'es', 'fr'],
        capabilities: ['stt', 'vad'],
        runtime: 'ONNX Runtime',
        quantization: 'INT8',
        minRamMb: 512,
        supportedAccelerators: ['CPU', 'GPU'],
        isLoadedInMemory: true,
        installPath: '/data/models/whisper-large.bin',
      );

      final metaJson = meta.toJson();
      final metaRestored = ModelMetadata.fromJson(metaJson);
      expect(metaRestored.id, equals('model_1'));
      expect(metaRestored.runtime, equals('ONNX Runtime'));
      expect(metaRestored.quantization, equals('INT8'));
      expect(metaRestored.minRamMb, equals(512));
      expect(metaRestored.supportedAccelerators, contains('GPU'));
      expect(metaRestored.isLoadedInMemory, isTrue);
      expect(metaRestored.installPath, equals('/data/models/whisper-large.bin'));

      // AIProviderType fromJson fallback
      expect(AIProviderType.fromJson('gemini'), equals(AIProviderType.gemini));
      expect(AIProviderType.fromJson('openai'), equals(AIProviderType.openai));
      expect(AIProviderType.fromJson('anthropic'), equals(AIProviderType.anthropic));
      expect(AIProviderType.fromJson('custom'), equals(AIProviderType.custom));
      expect(AIProviderType.fromJson('local'), equals(AIProviderType.local));
      expect(AIProviderType.fromJson('aicore'), equals(AIProviderType.aicore));
      expect(AIProviderType.fromJson('unknown_provider'), equals(AIProviderType.custom));

      // GeneratedReport without metadata
      final report = GeneratedReport(
        id: 'rep_1',
        conversationId: 'conv_1',
        reportType: ReportType.quickSummary,
        title: 'Quick Summary',
        content: 'Report content',
        createdAt: '2026-09-20T00:00:00Z',
      );
      final reportJson = report.toJson();
      expect(reportJson.containsKey('metadata'), isFalse);
      final reportRestored = GeneratedReport.fromJson(reportJson);
      expect(reportRestored.title, equals('Quick Summary'));

      // ConversationSegment with null endTime and explanation
      final seg = ConversationSegment(
        id: 'seg_1',
        speakerId: 'spk_1',
        speakerName: 'User',
        startTime: 1000,
        originalText: 'Hello',
        originalLanguage: 'en',
        translatedText: 'Hola',
        targetLanguage: 'es',
      );
      final segJson = seg.toJson();
      expect(segJson.containsKey('endTime'), isFalse);
      expect(segJson.containsKey('explanation'), isFalse);
      final segRestored = ConversationSegment.fromJson(segJson);
      expect(segRestored.endTime, isNull);
      expect(segRestored.explanation, isNull);

      // ExtractedQuestion without optional fields
      final q = ExtractedQuestion(
        id: 'q_1',
        questionText: 'Is this working?',
      );
      final qJson = q.toJson();
      expect(qJson.containsKey('segmentId'), isFalse);
      expect(qJson.containsKey('askedBySpeakerId'), isFalse);
      expect(qJson.containsKey('answerText'), isFalse);
      final qRestored = ExtractedQuestion.fromJson(qJson);
      expect(qRestored.questionText, equals('Is this working?'));

      // ActionItem without optional fields
      final a = ActionItem(id: 'a_1', title: 'Write tests');
      final aJson = a.toJson();
      expect(aJson.containsKey('assignee'), isFalse);
      expect(aJson.containsKey('dueDate'), isFalse);
      expect(aJson.containsKey('segmentId'), isFalse);
      final aRestored = ActionItem.fromJson(aJson);
      expect(aRestored.title, equals('Write tests'));

      // DecisionItem without context or segmentId
      final d = DecisionItem(id: 'd_1', decisionText: 'Use Dart 3.5');
      final dJson = d.toJson();
      expect(dJson.containsKey('context'), isFalse);
      expect(dJson.containsKey('segmentId'), isFalse);
      final dRestored = DecisionItem.fromJson(dJson);
      expect(dRestored.decisionText, equals('Use Dart 3.5'));

      // TopicItem defaults
      final t = TopicItem(id: 't_1', name: 'Testing');
      final tJson = t.toJson();
      final tRestored = TopicItem.fromJson(tJson);
      expect(tRestored.keywords, isEmpty);
      expect(tRestored.relevanceScore, equals(1.0));

      // InterviewRubricScore
      final rub = InterviewRubricScore(criterion: 'delivery', score: 10, feedback: 'Great delivery');
      final rubRestored = InterviewRubricScore.fromJson(rub.toJson());
      expect(rubRestored.score, equals(10));

      // Conversation copyWith all fields
      final conv = Conversation(
        id: 'c1',
        title: 'Session 1',
        startedAt: '2026-09-20T00:00:00Z',
      );
      final fullCopy = conv.copyWith(
        id: 'c2',
        title: 'Session 2',
        mode: ApplicationMode.meeting,
        executionMode: ExecutionMode.cloud,
        startedAt: '2026-09-20T01:00:00Z',
        endedAt: '2026-09-20T02:00:00Z',
        participants: [Participant(id: 'p1', name: 'Bob')],
        segments: [seg],
        questions: [q],
        topics: [t],
        decisions: [d],
        actionItems: [a],
        unresolvedQuestions: ['Who is on call?'],
        assessments: [],
        metadata: {'tag': 'production'},
      );
      expect(fullCopy.id, equals('c2'));
      expect(fullCopy.title, equals('Session 2'));
      expect(fullCopy.mode, equals(ApplicationMode.meeting));
      expect(fullCopy.executionMode, equals(ExecutionMode.cloud));
      expect(fullCopy.endedAt, equals('2026-09-20T02:00:00Z'));
      expect(fullCopy.participants.first.name, equals('Bob'));
      expect(fullCopy.segments.length, equals(1));
      expect(fullCopy.questions.length, equals(1));
      expect(fullCopy.topics.length, equals(1));
      expect(fullCopy.decisions.length, equals(1));
      expect(fullCopy.actionItems.length, equals(1));
      expect(fullCopy.unresolvedQuestions, contains('Who is on call?'));
      expect(fullCopy.metadata?['tag'], equals('production'));
    });

    test('OpenAIProvider complete, completeStream, testConnection, retry and error handling', () async {
      // 1. Private offline mode restrictions
      final offlineProvider = OpenAIProvider(
        executionMode: ExecutionMode.privateOffline,
        apiKey: 'test-key',
      );
      expect(offlineProvider.id, equals('openai_llm'));
      expect(offlineProvider.name, contains('gpt-4o-mini'));
      expect(offlineProvider.isOfflineCapable, isFalse);

      final offlineConn = await offlineProvider.testConnection();
      expect(offlineConn.isSuccessful, isFalse);
      expect(offlineConn.errorMessage, contains('private_offline'));

      expect(
        () => offlineProvider.complete('hello'),
        throwsA(isA<OfflineViolationException>()),
      );
      expect(
        () => offlineProvider.completeStream('hello').toList(),
        throwsA(isA<OfflineViolationException>()),
      );

      // 2. Mock HTTP server for complete, streaming, retries, and errors
      NetworkGate().setOfflineEnforcement(false);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      int requestCount = 0;

      server.listen((HttpRequest request) async {
        requestCount++;
        final bodyStr = await utf8.decoder.bind(request).join();

        if (requestCount == 1) {
          // Healthcheck / testConnection
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'choices': [
                {
                  'message': {'content': 'healthcheck ok'}
                }
              ]
            }));
          await request.response.close();
        } else if (requestCount == 2) {
          // 429 Rate limited simulation on first attempt
          request.response
            ..statusCode = 429
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': {'message': 'Rate limit exceeded'}}));
          await request.response.close();
        } else if (requestCount == 3) {
          // Success after retry
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Response after retry'}
                }
              ]
            }));
          await request.response.close();
        } else if (requestCount == 4) {
          // 400 Bad Request error
          request.response
            ..statusCode = HttpStatus.badRequest
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': {'message': 'Model parameter error'}}));
          await request.response.close();
        } else {
          // Empty choices fallback
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'choices': []}));
          await request.response.close();
        }
      });

      try {
        final cloudProvider = OpenAIProvider(
          executionMode: ExecutionMode.cloud,
          apiKey: 'test-api-key',
          baseUrl: 'http://${server.address.host}:${server.port}',
          timeoutMs: 3000,
        );

        // Test 1: testConnection success
        final connResult = await cloudProvider.testConnection();
        expect(connResult.isSuccessful, isTrue);

        // Test 2: complete with 429 retry then success
        final result = await cloudProvider.complete(
          'Summarize architecture',
          systemPrompt: 'You are an architect',
        );
        expect(result, equals('Response after retry'));

        // Test 3: complete with 400 error throws ProviderException
        expect(
          () => cloudProvider.complete('Failing prompt'),
          throwsA(isA<ProviderException>()),
        );

        // Test 4: empty choices returns 'No response generated.'
        final emptyChoicesResult = await cloudProvider.complete('Empty prompt');
        expect(emptyChoicesResult, equals('No response generated.'));

        // Test 5: completeStream yields chunks
        // Server will now return 'Empty choices' so completeStream yields 'No response generated.'
        final streamChunks = await cloudProvider.completeStream('Streaming prompt').toList();
        expect(streamChunks, isNotEmpty);
      } finally {
        await server.close(force: true);
        NetworkGate().setOfflineEnforcement(true);
      }
    });

    test('AnthropicProvider complete, completeStream, testConnection, retry and error handling', () async {
      // 1. Private offline mode restrictions
      final offlineProvider = AnthropicProvider(
        executionMode: ExecutionMode.privateOffline,
        apiKey: 'test-key',
      );
      expect(offlineProvider.id, equals('anthropic_llm'));
      expect(offlineProvider.name, contains('claude-3-5-sonnet'));
      expect(offlineProvider.isOfflineCapable, isFalse);

      final offlineConn = await offlineProvider.testConnection();
      expect(offlineConn.isSuccessful, isFalse);
      expect(offlineConn.errorMessage, contains('private_offline'));

      expect(
        () => offlineProvider.complete('hello'),
        throwsA(isA<OfflineViolationException>()),
      );
      expect(
        () => offlineProvider.completeStream('hello').toList(),
        throwsA(isA<OfflineViolationException>()),
      );

      // 2. Missing API key
      final noKeyProvider = AnthropicProvider(
        executionMode: ExecutionMode.cloud,
        apiKey: '',
      );
      final noKeyConn = await noKeyProvider.testConnection();
      expect(noKeyConn.isSuccessful, isFalse);
      expect(noKeyConn.errorMessage, contains('Missing Anthropic API key'));
      expect(
        () => noKeyProvider.complete('hello'),
        throwsA(isA<ProviderException>()),
      );

      // 3. Mock HTTP server for complete, streaming, retries, and errors
      NetworkGate().setOfflineEnforcement(false);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      int requestCount = 0;

      server.listen((HttpRequest request) async {
        requestCount++;
        final bodyStr = await utf8.decoder.bind(request).join();

        if (requestCount == 1) {
          // Healthcheck / testConnection
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'content': [
                {'text': 'healthcheck ok'}
              ]
            }));
          await request.response.close();
        } else if (requestCount == 2) {
          // 429 Rate limited simulation
          request.response
            ..statusCode = 429
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': {'message': 'Too many requests'}}));
          await request.response.close();
        } else if (requestCount == 3) {
          // Success after retry
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'content': [
                {'text': 'Claude response after retry'}
              ]
            }));
          await request.response.close();
        } else if (requestCount == 4) {
          // 400 Bad Request
          request.response
            ..statusCode = HttpStatus.badRequest
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': {'message': 'Invalid prompt payload'}}));
          await request.response.close();
        } else {
          // Empty content
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'content': []}));
          await request.response.close();
        }
      });

      try {
        final cloudProvider = AnthropicProvider(
          executionMode: ExecutionMode.cloud,
          apiKey: 'sk-ant-test',
          endpoint: 'http://${server.address.host}:${server.port}/v1/messages',
          timeoutMs: 3000,
        );

        // Test 1: testConnection success
        final connResult = await cloudProvider.testConnection();
        expect(connResult.isSuccessful, isTrue);

        // Test 2: complete with 429 retry then success
        final result = await cloudProvider.complete(
          'Explain Kubernetes',
          systemPrompt: 'You are an SRE expert',
        );
        expect(result, equals('Claude response after retry'));

        // Test 3: complete with 400 error throws ProviderException
        expect(
          () => cloudProvider.complete('Failing prompt'),
          throwsA(isA<ProviderException>()),
        );

        // Test 4: empty content returns 'No response generated.'
        final emptyContentResult = await cloudProvider.complete('Empty prompt');
        expect(emptyContentResult, equals('No response generated.'));

        // Test 5: completeStream yields chunks
        final streamChunks = await cloudProvider.completeStream('Stream test').toList();
        expect(streamChunks, isNotEmpty);
      } finally {
        await server.close(force: true);
        NetworkGate().setOfflineEnforcement(true);
      }
    });

    test('AIProviderRouter registration, routing logic, execution modes, and fallback', () async {
      final android = AndroidAICoreProvider();
      final local = LocalLLMProvider(isModelLoaded: false);
      final cloud = CloudLLMProvider(
        executionMode: ExecutionMode.cloud,
        apiKey: 'gemini-key',
      );

      final router = AIProviderRouter(
        androidProvider: android,
        localProvider: local,
        cloudProvider: cloud,
        executionMode: ExecutionMode.privateOffline,
      );

      expect(router.id, equals('ai_provider_router'));
      expect(router.name, contains('UNICOM AI Provider Router'));
      expect(router.isOfflineCapable, isTrue);

      // Register custom OpenAI provider config
      router.registerProviderConfig(const AIProviderConfig(
        id: 'cfg_openai',
        type: AIProviderType.openai,
        displayName: 'OpenAI GPT-4o',
        apiKey: 'sk-openai-key',
        modelId: 'gpt-4o',
        supportedCapabilities: ['qa', 'reasoning'],
      ));

      // Register Anthropic provider config
      router.registerProviderConfig(const AIProviderConfig(
        id: 'cfg_anthropic',
        type: AIProviderType.anthropic,
        displayName: 'Claude 3.5',
        apiKey: 'sk-ant-key',
        supportedCapabilities: ['code'],
      ));

      // Register Gemini provider config as default
      router.registerProviderConfig(const AIProviderConfig(
        id: 'cfg_gemini',
        type: AIProviderType.gemini,
        displayName: 'Gemini 1.5 Pro',
        apiKey: 'sk-gem-key',
        isDefault: true,
        supportedCapabilities: ['general'],
      ));

      // Register Local & AICore configs
      router.registerProviderConfig(const AIProviderConfig(
        id: 'cfg_local',
        type: AIProviderType.local,
        displayName: 'Local Model',
      ));
      router.registerProviderConfig(const AIProviderConfig(
        id: 'cfg_aicore',
        type: AIProviderType.aicore,
        displayName: 'Android AICore',
      ));

      expect(router.configuredProviders.length, equals(5));
      expect(router.defaultProviderId, equals('cfg_gemini'));
      expect(router.activeProviderConfig?.displayName, equals('Gemini 1.5 Pro'));

      // Capability routing check
      router.setCapabilityRoute('reasoning', 'cfg_openai');

      // 1. Private Offline mode routing
      router.setExecutionMode(ExecutionMode.privateOffline);
      // No AICore available and local model not loaded -> throws OfflineInferenceUnavailableException
      await expectLater(
        router.selectProvider(),
        throwsA(isA<OfflineInferenceUnavailableException>()),
      );

      // 2. Hybrid mode routing
      router.setExecutionMode(ExecutionMode.hybrid);
      final hybridProvider = await router.selectProvider(capability: 'qa');
      expect(hybridProvider, isNotNull);

      // 3. Cloud mode routing
      router.setExecutionMode(ExecutionMode.cloud);
      final cloudProvider = await router.selectProvider(capability: 'code');
      expect(cloudProvider.id, equals('anthropic_llm'));

      final defaultCloudProvider = await router.selectProvider(capability: 'unknown_cap');
      expect(defaultCloudProvider, isNotNull);

      // 4. Auto mode routing
      router.setExecutionMode(ExecutionMode.auto);
      final autoProvider = await router.selectProvider();
      expect(autoProvider, isNotNull);

      // Discover capabilities
      final caps = await router.discoverCapabilities();
      expect(caps['executionMode'], equals('auto'));
      expect(caps['registeredProviders'], isNotEmpty);

      // Remove config
      router.removeProviderConfig('cfg_gemini');
      expect(router.configuredProviders.any((c) => c.id == 'cfg_gemini'), isFalse);

      // Set default provider
      router.setDefaultProvider('cfg_openai');
      expect(router.defaultProviderId, equals('cfg_openai'));

      // Test complete with fallback
      final fakePrimary = _FakeLLMProvider(
        onComplete: (_) async => throw Exception('Primary failed'),
        offline: false,
      );
      final fakeFallbackCloud = CloudLLMProvider(
        executionMode: ExecutionMode.cloud,
        apiKey: 'valid-gemini-key',
      );
      final routerWithFallback = AIProviderRouter(
        androidProvider: android,
        localProvider: LocalLLMProvider(isModelLoaded: false),
        cloudProvider: fakeFallbackCloud,
        executionMode: ExecutionMode.cloud,
      );
      routerWithFallback.registerProviderInstance('primary_test', fakePrimary);
      routerWithFallback.setDefaultProvider('primary_test');

      // Complete in privateOffline mode rethrows without cloud fallback
      routerWithFallback.setExecutionMode(ExecutionMode.privateOffline);
      await expectLater(
        routerWithFallback.complete('test'),
        throwsA(anything),
      );
    });
  });
}
