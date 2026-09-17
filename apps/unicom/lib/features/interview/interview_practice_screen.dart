import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';

class InterviewPracticeScreen extends StatefulWidget {
  final ConversationController controller;

  const InterviewPracticeScreen({super.key, required this.controller});

  @override
  State<InterviewPracticeScreen> createState() =>
      _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState extends State<InterviewPracticeScreen> {
  final TextEditingController _answerController = TextEditingController();
  String _activeQuestion =
      'Describe an architectural decision you made and how you balanced trade-offs under high concurrency.';
  InterviewAssessment? _latestAssessment;
  bool _isEvaluating = false;

  static const List<String> _sampleQuestions = [
    'Describe an architectural decision you made and how you balanced trade-offs under high concurrency.',
    'Tell me about a time when a production incident occurred. How did you diagnose, mitigate, and remediate it?',
    'How do you approach database schema migrations in zero-downtime microservice or local-first environments?',
    'Explain the differences between optimistic and pessimistic locking and when you would select each.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Practice & Coaching'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Non-covert compliance notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: UnicomTheme.warningAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: UnicomTheme.warningAmber.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.gavel, color: UnicomTheme.warningAmber, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transparency Notice: UNICOM Interview Mode is designed for pre-interview drills, permitted accessibility, and post-session study plans. It is not designed for covert live cheating.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Current Question Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.quiz,
                          color: UnicomTheme.accentCyan, size: 20),
                      const SizedBox(width: 8),
                      const Text('Active Prompt',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.swap_horiz, size: 20),
                        tooltip: 'Switch Question',
                        onSelected: (q) => setState(() => _activeQuestion = q),
                        itemBuilder: (context) => _sampleQuestions
                            .map((q) => PopupMenuItem(
                                value: q,
                                child: Text(q,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_activeQuestion,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Candidate Answer Field
          TextField(
            controller: _answerController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'Type or dictate your response (e.g. using STAR method: Situation, Task, Action, Result)...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: Theme.of(context).cardTheme.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                icon: _isEvaluating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.analytics),
                label: const Text('Evaluate Answer & Study Plan'),
                onPressed: _isEvaluating ? null : _evaluateCurrentAnswer,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text('Speak Response'),
                onPressed: () {
                  widget.controller.startVoiceInput().then((_) {
                    if (widget
                        .controller.currentConversation.segments.isNotEmpty) {
                      _answerController.text = widget.controller
                          .currentConversation.segments.last.originalText;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Assessment Results
          if (_latestAssessment != null) ...[
            _buildAssessmentCard(_latestAssessment!),
          ],
        ],
      ),
    );
  }

  Future<void> _evaluateCurrentAnswer() async {
    final ans = _answerController.text.trim();
    if (ans.isEmpty) return;

    setState(() => _isEvaluating = true);
    final assessment =
        await widget.controller.interviewEvaluator.evaluateAnswer(
      question: _activeQuestion,
      candidateAnswer: ans,
    );
    setState(() {
      _latestAssessment = assessment;
      _isEvaluating = false;
    });
  }

  Widget _buildAssessmentCard(InterviewAssessment a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: UnicomTheme.successGreen),
                const SizedBox(width: 8),
                const Text('Overall Score',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('${a.overallScore} / 10',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: UnicomTheme.primaryBlueLight)),
              ],
            ),
            const Divider(height: 24),
            const Text('Rubric Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...a.rubrics.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 120,
                          child: Text(r.criterion.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: r.score / 10.0,
                              minHeight: 8,
                              color: UnicomTheme.accentCyan),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${r.score}/10',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text('Identified Strengths',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: UnicomTheme.successGreen)),
            ...a.strengths.map((s) => Text('• $s',
                style: const TextStyle(fontSize: 13, height: 1.4))),
            const SizedBox(height: 12),
            const Text('Areas for Improvement',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: UnicomTheme.warningAmber)),
            ...a.areasForImprovement.map((imp) => Text('• $imp',
                style: const TextStyle(fontSize: 13, height: 1.4))),
            const SizedBox(height: 12),
            const Text('Targeted Study Plan',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: UnicomTheme.primaryBlueLight)),
            ...a.studyPlan.map((p) => Text('• $p',
                style: const TextStyle(fontSize: 13, height: 1.4))),
          ],
        ),
      ),
    );
  }
}
