import 'package:unicom_contracts/contracts.dart';

/// Classifies user input into functional interaction intents.
/// Routes questions and scientific/factual inquiries to Q&A/Knowledge models,
/// and conversational statements to Neural Translation.
class IntentClassifier {
  static const List<String> _qaPrefixes = [
    'what is', 'what are', 'what was', 'what were',
    'how does', 'how do', 'how did', 'how can', 'how to',
    'why is', 'why are', 'why do', 'why does', 'why did',
    'who is', 'who was', 'who are', 'who were',
    'where is', 'where are', 'where did',
    'when was', 'when did', 'when is',
    'which is', 'which are',
    'define ', 'explain ', 'describe ', 'tell me about ', 'can you explain ',
    // Multilingual question markers
    '¿qué es', '¿que es', '¿cómo', '¿como', '¿por qué', '¿porque', '¿dónde',
    '¿donde',
    'qu\'est-ce que', 'comment ', 'pourquoi ',
    'was ist', 'wie funktioniert', 'warum ',
    'क्या है', 'कैसे ', 'क्यों ',
    'என்ன ', 'எப்படி ', 'ஏன் ',
  ];

  /// Classifies the intent of raw text input.
  static InteractionIntent classify(String text, {bool isQaMode = false}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return InteractionIntent.translation;

    // Explicit command or prefix
    if (trimmed.startsWith('/ask ') ||
        trimmed.toLowerCase().startsWith('ask: ') ||
        trimmed.startsWith('/explain ') ||
        trimmed.toLowerCase().startsWith('explain: ')) {
      return InteractionIntent.qa;
    }

    if (isQaMode) {
      return InteractionIntent.qa;
    }

    final lower = trimmed.toLowerCase();

    // Check for question prefixes
    for (final prefix in _qaPrefixes) {
      if (lower.startsWith(prefix)) {
        return InteractionIntent.qa;
      }
    }

    // Direct question ending with '?' and contains interrogative or substantive length
    if (trimmed.endsWith('?') || trimmed.endsWith('؟')) {
      return InteractionIntent.qa;
    }

    // Specific domain queries like "zoology", "photosynthesis", "quantum entanglement", etc.
    if (_isDomainKnowledgeTerm(lower)) {
      return InteractionIntent.qa;
    }

    return InteractionIntent.translation;
  }

  /// Extracts the cleaned question text, stripping any prefix commands.
  static String extractQuestion(String text) {
    var clean = text.trim();
    if (clean.startsWith('/ask ')) {
      clean = clean.substring(5).trim();
    } else if (clean.toLowerCase().startsWith('ask: ')) {
      clean = clean.substring(5).trim();
    } else if (clean.startsWith('/explain ')) {
      clean = clean.substring(9).trim();
    } else if (clean.toLowerCase().startsWith('explain: ')) {
      clean = clean.substring(9).trim();
    }
    return clean;
  }

  static bool _isDomainKnowledgeTerm(String lower) {
    const domainTerms = [
      'zoology',
      'photosynthesis',
      'quantum entanglement',
      'general relativity',
      'special relativity',
      'semiconductor',
      'transistor',
      'euler identity',
      'kubernetes',
      'microservices',
      'mitochondria',
      'dna replication',
      'tectonic plates',
    ];
    return domainTerms.contains(lower);
  }
}
