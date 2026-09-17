import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
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
  });
}
