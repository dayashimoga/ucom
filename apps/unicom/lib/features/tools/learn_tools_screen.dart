import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';
import '../interview/interview_practice_screen.dart';
import '../meeting/meeting_screen.dart';
import '../reports/report_screen.dart';

class LearnToolsScreen extends StatelessWidget {
  final ConversationController controller;

  const LearnToolsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Intelligence Tools'),
          bottom: const TabBar(
            isScrollable: false,
            indicatorColor: UnicomTheme.accentCyan,
            tabs: [
              Tab(
                icon: Icon(Icons.school_outlined, size: 20),
                text: 'Interview',
              ),
              Tab(
                icon: Icon(Icons.groups_outlined, size: 20),
                text: 'Meeting',
              ),
              Tab(
                icon: Icon(Icons.description_outlined, size: 20),
                text: 'Reports',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            InterviewPracticeScreen(controller: controller),
            MeetingScreen(controller: controller),
            ReportScreen(controller: controller),
          ],
        ),
      ),
    );
  }
}
