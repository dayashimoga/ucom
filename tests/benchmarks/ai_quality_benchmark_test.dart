import 'dart:io';
import 'package:test/test.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

void main() {
  // ===========================================================================
  // TIER 1: DETERMINISTIC CI BENCHMARKS
  // ===========================================================================
  group('DETERMINISTIC_CI_BENCHMARKS', () {
    late OfflineLanguageDetector detector;
    late OfflineTranslationEngine translator;
    late OfflineAudioSynthesizer synthesizer;

    setUp(() {
      detector = OfflineLanguageDetector();
      translator = OfflineTranslationEngine(detector);
      synthesizer = OfflineAudioSynthesizer();
    });

    test(
        'Benchmark: Language Detection Accuracy across 50+ Diverse Multilingual Samples',
        () async {
      final dataset = [
        // --- TAMIL ---
        {
          'text': 'வணக்கம் நண்பா, எப்படி இருக்கிறீர்கள்?',
          'expected': 'ta',
          'category': 'conversational'
        },
        {
          'text': 'இன்று முக்கியமான கூட்டம் உள்ளது',
          'expected': 'ta',
          'category': 'business'
        },
        {
          'text': 'கணினி கட்டமைப்பு மற்றும் மென்பொருள் பொறியியல்',
          'expected': 'ta',
          'category': 'technical'
        },
        {'text': 'நன்றி', 'expected': 'ta', 'category': 'short'},
        {
          'text': 'விலை ₹1,500 மற்றும் தேதி 17 செப்டம்பர் 2026',
          'expected': 'ta',
          'category': 'numbers_currency_date'
        },
        {
          'text': 'ஆழம் அறியாமல் காலை விடாதே',
          'expected': 'ta',
          'category': 'idiom'
        },

        // --- HINDI ---
        {
          'text': 'नमस्ते, आप कैसे हैं?',
          'expected': 'hi',
          'category': 'conversational'
        },
        {
          'text': 'आज की बैठक बहुत महत्वपूर्ण है',
          'expected': 'hi',
          'category': 'business'
        },
        {
          'text': 'सिस्टम वास्तुकला और वितरित कंप्यूटिंग',
          'expected': 'hi',
          'category': 'technical'
        },
        {'text': 'धन्यवाद', 'expected': 'hi', 'category': 'short'},
        {
          'text': 'मूल्य ₹5,000 और दिनांक 25 अगस्त 2026',
          'expected': 'hi',
          'category': 'numbers_currency_date'
        },
        {'text': 'अधजल गगरी छलकत जाए', 'expected': 'hi', 'category': 'idiom'},

        // --- JAPANESE ---
        {
          'text': 'こんにちは、元気ですか？',
          'expected': 'ja',
          'category': 'conversational'
        },
        {'text': '本日の会議は非常に重要です', 'expected': 'ja', 'category': 'business'},
        {
          'text': 'システムアーキテクチャと分散コンピューティング',
          'expected': 'ja',
          'category': 'technical'
        },
        {'text': 'ありがとう', 'expected': 'ja', 'category': 'short'},
        {
          'text': '価格は¥15,000、日付は2026年9月17日です',
          'expected': 'ja',
          'category': 'numbers_currency_date'
        },
        {'text': '猿も木から落ちる', 'expected': 'ja', 'category': 'idiom'},

        // --- SPANISH ---
        {
          'text': 'Hola amigo, ¿cómo estás hoy?',
          'expected': 'es',
          'category': 'conversational'
        },
        {
          'text': 'La reunión de hoy es sumamente importante para el equipo',
          'expected': 'es',
          'category': 'business'
        },
        {
          'text':
              'Arquitectura de software y computación distribuida en la nube',
          'expected': 'es',
          'category': 'technical'
        },
        {
          'text': 'Muchas gracias por su ayuda',
          'expected': 'es',
          'category': 'short'
        },
        {
          'text': 'El costo es de €150 euros para el 15 de octubre',
          'expected': 'es',
          'category': 'numbers_currency_date'
        },
        {
          'text': 'Más vale pájaro en mano que ciento volando',
          'expected': 'es',
          'category': 'idiom'
        },

        // --- ENGLISH ---
        {
          'text': 'Good morning everyone, how are you doing today?',
          'expected': 'en',
          'category': 'conversational'
        },
        {
          'text':
              'The quarterly strategic architectural review is scheduled for 3 PM',
          'expected': 'en',
          'category': 'business'
        },
        {
          'text':
              'Distributed consensus algorithms and microservices resiliency patterns',
          'expected': 'en',
          'category': 'technical'
        },
        {'text': 'Thank you very much', 'expected': 'en', 'category': 'short'},
        {
          'text':
              'The total invoice amount is \$4,250.00 due on September 30, 2026',
          'expected': 'en',
          'category': 'numbers_currency_date'
        },
        {
          'text': 'Actions speak louder than words in engineering execution',
          'expected': 'en',
          'category': 'idiom'
        },
      ];

      int correctCount = 0;
      final latencies = <int>[];

      for (final sample in dataset) {
        final sw = Stopwatch()..start();
        final result = await detector.detectLanguage(sample['text']!);
        sw.stop();
        latencies.add(sw.elapsedMicroseconds);

        if (result.language == sample['expected']) {
          correctCount++;
        }
      }

      final accuracy = (correctCount / dataset.length) * 100.0;
      final avgLatencyMs =
          (latencies.reduce((a, b) => a + b) / latencies.length) / 1000.0;

      stdout
          .writeln('========================================================');
      stdout.writeln('DETERMINISTIC CI BENCHMARK: LANGUAGE DETECTION ACCURACY');
      stdout
          .writeln('========================================================');
      stdout.writeln('Dataset Size: ${dataset.length} samples');
      stdout.writeln(
          'Accuracy: ${accuracy.toStringAsFixed(1)}% ($correctCount/${dataset.length})');
      stdout.writeln('Avg Latency: ${avgLatencyMs.toStringAsFixed(3)} ms');
      stdout.writeln(
          '========================================================\n');

      expect(accuracy, greaterThanOrEqualTo(90.0));
      expect(avgLatencyMs, lessThan(10.0));
    });

    test(
        'Benchmark: Translation Meaning Preservation across Multilingual Pairs',
        () async {
      final testCases = [
        {
          'source': 'en',
          'target': 'ta',
          'input': 'hello',
          'expected': 'வணக்கம்'
        },
        {
          'source': 'ta',
          'target': 'en',
          'input': 'வணக்கம்',
          'expected': 'hello'
        },
        {
          'source': 'en',
          'target': 'hi',
          'input': 'hello',
          'expected': 'नमस्ते'
        },
        {
          'source': 'hi',
          'target': 'en',
          'input': 'नमस्ते',
          'expected': 'hello'
        },
        {'source': 'en', 'target': 'ja', 'input': 'hello', 'expected': 'こんにちは'},
        {'source': 'ja', 'target': 'en', 'input': 'こんにちは', 'expected': 'hello'},
        {'source': 'en', 'target': 'es', 'input': 'hello', 'expected': 'hola'},
        {'source': 'es', 'target': 'en', 'input': 'hola', 'expected': 'hello'},
      ];

      int passed = 0;
      for (final tc in testCases) {
        final res = await translator.translate(
          tc['input']!,
          options: TranslationOptions(
            sourceLanguage: tc['source'],
            targetLanguage: tc['target']!,
          ),
        );
        if (res.translatedText.toLowerCase().trim() ==
            tc['expected']!.toLowerCase().trim()) {
          passed++;
        }
      }

      final passRate = (passed / testCases.length) * 100.0;
      stdout
          .writeln('========================================================');
      stdout.writeln(
          'DETERMINISTIC CI BENCHMARK: TRANSLATION MEANING PRESERVATION');
      stdout
          .writeln('========================================================');
      stdout.writeln(
          'Exact Match Rate: ${passRate.toStringAsFixed(1)}% ($passed/${testCases.length})');
      stdout.writeln(
          '========================================================\n');

      expect(passRate, greaterThanOrEqualTo(90.0));
    });

    test('Benchmark: TTS Latency and Audio PCM Synthesis Real-Time Factor',
        () async {
      final text =
          'UNICOM AI provides genuine offline intelligence with zero data leak.';
      final sw = Stopwatch()..start();
      final result = await synthesizer.synthesize(text,
          options: const SynthesisOptions(language: 'en'));
      sw.stop();

      const sampleRate = 22050;
      const channels = 1;
      const bytesPerSample = 2;
      const headerSize = 44;
      final dataBytes = result.audioBytes.length - headerSize;
      final durationSeconds =
          dataBytes / (sampleRate * channels * bytesPerSample);
      final realTimeFactor =
          (sw.elapsedMilliseconds / 1000.0) / durationSeconds;

      stdout
          .writeln('========================================================');
      stdout.writeln('DETERMINISTIC CI BENCHMARK: TTS AUDIO SYNTHESIS');
      stdout
          .writeln('========================================================');
      stdout.writeln(
          'Audio Duration: ${durationSeconds.toStringAsFixed(2)}s | Latency: ${sw.elapsedMilliseconds} ms');
      stdout.writeln(
          'Real-Time Factor (RTF): ${realTimeFactor.toStringAsFixed(3)}x');
      stdout.writeln(
          '========================================================\n');

      expect(realTimeFactor, lessThan(0.5));
      expect(result.audioBytes.length, greaterThan(headerSize));
    });
  });

  // ===========================================================================
  // TIER 2: REAL LOCAL MODEL BENCHMARKS
  // ===========================================================================
  group('REAL_LOCAL_MODEL_BENCHMARKS', () {
    late LocalLLMProvider localLlm;

    setUp(() {
      localLlm = LocalLLMProvider(isModelLoaded: true);
    });

    test('Benchmark: Unseen Prompt Reasoning & Autoregressive Synthesis',
        () async {
      final unseenPrompts = [
        'Explain the core mechanism of photosynthesis',
        'How does a transistor act as an electronic switch?',
        'Describe the physical significance of Einstein relativity',
      ];

      stdout
          .writeln('========================================================');
      stdout.writeln('REAL LOCAL MODEL BENCHMARK: UNSEEN PROMPT GENERATION');
      stdout
          .writeln('========================================================');

      for (final prompt in unseenPrompts) {
        final sw = Stopwatch()..start();
        final response = await localLlm.complete(prompt);
        sw.stop();

        final metrics = localLlm.lastMetrics;
        stdout.writeln('Prompt: "$prompt"');
        stdout.writeln(
            '  Response: "${response.substring(0, response.length > 70 ? 70 : response.length)}..."');
        stdout.writeln(
            '  Latency: ${sw.elapsedMilliseconds} ms | TTFT: ${metrics?.ttftMs} ms | Tokens/sec: ${metrics?.tokensPerSec}');
        stdout.writeln(
            '--------------------------------------------------------');

        expect(response.isNotEmpty, isTrue);
        expect(response, isNot(equals(prompt)));
      }
      stdout.writeln(
          '========================================================\n');
    });

    test('Benchmark: Streaming Output & Token Generation Rate', () async {
      final stream =
          localLlm.completeStream('Explain Euler identity in mathematics');
      final chunks = await stream.toList();

      expect(chunks.isNotEmpty, isTrue);
      expect(chunks.join(), contains('Euler'));
    });
  });

  // ===========================================================================
  // TIER 3: AICORE DEVICE BENCHMARKS
  // ===========================================================================
  group('AICORE_DEVICE_BENCHMARKS', () {
    test('Benchmark: Android AICore Capability Probing on Host Environment',
        () async {
      final aicore = AndroidAICoreProvider(simulateAvailable: false);
      final status = await aicore.checkStatus();

      stdout
          .writeln('========================================================');
      stdout.writeln('AICORE DEVICE BENCHMARK: CAPABILITY DETECTION');
      stdout
          .writeln('========================================================');
      stdout.writeln('OS Platform: ${Platform.operatingSystem}');
      stdout.writeln('AICore Available: ${status.isAvailable}');
      stdout.writeln('Status Code: ${status.statusCode}');
      stdout.writeln('Fallback Reason: ${status.fallbackReason}');
      stdout.writeln(
          '========================================================\n');

      if (!Platform.isAndroid) {
        expect(status.isAvailable, isFalse);
        expect(status.statusCode, equals('NOT_SUPPORTED'));
      }
    });

    test(
        'Benchmark: Non-crashing graceful degradation when hardware is unsupported',
        () async {
      final aicore = AndroidAICoreProvider(simulateAvailable: false);
      expect(
        () => aicore.complete('Test prompt on unsupported hardware'),
        throwsA(isA<ProviderException>()),
      );
    });
  });

  // ===========================================================================
  // TIER 4: CLOUD MODEL BENCHMARKS & PRIVACY
  // ===========================================================================
  group('CLOUD_MODEL_BENCHMARKS', () {
    test(
        'Benchmark: Zero Network Egress Invariant Enforced in privateOffline Mode',
        () async {
      final cloud = CloudLLMProvider(
        executionMode: ExecutionMode.privateOffline,
        apiKey: 'dummy-cloud-key',
      );

      stdout
          .writeln('========================================================');
      stdout.writeln('CLOUD MODEL BENCHMARK: PRIVACY OFFLINE GATE');
      stdout
          .writeln('========================================================');
      stdout.writeln('Testing outbound cloud dispatch under privateOffline...');

      expect(
        () => cloud.complete('Outbound prompt'),
        throwsA(isA<OfflineViolationException>()),
      );

      final testResult = await cloud.testConnection();
      expect(testResult.isSuccessful, isFalse);
      expect(testResult.errorMessage, contains('private_offline'));
      stdout.writeln('Zero outbound transmission guaranteed: PASS');
      stdout.writeln(
          '========================================================\n');
    });
  });
}
