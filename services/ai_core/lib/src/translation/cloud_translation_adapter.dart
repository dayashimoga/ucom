import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

class CloudTranslationAdapter implements TranslationProvider {
  final ExecutionMode executionMode;
  final String? apiKey;

  CloudTranslationAdapter({
    required this.executionMode,
    this.apiKey,
  });

  @override
  String get id => 'cloud_translation_adapter';

  @override
  String get name => 'Cloud Translation Adapter';

  @override
  bool get isOfflineCapable => false;

  @override
  Future<TranslationResult> translate(
    String text, {
    required TranslationOptions options,
  }) async {
    // Strictly verify privacy boundary
    if (executionMode == ExecutionMode.privateOffline) {
      throw const OfflineViolationException(
          'Privacy Violation: Cloud translation cannot be invoked in private_offline mode.');
    }

    if (apiKey == null || apiKey!.isEmpty) {
      throw ProviderException(
          id, 'Missing API credentials for cloud translation.');
    }

    return TranslationResult(
      translatedText: '[CLOUD-${options.targetLanguage.toUpperCase()}] $text',
      sourceLanguage: options.sourceLanguage ?? 'en',
      targetLanguage: options.targetLanguage,
      confidence: 0.99,
      provider: id,
    );
  }
}
