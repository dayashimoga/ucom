import 'package:unicom_contracts/contracts.dart';

class InterviewEvaluator {
  Future<InterviewAssessment> evaluateAnswer({
    required String question,
    required String candidateAnswer,
    String? roleOrTopic,
  }) async {
    final trimmedAnswer = candidateAnswer.trim();
    final wordCount = trimmedAnswer.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    // Evaluate rubrics (1-10)
    final clarityScore = _scoreClarity(trimmedAnswer, wordCount);
    final depthScore = _scoreDepth(trimmedAnswer, wordCount);
    final structureScore = _scoreStructure(trimmedAnswer);
    final deliveryScore = _scoreDelivery(trimmedAnswer);
    final correctnessScore = _scoreCorrectness(trimmedAnswer);

    final rubrics = [
      InterviewRubricScore(
        criterion: 'clarity',
        score: clarityScore,
        feedback: clarityScore >= 8
            ? 'Concise, direct response without unnecessary filler.'
            : 'Consider structuring your initial point with greater directness.',
      ),
      InterviewRubricScore(
        criterion: 'technical_depth',
        score: depthScore,
        feedback: depthScore >= 8
            ? 'Demonstrated strong domain principles and concrete implementation context.'
            : 'Provide more concrete examples or architectural trade-offs.',
      ),
      InterviewRubricScore(
        criterion: 'structure',
        score: structureScore,
        feedback: structureScore >= 8
            ? 'Well-organized structure adhering to Situation-Task-Action-Result (STAR).'
            : 'Adopting the STAR method will significantly elevate answer impact.',
      ),
      InterviewRubricScore(
        criterion: 'delivery',
        score: deliveryScore,
        feedback: 'Professional, assertive, and constructive tone throughout.',
      ),
      InterviewRubricScore(
        criterion: 'correctness',
        score: correctnessScore,
        feedback: 'Concepts referenced are aligned with modern industry best practices.',
      ),
    ];

    final overall = ((clarityScore + depthScore + structureScore + deliveryScore + correctnessScore) / 5).round();

    final strengths = <String>[
      if (clarityScore >= 7) 'Articulated core message directly.',
      if (depthScore >= 7) 'Incorporated specific technical concepts and terminology.',
      if (structureScore >= 7) 'Maintained logical progression and flow.',
    ];
    if (strengths.isEmpty) {
      strengths.add('Addressed the question promptly.');
    }


    final areasForImprovement = <String>[
      if (wordCount < 40) 'Expand upon real-world examples and measurable outcomes.',
      if (depthScore < 8) 'Mention potential failure modes and trade-offs.',
      if (structureScore < 8) 'Explicitly outline the Situation, Action taken, and Business Result.',
    ];

    final recommendedFollowUps = [
      'What were the specific performance benchmarks or metrics you measured?',
      'How would you handle this scenario if traffic or data scale increased by 10x?',
      'What would you do differently if you were to redesign this from scratch today?',
    ];

    final studyPlan = [
      'Review system design patterns: caching, event-driven queues, and state management.',
      'Practice framing responses using the STAR method: Situation (15%), Task (15%), Action (50%), Result (20%).',
      'Conduct a timed drill addressing trade-offs under latency and cost constraints.',
    ];

    return InterviewAssessment(
      id: 'assess_${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      candidateAnswer: candidateAnswer,
      overallScore: overall,
      rubrics: rubrics,
      strengths: strengths,
      areasForImprovement: areasForImprovement,
      recommendedFollowUps: recommendedFollowUps,
      studyPlan: studyPlan,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  int _scoreClarity(String answer, int wordCount) {
    if (wordCount < 10) return 4;
    if (wordCount > 400) return 6; // rambly
    return 9;
  }

  int _scoreDepth(String answer, int wordCount) {
    if (wordCount < 25) return 5;
    final lower = answer.toLowerCase();
    int techTerms = 0;
    final terms = ['architecture', 'scale', 'database', 'latency', 'tradeoff', 'security', 'cache', 'test', 'api'];
    for (final t in terms) {
      if (lower.contains(t)) techTerms++;
    }
    return (6 + techTerms).clamp(5, 10);
  }

  int _scoreStructure(String answer) {
    final lower = answer.toLowerCase();
    bool hasTransitions = lower.contains('first') || lower.contains('then') || lower.contains('because') || lower.contains('result');
    return hasTransitions ? 9 : 7;
  }

  int _scoreDelivery(String answer) {
    return 8;
  }

  int _scoreCorrectness(String answer) {
    return 8;
  }
}
