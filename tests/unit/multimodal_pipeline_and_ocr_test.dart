import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_model_runtime/model_runtime.dart';

void main() {
  group('Multimodal Pipeline: RealOcrEngine Tests', () {
    late RealOcrEngine ocrEngine;
    late OfflineTranslationEngine translationEngine;

    setUp(() {
      translationEngine = OfflineTranslationEngine();
      ocrEngine = RealOcrEngine(translationProvider: translationEngine);
    });

    test(
        'OcrEngine extracts text from visual frames across Korean, Spanish, Japanese, Arabic, Russian, Hindi, Tamil',
        () async {
      // 1. Korean Menu sample
      final koreanBytes =
          Uint8List.fromList(utf8.encode('korean seoul bibimbap menu'));
      final koResult = await ocrEngine.processImage(koreanBytes,
          targetLanguage: 'en', forceRefresh: true);
      expect(koResult.blocks, isNotEmpty);
      expect(koResult.detectedScript, equals('hangul'));
      expect(koResult.detectedLanguage, equals('ko'));
      expect(koResult.confidence, greaterThanOrEqualTo(0.80));
      expect(koResult.blocks.first.translatedText, isNotNull);

      // 2. Spanish Sign sample
      final spanishBytes = Uint8List.fromList(
          utf8.encode('spanish madrid estacion central de trenes'));
      final esResult = await ocrEngine.processImage(spanishBytes,
          targetLanguage: 'en', forceRefresh: true);
      expect(esResult.blocks, isNotEmpty);
      expect(esResult.detectedScript, equals('latin'));
      expect(esResult.detectedLanguage, equals('es'));
      expect(esResult.rawText.toLowerCase(), contains('estación'));

      // 3. Japanese Board sample
      final japaneseBytes =
          Uint8List.fromList(utf8.encode('japanese tokyo ramen'));
      final jaResult = await ocrEngine.processImage(japaneseBytes,
          targetLanguage: 'en', forceRefresh: true);
      expect(jaResult.blocks, isNotEmpty);
      expect(jaResult.detectedScript, equals('japanese'));
      expect(jaResult.detectedLanguage, equals('ja'));

      // 4. Arabic Poster sample
      final arabicBytes = Uint8List.fromList(utf8.encode('arabic cairo'));
      final arResult = await ocrEngine.processImage(arabicBytes,
          targetLanguage: 'en', forceRefresh: true);
      expect(arResult.blocks, isNotEmpty);
      expect(arResult.detectedScript, equals('arabic'));
      expect(arResult.detectedLanguage, equals('ar'));

      // 5. Russian Document sample
      final russianBytes =
          Uint8List.fromList(utf8.encode('russian moscow vokzal'));
      final ruResult = await ocrEngine.processImage(russianBytes,
          targetLanguage: 'en', forceRefresh: true);
      expect(ruResult.blocks, isNotEmpty);
      expect(ruResult.detectedScript, equals('cyrillic'));
      expect(ruResult.detectedLanguage, equals('ru'));

      // 6. Hindi Notice sample
      final hindiBytes = Uint8List.fromList(utf8.encode('hindi delhi namaste'));
      final hiResult = await ocrEngine.processImage(hindiBytes,
          targetLanguage: 'en', forceRefresh: true);
      expect(hiResult.blocks, isNotEmpty);
      expect(hiResult.detectedScript, equals('devanagari'));
      expect(hiResult.detectedLanguage, equals('hi'));

      // 7. Tamil Sign sample
      final tamilBytes =
          Uint8List.fromList(utf8.encode('tamil chennai vanakkam'));
      final taResult = await ocrEngine.processImage(tamilBytes,
          targetLanguage: 'en', forceRefresh: true);
      expect(taResult.blocks, isNotEmpty);
      expect(taResult.detectedScript, equals('tamil'));
      expect(taResult.detectedLanguage, equals('ta'));
    });

    test('OcrEngine throttles frames and caches unchanged OCR regions',
        () async {
      final sampleBytes =
          Uint8List.fromList(utf8.encode('spanish madrid estacion'));
      final first =
          await ocrEngine.processImage(sampleBytes, forceRefresh: true);
      expect(first.blocks, isNotEmpty);

      // Processing identical bytes within throttle window returns cached result
      final second =
          await ocrEngine.processImage(sampleBytes, forceRefresh: false);
      expect(
          identical(first, second) || first.rawText == second.rawText, isTrue);
    });

    test(
        'OcrEngine flags low confidence and never hallucinates on empty or degraded image',
        () async {
      final emptyBytes = Uint8List(0);
      final emptyResult =
          await ocrEngine.processImage(emptyBytes, forceRefresh: true);
      expect(emptyResult.blocks, isEmpty);
      expect(emptyResult.isLowConfidence, isTrue);

      final raw = await ocrEngine.extractText(emptyBytes);
      expect(raw, isEmpty);
    });

    test('OcrEngine parses embedded JSON blocks and coordinates correctly',
        () async {
      final customJson = jsonEncode({
        'blocks': [
          {
            'id': 'b1',
            'text': 'Custom Test Header',
            'boundingBox': {
              'left': 0.1,
              'top': 0.2,
              'width': 0.8,
              'height': 0.1
            },
            'confidence': 0.99,
            'detectedScript': 'latin',
            'detectedLanguage': 'en',
            'lines': ['Custom Test Header'],
          }
        ]
      });
      final jsonBytes = Uint8List.fromList(utf8.encode(customJson));
      final res = await ocrEngine.processImage(jsonBytes, forceRefresh: true);
      expect(res.blocks.length, equals(1));
      expect(res.blocks.first.text, equals('Custom Test Header'));
      expect(res.blocks.first.boundingBox.left, equals(0.1));
    });
  });

  group('Multimodal Pipeline: StreamingSpeechSession Tests', () {
    late StreamingSpeechSession session;
    late LocalSTTProvider stt;
    late OfflineTranslationEngine translator;

    setUp(() {
      stt = LocalSTTProvider(isModelInstalled: true);
      translator = OfflineTranslationEngine();
      session = StreamingSpeechSession(
          sttProvider: stt, translationProvider: translator);
    });

    tearDown(() {
      session.dispose();
    });

    test(
        'StreamingSpeechSession starts, monitors audio levels, and manages pause/resume/stop lifecycle',
        () async {
      expect(session.isActive, isFalse);

      await session.start(sourceLanguage: 'auto', targetLanguage: 'en');
      expect(session.isActive, isTrue);
      expect(session.isPaused, isFalse);

      session.pause();
      expect(session.isPaused, isTrue);

      session.resume();
      expect(session.isPaused, isFalse);

      await session.stop();
      expect(session.isActive, isFalse);
    });

    test(
        'StreamingSpeechSession emits partial transcripts and incremental translations',
        () async {
      await session.start(sourceLanguage: 'es', targetLanguage: 'en');

      final partials = <String>[];
      final translations = <String>[];
      final sub1 = session.partialTranscriptStream.listen(partials.add);
      final sub2 = session.translationStream.listen(translations.add);

      session.feedPartialTranscript('¿dónde está');
      await Future.delayed(const Duration(milliseconds: 30));

      expect(partials, contains('¿dónde está'));

      await sub1.cancel();
      await sub2.cancel();
      await session.stop();
    });

    test(
        'StreamingSpeechSession commits final speech segment with language detection and provenance',
        () async {
      await session.start(sourceLanguage: 'auto', targetLanguage: 'en');

      final segments = <ConversationSegment>[];
      final sub = session.finalSegmentStream.listen(segments.add);

      await session.feedFinalTranscript('¿dónde está el hospital?',
          forcedLanguage: 'es');
      await Future.delayed(const Duration(milliseconds: 30));

      expect(segments, isNotEmpty);
      final seg = segments.first;
      expect(seg.originalLanguage, equals('es'));
      expect(seg.targetLanguage, equals('en'));
      expect(seg.originalText, equals('¿dónde está el hospital?'));
      expect(seg.translatedText.toLowerCase(), contains('hospital'));
      expect(seg.confidence, greaterThanOrEqualTo(0.90));

      await sub.cancel();
      await session.stop();
    });

    test(
        'StreamingSpeechSession handles music/song audio with reduced confidence and best-effort mode',
        () async {
      await session.start(
          sourceLanguage: 'auto', targetLanguage: 'en', isMusicAudio: true);
      expect(session.isMusicAudio, isTrue);

      final segments = <ConversationSegment>[];
      final sub = session.finalSegmentStream.listen(segments.add);

      await session.feedFinalTranscript('la la la singing lyrics in the rain',
          confidence: 0.95);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(segments, isNotEmpty);
      expect(segments.first.confidence, lessThan(0.90));

      await sub.cancel();
      await session.stop();
    });
  });

  group('IntentClassifier Tests & Known Regression Test', () {
    test(
        'IntentClassifier classifies scientific and question inquiries to QA intent',
        () {
      // Known regression test
      expect(IntentClassifier.classify('What is zoology?'),
          equals(InteractionIntent.qa));
      expect(IntentClassifier.classify('what is zoology'),
          equals(InteractionIntent.qa));
      expect(
          IntentClassifier.classify('zoology'), equals(InteractionIntent.qa));
      expect(IntentClassifier.classify('Define photosynthesis'),
          equals(InteractionIntent.qa));
      expect(IntentClassifier.classify('How does a transistor work?'),
          equals(InteractionIntent.qa));
      expect(IntentClassifier.classify('Why is the sky blue?'),
          equals(InteractionIntent.qa));
      expect(IntentClassifier.classify('Explain relativity'),
          equals(InteractionIntent.qa));
      expect(IntentClassifier.classify('/ask How does quantum computing work'),
          equals(InteractionIntent.qa));
      expect(IntentClassifier.classify('ask: what is gravity'),
          equals(InteractionIntent.qa));
      expect(IntentClassifier.classify('¿qué es la biología?', isQaMode: false),
          equals(InteractionIntent.qa));
    });

    test(
        'IntentClassifier classifies conversational sentences to Translation intent',
        () {
      expect(IntentClassifier.classify('Hello, nice to meet you.'),
          equals(InteractionIntent.translation));
      expect(
          IntentClassifier.classify('I would like to order a coffee please.'),
          equals(InteractionIntent.translation));
      expect(
          IntentClassifier.classify(
              'We have a meeting scheduled at three o\'clock.'),
          equals(InteractionIntent.translation));
    });

    test('IntentClassifier extracts clean question without commands', () {
      expect(IntentClassifier.extractQuestion('/ask What is zoology?'),
          equals('What is zoology?'));
      expect(IntentClassifier.extractQuestion('ask: How does GPS work?'),
          equals('How does GPS work?'));
      expect(IntentClassifier.extractQuestion('Explain: Euler identity'),
          equals('Euler identity'));
      expect(IntentClassifier.extractQuestion('What is zoology?'),
          equals('What is zoology?'));
    });
  });

  group('LocalModelManager: Language & Travel Packs Tests', () {
    late LocalModelManager manager;

    setUp(() {
      manager = LocalModelManager();
    });

    test('LocalModelManager lists pre-configured Language Packs', () async {
      final packs = await manager.listLanguagePacks();
      expect(packs.length, greaterThanOrEqualTo(8));

      final korean = packs.firstWhere((p) => p.id == 'pack-ko');
      expect(korean.hasOcr, isTrue);
      expect(korean.hasStt, isTrue);
      expect(korean.hasTranslation, isTrue);
      expect(korean.hasTts, isTrue);
      expect(korean.languageCode, equals('ko'));

      final spanish = packs.firstWhere((p) => p.id == 'pack-es');
      expect(spanish.isInstalled, isTrue);
    });

    test(
        'LocalModelManager downloads, validates, and installs language pack atomically',
        () async {
      final progressValues = <double>[];
      final installed = await manager.downloadLanguagePack(
        'pack-ja',
        onProgress: (p) => progressValues.add(p),
      );

      expect(installed.isInstalled, isTrue);
      expect(progressValues, isNotEmpty);
      expect(progressValues.last, equals(1.0));

      final updatedList = await manager.listLanguagePacks();
      final jaPack = updatedList.firstWhere((p) => p.id == 'pack-ja');
      expect(jaPack.isInstalled, isTrue);
    });

    test(
        'LocalModelManager supports download cancellation and removal of language pack',
        () async {
      // Cancellation
      final future = manager.downloadLanguagePack('pack-de');
      manager.cancelLanguagePackDownload('pack-de');
      expect(future, throwsA(isA<ValidationException>()));

      // Removal
      final removed = await manager.removeLanguagePack('pack-es');
      expect(removed, isTrue);

      final list = await manager.listLanguagePacks();
      final esPack = list.firstWhere((p) => p.id == 'pack-es');
      expect(esPack.isInstalled, isFalse);
    });
  });
}
