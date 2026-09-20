import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../../ui/adaptive/responsive_breakpoints.dart';
import '../conversation/conversation_state_notifier.dart';

class MeetingScreen extends StatefulWidget {
  final ConversationController controller;

  const MeetingScreen({super.key, required this.controller});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final TextEditingController _statementController = TextEditingController();
  String _selectedSpeaker = 'Speaker 1';
  final List<String> _speakers = ['Speaker 1', 'Speaker 2', 'Speaker 3', 'Speaker 4'];

  @override
  void dispose() {
    _statementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final conv = widget.controller.currentConversation;
        final isActive = widget.controller.isMeetingActive;
        final isPaused = widget.controller.isMeetingPaused;
        final isPhone = ResponsiveLayout.isPhone(context);

        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                isPhone ? 'Meeting' : 'Meeting Intelligence & Minutes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            actions: [
              if (!isPhone) ...[
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Minutes'),
                  onPressed: () async {
                    final report =
                        await widget.controller.createReport(ReportType.meetingMinutes);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Meeting minutes generated: ${report.title}'),
                          backgroundColor: UnicomTheme.successGreen,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.description_outlined),
                  tooltip: 'Minutes',
                  onPressed: () async {
                    final report =
                        await widget.controller.createReport(ReportType.meetingMinutes);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Meeting minutes generated: ${report.title}'),
                          backgroundColor: UnicomTheme.successGreen,
                        ),
                      );
                    }
                  },
                ),
              ],
              if (isActive) ...[
                if (!isPhone)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isPaused ? UnicomTheme.warningAmber.withOpacity(0.2) : UnicomTheme.dangerRed.withOpacity(0.2),
                    ),
                    icon: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      size: 18,
                      color: isPaused ? UnicomTheme.warningAmber : UnicomTheme.dangerRed,
                    ),
                    label: Text(
                      isPaused ? 'Resume' : 'Pause',
                      style: TextStyle(
                        color: isPaused ? UnicomTheme.warningAmber : UnicomTheme.dangerRed,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () {
                      if (isPaused) {
                        widget.controller.resumeMeeting();
                      } else {
                        widget.controller.pauseMeeting();
                      }
                    },
                  )
                else
                  IconButton(
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    tooltip: isPaused ? 'Resume' : 'Pause',
                    onPressed: () {
                      if (isPaused) {
                        widget.controller.resumeMeeting();
                      } else {
                        widget.controller.pauseMeeting();
                      }
                    },
                  ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isActive ? UnicomTheme.dangerRed : UnicomTheme.primaryBlue,
                  padding: isPhone ? const EdgeInsets.symmetric(horizontal: 10) : null,
                ),
                icon: Icon(isActive ? Icons.stop : Icons.fiber_manual_record, size: 18),
                label: Text(isActive ? (isPhone ? 'End' : 'End Meeting') : (isPhone ? 'Start' : 'Start Meeting')),
                onPressed: () async {
                  if (isActive) {
                    final report = await widget.controller.stopMeeting();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Meeting ended. Report saved: ${report.title}'),
                          action: SnackBarAction(
                            label: 'View',
                            onPressed: () {
                              // User can navigate to Reports
                            },
                          ),
                        ),
                      );
                    }
                  } else {
                    await widget.controller.startMeeting();
                  }
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              _buildMeetingStatusBar(context, isActive, isPaused),
              Expanded(
                child: isPhone
                    ? _buildPhoneLayout(context, conv)
                    : _buildSplitLayout(context, conv),
              ),
              _buildManualContributionInput(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetingStatusBar(BuildContext context, bool isActive, bool isPaused) {
    if (!isActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).cardColor,
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap "Start Meeting" to capture live audio, transcribe participants, and generate minutes.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    final partial = widget.controller.livePartialTranscript;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isPaused
          ? UnicomTheme.warningAmber.withOpacity(0.15)
          : UnicomTheme.successGreen.withOpacity(0.15),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPaused ? UnicomTheme.warningAmber : UnicomTheme.successGreen,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPaused ? 'Meeting Paused' : 'Recording Continuous Audio...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPaused ? UnicomTheme.warningAmber : UnicomTheme.successGreen,
            ),
          ),
          const SizedBox(width: 12),
          if (partial != null && partial.isNotEmpty)
            Expanded(
              child: Text(
                '"$partial"',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSplitLayout(BuildContext context, Conversation conv) {
    return Row(
      children: [
        Expanded(flex: 6, child: _buildTranscriptList(conv)),
        const VerticalDivider(width: 1, color: UnicomTheme.darkSurfaceVariant),
        Expanded(flex: 4, child: _buildMeetingOutcomes(conv)),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context, Conversation conv) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: UnicomTheme.accentCyan,
            tabs: [
              Tab(icon: Icon(Icons.forum_outlined, size: 18), text: 'Transcript'),
              Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Decisions & Actions'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTranscriptList(conv),
                _buildMeetingOutcomes(conv),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptList(Conversation conv) {
    if (conv.segments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_none, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No Contributions Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                'Speak aloud or type contributions below. Speech will be transcribed live.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conv.segments.length,
      itemBuilder: (context, index) {
        final seg = conv.segments[index];
        final timeStr = DateTime.fromMillisecondsSinceEpoch(seg.startTime);
        final formattedTime =
            '${timeStr.hour.toString().padLeft(2, '0')}:${timeStr.minute.toString().padLeft(2, '0')}:${timeStr.second.toString().padLeft(2, '0')}';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      seg.speakerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: UnicomTheme.primaryBlueLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      seg.originalLanguage.toUpperCase(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(seg.originalText, style: const TextStyle(fontSize: 14)),
                if (seg.translatedText.isNotEmpty && seg.translatedText != seg.originalText) ...[
                  const SizedBox(height: 4),
                  Text(
                    seg.translatedText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: UnicomTheme.accentCyan,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeetingOutcomes(Conversation conv) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Decisions Reached',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (conv.decisions.isEmpty)
          const Text(
            'No formal decisions identified yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          )
        else
          ...conv.decisions.map((d) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box, color: UnicomTheme.successGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(d.decisionText, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 20),
        const Text(
          'Action Items & Deliverables',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (conv.actionItems.isEmpty)
          const Text(
            'No action items assigned yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          )
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
                      Text(
                        'Assignee: ${a.assignee ?? "Unassigned"}',
                        style: const TextStyle(fontSize: 12, color: UnicomTheme.accentCyan),
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 20),
        const Text(
          'Key Questions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (conv.questions.isEmpty)
          const Text(
            'No questions recorded yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          )
        else
          ...conv.questions.map((q) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('• ${q.questionText}', style: const TextStyle(fontSize: 13)),
                ),
              )),
      ],
    );
  }

  Widget _buildManualContributionInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(top: BorderSide(color: UnicomTheme.darkSurfaceVariant)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            DropdownButton<String>(
              value: _selectedSpeaker,
              underline: const SizedBox(),
              items: _speakers
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSpeaker = val);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _statementController,
                decoration: const InputDecoration(
                  hintText: 'Add statement manually...',
                  hintStyle: TextStyle(fontSize: 13),
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
    );
  }

  void _addStatement(String text) {
    if (text.trim().isEmpty) return;
    widget.controller.sendTextInput(text, speakerName: _selectedSpeaker);
    _statementController.clear();
  }
}
