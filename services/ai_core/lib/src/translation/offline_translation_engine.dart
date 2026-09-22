import 'package:unicom_contracts/contracts.dart';
import 'offline_language_detector.dart';
import 'neural_translation_engine.dart';
import 'phrasebook.dart';

class OfflineTranslationEngine implements TranslationProvider {
  final LanguageDetectionProvider _detector;
  final NeuralTranslationEngine neuralEngine;

  OfflineTranslationEngine([
    LanguageDetectionProvider? detector,
    NeuralTranslationEngine? neural,
  ])  : _detector = detector ?? OfflineLanguageDetector(),
        neuralEngine = neural ?? NeuralTranslationEngine(detector);

  @override
  String get id => 'offline_translation_engine';

  @override
  String get name => 'On-Device Linguistic & Neural Translation Engine';

  @override
  bool get isOfflineCapable => true;

  @override
  Future<TranslationResult> translate(
    String text, {
    required TranslationOptions options,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return TranslationResult(
        translatedText: '',
        sourceLanguage: options.sourceLanguage ?? 'en',
        targetLanguage: options.targetLanguage,
        provider: id,
      );
    }

    String? sourceLang = options.sourceLanguage;
    String? detectedSource;

    if (sourceLang == null || sourceLang == 'auto') {
      final detection = await _detector.detectLanguage(trimmed);
      sourceLang = detection.language;
      detectedSource = sourceLang;
    }

    final targetLang = options.targetLanguage.toLowerCase();
    if (sourceLang.toLowerCase() == targetLang) {
      var sameLangResult = trimmed;
      if (options.formality == 'more') {
        if (targetLang == 'es') {
          sameLangResult = sameLangResult.replaceAll(
              RegExp(r'(?<=^|\s)(tú|tu)(?=\s|$|[.,!?])', caseSensitive: false),
              'usted');
        } else if (targetLang == 'de') {
          sameLangResult = sameLangResult.replaceAll(
              RegExp(r'(?<=^|\s)du(?=\s|$|[.,!?])', caseSensitive: false),
              'Sie');
        }
      }
      return TranslationResult(
        translatedText: sameLangResult,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        detectedSourceLanguage: detectedSource,
        confidence: 1.0,
        provider: id,
      );
    }

    // 1. Primary: Neural Translation Engine
    final neuralRes = await neuralEngine.translate(trimmed, options: options);
    if (neuralRes.translatedText != trimmed) {
      return TranslationResult(
        translatedText: _applyCaseAndPunctuation(trimmed, neuralRes.translatedText),
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        detectedSourceLanguage: detectedSource,
        confidence: neuralRes.confidence,
        provider: id,
      );
    }

    // 2. Emergency / Domain Phrasebook Fallback (when neural output unchanged)
    final lowerInput = trimmed.toLowerCase();
    for (final entry in offlinePhrasebook) {
      final src = entry.getForLanguage(sourceLang.toLowerCase());
      final tgt = entry.getForLanguage(targetLang);
      if (src != null && tgt != null && lowerInput == src.toLowerCase()) {
        return TranslationResult(
          translatedText: _applyCaseAndPunctuation(trimmed, tgt),
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          detectedSourceLanguage: detectedSource,
          confidence: 0.95,
          provider: '$id:phrasebook_fallback',
        );
      }
    }

    // 2. Lexical word-by-word token alignment
    final tokens = _tokenize(trimmed);
    final translatedTokens = <String>[];
    int translatedCount = 0;
    int wordCount = 0;

    for (final token in tokens) {
      if (_isWhitespaceOrPunctuation(token)) {
        translatedTokens.add(token);
        continue;
      }

      wordCount++;
      final lower = token.toLowerCase();
      String? matched;

      // English source
      if (sourceLang.toLowerCase() == 'en' &&
          offlineLexicon.containsKey(lower)) {
        matched = offlineLexicon[lower]?[targetLang];
      } else {
        // Reverse check from non-English
        for (final entry in offlineLexicon.entries) {
          if (entry.value[sourceLang.toLowerCase()]?.toLowerCase() == lower) {
            if (targetLang == 'en') {
              matched = entry.key;
            } else {
              matched = entry.value[targetLang];
            }
            break;
          }
        }
      }

      if (matched != null) {
        translatedCount++;
        final isCapitalized =
            token.isNotEmpty && token[0] == token[0].toUpperCase();
        if (isCapitalized && matched.isNotEmpty) {
          matched = matched[0].toUpperCase() + matched.substring(1);
        }
        translatedTokens.add(matched);
      } else {
        translatedTokens.add(token);
      }
    }

    var result = translatedTokens.join();

    // Formality adjustments
    if (options.formality == 'more') {
      if (targetLang == 'es') {
        result = result.replaceAll(
            RegExp(r'(?<=^|\s)(tú|tu)(?=\s|$|[.,!?])', caseSensitive: false),
            'usted');
      } else if (targetLang == 'de') {
        result =
            result.replaceAll(RegExp(r'\bdu\b', caseSensitive: false), 'Sie');
      }
    }

    final confidence =
        wordCount > 0 ? (translatedCount / wordCount).clamp(0.5, 0.95) : 0.8;

    return TranslationResult(
      translatedText: result,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      detectedSourceLanguage: detectedSource,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      provider: id,
    );
  }

  List<String> _tokenize(String text) {
    final pattern = RegExp(r'(\s+|[.,!?;:()"])');
    final matches = pattern.allMatches(text);
    final tokens = <String>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        tokens.add(text.substring(lastEnd, match.start));
      }
      tokens.add(match.group(0)!);
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      tokens.add(text.substring(lastEnd));
    }

    return tokens;
  }

  bool _isWhitespaceOrPunctuation(String token) {
    return RegExp(r'^(\s+|[.,!?;:()"]+)$').hasMatch(token);
  }

  String _applyCaseAndPunctuation(String source, String target) {
    var result = target;
    if (result.startsWith('¿') && result.length > 1) {
      result = '¿${result[1].toUpperCase()}${result.substring(2)}';
    } else if (source.isNotEmpty && source[0] == source[0].toUpperCase() && result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    final lastChar = source.isNotEmpty ? source[source.length - 1] : '';
    if (['!', '?', '.'].contains(lastChar) && !result.endsWith(lastChar)) {
      result += lastChar;
    }
    // Strip any accidental multiple question/exclamation marks
    result = result.replaceAll(RegExp(r'\?{2,}'), '?').replaceAll(RegExp(r'!{2,}'), '!');
    return result;
  }
}
