import 'package:flutter/material.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import '../features/conversation/conversation_state_notifier.dart';
import '../features/conversation/conversation_screen.dart';
import '../features/history/history_screen.dart';
import '../features/tools/learn_tools_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'UNICOM AI',
          debugShowCheckedModeBanner: false,
          theme: UnicomTheme.lightTheme,
          darkTheme: UnicomTheme.darkTheme,
          themeMode: widget.controller.themeMode,
          home: _buildAdaptiveShell(context),
        );
      },
    );
  }

  Widget _buildAdaptiveShell(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final isDesktopOrTablet = !ResponsiveLayout.isPhone(ctx);

        final screens = [
          ConversationScreen(controller: widget.controller),
          HistoryScreen(
            controller: widget.controller,
            onOpenLive: () => setState(() => _currentIndex = 0),
          ),
          LearnToolsScreen(controller: widget.controller),
          SettingsScreen(controller: widget.controller),
        ];

        if (isDesktopOrTablet) {
          return Scaffold(
            body: Row(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: NavigationRail(
                            selectedIndex: _currentIndex,
                            onDestinationSelected: (idx) =>
                                setState(() => _currentIndex = idx),
                            labelType: constraints.maxHeight < 550
                                ? NavigationRailLabelType.none
                                : NavigationRailLabelType.all,
                            leading: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical:
                                      constraints.maxHeight < 550 ? 8 : 16),
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: UnicomTheme.primaryBlue,
                                child: Icon(Icons.hub,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.chat_bubble_outline),
                                selectedIcon: Icon(Icons.chat_bubble),
                                label: Text('Live'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.history_outlined),
                                selectedIcon: Icon(Icons.history),
                                label: Text('History'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.widgets_outlined),
                                selectedIcon: Icon(Icons.widgets),
                                label: Text('Tools'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings_outlined),
                                selectedIcon: Icon(Icons.settings),
                                label: Text('Settings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Live',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.widgets_outlined),
                selectedIcon: Icon(Icons.widgets),
                label: 'Tools',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
