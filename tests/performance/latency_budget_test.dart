import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';

void main() {
  group('Performance & Latency Budget Tests', () {
    test('offline language detection executes within 25ms budget', () async {
      final detector = OfflineLanguageDetector();
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 20; i++) {
        await detector
            .detectLanguage('This is a performance budget verification test.');
      }

      stopwatch.stop();
      final avgMs = stopwatch.elapsedMilliseconds / 20;
      expect(avgMs, lessThan(25.0));
    });

    test('offline translation executes within 30ms budget', () async {
      final translator = OfflineTranslationEngine();
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 20; i++) {
        await translator.translate(
          'hello how are you?',
          options: const TranslationOptions(
              sourceLanguage: 'en', targetLanguage: 'es'),
        );
      }

      stopwatch.stop();
      final avgMs = stopwatch.elapsedMilliseconds / 20;
      expect(avgMs, lessThan(30.0));
    });

    test('multi-persona explanation engine executes within 50ms budget',
        () async {
      final engine = ExplanationEngine();
      final stopwatch = Stopwatch()..start();

      final res = await engine.generateExplanations(
        'We need to review the system architecture before deploying to production.',
        translatedText: 'Necesitamos revisar la arquitectura del sistema.',
        targetLanguage: 'es',
      );

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(res.explanations.length, equals(7));
    });
  });
}
