import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_reporting/reporting.dart';
import 'package:unicom_model_runtime/model_runtime.dart';

void main() {
  group('Comprehensive Coverage & Quality Invariant Tests', () {
    test('all enums toJson and fromJson roundtrip and default fallbacks', () {
      // ExecutionMode
      for (final mode in ExecutionMode.values) {
        expect(ExecutionMode.fromJson(mode.toJson()), equals(mode));
      }
      expect(ExecutionMode.fromJson('invalid_mode'),
          equals(ExecutionMode.privateOffline));

      // ApplicationMode
      for (final mode in ApplicationMode.values) {
        expect(ApplicationMode.fromJson(mode.toJson()), equals(mode));
      }
      expect(ApplicationMode.fromJson('unknown_mode'),
          equals(ApplicationMode.general));

      // ExplanationPersona
      for (final persona in ExplanationPersona.values) {
        expect(ExplanationPersona.fromJson(persona.toJson()), equals(persona));
      }
      expect(ExplanationPersona.fromJson('unknown_persona'),
          equals(ExplanationPersona.simple));

      // ConversationState
      for (final state in ConversationState.values) {
        expect(ConversationState.fromJson(state.toJson()), equals(state));
      }
      expect(ConversationState.fromJson('UNKNOWN'),
          equals(ConversationState.idle));

      // ReportType
      for (final type in ReportType.values) {
        expect(ReportType.fromJson(type.toJson()), equals(type));
      }
      expect(ReportType.fromJson('unknown_report'),
          equals(ReportType.quickSummary));
    });

    test('all domain models toJson and fromJson full coverage', () {
      // Participant
      final p = Participant(
          id: 'p1',
          name: 'Alice',
          role: 'Architect',
          isHost: true,
          preferredLanguage: 'en');
      final pJson = p.toJson();
      final pRestored = Participant.fromJson(pJson);
      expect(pRestored.id, equals('p1'));
      expect(pRestored.role, equals('Architect'));
      expect(pRestored.preferredLanguage, equals('en'));

      // ExplanationEntry & ExplanationResult
      final entry = ExplanationEntry(
          persona: ExplanationPersona.simple,
          content: 'Simple text',
          keyPoints: ['point1']);
      final entryJson = entry.toJson();
      final entryRestored = ExplanationEntry.fromJson(entryJson);
      expect(entryRestored.persona, equals(ExplanationPersona.simple));
      expect(entryRestored.keyPoints.first, equals('point1'));

      final expResult = ExplanationResult(
        id: 'exp1',
        segmentId: 'seg1',
        originalText: 'Hello',
        translatedText: 'Hola',
        targetLanguage: 'es',
        explanations: {ExplanationPersona.simple: entry},
        createdAt: '2026-09-17T00:00:00Z',
      );
      final expJson = expResult.toJson();
      final expRestored = ExplanationResult.fromJson(expJson);
      expect(expRestored.id, equals('exp1'));
      expect(expRestored.segmentId, equals('seg1'));
      expect(expRestored.explanations[ExplanationPersona.simple]?.content,
          equals('Simple text'));

      // ConversationSegment
      final seg = ConversationSegment(
        id: 'seg1',
        speakerId: 'p1',
        speakerName: 'Alice',
        startTime: 100,
        endTime: 500,
        originalText: 'Original text',
        originalLanguage: 'en',
        translatedText: 'Translated text',
        targetLanguage: 'es',
        confidence: 0.95,
        explanation: expResult,
        isFinal: true,
      );
      final segJson = seg.toJson();
      final segRestored = ConversationSegment.fromJson(segJson);
      expect(segRestored.id, equals('seg1'));
      expect(segRestored.endTime, equals(500));
      expect(segRestored.explanation?.id, equals('exp1'));

      // ExtractedQuestion
      final q = ExtractedQuestion(
        id: 'q1',
        segmentId: 'seg1',
        questionText: 'Is this covered?',
        askedBySpeakerId: 'p1',
        answerText: 'Yes',
        isAnswered: true,
        followUpQuestions: ['Why?'],
      );
      final qJson = q.toJson();
      final qRestored = ExtractedQuestion.fromJson(qJson);
      expect(qRestored.id, equals('q1'));
      expect(qRestored.answerText, equals('Yes'));
      expect(qRestored.followUpQuestions.first, equals('Why?'));

      // ActionItem
      final act = ActionItem(
        id: 'a1',
        title: 'Complete task',
        assignee: 'Alice',
        dueDate: '2026-09-20',
        status: 'in_progress',
        segmentId: 'seg1',
      );
      final actJson = act.toJson();
      final actRestored = ActionItem.fromJson(actJson);
      expect(actRestored.id, equals('a1'));
      expect(actRestored.dueDate, equals('2026-09-20'));
      expect(actRestored.status, equals('in_progress'));

      // DecisionItem
      final dec = DecisionItem(
        id: 'd1',
        decisionText: 'Approved release',
        context: 'Meeting context',
        segmentId: 'seg1',
      );
      final decJson = dec.toJson();
      final decRestored = DecisionItem.fromJson(decJson);
      expect(decRestored.id, equals('d1'));
      expect(decRestored.context, equals('Meeting context'));

      // TopicItem
      final top = TopicItem(
          id: 't1',
          name: 'Security',
          keywords: ['auth', 'crypto'],
          relevanceScore: 0.9);
      final topJson = top.toJson();
      final topRestored = TopicItem.fromJson(topJson);
      expect(topRestored.id, equals('t1'));
      expect(topRestored.keywords.length, equals(2));

      // InterviewRubricScore & InterviewAssessment
      final rubric = InterviewRubricScore(
          criterion: 'clarity', score: 9, feedback: 'Great');
      final rubricJson = rubric.toJson();
      final rubricRestored = InterviewRubricScore.fromJson(rubricJson);
      expect(rubricRestored.score, equals(9));

      final assessment = InterviewAssessment(
        id: 'as1',
        question: 'Explain sharding',
        candidateAnswer: 'Horizontal partitioning of database records',
        overallScore: 9,
        rubrics: [rubric],
        strengths: ['Clear terminology'],
        areasForImprovement: ['Add metric'],
        recommendedFollowUps: ['How about rebalancing?'],
        studyPlan: ['Read distributed systems'],
        createdAt: '2026-09-17T00:00:00Z',
      );
      final asJson = assessment.toJson();
      final asRestored = InterviewAssessment.fromJson(asJson);
      expect(asRestored.id, equals('as1'));
      expect(asRestored.rubrics.first.criterion, equals('clarity'));
      expect(asRestored.studyPlan.first, contains('distributed systems'));

      // GeneratedReport
      final report = GeneratedReport(
        id: 'rep1',
        conversationId: 'c1',
        reportType: ReportType.questionsReport,
        title: 'Questions Report',
        content: '# Questions',
        createdAt: '2026-09-17T00:00:00Z',
        metadata: {'author': 'UNICOM'},
      );
      final repJson = report.toJson();
      final repRestored = GeneratedReport.fromJson(repJson);
      expect(repRestored.id, equals('rep1'));
      expect(repRestored.metadata?['author'], equals('UNICOM'));

      // ModelMetadata
      final model = ModelMetadata(
        id: 'm1',
        name: 'Model 1',
        version: '1.0.0',
        type: 'stt',
        sizeBytes: 1024,
        sha256: 'abc',
        license: 'MIT',
        isInstalled: true,
        isActive: true,
        isDownloadable: false,
        downloadUrl: 'https://example.com/model',
        supportedLanguages: ['en', 'es'],
        capabilities: ['stt'],
      );
      final mJson = model.toJson();
      final mRestored = ModelMetadata.fromJson(mJson);
      expect(mRestored.id, equals('m1'));
      expect(mRestored.downloadUrl, equals('https://example.com/model'));
      expect(mRestored.isInstalled, isTrue);

      // RetrievalDocument
      const rDoc = RetrievalDocument(
        id: 'rd1',
        title: 'Title',
        content: 'Content',
        sourceUri: 'https://example.com',
        score: 0.95,
        metadata: {'author': 'admin'},
      );
      final rJson = rDoc.toJson();
      final rRestored = RetrievalDocument.fromJson(rJson);
      expect(rRestored.id, equals('rd1'));
      expect(rRestored.title, equals('Title'));
      expect(rRestored.sourceUri, equals('https://example.com'));
      expect(rRestored.metadata?['author'], equals('admin'));

      const rDocMin = RetrievalDocument(id: 'rd2', title: 'T2', content: 'C2');
      final rJsonMin = rDocMin.toJson();
      final rRestoredMin = RetrievalDocument.fromJson(rJsonMin);
      expect(rRestoredMin.id, equals('rd2'));

      // KnowledgeResponse
      final kr = KnowledgeResponse(
        id: 'kr1',
        question: 'What is K8s?',
        generativeAnswer: 'Kubernetes is a container orchestration platform.',
        explanation: 'Simple explanation',
        translatedAnswer: 'K8s es una plataforma',
        targetLanguage: 'es',
        aiSummary: 'Short summary',
        groundedSources: [rDoc],
        providerId: 'android_aicore',
        executionMode: 'private_offline',
        latencyMs: 12,
        createdAt: DateTime.now(),
      );
      final krJson = kr.toJson();
      final krRestored = KnowledgeResponse.fromJson(krJson);
      expect(krRestored.id, equals('kr1'));
      expect(krRestored.explanation, equals('Simple explanation'));
      expect(krRestored.groundedSources.length, equals(1));
      expect(kr.toStructuredMarkdown(), contains('### VERBATIM QUESTION'));

      final krMin = KnowledgeResponse(
        id: 'kr2',
        question: 'What is AI?',
        generativeAnswer: 'Artificial intelligence',
        providerId: 'local_llm',
        executionMode: 'private_offline',
        latencyMs: 5,
        createdAt: DateTime.now(),
      );
      final krMinJson = krMin.toJson();
      final krMinRestored = KnowledgeResponse.fromJson(krMinJson);
      expect(krMinRestored.id, equals('kr2'));
      expect(krMin.toStructuredMarkdown(), isNotEmpty);
    });

    test('exceptions hierarchy coverage: toString and toJson', () {
      const err = UnicomException('Base error',
          code: 'BASE_ERR', statusCode: 500, details: {'key': 'val'});
      expect(err.toString(), contains('BASE_ERR'));
      expect(err.toJson()['statusCode'], equals(500));

      const valErr = ValidationException('Validation failed', 'field_error');
      expect(valErr.statusCode, equals(400));
      expect(valErr.details, equals('field_error'));

      const notFound1 = NotFoundException('Session', '123');
      expect(notFound1.message, contains("Session with ID '123'"));

      const notFound2 = NotFoundException('Session');
      expect(notFound2.message, contains('Session not found'));

      const offErr = OfflineViolationException();
      expect(offErr.statusCode, equals(403));

      const provErr = ProviderException('p_id', 'Service unreachable');
      expect(provErr.providerId, equals('p_id'));
      expect(provErr.statusCode, equals(502));

      const checkErr =
          ChecksumMismatchException('m1', 'expected_hash', 'actual_hash');
      expect(checkErr.statusCode, equals(422));
    });

    test('shared utilities: CryptoUtils and TextUtils full coverage', () {
      final hashStr = CryptoUtils.sha256String('UNICOM');
      expect(hashStr, isNotEmpty);

      final hashBytes = CryptoUtils.sha256Bytes(utf8.encode('UNICOM'));
      expect(hashBytes, equals(hashStr));

      expect(TextUtils.countWords(''), equals(0));
      expect(TextUtils.countWords('  three   words  here '), equals(3));
      expect(TextUtils.estimateReadingTimeMinutes('word ' * 360), equals(2));
      expect(TextUtils.truncate('Short', 10), equals('Short'));
      expect(TextUtils.truncate('Longer text that needs truncation', 15),
          endsWith('...'));
    });

    test('exporters coverage: MarkdownExporter, TextExporter, JsonExporter',
        () {
      final rep = GeneratedReport(
        id: 'rep_exp',
        conversationId: 'c1',
        reportType: ReportType.learningReport,
        title: 'Learning Report',
        content: '# Learning Report\n\n**Key**: Value\n> Note here',
        createdAt: '2026-09-17T00:00:00Z',
      );

      final mdExporter = MarkdownExporter();
      expect(mdExporter.export(rep), contains('# Learning Report'));

      final txtExporter = TextExporter();
      final txt = txtExporter.export(rep);
      expect(txt.contains('#'), isFalse);
      expect(txt.contains('**'), isFalse);

      final jsonExporter = JsonExporter();
      final jsonRep = jsonExporter.export(rep);
      expect(jsonRep, contains('learning_report'));

      final conv = Conversation(
        id: 'c_json',
        title: 'JSON export session',
        startedAt: '2026-09-17T00:00:00Z',
      );
      final jsonConv = jsonExporter.exportConversation(conv);
      expect(jsonConv, contains('JSON export session'));
    });

    test('report generator coverage for all 9 types', () {
      final conv = Conversation(
        id: 'c_all_reports',
        title: 'Full Report Generation Session',
        startedAt: '2026-09-17T00:00:00Z',
        participants: [
          Participant(id: 'p1', name: 'Alice', isHost: true),
          Participant(id: 'p2', name: 'Bob'),
        ],
        segments: [
          ConversationSegment(
            id: 's1',
            speakerId: 'p1',
            speakerName: 'Alice',
            startTime: 0,
            originalText: 'System architecture review',
            originalLanguage: 'en',
            translatedText: 'Revisión de arquitectura del sistema',
            targetLanguage: 'es',
            explanation: ExplanationResult(
              id: 'exp1',
              originalText: 'System architecture review',
              createdAt: '2026-09-17T00:00:00Z',
              explanations: {
                ExplanationPersona.simple: ExplanationEntry(
                    persona: ExplanationPersona.simple, content: 'Simple'),
                ExplanationPersona.grammar: ExplanationEntry(
                    persona: ExplanationPersona.grammar, content: 'Grammar'),
                ExplanationPersona.culturalContext: ExplanationEntry(
                    persona: ExplanationPersona.culturalContext,
                    content: 'Culture'),
                ExplanationPersona.terminology: ExplanationEntry(
                    persona: ExplanationPersona.terminology, content: 'Terms'),
              },
            ),
          ),
        ],
        questions: [
          ExtractedQuestion(
              id: 'q1',
              questionText: 'Is the release ready?',
              isAnswered: false,
              followUpQuestions: ['When?']),
        ],
        actionItems: [
          ActionItem(
              id: 'a1',
              title: 'Verify test coverage',
              status: 'completed',
              assignee: 'Bob'),
          ActionItem(id: 'a2', title: 'Deploy artifacts', status: 'pending'),
        ],
        decisions: [
          DecisionItem(id: 'd1', decisionText: 'Use Podman containers'),
        ],
        assessments: [],
      );

      final gen = ReportGenerator();
      for (final type in ReportType.values) {
        final report = gen.generateReport(conversation: conv, type: type);
        expect(report.content, isNotEmpty);
        expect(report.title, isNotEmpty);
      }
    });

    test('cloud adapters handle hybrid mode with valid API keys', () async {
      final cloudTrans = CloudTranslationAdapter(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'valid-api-key',
      );

      final transRes = await cloudTrans.translate(
        'hello cloud',
        options: const TranslationOptions(targetLanguage: 'fr'),
      );
      expect(transRes.translatedText, contains('CLOUD-FR'));
      expect(transRes.provider, equals('cloud_translation_adapter'));

      final cloudSpeech = CloudSpeechAdapter(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'valid-speech-key',
      );

      final sttRes = await cloudSpeech.transcribe(Uint8List(50));
      expect(sttRes.text, equals('[CLOUD_TRANSCRIPTION_RESULT]'));

      final ttsRes = await cloudSpeech.synthesize('hello cloud');
      expect(ttsRes.mimeType, equals('audio/mp3'));
    });

    test('fake speech and translation provider helper methods', () async {
      final fakeTrans = DeterministicFakeTranslationProvider();
      fakeTrans.setTranslation('custom key', 'Respuesta personalizada');

      final res1 = await fakeTrans.translate(
        'custom key',
        options: const TranslationOptions(targetLanguage: 'es'),
      );
      expect(res1.translatedText, equals('Respuesta personalizada'));

      final fakeTTS = DeterministicFakeTTSProvider();
      final audio =
          await fakeTTS.synthesize('Synthesize deterministic speech text');
      expect(audio.mimeType, equals('audio/wav'));
      expect(audio.durationMs, greaterThan(0));
    });

    test('model manager error branches coverage', () async {
      final manager = LocalModelManager();

      // Download non-existent model throws NotFoundException
      expect(() async => await manager.downloadModel('non-existent'),
          throwsA(isA<NotFoundException>()));

      // Checksum non-existent model throws NotFoundException
      expect(() async => await manager.verifyChecksum('non-existent'),
          throwsA(isA<NotFoundException>()));

      // Activate uninstalled model throws ValidationException
      expect(() async => await manager.activateModel('whisper-tiny-quantized'),
          throwsA(isA<ValidationException>()));

      // Remove non-existent model throws NotFoundException
      expect(() async => await manager.removeModel('non-existent'),
          throwsA(isA<NotFoundException>()));

      // Remove uninstalled model returns false
      final removed = await manager.removeModel('piper-neural-voice-en');
      expect(removed, isFalse);
    });

    test('phrasebook getForLanguage fallback and all languages coverage', () {
      final entry = offlinePhrasebook.first;
      expect(entry.getForLanguage('es'), equals('hola'));
      expect(entry.getForLanguage('fr'), equals('bonjour'));
      expect(entry.getForLanguage('de'), equals('hallo'));
      expect(entry.getForLanguage('zh'), equals('你好'));
      expect(entry.getForLanguage('ja'), equals('こんにちは'));
      expect(entry.getForLanguage('ar'), equals('مرحبا'));
      expect(entry.getForLanguage('hi'), equals('नमस्ते'));
      expect(entry.getForLanguage('pt'), equals('olá'));
      expect(entry.getForLanguage('ru'), equals('здравствуйте'));
      expect(entry.getForLanguage('unknown'), isNull);
    });

    test('offline translation engine edge branches coverage', () async {
      final engine = OfflineTranslationEngine();

      // Empty text
      final emptyRes = await engine.translate('   ',
          options: const TranslationOptions(targetLanguage: 'es'));
      expect(emptyRes.translatedText, isEmpty);

      // Auto source language detection
      final autoRes = await engine.translate(
        'வணக்கம்',
        options: const TranslationOptions(
            sourceLanguage: 'auto', targetLanguage: 'en'),
      );
      expect(autoRes.translatedText.toLowerCase(), equals('hello'));
      expect(autoRes.detectedSourceLanguage, equals('ta'));

      // Same language without formality
      final sameLang = await engine.translate(
        'Hola amigo',
        options: const TranslationOptions(
            sourceLanguage: 'es', targetLanguage: 'es'),
      );
      expect(sameLang.translatedText, equals('Hola amigo'));

      // Same language with formality in Spanish
      final sameLangEs = await engine.translate(
        'tú eres genial',
        options: const TranslationOptions(
            sourceLanguage: 'es', targetLanguage: 'es', formality: 'more'),
      );
      expect(sameLangEs.translatedText, contains('usted'));

      // Same language with formality in German
      final sameLangDe = await engine.translate(
        'du bist nett',
        options: const TranslationOptions(
            sourceLanguage: 'de', targetLanguage: 'de', formality: 'more'),
      );
      expect(sameLangDe.translatedText, contains('Sie'));

      // Non-English source to English via lexical lookup
      final esToEn = await engine.translate(
        'mundo proyecto',
        options: const TranslationOptions(
            sourceLanguage: 'es', targetLanguage: 'en'),
      );
      expect(esToEn.translatedText.toLowerCase(), contains('world'));

      // Non-English source to another non-English language
      final esToDe = await engine.translate(
        'mundo',
        options: const TranslationOptions(
            sourceLanguage: 'es', targetLanguage: 'de'),
      );
      expect(esToDe.translatedText.toLowerCase(), contains('welt'));

      // Capitalized lexical token
      final capRes = await engine.translate(
        'World',
        options: const TranslationOptions(
            sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(capRes.translatedText, startsWith('Mundo'));

      // Translated text with formality in Spanish and German
      final transFormEs = await engine.translate(
        'hello tú',
        options: const TranslationOptions(
            sourceLanguage: 'en', targetLanguage: 'es', formality: 'more'),
      );
      expect(transFormEs.translatedText, isNotEmpty);

      final transFormDe = await engine.translate(
        'hello du',
        options: const TranslationOptions(
            sourceLanguage: 'en', targetLanguage: 'de', formality: 'more'),
      );
      expect(transFormDe.translatedText, isNotEmpty);

      // Phrasebook match with trailing punctuation (!, ?, .)
      final pExcl = await engine.translate(
        'hello!',
        options: const TranslationOptions(
            sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(pExcl.translatedText, endsWith('!'));

      final pQues = await engine.translate(
        'how are you??',
        options: const TranslationOptions(
            sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(pQues.translatedText, endsWith('?'));
    });

    test('deterministic fake STT cancel beforehand returns empty result',
        () async {
      final fakeStt = DeterministicFakeSTTProvider();
      fakeStt.cancel();
      final res = await fakeStt.transcribe(Uint8List(10));
      expect(res.text, isEmpty);
      expect(res.confidence, equals(0));
    });

    test('cloud translation and speech adapters handle null and empty apiKey',
        () async {
      final cloudTransNull = CloudTranslationAdapter(
          executionMode: ExecutionMode.hybrid, apiKey: null);
      expect(
        () async => await cloudTransNull.translate('hello',
            options: const TranslationOptions(targetLanguage: 'es')),
        throwsA(isA<ProviderException>()),
      );

      final cloudSpeechNull =
          CloudSpeechAdapter(executionMode: ExecutionMode.hybrid, apiKey: null);
      expect(
        () async => await cloudSpeechNull.transcribe(Uint8List(10)),
        throwsA(isA<ProviderException>()),
      );
      expect(
        () async => await cloudSpeechNull.synthesize('hello'),
        throwsA(isA<ProviderException>()),
      );
    });

    test('additional branch coverage for exceptions, logger, and models',
        () async {
      const cErr = CorruptedDataException('Data corrupted', 'byte_offset_42');
      expect(cErr.code, equals('CORRUPTED_DATA'));
      expect(cErr.statusCode, equals(422));
      expect(cErr.details, equals('byte_offset_42'));

      // PrivacyLogger shouldLog filtering
      const silentLogger = PrivacyLogger(minLevel: LogLevel.warn);
      silentLogger.debug('This should be filtered out by minLevel check');
      silentLogger.info('This should also be filtered out');

      // Conversation with endedAt and metadata
      final fullConv = Conversation(
        id: 'c_full_meta',
        title: 'Full Meta Dialogue',
        startedAt: '2026-09-17T00:00:00Z',
        endedAt: '2026-09-17T01:00:00Z',
        metadata: {'tag': 'production'},
      );
      final fullConvJson = fullConv.toJson();
      expect(fullConvJson['endedAt'], equals('2026-09-17T01:00:00Z'));
      expect(fullConvJson['metadata']['tag'], equals('production'));

      final fromJsonMinimal = Conversation.fromJson({
        'id': 'c_min',
        'title': 'Minimal',
        'startedAt': '2026-09-17T00:00:00Z',
      });
      expect(fromJsonMinimal.questions, isEmpty);
      expect(fromJsonMinimal.topics, isEmpty);
      expect(fromJsonMinimal.decisions, isEmpty);
      expect(fromJsonMinimal.assessments, isEmpty);

      // ModelMetadata with and without all optional fields
      final fullModel = ModelMetadata(
        id: 'full_m',
        name: 'Full Model',
        version: '1.0.0',
        type: 'llm',
        sizeBytes: 1000,
        sha256: 'hash',
        license: 'MIT',
        runtime: 'ONNX',
        quantization: 'INT8',
        minRamMb: 512,
        installPath: '/tmp/model.bin',
      );
      final fullModelJson = fullModel.toJson();
      expect(fullModelJson['runtime'], equals('ONNX'));
      expect(fullModelJson['quantization'], equals('INT8'));
      expect(fullModelJson['minRamMb'], equals(512));
      expect(fullModelJson['installPath'], equals('/tmp/model.bin'));

      final fromJsonFullModel = ModelMetadata.fromJson(fullModelJson);
      expect(fromJsonFullModel.runtime, equals('ONNX'));
      expect(fromJsonFullModel.minRamMb, equals(512));

      // Provider IDs and names coverage
      final fTrans = DeterministicFakeTranslationProvider();
      expect(fTrans.id, isNotEmpty);
      expect(fTrans.name, isNotEmpty);

      final fStt = DeterministicFakeSTTProvider();
      expect(fStt.id, isNotEmpty);
      expect(fStt.name, isNotEmpty);

      final fTts = DeterministicFakeTTSProvider();
      expect(fTts.id, isNotEmpty);
      expect(fTts.name, isNotEmpty);

      final cSpeech = CloudSpeechAdapter(executionMode: ExecutionMode.hybrid);
      expect(cSpeech.id, isNotEmpty);
      expect(cSpeech.name, isNotEmpty);

      final cTrans =
          CloudTranslationAdapter(executionMode: ExecutionMode.hybrid);
      expect(cTrans.id, isNotEmpty);
      expect(cTrans.name, isNotEmpty);

      final synth = OfflineAudioSynthesizer();
      expect(synth.id, isNotEmpty);
      expect(synth.name, isNotEmpty);

      final det = OfflineLanguageDetector();
      expect(det.id, isNotEmpty);
      expect(det.name, isNotEmpty);

      final expEngine = ExplanationEngine();
      final expRes =
          await expEngine.generateExplanations('What is a neural network?');
      expect(expRes.explanations, isNotEmpty);

      final rag = RagRetrievalProvider();
      expect(rag.id, isNotEmpty);
      expect(rag.name, isNotEmpty);

      final router = AIProviderRouter(
        androidProvider: AndroidAICoreProvider(),
        localProvider: LocalLLMProvider(),
        cloudProvider: CloudLLMProvider(executionMode: ExecutionMode.hybrid),
      );
      expect(router.id, isNotEmpty);
      expect(router.name, isNotEmpty);

      final pdfExp = PdfExporter();
      expect(
          pdfExp.exportPdf(GeneratedReport(
            id: 'r_long',
            conversationId: 'c1',
            reportType: ReportType.detailedSummary,
            title: 'Long Report',
            content: List.generate(
                60, (i) => 'Line $i of the detailed audit report.').join('\n'),
            createdAt: '2026-09-17T00:00:00Z',
          )),
          isNotEmpty);
    });

    test(
        'branch coverage for empty reports, long interview answers, and non-letter language detection',
        () async {
      final repGen = ReportGenerator();

      // Empty questions in report
      final convEmptyQ = Conversation(
        id: 'c_empty_q',
        title: 'No Questions Dialogue',
        startedAt: '2026-09-17T00:00:00Z',
      );
      final qReport = repGen.generateReport(
          conversation: convEmptyQ, type: ReportType.questionsReport);
      expect(qReport.content, contains('No explicit inquiries detected'));

      // Empty action items in report
      final aReport = repGen.generateReport(
          conversation: convEmptyQ, type: ReportType.actionItems);
      expect(aReport.content, contains('No outstanding action items recorded'));

      // Meeting minutes with host participant having role
      final convMeeting = Conversation(
        id: 'c_meet',
        title: 'Executive Session',
        startedAt: '2026-09-17T00:00:00Z',
        participants: [
          Participant(
              id: 'p1', name: 'Alice', isHost: true, role: 'VP Architecture')
        ],
      );
      final mReport = repGen.generateReport(
          conversation: convMeeting, type: ReportType.meetingMinutes);
      expect(mReport.content, contains('(Host)'));
      expect(mReport.content, contains('VP Architecture'));

      // Language detector on text with no letters (e.g. only numbers and punctuation)
      final det = OfflineLanguageDetector();
      final numRes = await det.detectLanguage('12345 67890 !@#\$%');
      expect(numRes.language, equals('en'));
      expect(numRes.confidence, equals(0.5));

      // Conversation extractor: unresolved questions
      final extractor = ConversationExtractor();
      final questions = [
        ExtractedQuestion(
            id: 'q1', questionText: 'Is this done?', isAnswered: true),
        ExtractedQuestion(
            id: 'q2', questionText: 'What is next?', isAnswered: false),
      ];
      final unresolved = extractor.extractUnresolvedQuestions(questions);
      expect(unresolved.length, equals(1));
      expect(unresolved.first, equals('What is next?'));

      // Interview evaluator: very short answer
      final evaluator = InterviewEvaluator();
      final shortAssessment = await evaluator.evaluateAnswer(
          question: 'Explain sharding', candidateAnswer: 'no');
      expect(
          shortAssessment.rubrics
              .firstWhere((r) => r.criterion == 'clarity')
              .score,
          equals(4));
      expect(shortAssessment.areasForImprovement,
          contains('Expand upon real-world examples and measurable outcomes.'));

      // Interview evaluator: rambly answer (>400 words)
      final ramblyAnswer = List.generate(420, (i) => 'word$i').join(' ');
      final ramblyAssessment = await evaluator.evaluateAnswer(
          question: 'Explain system architecture',
          candidateAnswer: ramblyAnswer);
      expect(
          ramblyAssessment.rubrics
              .firstWhere((r) => r.criterion == 'clarity')
              .score,
          equals(6));

      // LocalModelManager: unload non-existent model
      final manager = LocalModelManager();
      expect(() async => await manager.unloadModel('non-existent'),
          throwsA(isA<NotFoundException>()));
    });

    test('branch coverage for AudioEnergyVad, STT metrics, and Neural Translation', () async {
      // 1. AudioEnergyVad
      const vad = AudioEnergyVad();
      final emptyFrame = vad.analyzePcm(Uint8List(0));
      expect(emptyFrame.isSpeech, isFalse);
      expect(emptyFrame.sampleCount, equals(0));

      final singleByteFrame = vad.analyzePcm(Uint8List(1));
      expect(singleByteFrame.isSpeech, isFalse);

      final vadJson = const VadFrame(
        rmsEnergy: 100.5,
        zeroCrossingRate: 0.15,
        snrDb: 18.2,
        isSpeech: true,
        sampleCount: 1600,
        durationMs: 100,
      ).toJson();
      expect(vadJson['isSpeech'], isTrue);
      expect(vadJson['rmsEnergy'], equals(100.5));

      // RIFF header parsing in VAD
      final riffHeaderBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        ...List.filled(40, 0),   // Rest of WAV header (44 bytes total)
        ...List.filled(320, 100), // Raw PCM data
      ]);
      final riffFrame = vad.analyzePcm(riffHeaderBytes);
      expect(riffFrame.sampleCount, greaterThan(0));

      // RIFF header without enough payload bytes (sampleCount == 0 branch)
      final riffEmptyPayload = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        ...List.filled(40, 0),   // 44 bytes header
        0x01,                    // Only 1 byte payload => sampleCount = 0
      ]);
      final emptyPayloadFrame = vad.analyzePcm(riffEmptyPayload);
      expect(emptyPayloadFrame.sampleCount, equals(0));

      // trimSilence edge cases
      expect(vad.trimSilence(Uint8List(10)), equals(Uint8List(10)));

      // Silent buffer trim returns empty
      final silentBuffer = Uint8List(16000 * 2); // 1 sec silence
      final trimmedSilent = vad.trimSilence(silentBuffer);
      expect(trimmedSilent.length, equals(0));

      // Buffer with speech flanked by silence
      final speechBytes = ByteData(320 * 2);
      for (int i = 0; i < 320; i++) {
        speechBytes.setInt16(i * 2, (i % 2 == 0 ? 16000 : -16000), Endian.little);
      }
      final speechWithSilence = Uint8List.fromList([
        ...List.filled(640, 0), // leading silence (1 frame)
        ...speechBytes.buffer.asUint8List(), // speech frame
        ...List.filled(640, 0), // trailing silence (1 frame)
      ]);
      final trimmedSpeech = vad.trimSilence(speechWithSilence);
      expect(trimmedSpeech.length, greaterThan(0));

      // 2. STT Evaluation Metrics
      const sttMetrics = SttEvaluationMetrics(
        wer: 0.05,
        cer: 0.02,
        substitutions: 1,
        deletions: 0,
        insertions: 0,
        referenceWords: 20,
      );
      final sttJson = sttMetrics.toJson();
      expect(sttJson['wer'], equals(0.05));
      expect(sttJson['substitutions'], equals(1));

      // computeWER edge cases
      expect(computeWER('', ''), equals(0.0));
      expect(computeWER('', 'hello'), equals(1.0));
      expect(computeWER('hello', ''), equals(1.0));
      expect(computeWER('hello world', 'hello'), equals(0.5));
      expect(computeWER('hello world', 'hello universe'), equals(0.5));

      // computeCER edge cases
      expect(computeCER('', ''), equals(0.0));
      expect(computeCER('', 'a'), equals(1.0));
      expect(computeCER('a', ''), equals(1.0));
      expect(computeCER('cat', 'bat'), closeTo(0.33, 0.01));

      // 3. Neural Translation Engine
      final detector = OfflineLanguageDetector();
      final neuralEngine = NeuralTranslationEngine(detector);

      // Empty text
      final emptyTrans = await neuralEngine.translate('', options: const TranslationOptions(targetLanguage: 'es'));
      expect(emptyTrans.translatedText, isEmpty);

      // Same language
      final sameLangTrans = await neuralEngine.translate('hello', options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'en'));
      expect(sameLangTrans.translatedText, equals('hello'));
      expect(sameLangTrans.confidence, equals(1.0));

      // Auto detect
      final autoTrans = await neuralEngine.translate('hello', options: const TranslationOptions(sourceLanguage: 'auto', targetLanguage: 'es'));
      expect(autoTrans.detectedSourceLanguage, equals('en'));

      // German bidirectional
      final deTrans = await neuralEngine.translate('hello', options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'de'));
      expect(deTrans.translatedText, contains('hallo'));
      final deToEn = await neuralEngine.translate('hallo', options: const TranslationOptions(sourceLanguage: 'de', targetLanguage: 'en'));
      expect(deToEn.translatedText, contains('hello'));

      // French bidirectional
      final frTrans = await neuralEngine.translate('hello', options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'fr'));
      expect(frTrans.translatedText, contains('bonjour'));
      final frToEn = await neuralEngine.translate('bonjour', options: const TranslationOptions(sourceLanguage: 'fr', targetLanguage: 'en'));
      expect(frToEn.translatedText, contains('hello'));

      // Fallback unsupported pair
      final fallbackTrans = await neuralEngine.translate('sample text', options: const TranslationOptions(sourceLanguage: 'ru', targetLanguage: 'zh'));
      expect(fallbackTrans.translatedText, equals('sample text'));

      // TranslationMetrics BLEU edge cases
      expect(TranslationMetrics.computeBleu('', ''), equals(0.0));
      expect(TranslationMetrics.computeBleu('hello', ''), equals(0.0));
      expect(TranslationMetrics.computeBleu('one two three', 'one two three'), equals(1.0));

      // 4. Local LLM Runtime & Tokenizer
      const localMetrics = LocalInferenceMetrics(
        promptTokens: 10,
        completionTokens: 20,
        ttftMs: 15,
        tokensPerSec: 45.0,
        totalLatencyMs: 400,
      );
      final lJson = localMetrics.toJson();
      expect(lJson['promptTokens'], equals(10));
      expect(lJson['tokensPerSec'], equals(45.0));

      final tokenizer = BpeSubwordTokenizer();
      expect(tokenizer.encode(''), isEmpty);
      expect(tokenizer.decode([]), isEmpty);
      expect(tokenizer.vocabSize, greaterThan(100));

      // Tokenize byte fallbacks
      final encoded = tokenizer.encode('Unicode ~ ^ %');
      expect(encoded, isNotEmpty);
      final decoded = tokenizer.decode(encoded);
      expect(decoded, isNotEmpty);

      // QuantizedTransformerRuntime forward pass
      final runtime = QuantizedTransformerRuntime();
      final logits = runtime.forward([BpeSubwordTokenizer.bosTokenId, 5, 6]);
      expect(logits.length, equals(runtime.tokenizer.vocabSize));

      // LocalLLMProvider prompt completion and unloaded error handling
      final unloadedLlm = LocalLLMProvider(isModelLoaded: false);
      expect(() async => await unloadedLlm.complete('test'), throwsA(isA<ValidationException>()));

      final localLlm = LocalLLMProvider();
      final completion = await localLlm.complete(
        'explain quantum entanglement',
        systemPrompt: 'You are a physics expert.',
        maxTokens: 15,
        temperature: 0.2,
      );
      expect(completion, isNotEmpty);
      expect(localLlm.lastMetrics, isNotNull);
      expect(localLlm.lastMetrics!.tokensPerSec, greaterThan(0));

      final streamChunks = <String>[];
      await for (final chunk in localLlm.completeStream('what is energy', maxTokens: 10)) {
        streamChunks.add(chunk);
      }
      expect(streamChunks, isNotEmpty);
    });
  });
}
