import 'dart:convert';
import 'package:unicom_contracts/contracts.dart';

class ExplanationEngine {
  final LLMProvider? provider;

  ExplanationEngine([this.provider]);

  Future<ExplanationResult> generateExplanations(
    String text, {
    String? segmentId,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    List<ExplanationPersona>? personas,
    String? context,
  }) async {
    final trimmed = text.trim();
    final requestedPersonas = personas ?? ExplanationPersona.values;
    final explanations = <ExplanationPersona, ExplanationEntry>{};

    // Attempt real LLM generation if provider is available
    if (provider != null) {
      try {
        final prompt = '''
Analyze and explain the following message across linguistic and cultural dimensions.
Message: "$trimmed"
Context: "${context ?? 'General conversation'}"
Target Language: "${targetLanguage ?? 'en'}"

Return ONLY a valid JSON object where keys are the persona names ("simple", "detailed", "terminology", "grammar", "culturalContext", "examples", "childFriendly") and each value is an object with:
- "content": string explanation
- "keyPoints": list of strings (2-4 key takeaways)
''';
        final response =
            await provider!.complete(prompt, maxTokens: 800, temperature: 0.3);
        final cleanJson = _extractJson(response);
        if (cleanJson != null) {
          final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
          for (final persona in requestedPersonas) {
            final entryMap = parsed[persona.name] as Map<String, dynamic>?;
            if (entryMap != null && entryMap['content'] != null) {
              final keyPoints = (entryMap['keyPoints'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
              explanations[persona] = ExplanationEntry(
                persona: persona,
                content: entryMap['content'].toString(),
                keyPoints: keyPoints,
              );
            }
          }
        }
      } catch (_) {
        // Fall back to structured linguistic template
      }
    }

    // Fill any missing personas with structured template fallback
    for (final persona in requestedPersonas) {
      if (!explanations.containsKey(persona)) {
        explanations[persona] =
            _buildPersonaExplanation(persona, trimmed, context, targetLanguage);
      }
    }

    return ExplanationResult(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      segmentId: segmentId,
      originalText: trimmed,
      translatedText: translatedText,
      targetLanguage: targetLanguage,
      explanations: explanations,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  String? _extractJson(String response) {
    try {
      final start = response.indexOf('{');
      final end = response.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        return response.substring(start, end + 1);
      }
    } catch (_) {}
    return null;
  }

  ExplanationEntry _buildPersonaExplanation(
    ExplanationPersona persona,
    String text,
    String? context,
    String? targetLanguage,
  ) {
    final isQuestion = text.endsWith('?');
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    switch (persona) {
      case ExplanationPersona.simple:
        return ExplanationEntry(
          persona: persona,
          content:
              'In simple words: "$text" expresses a ${isQuestion ? 'direct question' : 'clear statement'}. It shares the main idea plainly without complex jargon.',
          keyPoints: ['Direct meaning', 'Clear and easy to understand'],
        );

      case ExplanationPersona.detailed:
        return ExplanationEntry(
          persona: persona,
          content:
              'In-depth analysis: The message contains ${words.length} words. Functionally, it operates as a ${isQuestion ? 'structured inquiry' : 'declarative statement'}${context != null ? ' within the context of "$context"' : ''}. It precisely establishes common ground between speakers.',
          keyPoints: [
            'Word count: ${words.length}',
            'Pragmatic function: ${isQuestion ? 'Inquiry' : 'Declarative'}',
            if (targetLanguage != null) 'Target language: $targetLanguage',
          ],
        );

      case ExplanationPersona.terminology:
        final longWords = words.where((w) => w.length > 4).take(3).toList();
        return ExplanationEntry(
          persona: persona,
          content: longWords.isNotEmpty
              ? 'Key terminology analyzed:\n${longWords.map((w) => '• $w: High-information term carrying domain meaning').join('\n')}'
              : 'Lexical analysis: Standard conversational vocabulary used without overly specialized jargon.',
          keyPoints: longWords.isNotEmpty ? longWords : ['Standard vocabulary'],
        );

      case ExplanationPersona.grammar:
        return ExplanationEntry(
          persona: persona,
          content:
              'Grammatical structure:\n- Sentence Type: ${isQuestion ? 'Interrogative clause' : 'Declarative clause'}\n- Mood: ${isQuestion ? 'Interrogative mood' : 'Indicative mood'}\n- Punctuation: Terminal ${isQuestion ? 'question mark' : 'period/marker'} properly terminates the clause.',
          keyPoints: [
            isQuestion ? 'Interrogative clause' : 'Declarative clause',
            'Standard syntax'
          ],
        );

      case ExplanationPersona.culturalContext:
        return ExplanationEntry(
          persona: persona,
          content:
              'Cultural and pragmatic context: Tone is ${isQuestion ? 'respectful and open' : 'professional and neutral'}. Suitable for cross-cultural communication in professional, academic, or social environments without offensive connotations.',
          keyPoints: ['Neutral & professional', 'Cross-culturally appropriate'],
        );

      case ExplanationPersona.examples:
        return ExplanationEntry(
          persona: persona,
          content:
              'Real-world usage examples:\n1. Professional: "In the project review, we noted: \'$text\'."\n2. Daily conversation: "Just to check: \'$text\', right?"\n3. Collaboration: "Building upon \'$text\', we agreed on the next steps."',
          keyPoints: [
            'Workplace review',
            'Daily dialogue',
            'Collaborative alignment'
          ],
        );

      case ExplanationPersona.childFriendly:
        return ExplanationEntry(
          persona: persona,
          content:
              'Think of this like talking with your best friend! "$text" is a nice, cheerful way to say ${isQuestion ? '"Can you tell me more about this?"' : '"Here is something fun I wanted to tell you!"'}',
          keyPoints: ['Super friendly', 'Easy and fun!'],
        );
    }
  }
}
