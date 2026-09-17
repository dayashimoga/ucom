import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_reporting/reporting.dart';
import 'package:unicom_model_runtime/model_runtime.dart';

void main() {
  group('E2E Mandatory User Journeys', () {
    // Flow 1: Translate → Explain → Save → Report
    test('E2E Flow 1: Translate -> Explain -> Save -> Report', () async {
      final translator = OfflineTranslationEngine();
      final explanationEngine = ExplanationEngine();
      final reportGenerator = ReportGenerator();

      // Translate
      final trans = await translator.translate(
        'hello world',
        options: const TranslationOptions(
            sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(trans.translatedText, contains('hola'));

      // Explain
      final exp = await explanationEngine.generateExplanations(
        'hello world',
        translatedText: trans.translatedText,
        targetLanguage: 'es',
      );
      expect(exp.explanations.length, equals(7));

      // Save
      final conv = Conversation(
        id: 'flow1_conv',
        title: 'Global Greetings',
        startedAt: DateTime.now().toUtc().toIso8601String(),
        participants: [Participant(id: 'p1', name: 'You')],
        segments: [
          ConversationSegment(
            id: 's1',
            speakerId: 'p1',
            speakerName: 'You',
            startTime: 0,
            originalText: 'hello world',
            originalLanguage: 'en',
            translatedText: trans.translatedText,
            targetLanguage: 'es',
            explanation: exp,
          ),
        ],
      );

      // Report
      final report = reportGenerator.generateReport(
        conversation: conv,
        type: ReportType.quickSummary,
      );
      expect(report.content, contains('Global Greetings'));

      final pdfExporter = PdfExporter();
      final pdf = pdfExporter.exportPdf(report);
      expect(pdf.length, greaterThan(100));
    });

    // Flow 2: Offline → Translate → Report (Network Disabled, 0 Leaks)
    test('E2E Flow 2: Network disabled -> offline translate -> report',
        () async {
      final translator = OfflineTranslationEngine();
      final reportGenerator = ReportGenerator();

      final trans = await translator.translate(
        'system architecture',
        options: const TranslationOptions(
            sourceLanguage: 'en', targetLanguage: 'de'),
      );
      expect(trans.translatedText.toLowerCase(), contains('systemarchitektur'));

      final conv = Conversation(
        id: 'flow2_conv',
        title: 'Offline Architecture Sync',
        executionMode: ExecutionMode.privateOffline,
        startedAt: DateTime.now().toUtc().toIso8601String(),
        segments: [
          ConversationSegment(
            id: 's1',
            speakerId: 'p1',
            speakerName: 'Architect',
            startTime: 0,
            originalText: 'system architecture',
            originalLanguage: 'en',
            translatedText: trans.translatedText,
            targetLanguage: 'de',
          ),
        ],
      );

      final report = reportGenerator.generateReport(
        conversation: conv,
        type: ReportType.detailedSummary,
      );
      expect(report.content, contains('Offline Architecture Sync'));
      expect(report.content, contains('systemarchitektur'));
    });

    // Flow 3: Interview Practice → Question → Answer → Feedback → Report
    test(
        'E2E Flow 3: Interview Practice -> question -> answer -> feedback -> report',
        () async {
      const question =
          'How do you design a scalable event-driven messaging system?';
      const candidateAnswer =
          'First, I analyze throughput and delivery guarantees. Then, I configure partitioned topics with idempotency keys and consumers organized into consumer groups. Because of this structure, the system scales horizontally under load while guaranteeing at-least-once delivery.';

      final evaluator = InterviewEvaluator();
      final assessment = await evaluator.evaluateAnswer(
        question: question,
        candidateAnswer: candidateAnswer,
      );

      expect(assessment.overallScore, greaterThanOrEqualTo(8));
      expect(assessment.rubrics.length, equals(5));
      expect(assessment.studyPlan, isNotEmpty);

      final conv = Conversation(
        id: 'flow3_conv',
        title: 'Staff Architect Interview Drill',
        mode: ApplicationMode.interviewPractice,
        startedAt: DateTime.now().toUtc().toIso8601String(),
        assessments: [assessment],
      );

      final reportGenerator = ReportGenerator();
      final report = reportGenerator.generateReport(
        conversation: conv,
        type: ReportType.interviewReport,
      );

      expect(report.content, contains('Staff Architect Interview Drill'));
      expect(report.content, contains('Rubric Breakdown'));
      expect(report.content, contains('Targeted Study Plan'));
    });

    // Flow 4: Meeting → Segments → Questions/Actions → Minutes Report
    test('E2E Flow 4: Meeting -> segments -> questions/actions -> report',
        () async {
      final segments = [
        ConversationSegment(
          id: 's1',
          speakerId: 'p1',
          speakerName: 'Product Manager',
          startTime: 100,
          originalText: 'Can we complete all E2E verification tests by 5 PM?',
          originalLanguage: 'en',
          translatedText: '¿Podemos completar todas las pruebas...?',
          targetLanguage: 'es',
        ),
        ConversationSegment(
          id: 's2',
          speakerId: 'p2',
          speakerName: 'Lead Engineer',
          startTime: 200,
          originalText:
              'Yes, we decided to run all tests in Podman and action item: @DevSecOps will generate the SBOM and release checksums.',
          originalLanguage: 'en',
          translatedText: 'Sí, decidimos ejecutar...',
          targetLanguage: 'es',
        ),
      ];

      final extractor = ConversationExtractor();
      final questions = extractor.extractQuestions(segments);
      final actions = extractor.extractActionItems(segments);
      final decisions = extractor.extractDecisions(segments);

      expect(questions.length, equals(1));
      expect(actions.length, equals(1));
      expect(decisions.length, equals(1));

      final conv = Conversation(
        id: 'flow4_conv',
        title: 'Sprint Release Alignment',
        mode: ApplicationMode.meeting,
        startedAt: DateTime.now().toUtc().toIso8601String(),
        participants: [
          Participant(id: 'p1', name: 'Product Manager', isHost: true),
          Participant(id: 'p2', name: 'Lead Engineer'),
        ],
        segments: segments,
        questions: questions,
        actionItems: actions,
        decisions: decisions,
      );

      final reportGenerator = ReportGenerator();
      final minutes = reportGenerator.generateReport(
        conversation: conv,
        type: ReportType.meetingMinutes,
      );

      expect(minutes.content, contains('Meeting Minutes'));
      expect(minutes.content, contains('Sprint Release Alignment'));
      expect(minutes.content, contains('Decisions Reached'));
      expect(minutes.content, contains('Action Items'));
    });

    // Flow 5: Multi-Platform / Model Lifecycle E2E
    test(
        'E2E Flow 5: Model Manager catalog verification, download & activation',
        () async {
      final modelManager = LocalModelManager();
      final models = await modelManager.listModels();
      expect(models, isNotEmpty);

      // Verify checksum
      final valid = await modelManager.verifyChecksum('unicom-lexicon-v1');
      expect(valid, isTrue);

      // Download new pack
      final downloaded =
          await modelManager.downloadModel('whisper-tiny-quantized');
      expect(downloaded.isInstalled, isTrue);

      // Activate pack
      final activated =
          await modelManager.activateModel('whisper-tiny-quantized');
      expect(activated, isTrue);
    });
  });
}
