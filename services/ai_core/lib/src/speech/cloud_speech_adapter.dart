import 'dart:typed_data';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

class CloudSpeechAdapter implements STTProvider, TTSProvider {
  final ExecutionMode executionMode;
  final String? apiKey;

  CloudSpeechAdapter({
    required this.executionMode,
    this.apiKey,
  });

  @override
  String get id => 'cloud_speech_adapter';

  @override
  String get name => 'Cloud Speech Provider';

  @override
  bool get isOfflineCapable => false;

  @override
  Future<TranscriptionResult> transcribe(
    Uint8List audioBytes, {
    TranscriptionOptions options = const TranscriptionOptions(),
  }) async {
    if (executionMode == ExecutionMode.privateOffline) {
      throw const OfflineViolationException(
          'Privacy Violation: Cloud speech transcription attempted in private_offline mode.');
    }
    if (apiKey == null || apiKey!.isEmpty) {
      throw ProviderException(id, 'Missing Cloud Speech API key.');
    }
    return const TranscriptionResult(
      text: '[CLOUD_TRANSCRIPTION_RESULT]',
      confidence: 0.99,
      isFinal: true,
    );
  }

  @override
  void cancel() {}

  @override
  Future<SynthesisResult> synthesize(
    String text, {
    SynthesisOptions options = const SynthesisOptions(),
  }) async {
    if (executionMode == ExecutionMode.privateOffline) {
      throw const OfflineViolationException(
          'Privacy Violation: Cloud speech synthesis attempted in private_offline mode.');
    }
    if (apiKey == null || apiKey!.isEmpty) {
      throw ProviderException(id, 'Missing Cloud Speech API key.');
    }
    return SynthesisResult(
      audioBytes: Uint8List(100),
      mimeType: 'audio/mp3',
      durationMs: 1200,
    );
  }
}
