import 'package:unicom_contracts/contracts.dart';

class DeterministicFakeTranslationProvider implements TranslationProvider {
  final Map<String, String> _customTranslations = {};

  @override
  String get id => 'fake_translation_provider';

  @override
  String get name => 'Deterministic Fake Translation Provider';

  @override
  bool get isOfflineCapable => true;

  void setTranslation(String key, String translation) {
    _customTranslations[key.toLowerCase().trim()] = translation;
  }

  @override
  Future<TranslationResult> translate(
    String text, {
    required TranslationOptions options,
  }) async {
    final directKey = text.toLowerCase().trim();
    final specificKey =
        '${options.sourceLanguage ?? "auto"}->${options.targetLanguage}:$directKey';

    final translated = _customTranslations[specificKey] ??
        _customTranslations[directKey] ??
        '[${options.targetLanguage.toUpperCase()}] $text';

    return TranslationResult(
      translatedText: translated,
      sourceLanguage: options.sourceLanguage ?? 'en',
      targetLanguage: options.targetLanguage,
      confidence: 1.0,
      provider: id,
    );
  }
}
