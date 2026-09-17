import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';

void main() {
  group('ExplanationEngine Tests', () {
    late ExplanationEngine engine;

    setUp(() {
      engine = ExplanationEngine();
    });

    test('generates all 7 distinct explanation personas', () async {
      final res = await engine.generateExplanations(
        'Can we deploy the new architecture to staging tomorrow?',
        translatedText: '¿Podemos desplegar la nueva arquitectura en staging mañana?',
        targetLanguage: 'es',
        context: 'technical_planning',
      );

      expect(res.originalText, equals('Can we deploy the new architecture to staging tomorrow?'));
      expect(res.explanations.length, equals(7));

      // 1. Simple
      final simple = res.explanations[ExplanationPersona.simple]!;
      expect(simple.content, isNotEmpty);
      expect(simple.keyPoints, isNotEmpty);

      // 2. Detailed
      final detailed = res.explanations[ExplanationPersona.detailed]!;
      expect(detailed.content, contains('technical_planning'));
      expect(detailed.content, contains('inquiry'));

      // 3. Terminology
      final terms = res.explanations[ExplanationPersona.terminology]!;
      expect(terms.content, isNotEmpty);

      // 4. Grammar
      final grammar = res.explanations[ExplanationPersona.grammar]!;
      expect(grammar.content, contains('Interrogative'));

      // 5. Cultural Context
      final culture = res.explanations[ExplanationPersona.culturalContext]!;
      expect(culture.content, isNotEmpty);

      // 6. Examples
      final examples = res.explanations[ExplanationPersona.examples]!;
      expect(examples.content, contains('Real-world usage examples'));

      // 7. Child-Friendly
      final child = res.explanations[ExplanationPersona.childFriendly]!;
      expect(child.content, contains('friend'));
    });
  });
}
