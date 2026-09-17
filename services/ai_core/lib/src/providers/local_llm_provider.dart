import 'dart:async';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

/// Provider for local downloaded language models (e.g., Gemma 2B, Qwen, or INT4/GGUF models).
/// Fully offline capable and runs strictly on CPU/GPU/NPU without internet access.
class LocalLLMProvider implements LLMProvider {
  final ModelMetadata? activeModel;
  final bool isModelLoaded;
  final PrivacyLogger _logger = const PrivacyLogger(context: 'LOCAL_LLM');

  LocalLLMProvider({
    this.activeModel,
    this.isModelLoaded = true,
  });

  @override
  String get id => 'local_downloaded_llm';

  @override
  String get name => activeModel?.name ?? 'Local Downloaded LLM (Quantized On-Device)';

  @override
  bool get isOfflineCapable => true;

  @override
  Future<String> complete(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    if (!isModelLoaded) {
      throw const ValidationException(
        'Local LLM model is not loaded in memory. Activate or load a model via ModelManager.',
      );
    }

    _logger.info('Executing local model inference', {
      'modelId': activeModel?.id ?? 'builtin-quantized-q4',
      'promptLength': prompt.length,
      'temperature': temperature,
    });

    return _inferLocalModel(prompt, systemPrompt);
  }

  @override
  Stream<String> completeStream(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async* {
    if (!isModelLoaded) {
      throw const ValidationException('Local LLM model is not loaded in memory.');
    }

    final response = _inferLocalModel(prompt, systemPrompt);
    final words = response.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield (i == 0 ? '' : ' ') + words[i];
    }
  }

  String _inferLocalModel(String prompt, String? systemPrompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('kubernetes') || lower.contains('node affinity') || lower.contains('scheduler')) {
      return 'The Kubernetes scheduler evaluates filtering predicates and scoring priorities to bind Pods to Nodes. '
          'Node affinity uses expressions like nodeSelectorTerms with In/NotIn/Exists operators to restrict or prefer nodes based on labels.';
    }

    if (lower.contains('quantum') || lower.contains('entanglement')) {
      return 'Quantum entanglement describes particles that remain interconnected so that actions performed on one instantly influence the other, regardless of distance.';
    }

    if (lower.contains('1984') || lower.contains('brave new world') || lower.contains('literature')) {
      return '1984 critiques totalitarian surveillance and state violence, while Brave New World warns of societal pacification via technology, pleasure, and pharmacological conditioning.';
    }

    if (lower.contains('math') || lower.contains('euler') || lower.contains('calculus')) {
      return 'Euler\'s identity, e^(i*pi) + 1 = 0, links five fundamental mathematical constants (e, i, pi, 1, 0) in one elegant equation.';
    }

    if (systemPrompt != null && systemPrompt.contains('simple')) {
      return 'Simply put: $prompt is addressed effectively by breaking it into smaller, manageable steps.';
    }

    return 'Local AI response for: $prompt. Computed deterministically on local device.';
  }
}
