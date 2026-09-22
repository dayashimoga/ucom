import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';

void main() {
  group('Product Recovery & Bug Fix Regression Tests', () {
    late OfflineTranslationEngine translationEngine;
    late LocalLLMProvider localLLM;

    setUp(() {
      translationEngine = OfflineTranslationEngine();
      localLLM = LocalLLMProvider(isModelLoaded: true);
    });

    test('BUG-001 REGRESSION: "What is zoology?" EN->ES outputs authentic Spanish translation', () async {
      final res = await translationEngine.translate(
        'What is zoology?',
        options: const TranslationOptions(
          sourceLanguage: 'en',
          targetLanguage: 'es',
        ),
      );

      // Must be actual Spanish translation
      expect(res.translatedText, equals('¿Qué es la zoología?'));
      // Must NOT contain generic English answer text
      expect(res.translatedText.toLowerCase(), isNot(contains('branch of biology')));
      expect(res.translatedText.toLowerCase(), isNot(contains('study of animals')));
    });

    test('BUG-001 REGRESSION: "What is zoology?" EN->TA outputs authentic Tamil translation', () async {
      final res = await translationEngine.translate(
        'What is zoology?',
        options: const TranslationOptions(
          sourceLanguage: 'en',
          targetLanguage: 'ta',
        ),
      );

      expect(res.translatedText, equals('விலங்கியல் என்றால் என்ன?'));
    });

    test('BUG-001 REGRESSION: "What is zoology?" EN->HI outputs authentic Hindi translation', () async {
      final res = await translationEngine.translate(
        'What is zoology?',
        options: const TranslationOptions(
          sourceLanguage: 'en',
          targetLanguage: 'hi',
        ),
      );

      expect(res.translatedText, equals('जंतु विज्ञान क्या है?'));
    });

    test('Bilateral hero translations: "Where is the railway station?" and "Where is the nearest hospital?" in Tamil', () async {
      final stationRes = await translationEngine.translate(
        'Where is the railway station?',
        options: const TranslationOptions(
          sourceLanguage: 'en',
          targetLanguage: 'ta',
        ),
      );
      expect(stationRes.translatedText, equals('ரயில் நிலையம் எங்கே உள்ளது?'));

      final hospitalRes = await translationEngine.translate(
        'Where is the nearest hospital?',
        options: const TranslationOptions(
          sourceLanguage: 'en',
          targetLanguage: 'ta',
        ),
      );
      expect(hospitalRes.translatedText, equals('அருகிலுள்ள மருத்துவமனை எங்கே உள்ளது?'));
    });

    test('Q&A intent produces real scientific explanation, never confused with translation', () async {
      final answer = await localLLM.complete('What is zoology?');

      // AI Answer must be authentic zoology definition
      expect(answer.toLowerCase(), contains('branch of biology'));
      expect(answer.toLowerCase(), contains('animals'));

      // Verify domain segment models can record intent and AI badge
      final seg = ConversationSegment(
        id: 'seg_qa_test',
        speakerId: 'ai',
        speakerName: 'UniCom AI',
        startTime: DateTime.now().millisecondsSinceEpoch,
        originalText: answer,
        originalLanguage: 'en',
        translatedText: '',
        targetLanguage: 'es',
        intent: InteractionIntent.qa,
        isAiResponse: true,
        aiModelName: 'Local LLM INT4',
      );

      expect(seg.intent, equals(InteractionIntent.qa));
      expect(seg.isAiResponse, isTrue);
      expect(seg.aiModelName, equals('Local LLM INT4'));
      expect(seg.translatedText, isEmpty);
    });

    test('ConversationState enum includes required lifecycle states', () {
      expect(ConversationState.values, contains(ConversationState.listening));
      expect(ConversationState.values, contains(ConversationState.transcribing));
      expect(ConversationState.values, contains(ConversationState.processing));
      expect(ConversationState.values, contains(ConversationState.translating));
      expect(ConversationState.values, contains(ConversationState.speaking));
    });

    test('InteractionIntent enum serializes and deserializes correctly', () {
      for (final intent in InteractionIntent.values) {
        final json = intent.toJson();
        final parsed = InteractionIntent.fromJson(json);
        expect(parsed, equals(intent));
      }
    });
  });
}
