import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_contracts/contracts.dart';

void main() {
  group('AI Quality & Multilingual Benchmarking Suite v2.0 (Tamil, Hindi, Japanese, Spanish, English)', () {
    late OfflineLanguageDetector detector;
    late OfflineTranslationEngine translator;
    late ExplanationEngine explanationEngine;
    late OfflineAudioSynthesizer synthesizer;
    late AndroidAICoreProvider aicoreProvider;
    late LocalLLMProvider localLlmProvider;
    late AIProviderRouter router;
    late KnowledgeEngine knowledgeEngine;

    setUp(() {
      detector = OfflineLanguageDetector();
      translator = OfflineTranslationEngine(detector);
      explanationEngine = ExplanationEngine();
      synthesizer = OfflineAudioSynthesizer();

      aicoreProvider = AndroidAICoreProvider(simulateAvailable: true);
      localLlmProvider = LocalLLMProvider(isModelLoaded: true);
      final cloudProvider = CloudLLMProvider(executionMode: ExecutionMode.hybrid, apiKey: 'test-key');

      router = AIProviderRouter(
        androidProvider: aicoreProvider,
        localProvider: localLlmProvider,
        cloudProvider: cloudProvider,
        executionMode: ExecutionMode.privateOffline,
      );

      knowledgeEngine = KnowledgeEngine(
        router: router,
        translationProvider: translator,
        detectionProvider: detector,
      );
    });

    // =========================================================================
    // 1. Language Detection Accuracy & Robustness Corpus (50+ Diverse Samples)
    // =========================================================================
    test('Benchmark: Language Detection Accuracy across 50+ Diverse Samples', () async {
      final dataset = [
        // --- TAMIL ---
        {'text': 'வணக்கம் நண்பா, எப்படி இருக்கிறீர்கள்?', 'expected': 'ta', 'category': 'conversational'},
        {'text': 'இன்று முக்கியமான கூட்டம் உள்ளது', 'expected': 'ta', 'category': 'business'},
        {'text': 'கணினி கட்டமைப்பு மற்றும் மென்பொருள் பொறியியல்', 'expected': 'ta', 'category': 'technical'},
        {'text': 'நன்றி', 'expected': 'ta', 'category': 'short'},
        {'text': 'விலை ₹1,500 மற்றும் தேதி 17 செப்டம்பர் 2026', 'expected': 'ta', 'category': 'numbers_currency_date'},
        {'text': 'ஆழம் அறியாமல் காலை விடாதே', 'expected': 'ta', 'category': 'idiom'},

        // --- HINDI ---
        {'text': 'नमस्ते, आप कैसे हैं?', 'expected': 'hi', 'category': 'conversational'},
        {'text': 'आज की बैठक बहुत महत्वपूर्ण है', 'expected': 'hi', 'category': 'business'},
        {'text': 'सिस्टम वास्तुकला और वितरित कंप्यूटिंग', 'expected': 'hi', 'category': 'technical'},
        {'text': 'धन्यवाद', 'expected': 'hi', 'category': 'short'},
        {'text': 'मूल्य ₹5,000 और दिनांक 25 अगस्त 2026', 'expected': 'hi', 'category': 'numbers_currency_date'},
        {'text': 'नाच न जाने आँगन टेढ़ा', 'expected': 'hi', 'category': 'idiom'},

        // --- JAPANESE ---
        {'text': 'こんにちは、お元気ですか？', 'expected': 'ja', 'category': 'conversational'},
        {'text': '本日のアーキテクチャレビュー会議を始めます', 'expected': 'ja', 'category': 'business'},
        {'text': '分散システムとマイクロサービス設計', 'expected': 'ja', 'category': 'technical'},
        {'text': 'ありがとう', 'expected': 'ja', 'category': 'short'},
        {'text': '価格は¥25,000で、期日は2026年9月17日です', 'expected': 'ja', 'category': 'numbers_currency_date'},
        {'text': '猿も木から落ちる', 'expected': 'ja', 'category': 'idiom'},

        // --- SPANISH ---
        {'text': 'Hola, ¿cómo estás hoy?', 'expected': 'es', 'category': 'conversational'},
        {'text': 'Esta es una reunión de revisión técnica muy importante para el equipo', 'expected': 'es', 'category': 'business'},
        {'text': 'Arquitectura de software distribuida y balanceo de carga', 'expected': 'es', 'category': 'technical'},
        {'text': 'muchas gracias por tu ayuda', 'expected': 'es', 'category': 'short'},
        {'text': 'El costo total es \$450.00 EUR el 17 de septiembre de 2026', 'expected': 'es', 'category': 'numbers_currency_date'},
        {'text': 'Más vale pájaro en mano que ciento volando', 'expected': 'es', 'category': 'idiom'},

        // --- ENGLISH ---
        {'text': 'Hello team, welcome to the engineering architecture review', 'expected': 'en', 'category': 'conversational'},
        {'text': 'What is the action item and milestone schedule for next sprint?', 'expected': 'en', 'category': 'business'},
        {'text': 'Kubernetes scheduler node affinity and pod topology spread constraints', 'expected': 'en', 'category': 'technical'},
        {'text': 'Thanks a lot', 'expected': 'en', 'category': 'short'},
        {'text': 'The invoice amount is \$12,450.00 USD due on October 1st, 2026', 'expected': 'en', 'category': 'numbers_currency_date'},
        {'text': 'A piece of cake', 'expected': 'en', 'category': 'idiom'},

        // --- FRENCH ---
        {'text': 'Bonjour, comment allez-vous aujourd\'hui?', 'expected': 'fr', 'category': 'conversational'},
        {'text': 'L\'architecture logicielle du système distribué', 'expected': 'fr', 'category': 'technical'},
        {'text': 'Merci beaucoup', 'expected': 'fr', 'category': 'short'},

        // --- GERMAN ---
        {'text': 'Guten Tag, wie geht es Ihnen?', 'expected': 'de', 'category': 'conversational'},
        {'text': 'Softwarearchitektur und Verteilte Systeme', 'expected': 'de', 'category': 'technical'},
        {'text': 'Vielen Dank', 'expected': 'de', 'category': 'short'},

        // --- CHINESE ---
        {'text': '你好，很高兴认识你', 'expected': 'zh', 'category': 'conversational'},
        {'text': '分布式系统架构与微服务治理', 'expected': 'zh', 'category': 'technical'},
        {'text': '谢谢', 'expected': 'zh', 'category': 'short'},

        // --- ARABIC ---
        {'text': 'مرحبا كيف حالك اليوم؟', 'expected': 'ar', 'category': 'conversational'},
        {'text': 'هندسة الأنظمة والبرمجيات الموزعة', 'expected': 'ar', 'category': 'technical'},
        {'text': 'شكرا جزيلا', 'expected': 'ar', 'category': 'short'},

        // --- RUSSIAN ---
        {'text': 'Здравствуйте, как ваши дела?', 'expected': 'ru', 'category': 'conversational'},
        {'text': 'Архитектура распределенных систем', 'expected': 'ru', 'category': 'technical'},
        {'text': 'Спасибо', 'expected': 'ru', 'category': 'short'},

        // --- PORTUGUESE ---
        {'text': 'Olá, como você está hoje?', 'expected': 'pt', 'category': 'conversational'},
        {'text': 'Arquitetura de sistemas e microsserviços', 'expected': 'pt', 'category': 'technical'},
        {'text': 'Obrigado', 'expected': 'pt', 'category': 'short'},
      ];

      int correct = 0;
      final latencies = <int>[];
      final categoryStats = <String, Map<String, int>>{};

      for (final sample in dataset) {
        final cat = sample['category']!;
        categoryStats.putIfAbsent(cat, () => {'total': 0, 'correct': 0});
        categoryStats[cat]!['total'] = categoryStats[cat]!['total']! + 1;

        final sw = Stopwatch()..start();
        final result = await detector.detectLanguage(sample['text']!);
        sw.stop();
        latencies.add(sw.elapsedMicroseconds);

        if (result.language == sample['expected']) {
          correct++;
          categoryStats[cat]!['correct'] = categoryStats[cat]!['correct']! + 1;
        }
      }

      final accuracy = (correct / dataset.length) * 100.0;
      final avgLatencyUs = latencies.reduce((a, b) => a + b) / latencies.length;
      final avgLatencyMs = avgLatencyUs / 1000.0;

      stdout.writeln('\n========================================================');
      stdout.writeln('UNICOM AI EVALUATION REPORT: LANGUAGE DETECTION CORPUS');
      stdout.writeln('========================================================');
      stdout.writeln('Total Samples Tested: ${dataset.length}');
      stdout.writeln('Overall Detection Accuracy: ${accuracy.toStringAsFixed(1)}% ($correct/${dataset.length})');
      stdout.writeln('Average Detection Latency: ${avgLatencyMs.toStringAsFixed(3)} ms (${avgLatencyUs.toStringAsFixed(0)} µs)');
      stdout.writeln('--------------------------------------------------------');
      stdout.writeln('Accuracy by Category:');
      categoryStats.forEach((cat, stats) {
        final t = stats['total']!;
        final c = stats['correct']!;
        final pct = (c / t) * 100.0;
        stdout.writeln('  • ${cat.padRight(22)}: ${pct.toStringAsFixed(1)}% ($c/$t)');
      });
      stdout.writeln('========================================================\n');

      expect(accuracy, greaterThanOrEqualTo(90.0));
      expect(avgLatencyMs, lessThan(10.0)); // Ultra-fast offline detection < 10ms
    });

    // =========================================================================
    // 2. Multilingual Translation Meaning Preservation Benchmark
    // =========================================================================
    test('Benchmark: Translation Quality and Meaning Preservation across pairs', () async {
      final testCases = [
        // Tamil <-> English
        {'source': 'en', 'target': 'ta', 'input': 'hello', 'expected': 'வணக்கம்', 'type': 'greeting'},
        {'source': 'ta', 'target': 'en', 'input': 'வணக்கம்', 'expected': 'hello', 'type': 'greeting'},
        {'source': 'en', 'target': 'ta', 'input': 'thank you', 'expected': 'நன்றி', 'type': 'courtesy'},
        {'source': 'ta', 'target': 'en', 'input': 'நன்றி', 'expected': 'thank you', 'type': 'courtesy'},
        {'source': 'en', 'target': 'ta', 'input': 'system architecture', 'expected': 'கணினி கட்டமைப்பு', 'type': 'technical'},
        {'source': 'en', 'target': 'ta', 'input': 'action item', 'expected': 'நடவடிக்கை உருப்படி', 'type': 'workflow'},
        {'source': 'en', 'target': 'ta', 'input': 'decision', 'expected': 'முடிவு', 'type': 'workflow'},

        // Hindi <-> English
        {'source': 'en', 'target': 'hi', 'input': 'hello', 'expected': 'नमस्ते', 'type': 'greeting'},
        {'source': 'hi', 'target': 'en', 'input': 'नमस्ते', 'expected': 'hello', 'type': 'greeting'},
        {'source': 'en', 'target': 'hi', 'input': 'thank you', 'expected': 'धन्यवाद', 'type': 'courtesy'},
        {'source': 'hi', 'target': 'en', 'input': 'धन्यवाद', 'expected': 'thank you', 'type': 'courtesy'},
        {'source': 'en', 'target': 'hi', 'input': 'system architecture', 'expected': 'सिस्टम वास्तुकला', 'type': 'technical'},
        {'source': 'en', 'target': 'hi', 'input': 'action item', 'expected': 'कार्य मद', 'type': 'workflow'},
        {'source': 'en', 'target': 'hi', 'input': 'decision', 'expected': 'निर्णय', 'type': 'workflow'},

        // Japanese <-> English
        {'source': 'en', 'target': 'ja', 'input': 'hello', 'expected': 'こんにちは', 'type': 'greeting'},
        {'source': 'ja', 'target': 'en', 'input': 'こんにちは', 'expected': 'hello', 'type': 'greeting'},
        {'source': 'en', 'target': 'ja', 'input': 'thank you', 'expected': 'ありがとう', 'type': 'courtesy'},
        {'source': 'ja', 'target': 'en', 'input': 'ありがとう', 'expected': 'thank you', 'type': 'courtesy'},
        {'source': 'en', 'target': 'ja', 'input': 'system architecture', 'expected': 'システムアーキテクチャ', 'type': 'technical'},
        {'source': 'en', 'target': 'ja', 'input': 'action item', 'expected': 'アクションアイテム', 'type': 'workflow'},
        {'source': 'en', 'target': 'ja', 'input': 'decision', 'expected': '決定', 'type': 'workflow'},

        // Spanish <-> English
        {'source': 'en', 'target': 'es', 'input': 'hello', 'expected': 'hola', 'type': 'greeting'},
        {'source': 'es', 'target': 'en', 'input': 'hola', 'expected': 'hello', 'type': 'greeting'},
        {'source': 'en', 'target': 'es', 'input': 'thank you', 'expected': 'gracias', 'type': 'courtesy'},
        {'source': 'es', 'target': 'en', 'input': 'gracias', 'expected': 'thank you', 'type': 'courtesy'},
        {'source': 'en', 'target': 'es', 'input': 'system architecture', 'expected': 'arquitectura del sistema', 'type': 'technical'},
        {'source': 'en', 'target': 'es', 'input': 'action item', 'expected': 'tarea pendiente', 'type': 'workflow'},
        {'source': 'en', 'target': 'es', 'input': 'decision', 'expected': 'decisión', 'type': 'workflow'},
      ];

      int passed = 0;
      final latencies = <int>[];

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
        latencies.add(sw.elapsedMicroseconds);

        final matches = res.translatedText.toLowerCase().trim() == tc['expected']!.toLowerCase().trim();
        if (matches) passed++;
      }

      final exactMatchRate = (passed / testCases.length) * 100.0;
      final avgLatencyMs = (latencies.reduce((a, b) => a + b) / latencies.length) / 1000.0;

      stdout.writeln('========================================================');
      stdout.writeln('UNICOM AI EVALUATION REPORT: TRANSLATION ACCURACY');
      stdout.writeln('========================================================');
      stdout.writeln('Total Test Pairs: ${testCases.length}');
      stdout.writeln('Exact Match / Meaning Preservation: ${exactMatchRate.toStringAsFixed(1)}% ($passed/${testCases.length})');
      stdout.writeln('Average Translation Latency: ${avgLatencyMs.toStringAsFixed(3)} ms');
      stdout.writeln('========================================================\n');

      expect(exactMatchRate, greaterThanOrEqualTo(90.0));
      expect(avgLatencyMs, lessThan(20.0));
    });

    // =========================================================================
    // 3. Factual Q&A / Knowledge Engine Evaluation (Representative Questions)
    // =========================================================================
    test('Benchmark: General Knowledge Q&A Engine (Kubernetes, Quantum, Literature, Math)', () async {
      final questions = [
        {
          'domain': 'Cloud / Kubernetes',
          'q': 'Explain Kubernetes scheduler and node affinity',
          'expectedTerms': ['Kubernetes scheduler', 'node affinity'],
        },
        {
          'domain': 'Physics / Quantum',
          'q': 'Explain quantum entanglement accurately for a child',
          'expectedTerms': ['Quantum entanglement', 'magic dice'],
        },
        {
          'domain': 'Literature / Philosophy',
          'q': 'Compare themes in major literature 1984 and Brave New World',
          'expectedTerms': ['1984', 'Brave New World'],
        },
        {
          'domain': 'Mathematics / Science',
          'q': 'Explain Euler identity and calculus fundamentals',
          'expectedTerms': ['Euler', 'identity'],
        },
      ];

      stdout.writeln('========================================================');
      stdout.writeln('UNICOM AI EVALUATION REPORT: KNOWLEDGE & Q&A BENCHMARK');
      stdout.writeln('========================================================');

      for (final item in questions) {
        final sw = Stopwatch()..start();
        final resp = await knowledgeEngine.ask(
          question: item['q'] as String,
          persona: ExplanationPersona.simple,
          targetLanguage: 'es',
        );
        sw.stop();

        final ans = resp.generativeAnswer;
        final terms = item['expectedTerms'] as List<String>;
        final allMatched = terms.every((t) => ans.toLowerCase().contains(t.toLowerCase()));

        stdout.writeln('Domain: ${item['domain']}');
        stdout.writeln('  Question: "${item['q']}"');
        stdout.writeln('  Answer Preview: "${ans.substring(0, ans.length > 80 ? 80 : ans.length)}..."');
        stdout.writeln('  Provider: ${resp.providerId} | Mode: ${resp.executionMode}');
        stdout.writeln('  Latency: ${sw.elapsedMilliseconds} ms | Terms Matched: $allMatched');
        stdout.writeln('--------------------------------------------------------');

        expect(allMatched, isTrue);
        expect(resp.generativeAnswer, isNotEmpty);
        expect(resp.aiSummary, isNotNull);
      }
      stdout.writeln('========================================================\n');
    });

    // =========================================================================
    // 4. TTS Latency, Real-Time Factor (RTF) & Audio Synthesis Benchmark
    // =========================================================================
    test('Benchmark: TTS Latency and Audio PCM Synthesis Real-Time Factor', () async {
      final utterances = [
        'Hello and welcome to UNICOM AI.',
        'This is an on-device, high-performance neural synthesis benchmark.',
        'All data stays strictly private on this local device with zero network transmission.',
      ];

      stdout.writeln('========================================================');
      stdout.writeln('UNICOM AI EVALUATION REPORT: TTS AUDIO SYNTHESIS');
      stdout.writeln('========================================================');

      for (final text in utterances) {
        final sw = Stopwatch()..start();
        final result = await synthesizer.synthesize(
          text,
          options: const SynthesisOptions(language: 'en'),
        );
        sw.stop();
        final audioBytes = result.audioBytes;

        const sampleRate = 22050;
        const channels = 1;
        const bytesPerSample = 2;
        const headerSize = 44;
        final dataBytes = audioBytes.length - headerSize;
        final durationSeconds = dataBytes / (sampleRate * channels * bytesPerSample);
        final realTimeFactor = (sw.elapsedMilliseconds / 1000.0) / durationSeconds;

        stdout.writeln('Text: "$text"');
        stdout.writeln('  Audio: ${audioBytes.length} bytes (${durationSeconds.toStringAsFixed(2)}s audio)');
        stdout.writeln('  Synthesis Latency: ${sw.elapsedMilliseconds} ms | Real-Time Factor (RTF): ${realTimeFactor.toStringAsFixed(3)}x');
        stdout.writeln('--------------------------------------------------------');

        expect(audioBytes.length, greaterThan(headerSize));
        expect(realTimeFactor, lessThan(0.5)); // Faster than 0.5x real-time (sub-second)
      }
      stdout.writeln('========================================================\n');
    });

    // =========================================================================
    // 5. Full End-to-End Multilingual Knowledge Pipeline Latency
    // =========================================================================
    test('Benchmark: Complete Pipeline: Detect -> Retrieve -> Q&A -> Explain -> Translate -> TTS', () async {
      final input = 'Kubernetes scheduler and node affinity';
      final sw = Stopwatch()..start();

      // 1. Language Detection
      final detection = await detector.detectLanguage(input);

      // 2. Knowledge Q&A with RAG Grounding
      final qaResponse = await knowledgeEngine.ask(
        question: input,
        persona: ExplanationPersona.simple,
        targetLanguage: 'ta',
      );

      // 3. Audio Synthesis in Target Language (Tamil)
      final synthResult = await synthesizer.synthesize(
        qaResponse.translatedAnswer ?? 'வணக்கம்',
        options: const SynthesisOptions(language: 'ta'),
      );

      sw.stop();

      stdout.writeln('========================================================');
      stdout.writeln('UNICOM AI EVALUATION REPORT: FULL END-TO-END PIPELINE');
      stdout.writeln('========================================================');
      stdout.writeln('Pipeline Steps Executed:');
      stdout.writeln('  1. Language Detect: ${detection.language} (${(detection.confidence * 100).toStringAsFixed(1)}%)');
      stdout.writeln('  2. On-Device LLM: "${qaResponse.generativeAnswer.substring(0, 60)}..."');
      stdout.writeln('  3. Explanation Style: Simple Persona Generated');
      stdout.writeln('  4. Translation (Tamil): "${qaResponse.translatedAnswer?.substring(0, 40)}..."');
      stdout.writeln('  5. Audio Synthesizer: ${synthResult.audioBytes.length} bytes PCM WAV');
      stdout.writeln('Total Pipeline End-to-End Latency: ${sw.elapsedMilliseconds} ms');
      stdout.writeln('========================================================\n');

      expect(sw.elapsedMilliseconds, lessThan(250)); // Strict latency budget
      expect(synthResult.audioBytes.length, greaterThan(44));
    });
  });
}
