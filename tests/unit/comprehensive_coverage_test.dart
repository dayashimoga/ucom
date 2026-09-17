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
      expect(ExecutionMode.fromJson('invalid_mode'), equals(ExecutionMode.privateOffline));

      // ApplicationMode
      for (final mode in ApplicationMode.values) {
        expect(ApplicationMode.fromJson(mode.toJson()), equals(mode));
      }
      expect(ApplicationMode.fromJson('unknown_mode'), equals(ApplicationMode.general));

      // ExplanationPersona
      for (final persona in ExplanationPersona.values) {
        expect(ExplanationPersona.fromJson(persona.toJson()), equals(persona));
      }
      expect(ExplanationPersona.fromJson('unknown_persona'), equals(ExplanationPersona.simple));

      // ConversationState
      for (final state in ConversationState.values) {
        expect(ConversationState.fromJson(state.toJson()), equals(state));
      }
      expect(ConversationState.fromJson('UNKNOWN'), equals(ConversationState.idle));

      // ReportType
      for (final type in ReportType.values) {
        expect(ReportType.fromJson(type.toJson()), equals(type));
      }
      expect(ReportType.fromJson('unknown_report'), equals(ReportType.quickSummary));
    });

    test('all domain models toJson and fromJson full coverage', () {
      // Participant
      final p = Participant(id: 'p1', name: 'Alice', role: 'Architect', isHost: true, preferredLanguage: 'en');
      final pJson = p.toJson();
      final pRestored = Participant.fromJson(pJson);
      expect(pRestored.id, equals('p1'));
      expect(pRestored.role, equals('Architect'));
      expect(pRestored.preferredLanguage, equals('en'));

      // ExplanationEntry & ExplanationResult
      final entry = ExplanationEntry(persona: ExplanationPersona.simple, content: 'Simple text', keyPoints: ['point1']);
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
      expect(expRestored.explanations[ExplanationPersona.simple]?.content, equals('Simple text'));

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
      final top = TopicItem(id: 't1', name: 'Security', keywords: ['auth', 'crypto'], relevanceScore: 0.9);
      final topJson = top.toJson();
      final topRestored = TopicItem.fromJson(topJson);
      expect(topRestored.id, equals('t1'));
      expect(topRestored.keywords.length, equals(2));

      // InterviewRubricScore & InterviewAssessment
      final rubric = InterviewRubricScore(criterion: 'clarity', score: 9, feedback: 'Great');
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
    });

    test('exceptions hierarchy coverage: toString and toJson', () {
      const err = UnicomException('Base error', code: 'BASE_ERR', statusCode: 500, details: {'key': 'val'});
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

      const checkErr = ChecksumMismatchException('m1', 'expected_hash', 'actual_hash');
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
      expect(TextUtils.truncate('Longer text that needs truncation', 15), endsWith('...'));
    });

    test('exporters coverage: MarkdownExporter, TextExporter, JsonExporter', () {
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
                ExplanationPersona.simple: ExplanationEntry(persona: ExplanationPersona.simple, content: 'Simple'),
                ExplanationPersona.grammar: ExplanationEntry(persona: ExplanationPersona.grammar, content: 'Grammar'),
                ExplanationPersona.culturalContext: ExplanationEntry(persona: ExplanationPersona.culturalContext, content: 'Culture'),
                ExplanationPersona.terminology: ExplanationEntry(persona: ExplanationPersona.terminology, content: 'Terms'),
              },
            ),
          ),
        ],
        questions: [
          ExtractedQuestion(id: 'q1', questionText: 'Is the release ready?', isAnswered: false, followUpQuestions: ['When?']),
        ],
        actionItems: [
          ActionItem(id: 'a1', title: 'Verify test coverage', status: 'completed', assignee: 'Bob'),
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
      final audio = await fakeTTS.synthesize('Synthesize deterministic speech text');
      expect(audio.mimeType, equals('audio/wav'));
      expect(audio.durationMs, greaterThan(0));
    });

    test('model manager error branches coverage', () async {
      final manager = LocalModelManager();

      // Download non-existent model throws NotFoundException
      expect(() async => await manager.downloadModel('non-existent'), throwsA(isA<NotFoundException>()));

      // Checksum non-existent model throws NotFoundException
      expect(() async => await manager.verifyChecksum('non-existent'), throwsA(isA<NotFoundException>()));

      // Activate uninstalled model throws ValidationException
      expect(() async => await manager.activateModel('whisper-tiny-quantized'), throwsA(isA<ValidationException>()));

      // Remove non-existent model throws NotFoundException
      expect(() async => await manager.removeModel('non-existent'), throwsA(isA<NotFoundException>()));

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
  });
}
