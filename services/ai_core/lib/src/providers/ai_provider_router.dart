import 'dart:async';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'android_aicore_provider.dart';
import 'local_llm_provider.dart';
import 'cloud_llm_provider.dart';

/// Exception thrown when offline inference is required (private_offline mode) but no local or on-device model is available.
class OfflineInferenceUnavailableException extends UnicomException {
  const OfflineInferenceUnavailableException(String message)
      : super(message, code: 'OFFLINE_INFERENCE_UNAVAILABLE', statusCode: 503);
}

/// Unified Router orchestrating Android Built-in AI (AICore / Gemini Nano),
/// Local Downloaded Models (Quantized On-Device), and Cloud LLMs (Google Gemini / extensible).
class AIProviderRouter implements LLMProvider {
  final AndroidAICoreProvider androidProvider;
  final LocalLLMProvider localProvider;
  final CloudLLMProvider cloudProvider;
  ExecutionMode executionMode;
  final PrivacyLogger _logger = const PrivacyLogger(context: 'AI_ROUTER');

  AIProviderRouter({
    required this.androidProvider,
    required this.localProvider,
    required this.cloudProvider,
    this.executionMode = ExecutionMode.privateOffline,
  }) {
    NetworkGate().setOfflineEnforcement(executionMode == ExecutionMode.privateOffline);
  }

  @override
  String get id => 'ai_provider_router';

  @override
  String get name => 'UNICOM AI Provider Router';

  @override
  bool get isOfflineCapable => true;

  void setExecutionMode(ExecutionMode mode) {
    executionMode = mode;
    NetworkGate().setOfflineEnforcement(mode == ExecutionMode.privateOffline);
  }

  /// Capability discovery across all three tiers
  Future<Map<String, dynamic>> discoverCapabilities() async {
    final aicoreStatus = await androidProvider.checkStatus();
    return {
      'executionMode': executionMode.name,
      'androidAICore': aicoreStatus.toJson(),
      'localModel': {
        'id': localProvider.activeModel?.id,
        'name': localProvider.name,
        'isLoaded': localProvider.isModelLoaded,
      },
      'cloud': {
        'id': cloudProvider.id,
        'name': cloudProvider.name,
        'model': cloudProvider.modelName,
        'hasKey': cloudProvider.apiKey != null && cloudProvider.apiKey!.isNotEmpty,
      },
    };
  }

  /// Selects the optimal LLMProvider according to ExecutionMode and runtime capabilities.
  Future<LLMProvider> selectProvider() async {
    final aicoreStatus = await androidProvider.checkStatus();

    switch (executionMode) {
      case ExecutionMode.privateOffline:
        // STRICT PRIVACY INVARIANT: Only Android AICore or Local Downloaded Model
        if (aicoreStatus.isAvailable) {
          _logger.info('Routing to Android AICore (Gemini Nano)');
          return androidProvider;
        }
        if (localProvider.isModelLoaded) {
          _logger.info('Routing to Local Downloaded Model');
          return localProvider;
        }
        throw const OfflineInferenceUnavailableException(
          'No offline AI engine available. Android AICore is not present and no local model is loaded. '
          'Cannot fall back to cloud while in private_offline mode.',
        );

      case ExecutionMode.hybrid:
        // Local-first, fallback to cloud
        if (aicoreStatus.isAvailable) {
          return androidProvider;
        }
        if (localProvider.isModelLoaded) {
          return localProvider;
        }
        if (cloudProvider.apiKey != null && cloudProvider.apiKey!.isNotEmpty) {
          _logger.info('Hybrid fallback: Routing to Cloud LLM');
          return cloudProvider;
        }
        throw const OfflineInferenceUnavailableException(
          'No AI provider available in hybrid mode (no local model and no cloud API key configured).',
        );

      case ExecutionMode.cloud:
        // Cloud preferred, fallback to local
        if (cloudProvider.apiKey != null && cloudProvider.apiKey!.isNotEmpty) {
          return cloudProvider;
        }
        if (aicoreStatus.isAvailable) return androidProvider;
        if (localProvider.isModelLoaded) return localProvider;
        throw const ProviderException('cloud_provider', 'No cloud or local provider available.');

      case ExecutionMode.auto:
        // Capability-aware priority: AICore (zero latency/cost) -> Local -> Cloud
        if (aicoreStatus.isAvailable) return androidProvider;
        if (localProvider.isModelLoaded) return localProvider;
        if (cloudProvider.apiKey != null && cloudProvider.apiKey!.isNotEmpty) {
          return cloudProvider;
        }
        throw const OfflineInferenceUnavailableException('No AI provider available in auto mode.');
    }
  }

  @override
  Future<String> complete(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    final provider = await selectProvider();
    return provider.complete(
      prompt,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  @override
  Stream<String> completeStream(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async* {
    final provider = await selectProvider();
    yield* provider.completeStream(
      prompt,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }
}
