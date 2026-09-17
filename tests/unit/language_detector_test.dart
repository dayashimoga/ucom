import 'package:test/test.dart';
import 'package:unicom_ai_core/ai_core.dart';

void main() {
  group('OfflineLanguageDetector Tests', () {
    late OfflineLanguageDetector detector;

    setUp(() {
      detector = OfflineLanguageDetector();
    });

    test('detects English text accurately', () async {
      final res = await detector
          .detectLanguage('Hello, how are you today? This is a great project.');
      expect(res.language, equals('en'));
      expect(res.confidence, greaterThanOrEqualTo(0.7));
    });

    test('detects Spanish text accurately', () async {
      final res = await detector.detectLanguage(
          'Hola, ¿cómo estás? Muchas gracias por su ayuda con el proyecto.');
      expect(res.language, equals('es'));
      expect(res.confidence, greaterThanOrEqualTo(0.7));
    });

    test('detects French text accurately', () async {
      final res = await detector.detectLanguage(
          'Bonjour, comment allez-vous? Merci beaucoup pour votre travail.');
      expect(res.language, equals('fr'));
      expect(res.confidence, greaterThanOrEqualTo(0.7));
    });

    test('detects German text accurately', () async {
      final res = await detector.detectLanguage(
          'Guten Tag, wie geht es Ihnen? Vielen Dank für das Treffen.');
      expect(res.language, equals('de'));
      expect(res.confidence, greaterThanOrEqualTo(0.7));
    });

    test('detects Japanese script accurately', () async {
      final res = await detector.detectLanguage('こんにちは、元気ですか？');
      expect(res.language, equals('ja'));
      expect(res.confidence, greaterThanOrEqualTo(0.95));
    });

    test('detects Chinese script accurately', () async {
      final res = await detector.detectLanguage('你好，非常感谢你的帮助。');
      expect(res.language, equals('zh'));
      expect(res.confidence, greaterThanOrEqualTo(0.95));
    });

    test('detects Arabic script accurately', () async {
      final res = await detector.detectLanguage('مرحبا، شكرا جزيلا لك.');
      expect(res.language, equals('ar'));
      expect(res.confidence, greaterThanOrEqualTo(0.95));
    });

    test('detects Hindi script accurately', () async {
      final res = await detector.detectLanguage('नमस्ते, आप कैसे हैं?');
      expect(res.language, equals('hi'));
      expect(res.confidence, greaterThanOrEqualTo(0.95));
    });

    test('detects Russian script accurately', () async {
      final res =
          await detector.detectLanguage('Здравствуйте, спасибо большое.');
      expect(res.language, equals('ru'));
      expect(res.confidence, greaterThanOrEqualTo(0.95));
    });

    test('handles empty and whitespace string gracefully', () async {
      final res = await detector.detectLanguage('   ');
      expect(res.language, equals('en'));
      expect(res.confidence, equals(0.5));
    });
  });
}
