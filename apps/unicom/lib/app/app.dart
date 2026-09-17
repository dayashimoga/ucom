import 'package:flutter/material.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import '../features/conversation/conversation_state_notifier.dart';
import '../features/conversation/conversation_screen.dart';
import '../features/interview/interview_practice_screen.dart';
import '../features/meeting/meeting_screen.dart';
import '../features/reports/report_screen.dart';
import '../features/models/model_manager_screen.dart';
import '../features/settings/settings_screen.dart';
import '../ui/adaptive/responsive_breakpoints.dart';
import 'theme.dart';

class UnicomApp extends StatefulWidget {
  final ConversationController controller;
  final LocalModelManager modelManager;

  const UnicomApp({
    super.key,
    required this.controller,
    required this.modelManager,
  });

  @override
  State<UnicomApp> createState() => _UnicomAppState();
}

class _UnicomAppState extends State<UnicomApp> {
  int _currentIndex = 0;
  final ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNICOM AI',
      debugShowCheckedModeBanner: false,
      theme: UnicomTheme.lightTheme,
      darkTheme: UnicomTheme.darkTheme,
      themeMode: _themeMode,
      home: _buildAdaptiveShell(context),
    );
  }

  Widget _buildAdaptiveShell(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final isDesktopOrTablet = !ResponsiveLayout.isPhone(ctx);

        final screens = [
          ConversationScreen(controller: widget.controller),
          InterviewPracticeScreen(controller: widget.controller),
          MeetingScreen(controller: widget.controller),
          ReportScreen(controller: widget.controller),
          ModelManagerScreen(modelManager: widget.modelManager),
          SettingsScreen(controller: widget.controller),
        ];

        if (isDesktopOrTablet) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: UnicomTheme.primaryBlue,
                      child: Icon(Icons.hub, color: Colors.white, size: 22),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: Text('Live')),
                    NavigationRailDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: Text('Interview')),
                    NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: Text('Meeting')),
                    NavigationRailDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: Text('Reports')),
                    NavigationRailDestination(icon: Icon(Icons.memory_outlined), selectedIcon: Icon(Icons.memory), label: Text('Models')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: screens[_currentIndex]),
              ],
            ),
          );
        }

        // Phone Layout
        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Live'),
              NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Interview'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Meeting'),
              NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Reports'),
              NavigationDestination(icon: Icon(Icons.memory_outlined), selectedIcon: Icon(Icons.memory), label: 'Models'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }
}
