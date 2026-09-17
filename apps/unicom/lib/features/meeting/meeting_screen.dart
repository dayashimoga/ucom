import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';

class MeetingScreen extends StatefulWidget {
  final ConversationController controller;

  const MeetingScreen({super.key, required this.controller});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final TextEditingController _statementController = TextEditingController();
  String _selectedSpeaker = 'Alice';

  final List<String> _speakers = ['Alice', 'Bob', 'Charlie', 'Diana'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final conv = widget.controller.currentConversation;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Meeting Intelligence & Minutes'),
            actions: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.description, size: 18),
                label: const Text('Minutes'),
                onPressed: () async {
                  await widget.controller.createReport(ReportType.meetingMinutes);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meeting Minutes generated and saved to Reports.')),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Row(
            children: [
              // Left: Transcript stream
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: conv.segments.length,
                        itemBuilder: (context, index) {
                          final seg = conv.segments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(seg.speakerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: UnicomTheme.primaryBlueLight)),
                                      const Spacer(),
                                      Text(seg.originalLanguage.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(seg.originalText, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Statement Input
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        border: const Border(top: BorderSide(color: UnicomTheme.darkSurfaceVariant)),
                      ),
                      child: Row(
                        children: [
                          DropdownButton<String>(
                            value: _selectedSpeaker,
                            underline: const SizedBox(),
                            items: _speakers.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSpeaker = val);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _statementController,
                              decoration: const InputDecoration(
                                hintText: 'Enter speaker contribution...',
                                border: InputBorder.none,
                              ),
                              onSubmitted: _addStatement,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: UnicomTheme.accentCyan),
                            onPressed: () => _addStatement(_statementController.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, color: UnicomTheme.darkSurfaceVariant),
              // Right: Real-time Agenda, Decisions, and Action Items
              Expanded(
                flex: 4,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Decisions Reached', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    if (conv.decisions.isEmpty)
                      const Text('No formal decisions recorded yet.', style: TextStyle(fontSize: 13, color: Colors.grey))
                    else
                      ...conv.decisions.map((d) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_box, color: UnicomTheme.successGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(d.decisionText, style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            ),
                          )),
                    const SizedBox(height: 16),
                    const Text('Action Items & Deliverables', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    if (conv.actionItems.isEmpty)
                      const Text('No action items assigned yet.', style: TextStyle(fontSize: 13, color: Colors.grey))
                    else
                      ...conv.actionItems.map((a) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('Assignee: ${a.assignee ?? "Unassigned"}', style: const TextStyle(fontSize: 12, color: UnicomTheme.accentCyan)),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addStatement(String text) {
    if (text.trim().isEmpty) return;
    widget.controller.sendTextInput(text, speakerName: _selectedSpeaker);
    _statementController.clear();
  }
}
