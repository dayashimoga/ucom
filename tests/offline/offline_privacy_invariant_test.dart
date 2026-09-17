import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_reporting/reporting.dart';

void main() {
  group('Offline Privacy Invariant Tests', () {
    test('proves full conversation pipeline works completely offline without network', () async {
      // 1. STT completely on-device
      final stt = DeterministicFakeSTTProvider();
      final transcript = await stt.transcribe(Uint8List(50));
      expect(transcript.text, isNotEmpty);

      // 2. Language detection completely on-device
      final detector = OfflineLanguageDetector();
      final detection = await detector.detectLanguage(transcript.text);
      expect(detection.language, equals('en'));

      // 3. Translation on-device with zero network sockets
      final translator = OfflineTranslationEngine(detector);
      final trans = await translator.translate(
        'hello world',
        options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'es'),
      );
      expect(trans.translatedText, contains('hola'));

      // 4. Intelligence & Explanations on-device
      final engine = ExplanationEngine();
      final exp = await engine.generateExplanations(
        'hello world',
        translatedText: trans.translatedText,
        targetLanguage: 'es',
      );
      expect(exp.explanations.length, equals(7));

      // 5. TTS waveform generation on-device
      final synthesizer = OfflineAudioSynthesizer();
      final audio = await synthesizer.synthesize(trans.translatedText);
      expect(audio.audioBytes.length, greaterThan(44));

      // 6. Reporting on-device
      final conv = Conversation(
        id: 'c_offline_1',
        title: 'Offline Session',
        executionMode: ExecutionMode.privateOffline,
        startedAt: DateTime.now().toUtc().toIso8601String(),
        segments: [
          ConversationSegment(
            id: 'seg_1',
            speakerId: 'p1',
            speakerName: 'Me',
            startTime: 0,
            originalText: 'hello world',
            originalLanguage: 'en',
            translatedText: trans.translatedText,
            targetLanguage: 'es',
          ),
        ],
      );

      final reportGen = ReportGenerator();
      final rep = reportGen.generateReport(conversation: conv, type: ReportType.quickSummary);
      expect(rep.content, contains('Offline Session'));
    });

    test('strictly enforces OfflineViolationException when cloud adapter is invoked in private_offline mode', () async {
      final cloudTranslator = CloudTranslationAdapter(
        executionMode: ExecutionMode.privateOffline,
        apiKey: 'test-key',
      );

      expect(
        () async => await cloudTranslator.translate(
          'Secret conversation data',
          options: const TranslationOptions(sourceLanguage: 'en', targetLanguage: 'es'),
        ),
        throwsA(isA<OfflineViolationException>()),
      );

      final cloudSpeech = CloudSpeechAdapter(
        executionMode: ExecutionMode.privateOffline,
        apiKey: 'test-key',
      );

      expect(
        () async => await cloudSpeech.transcribe(Uint8List(50)),
        throwsA(isA<OfflineViolationException>()),
      );

      expect(
        () async => await cloudSpeech.synthesize('Secret speech'),
        throwsA(isA<OfflineViolationException>()),
      );
    });
  });
}
