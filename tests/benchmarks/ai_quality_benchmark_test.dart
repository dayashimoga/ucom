import 'dart:io';
import 'package:test/test.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_contracts/contracts.dart';

void main() {
  group('AI Quality Benchmarking Suite (Tamil, Hindi, Japanese, Spanish)', () {
    late OfflineLanguageDetector detector;
    late OfflineTranslationEngine translator;
    late ExplanationEngine explanationEngine;
    late OfflineAudioSynthesizer synthesizer;

    setUp(() {
      detector = OfflineLanguageDetector();
      translator = OfflineTranslationEngine(detector);
      explanationEngine = ExplanationEngine();
      synthesizer = OfflineAudioSynthesizer();
    });

    test('Benchmark: Language Detection Accuracy across target scripts', () async {
      final dataset = [
        // Tamil
        {'text': 'வணக்கம் நண்பா, எப்படி இருக்கிறீர்கள்?', 'expected': 'ta'},
        {'text': 'இன்று முக்கியமான கூட்டம் உள்ளது', 'expected': 'ta'},
        {'text': 'நன்றி', 'expected': 'ta'},
        // Hindi
        {'text': 'नमस्ते, आप कैसे हैं?', 'expected': 'hi'},
        {'text': 'आज की बैठक बहुत महत्वपूर्ण है', 'expected': 'hi'},
        {'text': 'धन्यवाद', 'expected': 'hi'},
        // Japanese
        {'text': 'こんにちは、お元気ですか？', 'expected': 'ja'},
        {'text': 'システムアーキテクチャのレビューを行います', 'expected': 'ja'},
        {'text': 'ありがとう', 'expected': 'ja'},
        // Spanish
        {'text': 'Hola, ¿cómo estás hoy?', 'expected': 'es'},
        {'text': 'Esta es una reunión muy importante para el equipo', 'expected': 'es'},
        {'text': 'muchas gracias por tu ayuda', 'expected': 'es'},
        // English
        {'text': 'Hello team, welcome to the engineering review', 'expected': 'en'},
        {'text': 'What is the action item from today?', 'expected': 'en'},
      ];

      int correct = 0;
      final stopwatch = Stopwatch()..start();

      for (final sample in dataset) {
        final result = await detector.detectLanguage(sample['text']!);
        if (result.language == sample['expected']) {
          correct++;
        }
      }

      stopwatch.stop();
      final accuracy = (correct / dataset.length) * 100.0;
      final avgLatencyMs = stopwatch.elapsedMilliseconds / dataset.length;

      // Log results
      stdout.writeln('--- LANGUAGE DETECTION BENCHMARK ---');
      stdout.writeln('Total Samples: ${dataset.length}');
      stdout.writeln('Accuracy: ${accuracy.toStringAsFixed(1)}% ($correct/${dataset.length})');
      stdout.writeln('Avg Detection Latency: ${avgLatencyMs.toStringAsFixed(2)} ms');

      expect(accuracy, greaterThanOrEqualTo(90.0));
      expect(avgLatencyMs, lessThan(20.0));
    });

    test('Benchmark: Translation Quality and Meaning Preservation across pairs', () async {
      final testCases = [
        // Tamil <-> English
        {'source': 'en', 'target': 'ta', 'input': 'hello', 'expected': 'வணக்கம்'},
        {'source': 'ta', 'target': 'en', 'input': 'வணக்கம்', 'expected': 'hello'},
        {'source': 'en', 'target': 'ta', 'input': 'thank you', 'expected': 'நன்றி'},
        {'source': 'ta', 'target': 'en', 'input': 'நன்றி', 'expected': 'thank you'},
        {'source': 'en', 'target': 'ta', 'input': 'action item', 'expected': 'நடவடிக்கை உருப்படி'},
        {'source': 'en', 'target': 'ta', 'input': 'system architecture', 'expected': 'கணினி கட்டமைப்பு'},

        // Hindi <-> English
        {'source': 'en', 'target': 'hi', 'input': 'hello', 'expected': 'नमस्ते'},
        {'source': 'hi', 'target': 'en', 'input': 'नमस्ते', 'expected': 'hello'},
        {'source': 'en', 'target': 'hi', 'input': 'thank you', 'expected': 'धन्यवाद'},
        {'source': 'hi', 'target': 'en', 'input': 'धन्यवाद', 'expected': 'thank you'},
        {'source': 'en', 'target': 'hi', 'input': 'system architecture', 'expected': 'सिस्टम वास्तुकला'},

        // Japanese <-> English
        {'source': 'en', 'target': 'ja', 'input': 'hello', 'expected': 'こんにちは'},
        {'source': 'ja', 'target': 'en', 'input': 'こんにちは', 'expected': 'hello'},
        {'source': 'en', 'target': 'ja', 'input': 'thank you', 'expected': 'ありがとう'},
        {'source': 'ja', 'target': 'en', 'input': 'ありがとう', 'expected': 'thank you'},
        {'source': 'en', 'target': 'ja', 'input': 'system architecture', 'expected': 'システムアーキテクチャ'},

        // Spanish <-> English
        {'source': 'en', 'target': 'es', 'input': 'hello', 'expected': 'hola'},
        {'source': 'es', 'target': 'en', 'input': 'hola', 'expected': 'hello'},
        {'source': 'en', 'target': 'es', 'input': 'thank you', 'expected': 'gracias'},
        {'source': 'es', 'target': 'en', 'input': 'gracias', 'expected': 'thank you'},
        {'source': 'en', 'target': 'es', 'input': 'system architecture', 'expected': 'arquitectura del sistema'},
      ];

      int passed = 0;
      final latencies = <int>[];

      stdout.writeln('\n--- TRANSLATION QUALITY BENCHMARK ---');

      for (final tc in testCases) {
        final sw = Stopwatch()..start();
        final res = await translator.translate(
          tc['input']!,
          options: TranslationOptions(
            sourceLanguage: tc['source'],
            targetLanguage: tc['target']!,
          ),
        );
        sw.stop();
        latencies.add(sw.elapsedMilliseconds);

        final matches = res.translatedText.toLowerCase().trim() == tc['expected']!.toLowerCase().trim();
        if (matches) passed++;

        stdout.writeln(
          '[${tc['source']}->${tc['target']}] "${tc['input']}" -> "${res.translatedText}" (${sw.elapsedMicroseconds}µs) [${matches ? 'PASS' : 'FAIL'}]',
        );
      }

      final exactMatchRate = (passed / testCases.length) * 100.0;
      final avgLatencyMs = latencies.reduce((a, b) => a + b) / latencies.length;

      stdout.writeln('Exact Match Quality: ${exactMatchRate.toStringAsFixed(1)}% ($passed/${testCases.length})');
      stdout.writeln('Avg Translation Latency: ${avgLatencyMs.toStringAsFixed(2)} ms');

      expect(exactMatchRate, greaterThanOrEqualTo(95.0));
      expect(avgLatencyMs, lessThan(30.0));
    });

    test('Benchmark: TTS Latency and Audio PCM Synthesis', () async {
      final utterances = [
        'Hello and welcome to UNICOM AI.',
        'This is a fast, offline text to speech engine test.',
        'Zero network leakage guaranteed.',
      ];

      stdout.writeln('\n--- TTS SYNTHESIS BENCHMARK ---');
      for (final text in utterances) {
        final sw = Stopwatch()..start();
        final result = await synthesizer.synthesize(
          text,
          options: const SynthesisOptions(language: 'en'),
        );
        sw.stop();
        final audioBytes = result.audioBytes;

        final sampleRate = 22050;
        final channels = 1;
        final bytesPerSample = 2; // 16-bit PCM
        final headerSize = 44;
        final dataBytes = audioBytes.length - headerSize;
        final durationSeconds = dataBytes / (sampleRate * channels * bytesPerSample);
        final realTimeFactor = (sw.elapsedMilliseconds / 1000.0) / durationSeconds;

        stdout.writeln(
          'Text: "$text" -> Audio: ${audioBytes.length} bytes, Duration: ${durationSeconds.toStringAsFixed(2)}s, Latency: ${sw.elapsedMilliseconds}ms, RTF: ${realTimeFactor.toStringAsFixed(3)}x',
        );

        expect(audioBytes.length, greaterThan(headerSize));
        expect(realTimeFactor, lessThan(0.5)); // Faster than real-time
      }
    });

    test('Benchmark: End-to-End Multilingual Pipeline Latency', () async {
      final input = 'system architecture';
      final sw = Stopwatch()..start();

      // 1. Detect
      final detection = await detector.detectLanguage(input);

      // 2. Translate to Tamil
      final translation = await translator.translate(
        input,
        options: TranslationOptions(
          sourceLanguage: detection.language,
          targetLanguage: 'ta',
        ),
      );

      // 3. Explain across personas
      final explanations = await explanationEngine.generateExplanations(
        input,
        translatedText: translation.translatedText,
        sourceLanguage: detection.language,
        targetLanguage: 'ta',
      );

      // 4. Synthesize Audio
      final synthResult = await synthesizer.synthesize(
        translation.translatedText,
        options: const SynthesisOptions(language: 'ta'),
      );
      final speechBytes = synthResult.audioBytes;

      sw.stop();

      stdout.writeln('\n--- END-TO-END PIPELINE BENCHMARK ---');
      stdout.writeln('Total Pipeline Time: ${sw.elapsedMilliseconds} ms');
      stdout.writeln('Detected Language: ${detection.language}');
      stdout.writeln('Translated Text: ${translation.translatedText}');
      stdout.writeln('Explanations Generated: ${explanations.explanations.length} personas');
      stdout.writeln('Synthesized Audio: ${speechBytes.length} bytes');

      // The entire offline pipeline must execute under 250ms on local CPU
      expect(sw.elapsedMilliseconds, lessThan(250));
      expect(translation.translatedText, equals('கணினி கட்டமைப்பு'));
      expect(explanations.explanations.length, equals(7));
      expect(speechBytes.length, greaterThan(44));
    });
  });
}
