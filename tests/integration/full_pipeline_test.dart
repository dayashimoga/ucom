import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_reporting/reporting.dart';

void main() {
  group('Full Pipeline Integration Tests', () {
    test('executes complete LISTEN to REPORT pipeline synchronously', () async {
      // 1. LISTEN & TRANSCRIBE
      final stt = DeterministicFakeSTTProvider();
      stt.setMockText('How are you today? We need to deploy the new release.');
      final transcript = await stt.transcribe(Uint8List(100));
      expect(transcript.text, isNotEmpty);

      // 2. DETECT LANGUAGE
      final detector = OfflineLanguageDetector();
      final langResult = await detector.detectLanguage(transcript.text);
      expect(langResult.language, equals('en'));

      // 3. TRANSLATE
      final translator = OfflineTranslationEngine(detector);
      final transResult = await translator.translate(
        transcript.text,
        options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(transResult.translatedText, isNotEmpty);

      // 4. UNDERSTAND & EXPLAIN
      final explanationEngine = ExplanationEngine();
      final explanation = await explanationEngine.generateExplanations(
        transcript.text,
        translatedText: transResult.translatedText,
        targetLanguage: 'es',
      );

      expect(explanation.explanations.length, equals(7));

      // 5. EXTRACT & REMEMBER
      final seg = ConversationSegment(
        id: 'seg_1',
        speakerId: 'p1',
        speakerName: 'Lead Engineer',
        startTime: 100,
        originalText: transcript.text,
        originalLanguage: langResult.language,
        translatedText: transResult.translatedText,
        targetLanguage: 'es',
        explanation: explanation,
      );

      final extractor = ConversationExtractor();
      final questions = extractor.extractQuestions([seg]);
      final actions = extractor.extractActionItems([seg]);

      expect(questions.length, equals(1));
      expect(actions.length, equals(1));

      final conversation = Conversation(
        id: 'conv_integration_1',
        title: 'Release Deployment Review',
        startedAt: DateTime.now().toUtc().toIso8601String(),
        participants: [Participant(id: 'p1', name: 'Lead Engineer')],
        segments: [seg],
        questions: questions,
        actionItems: actions,
      );

      // 6. SUMMARIZE & REPORT
      final reportGenerator = ReportGenerator();
      final report = reportGenerator.generateReport(
        conversation: conversation,
        type: ReportType.quickSummary,
      );

      expect(report.content, contains('Release Deployment Review'));

      // 7. EXPORT (PDF, Markdown, JSON)
      final pdfExporter = PdfExporter();
      final pdfBytes = pdfExporter.exportPdf(report);
      expect(pdfBytes.length, greaterThan(100));

      final jsonExporter = JsonExporter();
      final jsonOutput = jsonExporter.export(report);
      expect(jsonOutput, contains('quick_summary'));
    });
  });
}
