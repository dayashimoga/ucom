import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';

void main() {
  group('OfflineTranslationEngine Tests', () {
    late OfflineTranslationEngine engine;

    setUp(() {
      engine = OfflineTranslationEngine();
    });

    test('translates common phrases using offline phrasebook', () async {
      final res = await engine.translate(
        'hello',
        options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(res.translatedText.toLowerCase(), contains('hola'));
      expect(res.confidence, greaterThanOrEqualTo(0.95));
      expect(res.provider, equals('offline_translation_engine'));
    });

    test('preserves capitalization from source input', () async {
      final res = await engine.translate(
        'Hello',
        options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(res.translatedText, equals('Hola'));
    });

    test('preserves terminal punctuation', () async {
      final res = await engine.translate(
        'How are you?',
        options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'fr'),
      );
      expect(res.translatedText, contains('?'));
    });

    test('translates bidirectional from Spanish to English', () async {
      final res = await engine.translate(
        'gracias',
        options: const TranslationOptions(sourceLanguage: 'es', targetLanguage: 'en'),
      );
      expect(res.translatedText.toLowerCase(), contains('thank you'));
    });

    test('returns original string when source and target language are identical', () async {
      final res = await engine.translate(
        'Architecture',
        options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'en'),
      );
      expect(res.translatedText, equals('Architecture'));
      expect(res.confidence, equals(1.0));
    });

    test('applies formality rules when specified', () async {
      final formalRes = await engine.translate(
        'tú eres bueno',
        options: const TranslationOptions(sourceLanguage: 'es', targetLanguage: 'es', formality: 'more'),
      );
      // Formal in Spanish uses usted
      expect(formalRes.translatedText, contains('usted'));
    });

    test('handles empty input gracefully', () async {
      final res = await engine.translate(
        '   ',
        options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(res.translatedText, isEmpty);
    });
  });
}
