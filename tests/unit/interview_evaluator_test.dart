import 'package:test/test.dart';
import 'package:unicom_ai_core/ai_core.dart';

void main() {
  group('InterviewEvaluator Tests', () {
    late InterviewEvaluator evaluator;

    setUp(() {
      evaluator = InterviewEvaluator();
    });

    test('evaluates a structured candidate response with high score', () async {
      final assessment = await evaluator.evaluateAnswer(
        question: 'Tell me about how you handled a critical outage.',
        candidateAnswer: 'First, during a major incident, our cache layer failed due to high latency. Then, I initiated our circuit breaker pattern to isolate the database and shed non-essential traffic. Because of this action, system latency recovered within two minutes, resulting in zero data loss and 99.99% uptime for our users.',
      );

      expect(assessment.overallScore, greaterThanOrEqualTo(7));
      expect(assessment.rubrics.length, equals(5));
      expect(assessment.strengths, isNotEmpty);
      expect(assessment.recommendedFollowUps, isNotEmpty);
      expect(assessment.studyPlan, isNotEmpty);
    });

    test('evaluates brief answers and provides constructive feedback', () async {
      final assessment = await evaluator.evaluateAnswer(
        question: 'What is database sharding?',
        candidateAnswer: 'It splits data.',
      );

      expect(assessment.overallScore, lessThan(7));
      expect(assessment.areasForImprovement, isNotEmpty);
      expect(assessment.areasForImprovement.any((a) => a.contains('Expand')), isTrue);
    });
  });
}
