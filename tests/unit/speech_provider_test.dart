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
      final stt = LocalSTTProvider(isModelInstalled: true, modelPath: '/models/whisper.bin');
      expect(stt.isOfflineCapable, isTrue);
      expect(stt.id, equals('local_stt_whisper'));
      expect(stt.name, contains('Whisper'));

      final audio = Uint8List.fromList([1, 2, 3, 4, 5]);
      final res = await stt.transcribe(audio, options: const TranscriptionOptions(language: 'ta'));
      expect(res.isFinal, isTrue);
      expect(res.language, equals('ta'));
      expect(res.text, isNotEmpty);
    });

    test('LocalSTTProvider rejects transcription when model is uninstalled', () async {
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

    test('CloudSpeechAdapter enforces offline privacy invariant and API key validation', () async {
      final privateAdapter = CloudSpeechAdapter(executionMode: ExecutionMode.privateOffline);
      expect(
        () async => await privateAdapter.transcribe(Uint8List(10)),
        throwsA(isA<OfflineViolationException>()),
      );
      expect(
        () async => await privateAdapter.synthesize('hello'),
        throwsA(isA<OfflineViolationException>()),
      );

      final noKeyAdapter = CloudSpeechAdapter(executionMode: ExecutionMode.cloud, apiKey: null);
      expect(
        () async => await noKeyAdapter.transcribe(Uint8List(10)),
        throwsA(isA<ProviderException>()),
      );
      expect(
        () async => await noKeyAdapter.synthesize('hello'),
        throwsA(isA<ProviderException>()),
      );

      final validCloudAdapter = CloudSpeechAdapter(executionMode: ExecutionMode.cloud, apiKey: 'secret_key');
      final cloudTrans = await validCloudAdapter.transcribe(Uint8List(10));
      expect(cloudTrans.text, contains('[CLOUD_TRANSCRIPTION_RESULT]'));

      final cloudSynth = await validCloudAdapter.synthesize('test');
      expect(cloudSynth.mimeType, equals('audio/mp3'));
    });
  });
}
