import 'dart:async';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'android_aicore_provider.dart';
import 'local_llm_provider.dart';
import 'cloud_llm_provider.dart';
import 'openai_provider.dart';
import 'anthropic_provider.dart';

/// Exception thrown when offline inference is required (private_offline mode) but no local or on-device model is available.
class OfflineInferenceUnavailableException extends UnicomException {
  const OfflineInferenceUnavailableException(String message)
      : super(message, code: 'OFFLINE_INFERENCE_UNAVAILABLE', statusCode: 503);
}

/// Unified Router orchestrating Android Built-in AI (AICore / Gemini Nano),
/// Local Downloaded Models (Quantized On-Device), and Multi-Cloud LLMs (Gemini, OpenAI, Anthropic, Custom).
class AIProviderRouter implements LLMProvider {
  final AndroidAICoreProvider androidProvider;
  final LocalLLMProvider localProvider;
  CloudLLMProvider cloudProvider;
  ExecutionMode executionMode;

  final Map<String, LLMProvider> _registeredProviders = {};
  final Map<String, AIProviderConfig> _providerConfigs = {};
  String? _defaultProviderId;
  final Map<String, String> _capabilityRoutes = {}; // capability -> providerId

  final PrivacyLogger _logger = const PrivacyLogger(context: 'AI_ROUTER');

  AIProviderRouter({
    required this.androidProvider,
    required this.localProvider,
    required this.cloudProvider,
    this.executionMode = ExecutionMode.privateOffline,
  }) {
    NetworkGate()
        .setOfflineEnforcement(executionMode == ExecutionMode.privateOffline);
    _initRegistry();
  }

  void _initRegistry() {
    registerProviderInstance(androidProvider.id, androidProvider);
    registerProviderInstance(localProvider.id, localProvider);
    registerProviderInstance(cloudProvider.id, cloudProvider);
    _defaultProviderId = cloudProvider.id;
  }

  void registerProviderInstance(String id, LLMProvider provider) {
    _registeredProviders[id] = provider;
  }

  void registerProviderConfig(AIProviderConfig config) {
    _providerConfigs[config.id] = config;

    switch (config.type) {
      case AIProviderType.gemini:
        final p = CloudLLMProvider(
          executionMode: executionMode,
          apiKey: config.apiKey,
          modelName:
              config.modelId.isNotEmpty ? config.modelId : 'gemini-1.5-flash',
          endpoint: config.baseUrl.isNotEmpty
              ? config.baseUrl
              : 'https://generativelanguage.googleapis.com/v1beta',
        );
        _registeredProviders[config.id] = p;
        cloudProvider = p;
        break;

      case AIProviderType.openai:
      case AIProviderType.custom:
        final p = OpenAIProvider(
          executionMode: executionMode,
          apiKey: config.apiKey,
          modelName: config.modelId.isNotEmpty ? config.modelId : 'gpt-4o-mini',
          baseUrl: config.baseUrl.isNotEmpty
              ? config.baseUrl
              : 'https://api.openai.com',
        );
        _registeredProviders[config.id] = p;
        break;

      case AIProviderType.anthropic:
        final p = AnthropicProvider(
          executionMode: executionMode,
          apiKey: config.apiKey,
          modelName: config.modelId.isNotEmpty
              ? config.modelId
              : 'claude-3-5-sonnet-20241022',
          endpoint: config.baseUrl.isNotEmpty
              ? config.baseUrl
              : 'https://api.anthropic.com/v1/messages',
        );
        _registeredProviders[config.id] = p;
        break;

      case AIProviderType.local:
        _registeredProviders[config.id] = localProvider;
        break;

      case AIProviderType.aicore:
        _registeredProviders[config.id] = androidProvider;
        break;
    }

    if (config.isDefault) {
      _defaultProviderId = config.id;
    }

    for (final cap in config.supportedCapabilities) {
      if (!_capabilityRoutes.containsKey(cap) || config.isDefault) {
        _capabilityRoutes[cap] = config.id;
      }
    }
  }

  void removeProviderConfig(String id) {
    _providerConfigs.remove(id);
    _registeredProviders.remove(id);
    if (_defaultProviderId == id) {
      _defaultProviderId = _registeredProviders.keys.firstOrNull;
    }
    _capabilityRoutes.removeWhere((_, v) => v == id);
  }

  void setDefaultProvider(String id) {
    if (_registeredProviders.containsKey(id)) {
      _defaultProviderId = id;
    }
  }

  void setCapabilityRoute(String capability, String providerId) {
    if (_registeredProviders.containsKey(providerId)) {
      _capabilityRoutes[capability] = providerId;
    }
  }

  List<AIProviderConfig> get configuredProviders =>
      _providerConfigs.values.toList();

  AIProviderConfig? get activeProviderConfig =>
      _providerConfigs[_defaultProviderId];

  String? get defaultProviderId => _defaultProviderId;

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
        'hasKey':
            cloudProvider.apiKey != null && cloudProvider.apiKey!.isNotEmpty,
      },
      'registeredProviders': _registeredProviders.keys.toList(),
    };
  }

  Future<LLMProvider> selectProvider({String capability = 'qa'}) async {
    final aicoreStatus = await androidProvider.checkStatus();

    switch (executionMode) {
      case ExecutionMode.privateOffline:
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
        if (aicoreStatus.isAvailable) return androidProvider;
        if (localProvider.isModelLoaded) return localProvider;
        final cloudP = _selectConfiguredCloudProvider(capability);
        if (cloudP != null) {
          _logger.info('Hybrid fallback: Routing to Cloud LLM (${cloudP.id})');
          return cloudP;
        }
        throw const OfflineInferenceUnavailableException(
          'No AI provider available in hybrid mode (no local model and no cloud API key configured).',
        );

      case ExecutionMode.cloud:
        final cloudP = _selectConfiguredCloudProvider(capability);
        if (cloudP != null) return cloudP;
        if (aicoreStatus.isAvailable) return androidProvider;
        if (localProvider.isModelLoaded) return localProvider;
        throw const ProviderException(
            'cloud_provider', 'No cloud or local provider available.');

      case ExecutionMode.auto:
        if (aicoreStatus.isAvailable) return androidProvider;
        if (localProvider.isModelLoaded) return localProvider;
        final cloudP = _selectConfiguredCloudProvider(capability);
        if (cloudP != null) return cloudP;
        throw const OfflineInferenceUnavailableException(
            'No AI provider available in auto mode.');
    }
  }

  LLMProvider? _selectConfiguredCloudProvider(String capability) {
    if (_capabilityRoutes.containsKey(capability)) {
      final id = _capabilityRoutes[capability]!;
      final p = _registeredProviders[id];
      if (p != null) {
        if (p is CloudLLMProvider) {
          if (p.apiKey != null && p.apiKey!.isNotEmpty) return p;
        } else {
          return p;
        }
      }
    }

    if (_defaultProviderId != null &&
        _registeredProviders.containsKey(_defaultProviderId)) {
      final p = _registeredProviders[_defaultProviderId]!;
      if (p is CloudLLMProvider) {
        if (p.apiKey != null && p.apiKey!.isNotEmpty) return p;
      } else if (!p.isOfflineCapable ||
          executionMode != ExecutionMode.privateOffline) {
        return p;
      }
    }

    if (cloudProvider.apiKey != null && cloudProvider.apiKey!.isNotEmpty) {
      return cloudProvider;
    }

    for (final entry in _registeredProviders.entries) {
      if (entry.key != androidProvider.id && entry.key != localProvider.id) {
        final p = entry.value;
        if (p is CloudLLMProvider) {
          if (p.apiKey != null && p.apiKey!.isNotEmpty) return p;
        } else {
          return p;
        }
      }
    }

    return null;
  }

  @override
  Future<String> complete(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    final provider = await selectProvider(capability: 'qa');
    try {
      return await provider.complete(
        prompt,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } catch (e) {
      // Automatic fallback if allowed
      if (executionMode != ExecutionMode.privateOffline &&
          provider != cloudProvider &&
          cloudProvider.apiKey != null) {
        _logger.warn(
            'Primary provider failed, attempting fallback to Cloud Gemini: ${e.toString()}');
        return cloudProvider.complete(
          prompt,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      }
      rethrow;
    }
  }

  @override
  Stream<String> completeStream(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async* {
    final provider = await selectProvider(capability: 'qa');
    yield* provider.completeStream(
      prompt,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }
}
