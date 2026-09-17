import 'dart:math';
import 'dart:typed_data';
import 'package:unicom_contracts/contracts.dart';

class OfflineAudioSynthesizer implements TTSProvider {
  @override
  String get id => 'offline_audio_synthesizer';

  @override
  String get name => 'Offline Harmonic Waveform Synthesizer';

  @override
  bool get isOfflineCapable => true;

  @override
  Future<SynthesisResult> synthesize(
    String text, {
    SynthesisOptions options = const SynthesisOptions(),
  }) async {
    const sampleRate = 22050;
    final baseFreq = 220.0 * options.pitch;
    final durationSeconds =
        (text.length * (0.05 / options.rate.clamp(0.5, 2.0))).clamp(0.3, 60.0);
    final numSamples = (sampleRate * durationSeconds).floor();

    final byteData = ByteData(44 + numSamples * 2);

    // RIFF Header
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
    _writeString(byteData, 8, 'WAVE');
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little); // Block align
    byteData.setUint16(34, 16, Endian.little); // 16-bit
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, numSamples * 2, Endian.little);

    // Generate harmonic waveforms with attack/decay envelope
    final volume = options.volume.clamp(0.1, 1.0);
    const attack = sampleRate * 0.05;
    const decay = sampleRate * 0.05;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double env = 1.0;
      if (i < attack)
        env = i / attack;
      else if (i > numSamples - decay) env = (numSamples - i) / decay;

      final sample = (0.6 * sin(2 * pi * baseFreq * t) +
              0.3 * sin(2 * pi * baseFreq * 2 * t) +
              0.1 * sin(2 * pi * baseFreq * 3 * t)) *
          env *
          volume;

      final intSample = (sample * 32767).floor().clamp(-32768, 32767);
      byteData.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return SynthesisResult(
      audioBytes: byteData.buffer.asUint8List(),
      mimeType: 'audio/wav',
      durationMs: (durationSeconds * 1000).round(),
    );
  }

  void _writeString(ByteData data, int offset, String string) {
    for (int i = 0; i < string.length; i++) {
      data.setUint8(offset + i, string.codeUnitAt(i));
    }
  }
}
