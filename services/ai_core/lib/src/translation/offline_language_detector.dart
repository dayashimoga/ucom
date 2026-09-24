import 'package:unicom_contracts/contracts.dart';

class OfflineLanguageDetector implements LanguageDetectionProvider {
  @override
  String get id => 'offline_language_detector';

  @override
  String get name => 'Offline Unicode & N-gram Language Detector';

  @override
  bool get isOfflineCapable => true;

  static const Map<String, List<String>> _latinProfiles = {
    'en': [
      'the',
      'be',
      'to',
      'of',
      'and',
      'a',
      'in',
      'that',
      'have',
      'i',
      'it',
      'for',
      'not',
      'on',
      'with',
      'he',
      'as',
      'you',
      'do',
      'at',
      'this',
      'but',
      'his',
      'by',
      'from',
      'they',
      'we',
      'say',
      'her',
      'she',
      'or',
      'an',
      'will',
      'my',
      'one',
      'all',
      'would',
      'there',
      'their',
      'what',
      'so',
      'up',
      'out',
      'if',
      'about',
      'who',
      'get',
      'which',
      'go',
      'me',
      'hello',
      'how',
      'are'
    ],
    'es': [
      'de',
      'la',
      'que',
      'el',
      'en',
      'y',
      'a',
      'los',
      'del',
      'se',
      'las',
      'por',
      'un',
      'para',
      'con',
      'no',
      'una',
      'su',
      'al',
      'lo',
      'como',
      'más',
      'pero',
      'sus',
      'le',
      'ya',
      'o',
      'este',
      'sí',
      'porque',
      'esta',
      'son',
      'entre',
      'está',
      'cuando',
      'muy',
      'sin',
      'sobre',
      'ser',
      'hola',
      'cómo',
      'estás',
      'gracias',
      'bien'
    ],
    'fr': [
      'de',
      'la',
      'le',
      'et',
      'les',
      'des',
      'en',
      'un',
      'du',
      'une',
      'que',
      'est',
      'pour',
      'qui',
      'dans',
      'a',
      'par',
      'plus',
      'pas',
      'au',
      'sur',
      'ne',
      'se',
      'ce',
      'il',
      'sont',
      'avec',
      'tout',
      'faire',
      'son',
      'nous',
      'bonjour',
      'comment',
      'allez',
      'vous',
      'merci'
    ],
    'de': [
      'der',
      'die',
      'und',
      'in',
      'den',
      'von',
      'zu',
      'das',
      'mit',
      'sich',
      'des',
      'auf',
      'für',
      'ist',
      'im',
      'dem',
      'nicht',
      'ein',
      'eine',
      'als',
      'auch',
      'es',
      'an',
      'werden',
      'aus',
      'er',
      'hat',
      'dass',
      'sie',
      'nach',
      'wird',
      'bei',
      'einer',
      'hallo',
      'wie',
      'geht',
      'danke'
    ],
    'pt': [
      'de',
      'a',
      'o',
      'que',
      'e',
      'do',
      'da',
      'em',
      'um',
      'para',
      'é',
      'com',
      'não',
      'uma',
      'os',
      'no',
      'se',
      'na',
      'por',
      'mais',
      'as',
      'dos',
      'como',
      'mas',
      'foi',
      'ao',
      'ele',
      'das',
      'tem',
      'à',
      'seu',
      'sua',
      'ou',
      'ser',
      'olá',
      'como',
      'está',
      'obrigado'
    ],
    'it': [
      'di',
      'e',
      'il',
      'la',
      'che',
      'in',
      'a',
      'per',
      'un',
      'del',
      'della',
      'dei',
      'delle',
      'le',
      'si',
      'non',
      'da',
      'con',
      'sono',
      'una',
      'nel',
      'come',
      'anche',
      'più',
      'questo',
      'questa',
      'ciao',
      'come',
      'stai',
      'grazie'
    ],
  };

  @override
  Future<LanguageDetectionResult> detectLanguage(String text) async {
    return detectLanguageSync(text);
  }

  /// Synchronous language detection based on Unicode script analysis and N-gram stopword frequencies.
  LanguageDetectionResult detectLanguageSync(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const LanguageDetectionResult(language: 'en', confidence: 0.5);
    }

    // Unicode Script Range Detection
    // Japanese Hiragana & Katakana
    if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(trimmed)) {
      return const LanguageDetectionResult(language: 'ja', confidence: 0.99);
    }
    // Chinese Han
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(trimmed)) {
      return const LanguageDetectionResult(language: 'zh', confidence: 0.98);
    }
    // Arabic
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) {
      return const LanguageDetectionResult(language: 'ar', confidence: 0.99);
    }
    // Hindi Devanagari
    if (RegExp(r'[\u0900-\u097F]').hasMatch(trimmed)) {
      return const LanguageDetectionResult(language: 'hi', confidence: 0.99);
    }
    // Tamil Script
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(trimmed)) {
      return const LanguageDetectionResult(language: 'ta', confidence: 0.99);
    }
    // Russian Cyrillic
    if (RegExp(r'[\u0400-\u04FF]').hasMatch(trimmed)) {
      return const LanguageDetectionResult(language: 'ru', confidence: 0.99);
    }

    // Latin alphabet stopword matching
    final words = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return const LanguageDetectionResult(language: 'en', confidence: 0.5);
    }

    final scores = <String, int>{
      'en': 0,
      'es': 0,
      'fr': 0,
      'de': 0,
      'pt': 0,
      'it': 0
    };

    for (final word in words) {
      _latinProfiles.forEach((lang, list) {
        if (list.contains(word)) {
          scores[lang] = (scores[lang] ?? 0) + 1;
        }
      });
    }

    var topLang = 'en';
    var maxScore = -1;

    final alternatives = <Map<String, dynamic>>[];
    scores.forEach((lang, score) {
      final conf = ((score / words.length) * 1.5).clamp(0.4, 0.99);
      alternatives.add({
        'language': lang,
        'confidence': double.parse(conf.toStringAsFixed(2))
      });
      if (score > maxScore) {
        maxScore = score;
        topLang = lang;
      }
    });

    final confidence = maxScore > 0
        ? ((maxScore / words.length) * 1.2 + 0.3).clamp(0.5, 0.98)
        : 0.6;

    alternatives.sort((a, b) =>
        (b['confidence'] as double).compareTo(a['confidence'] as double));

    return LanguageDetectionResult(
      language: topLang,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      alternatives: alternatives,
    );
  }
}
