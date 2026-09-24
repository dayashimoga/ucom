import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';
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

  String _selectedRole = 'Software Architect';
  String _selectedTopic = 'System Architecture & Concurrency';
  String _selectedDifficulty = 'Senior';

  static const List<String> _roles = [
    'Software Architect',
    'Mobile / Flutter Engineer',
    'AI / ML Systems Engineer',
    'DevOps & Site Reliability',
    'Product Manager',
  ];

  static const List<String> _topics = [
    'System Architecture & Concurrency',
    'Incident Mitigation & Reliability',
    'Database Migrations & Distributed Cache',
    'Data Privacy & Local-First AI',
    'Algorithmic Complexity & Trade-offs',
  ];

  static const List<String> _difficulties = [
    'Mid-Level',
    'Senior',
    'Staff / Principal',
  ];

  String _currentQuestion =
      'Describe an architectural decision you made and how you balanced trade-offs under high concurrency.';
  InterviewAssessment? _latestAssessment;
  bool _isEvaluating = false;
  bool _isGeneratingQuestion = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _generateNewQuestion() async {
    setState(() {
      _isGeneratingQuestion = true;
      _latestAssessment = null;
      _answerController.clear();
    });

    try {
      if (widget.controller.executionMode != ExecutionMode.privateOffline &&
          widget.controller.router.configuredProviders.isNotEmpty) {
        final prompt =
            'Generate one challenging, realistic technical interview question for a $_selectedDifficulty candidate applying for a $_selectedRole position, focusing on $_selectedTopic. Return only the question text.';
        final aiQ = await widget.controller.router
            .complete(prompt, maxTokens: 120, temperature: 0.7);
        if (aiQ.trim().isNotEmpty &&
            !aiQ.toLowerCase().contains('unsupported')) {
          setState(() {
            _currentQuestion = aiQ.replaceAll(RegExp(r'^["\s]+|["\s]+$'), '');
            _isGeneratingQuestion = false;
          });
          return;
        }
      }

      // Offline / curated fallback matching role and topic
      final pool = _curatedPool[_selectedTopic] ??
          [
            'Describe an architectural decision you made and how you balanced trade-offs under high concurrency.',
            'Tell me about a time when a production incident occurred. How did you diagnose, mitigate, and remediate it?',
          ];
      final nextQ =
          pool[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % pool.length];
      setState(() {
        _currentQuestion = nextQ;
        _isGeneratingQuestion = false;
      });
    } catch (_) {
      setState(() => _isGeneratingQuestion = false);
    }
  }

  static const Map<String, List<String>> _curatedPool = {
    'System Architecture & Concurrency': [
      'Describe an architectural decision you made and how you balanced trade-offs under high concurrency.',
      'Explain the differences between optimistic and pessimistic locking and when you would select each in a distributed ledger.',
      'How do you design a thread-safe connection pool with backpressure in reactive microservices?',
    ],
    'Incident Mitigation & Reliability': [
      'Tell me about a time when a critical production outage occurred. How did you diagnose, mitigate, and remediate it?',
      'How do you implement circuit breakers and graceful degradation when upstream payment or AI APIs fail?',
    ],
    'Database Migrations & Distributed Cache': [
      'How do you approach database schema migrations in zero-downtime microservice or local-first environments?',
      'How do you design a distributed cache invalidation strategy to prevent cache stampedes and stale data?',
    ],
    'Data Privacy & Local-First AI': [
      'Describe how you enforce strict data privacy invariants and prevent data egress in local-first AI applications.',
      'How do you handle client-side model quantization and memory boundaries on low-RAM mobile devices?',
    ],
    'Algorithmic Complexity & Trade-offs': [
      'Walk me through how you profile CPU spikes, memory leaks, and GC pauses in high-throughput applications.',
      'Explain how a B-Tree compares to an LSM-tree for write-heavy vs read-heavy database storage engines.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Practice & Coaching',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Select Question',
            onSelected: (q) {
              setState(() {
                _currentQuestion = q;
                _latestAssessment = null;
                _answerController.clear();
              });
            },
            itemBuilder: (ctx) => _curatedPool.values
                .expand((i) => i)
                .map((q) => PopupMenuItem(
                    value: q,
                    child:
                        Text(q, maxLines: 1, overflow: TextOverflow.ellipsis)))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Next Question',
            onPressed: _generateNewQuestion,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Transparency Notice
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
                    'Transparency Notice: Practice Drill designed for interview preparation, STAR technique coaching, and study plans.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Role, Topic & Difficulty Selectors
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: UnicomTheme.accentCyan, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Practice Drill Setup',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Role
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _roles
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child:
                                Text(r, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  // Topic
                  DropdownButtonFormField<String>(
                    value: _selectedTopic,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _topics
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTopic = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  // Difficulty
                  DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seniority Level',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _difficulties
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child:
                                Text(d, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDifficulty = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      icon: _isGeneratingQuestion
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('New Question',
                          style: TextStyle(fontSize: 12)),
                      onPressed:
                          _isGeneratingQuestion ? null : _generateNewQuestion,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Current Question Card
          Card(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.quiz,
                          color: UnicomTheme.accentCyan, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_selectedRole • $_selectedDifficulty',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentQuestion,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Answer Input
          TextField(
            controller: _answerController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'Type or speak your answer (use STAR: Situation, Task, Action, Result)...',
              hintStyle: const TextStyle(fontSize: 13),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: _isEvaluating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.analytics, size: 18),
                  label: const Text('Evaluate Answer & Study Plan'),
                  onPressed: _isEvaluating ? null : _evaluateCurrentAnswer,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.mic, size: 18),
                label: const Text('Speak'),
                onPressed: () {
                  widget.controller.startVoiceInput();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Assessment Results
          if (_latestAssessment != null) ...[
            _buildAssessmentCard(_latestAssessment!),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Interview Question'),
              onPressed: _generateNewQuestion,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _evaluateCurrentAnswer() async {
    final ans = _answerController.text.trim();
    if (ans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter or dictate an answer first.')),
      );
      return;
    }

    setState(() => _isEvaluating = true);
    try {
      final evaluator = InterviewEvaluator(
        widget.controller.executionMode != ExecutionMode.privateOffline
            ? widget.controller.router
            : null,
      );
      final assessment = await evaluator.evaluateAnswer(
        question: _currentQuestion,
        candidateAnswer: ans,
      );
      setState(() {
        _latestAssessment = assessment;
        _isEvaluating = false;
      });
    } catch (e) {
      setState(() => _isEvaluating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evaluation failed: ${e.toString()}')),
        );
      }
    }
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
                Text(
                  '${a.overallScore} / 10',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: UnicomTheme.primaryBlueLight,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Rubric Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...a.rubrics.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.criterion.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text('${r.score}/10',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.score / 10.0,
                          minHeight: 6,
                          color: r.score >= 7
                              ? UnicomTheme.accentCyan
                              : UnicomTheme.warningAmber,
                        ),
                      ),
                      if (r.feedback.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(r.feedback,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text('Identified Strengths',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: UnicomTheme.successGreen)),
            const SizedBox(height: 4),
            ...a.strengths.map((s) => Text('• $s',
                style: const TextStyle(fontSize: 13, height: 1.4))),
            const SizedBox(height: 12),
            const Text('Missing Concepts & Improvements',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: UnicomTheme.warningAmber)),
            const SizedBox(height: 4),
            ...a.areasForImprovement.map((imp) => Text('• $imp',
                style: const TextStyle(fontSize: 13, height: 1.4))),
            const SizedBox(height: 12),
            const Text('Targeted Study Plan',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: UnicomTheme.primaryBlueLight)),
            const SizedBox(height: 4),
            ...a.studyPlan.map((p) => Text('• $p',
                style: const TextStyle(fontSize: 13, height: 1.4))),
          ],
        ),
      ),
    );
  }
}
