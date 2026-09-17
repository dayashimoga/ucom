import 'dart:typed_data';
import 'package:unicom_contracts/contracts.dart';

class DeterministicFakeSTTProvider implements STTProvider {
  String _mockText = 'Hello world, this is a simulated transcription.';
  bool _cancelled = false;

  @override
  String get id => 'fake_stt_provider';

  @override
  String get name => 'Deterministic Fake STT Provider';

  @override
  bool get isOfflineCapable => true;

  void setMockText(String text) {
    _mockText = text;
  }

  @override
  Future<TranscriptionResult> transcribe(
    Uint8List audioBytes, {
    TranscriptionOptions options = const TranscriptionOptions(),
  }) async {
    if (_cancelled) {
      _cancelled = false;
      return const TranscriptionResult(text: '', confidence: 0);
    }
    return TranscriptionResult(
      text: _mockText,
      language: options.language ?? 'en',
      confidence: 0.99,
      isFinal: true,
    );
  }

  @override
  void cancel() {
    _cancelled = true;
  }
}

class DeterministicFakeTTSProvider implements TTSProvider {
  @override
  String get id => 'fake_tts_provider';

  @override
  String get name => 'Deterministic Fake TTS Provider';

  @override
  bool get isOfflineCapable => true;

  @override
  Future<SynthesisResult> synthesize(
    String text, {
    SynthesisOptions options = const SynthesisOptions(),
  }) async {
    // Generate valid 44-byte WAV header + mock PCM sample bytes
    const sampleRate = 16000;
    const numChannels = 1;
    const bitsPerSample = 16;
    final durationSeconds = (text.length * 0.05).clamp(0.5, 30.0);
    final numSamples = (sampleRate * durationSeconds).floor();
    final dataByteCount = numSamples * numChannels * (bitsPerSample ~/ 8);

    final byteData = ByteData(44 + dataByteCount);

    // RIFF chunk descriptor
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, 36 + dataByteCount, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    // fmt sub-chunk
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * numChannels * (bitsPerSample ~/ 8), Endian.little);
    byteData.setUint16(32, numChannels * (bitsPerSample ~/ 8), Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // data sub-chunk
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, dataByteCount, Endian.little);

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
