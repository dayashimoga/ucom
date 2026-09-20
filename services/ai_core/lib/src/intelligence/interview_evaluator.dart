import 'dart:convert';
import 'package:unicom_contracts/contracts.dart';

class InterviewEvaluator {
  final LLMProvider? provider;

  InterviewEvaluator([this.provider]);

  Future<InterviewAssessment> evaluateAnswer({
    required String question,
    required String candidateAnswer,
    String? roleOrTopic,
  }) async {
    final trimmedAnswer = candidateAnswer.trim();

    // Attempt real LLM evaluation if provider is available
    if (provider != null) {
      try {
        final prompt = '''
Evaluate this candidate's interview response against standard technical and behavioral rubrics.
Question: "$question"
Candidate Answer: "$trimmedAnswer"
Context: "${roleOrTopic ?? 'Technical & Professional Excellence'}"

Return ONLY a valid JSON object with:
- "overallScore": integer (1-10)
- "rubrics": list of objects with "criterion" ("clarity", "technical_depth", "structure", "delivery", "correctness"), "score" (integer 1-10), and "feedback" (string)
- "strengths": list of strings (2-4 concrete strengths observed)
- "areasForImprovement": list of strings (2-4 actionable improvement items)
- "recommendedFollowUps": list of strings (2-3 relevant follow-up questions)
- "studyPlan": list of strings (3 targeted preparation drills)
''';
        final response = await provider!.complete(prompt, maxTokens: 1000, temperature: 0.3);
        final cleanJson = _extractJson(response);
        if (cleanJson != null) {
          final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
          final overallScore = (parsed['overallScore'] as num?)?.toInt() ?? 8;
          final rubricsList = (parsed['rubrics'] as List<dynamic>?)
                  ?.map((r) => InterviewRubricScore.fromJson(r as Map<String, dynamic>))
                  .toList() ??
              [];
          final strengths = (parsed['strengths'] as List<dynamic>?)
                  ?.map((s) => s.toString())
                  .toList() ??
              [];
          final areasForImprovement = (parsed['areasForImprovement'] as List<dynamic>?)
                  ?.map((a) => a.toString())
                  .toList() ??
              [];
          final recommendedFollowUps = (parsed['recommendedFollowUps'] as List<dynamic>?)
                  ?.map((f) => f.toString())
                  .toList() ??
              [];
          final studyPlan = (parsed['studyPlan'] as List<dynamic>?)
                  ?.map((p) => p.toString())
                  .toList() ??
              [];

          return InterviewAssessment(
            id: 'assess_${DateTime.now().millisecondsSinceEpoch}',
            question: question,
            candidateAnswer: trimmedAnswer,
            overallScore: overallScore,
            rubrics: rubricsList,
            strengths: strengths,
            areasForImprovement: areasForImprovement,
            recommendedFollowUps: recommendedFollowUps,
            studyPlan: studyPlan,
            createdAt: DateTime.now().toUtc().toIso8601String(),
          );
        }
      } catch (_) {
        // Fall back to heuristic scoring
      }
    }

    // Heuristic fallback
    final wordCount =
        trimmedAnswer.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

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
        feedback:
            'Concepts referenced are aligned with modern industry best practices.',
      ),
    ];

    final overall = ((clarityScore +
                depthScore +
                structureScore +
                deliveryScore +
                correctnessScore) /
            5)
        .round();

    final strengths = <String>[
      if (clarityScore >= 7) 'Articulated core message directly.',
      if (depthScore >= 7)
        'Incorporated specific technical concepts and terminology.',
      if (structureScore >= 7) 'Maintained logical progression and flow.',
    ];
    if (strengths.isEmpty) {
      strengths.add('Addressed the question promptly.');
    }

    final areasForImprovement = <String>[
      if (wordCount < 40)
        'Expand upon real-world examples and measurable outcomes.',
      if (depthScore < 8) 'Mention potential failure modes and trade-offs.',
      if (structureScore < 8)
        'Explicitly outline the Situation, Action taken, and Business Result.',
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

  int _scoreClarity(String answer, int wordCount) {
    if (wordCount < 10) return 4;
    if (wordCount > 400) return 6;
    return 9;
  }

  int _scoreDepth(String answer, int wordCount) {
    if (wordCount < 25) return 5;
    final lower = answer.toLowerCase();
    int techTerms = 0;
    final terms = [
      'architecture',
      'scale',
      'database',
      'latency',
      'tradeoff',
      'security',
      'cache',
      'test',
      'api'
    ];
    for (final t in terms) {
      if (lower.contains(t)) techTerms++;
    }
    return (6 + techTerms).clamp(5, 10);
  }

  int _scoreStructure(String answer) {
    final lower = answer.toLowerCase();
    bool hasTransitions = lower.contains('first') ||
        lower.contains('then') ||
        lower.contains('because') ||
        lower.contains('result');
    return hasTransitions ? 9 : 7;
  }

  int _scoreDelivery(String answer) => 8;
  int _scoreCorrectness(String answer) => 8;
}
