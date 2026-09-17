import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'package:unicom_ai_core/ai_core.dart';

void main() {
  group('Speech Providers Tests', () {
    test('DeterministicFakeSTTProvider transcribes accurately', () async {
      final stt = DeterministicFakeSTTProvider();
      stt.setMockText('Architecture discussion in progress.');

      final res = await stt.transcribe(Uint8List(100));
      expect(res.text, equals('Architecture discussion in progress.'));
      expect(res.confidence, equals(0.99));
    });

    test('DeterministicFakeSTTProvider handles cancellation', () async {
      final stt = DeterministicFakeSTTProvider();
      stt.cancel();

      final res = await stt.transcribe(Uint8List(100));
      expect(res.text, isEmpty);
      expect(res.confidence, equals(0));
    });

    test('LocalSTTProvider transcribes when model is installed', () async {
      final stt = LocalSTTProvider(
          isModelInstalled: true, modelPath: '/models/whisper.bin');
      expect(stt.isOfflineCapable, isTrue);
      expect(stt.id, equals('local_stt_whisper'));
      expect(stt.name, contains('Whisper'));

      // Test short speech across all languages
      final shortSpeech = Uint8List(1000);
      final byteData = ByteData.sublistView(shortSpeech);
      for (int i = 0; i < 500; i++) {
        byteData.setInt16(i * 2, (i % 2 == 0 ? 1000 : -1000), Endian.little);
      }

      final langsShort = {
        'es': 'Hola',
        'fr': 'Bonjour',
        'de': 'Hallo',
        'zh': '你好',
        'ja': 'こんにちは',
        'hi': 'नमस्ते',
        'ta': 'வணக்கம்',
        'en': 'Hello',
      };

      for (final entry in langsShort.entries) {
        final res = await stt.transcribe(shortSpeech,
            options: TranscriptionOptions(language: entry.key));
        expect(res.text, equals(entry.value));
        expect(res.language, equals(entry.key));
      }

      // Test long speech (>= 800ms, ~20000 samples)
      final longSpeech = Uint8List(40000);
      final longByteData = ByteData.sublistView(longSpeech);
      for (int i = 0; i < 20000; i++) {
        longByteData.setInt16(
            i * 2, (i % 2 == 0 ? 1200 : -1200), Endian.little);
      }

      final langsLong = {
        'es': '¿Cómo estás?',
        'fr': 'Comment allez-vous?',
        'de': 'Wie geht es Ihnen?',
        'zh': '你好吗？',
        'ja': 'お元気ですか？',
        'hi': 'आप कैसे हैं?',
        'ta': 'நீங்கள் எப்படி இருக்கிறீர்கள்?',
        'en': 'How are you?',
      };

      for (final entry in langsLong.entries) {
        final res = await stt.transcribe(longSpeech,
            options: TranscriptionOptions(language: entry.key));
        expect(res.text, equals(entry.value));
      }

      // Test RIFF header parsing
      final riffAudio = Uint8List(44 + 1000);
      riffAudio[0] = 0x52; // 'R'
      riffAudio[1] = 0x49; // 'I'
      riffAudio[2] = 0x46; // 'F'
      riffAudio[3] = 0x46; // 'F'
      for (int i = 0; i < 500; i++) {
        ByteData.sublistView(riffAudio, 44).setInt16(i * 2, 800, Endian.little);
      }
      final riffRes = await stt.transcribe(riffAudio,
          options: const TranscriptionOptions(language: 'en'));
      expect(riffRes.text, equals('Hello'));

      // Test silence (RMS energy <= 50)
      final silenceAudio = Uint8List(2000); // all zeros
      final silenceRes = await stt.transcribe(silenceAudio);
      expect(silenceRes.text, isEmpty);
      expect(silenceRes.confidence, equals(0.0));

      // Test under 2 pcm bytes
      final tinyAudio = Uint8List(1);
      final tinyRes = await stt.transcribe(tinyAudio);
      expect(tinyRes.text, isEmpty);
    });

    test('LocalSTTProvider rejects transcription when model is uninstalled',
        () async {
      final stt = LocalSTTProvider(isModelInstalled: false);
      expect(
        () async => await stt.transcribe(Uint8List(50)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('LocalSTTProvider handles cancellation and empty audio', () async {
      final stt = LocalSTTProvider(isModelInstalled: true);
      stt.cancel();

      final cancelledRes = await stt.transcribe(Uint8List(10));
      expect(cancelledRes.text, isEmpty);

      final emptyRes = await stt.transcribe(Uint8List(0));
      expect(emptyRes.text, isEmpty);
    });

    test('OfflineAudioSynthesizer produces valid WAV binary header', () async {
      final tts = OfflineAudioSynthesizer();
      final res = await tts.synthesize('Universal Communication Intelligence');

      expect(res.mimeType, equals('audio/wav'));
      expect(res.durationMs, greaterThan(0));
      expect(res.audioBytes.length, greaterThan(44));

      // Validate RIFF header
      final headerStr = String.fromCharCodes(res.audioBytes.sublist(0, 4));
      expect(headerStr, equals('RIFF'));
      final waveStr = String.fromCharCodes(res.audioBytes.sublist(8, 12));
      expect(waveStr, equals('WAVE'));
    });

    test(
        'CloudSpeechAdapter enforces offline privacy invariant and API key validation',
        () async {
      final privateAdapter =
          CloudSpeechAdapter(executionMode: ExecutionMode.privateOffline);
      expect(
        () async => await privateAdapter.transcribe(Uint8List(10)),
        throwsA(isA<OfflineViolationException>()),
      );
      expect(
        () async => await privateAdapter.synthesize('hello'),
        throwsA(isA<OfflineViolationException>()),
      );

      final noKeyAdapter =
          CloudSpeechAdapter(executionMode: ExecutionMode.cloud, apiKey: null);
      expect(
        () async => await noKeyAdapter.transcribe(Uint8List(10)),
        throwsA(isA<ProviderException>()),
      );
      expect(
        () async => await noKeyAdapter.synthesize('hello'),
        throwsA(isA<ProviderException>()),
      );

      final validCloudAdapter = CloudSpeechAdapter(
          executionMode: ExecutionMode.cloud, apiKey: 'secret_key');
      final cloudTrans = await validCloudAdapter.transcribe(Uint8List(10));
      expect(cloudTrans.text, contains('[CLOUD_TRANSCRIPTION_RESULT]'));

      final cloudSynth = await validCloudAdapter.synthesize('test');
      expect(cloudSynth.mimeType, equals('audio/mp3'));
    });
  });
}
