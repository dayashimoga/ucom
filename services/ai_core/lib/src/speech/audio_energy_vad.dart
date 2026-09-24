import 'dart:math';
import 'dart:typed_data';

/// Result of Voice Activity Detection analysis on an audio frame or buffer.
class VadFrame {
  final double rmsEnergy;
  final double zeroCrossingRate;
  final double snrDb;
  final bool isSpeech;
  final int sampleCount;
  final int durationMs;

  const VadFrame({
    required this.rmsEnergy,
    required this.zeroCrossingRate,
    required this.snrDb,
    required this.isSpeech,
    required this.sampleCount,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
        'rmsEnergy': double.parse(rmsEnergy.toStringAsFixed(2)),
        'zeroCrossingRate': double.parse(zeroCrossingRate.toStringAsFixed(4)),
        'snrDb': double.parse(snrDb.toStringAsFixed(2)),
        'isSpeech': isSpeech,
        'sampleCount': sampleCount,
        'durationMs': durationMs,
      };
}

/// Voice Activity Detector (VAD) analyzing PCM audio energy, zero-crossing rates,
/// and signal-to-noise ratio to classify human speech vs background silence/noise.
class AudioEnergyVad {
  final double speechEnergyThreshold;
  final double minSnrDbThreshold;
  final int sampleRate;

  const AudioEnergyVad({
    this.speechEnergyThreshold = 50.0,
    this.minSnrDbThreshold = 6.0,
    this.sampleRate = 16000,
  });

  /// Analyzes raw 16-bit little-endian PCM audio bytes.
  VadFrame analyzePcm(Uint8List pcmBytes) {
    if (pcmBytes.length < 2) {
      return const VadFrame(
        rmsEnergy: 0.0,
        zeroCrossingRate: 0.0,
        snrDb: 0.0,
        isSpeech: false,
        sampleCount: 0,
        durationMs: 0,
      );
    }

    // Skip RIFF header if present
    int offset = 0;
    if (pcmBytes.length > 44 &&
        pcmBytes[0] == 0x52 &&
        pcmBytes[1] == 0x49 &&
        pcmBytes[2] == 0x46 &&
        pcmBytes[3] == 0x46) {
      offset = 44;
    }

    final rawPcm = pcmBytes.sublist(offset);
    final sampleCount = rawPcm.length ~/ 2;
    if (sampleCount == 0) {
      return const VadFrame(
        rmsEnergy: 0.0,
        zeroCrossingRate: 0.0,
        snrDb: 0.0,
        isSpeech: false,
        sampleCount: 0,
        durationMs: 0,
      );
    }

    final byteData = ByteData.sublistView(rawPcm);
    double sumSquares = 0.0;
    int zeroCrossings = 0;
    int lastSample = 0;
    double noiseFloorEstimate = 15.0;

    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sumSquares += sample * sample;

      if ((sample >= 0 && lastSample < 0) || (sample < 0 && lastSample >= 0)) {
        zeroCrossings++;
      }
      lastSample = sample;
    }

    final meanSquare = sumSquares / sampleCount;
    final rms = sqrt(meanSquare);
    final zcr = zeroCrossings / sampleCount.toDouble();

    // Signal-to-Noise Ratio (SNR) in decibels relative to noise floor estimate
    final double signalRms = max(rms, 1.0);
    final double snrDb = 20.0 * (log(signalRms / noiseFloorEstimate) / ln10);

    final durationMs = ((sampleCount / sampleRate.toDouble()) * 1000).round();
    final bool isSpeech =
        rms >= speechEnergyThreshold && snrDb >= minSnrDbThreshold;

    return VadFrame(
      rmsEnergy: rms,
      zeroCrossingRate: zcr,
      snrDb: snrDb,
      isSpeech: isSpeech,
      sampleCount: sampleCount,
      durationMs: durationMs,
    );
  }

  /// Trims leading and trailing silence from 16-bit PCM buffer based on energy threshold.
  Uint8List trimSilence(Uint8List pcmBytes, {int frameSizeSamples = 320}) {
    if (pcmBytes.length < frameSizeSamples * 2) return pcmBytes;
    final frameSizeBytes = frameSizeSamples * 2;
    int startOffset = 0;
    int endOffset = pcmBytes.length;

    bool speechFound = false;

    // Find first frame with speech
    for (int i = 0;
        i + frameSizeBytes <= pcmBytes.length;
        i += frameSizeBytes) {
      final slice = pcmBytes.sublist(i, i + frameSizeBytes);
      final frame = analyzePcm(slice);
      if (frame.isSpeech) {
        startOffset = max(0, i - frameSizeBytes); // Keep small lead-in
        speechFound = true;
        break;
      }
    }

    if (!speechFound) {
      return Uint8List(0);
    }

    // Find last frame with speech
    for (int i = pcmBytes.length - frameSizeBytes;
        i >= startOffset;
        i -= frameSizeBytes) {
      final slice = pcmBytes.sublist(i, i + frameSizeBytes);
      final frame = analyzePcm(slice);
      if (frame.isSpeech) {
        endOffset = min(pcmBytes.length, i + frameSizeBytes * 2);
        break;
      }
    }

    if (startOffset >= endOffset) {
      return Uint8List(0);
    }
    return pcmBytes.sublist(startOffset, endOffset);
  }
}
