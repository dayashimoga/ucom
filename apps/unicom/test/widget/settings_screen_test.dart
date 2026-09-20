import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/settings/settings_screen.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController();
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: SettingsScreen(controller: controller),
      );
    }

    testWidgets('renders all settings cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('AI & System Settings'), findsOneWidget);
      expect(find.text('Language & Speech'), findsOneWidget);
      expect(find.text('AI Execution Tier & Privacy'), findsOneWidget);
      expect(find.text('Android Built-in AI (AICore)'), findsOneWidget);
      expect(find.text('Downloaded Local Models'), findsOneWidget);
      expect(find.text('Cloud AI & Model Configuration'), findsOneWidget);
      expect(find.text('Active Intelligence Mode'), findsOneWidget);
      expect(find.text('Data Hygiene & Retention'), findsOneWidget);
      expect(find.text('About UNICOM AI'), findsOneWidget);
      expect(find.text('Advanced: AI & Models'), findsOneWidget);
    });

    testWidgets('selects languages via modal bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open Primary Language picker
      await tester.tap(find.text('Primary Language'));
      await tester.pumpAndSettle();

      expect(find.text('Select Source Language'), findsOneWidget);
      await tester.tap(find.text('Tamil'));
      await tester.pumpAndSettle();
      expect(controller.sourceLanguage, equals('ta'));

      // Open Translation Target picker
      await tester.tap(find.text('Translation Target'));
      await tester.pumpAndSettle();

      expect(find.text('Select Target Language'), findsOneWidget);
      await tester.tap(find.text('Spanish'));
      await tester.pumpAndSettle();
      expect(controller.targetLanguage, equals('es'));
    });

    testWidgets('switches AI execution modes via radio buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Hybrid mode
      final hybridTile = find.text('Hybrid Mode');
      await tester.tap(hybridTile);
      await tester.pumpAndSettle();
      expect(controller.executionMode, equals(ExecutionMode.hybrid));

      // Tap Cloud Preferred mode
      final cloudTile = find.text('Cloud Preferred');
      await tester.tap(cloudTile);
      await tester.pumpAndSettle();
      expect(controller.executionMode, equals(ExecutionMode.cloud));

      // Tap Offline Only
      final offlineTile = find.text('Offline Only (Strict Privacy Invariant)');
      await tester.tap(offlineTile);
      await tester.pumpAndSettle();
      expect(controller.executionMode, equals(ExecutionMode.privateOffline));
    });

    testWidgets('enters API key and tests connection in settings',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField);
      await tester.enterText(apiKeyField, 'ai_key_test_12345');
      await tester.pumpAndSettle();

      // Find Test Connection button
      final testBtn = find.widgetWithText(ElevatedButton, 'Test');
      await tester.tap(testBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(controller.cloudApiKey, equals('ai_key_test_12345'));
    });

    testWidgets('changes application mode to interview practice',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap the dropdown to open it
      final dropdown = find.byType(DropdownButtonFormField<ApplicationMode>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final interviewChoice =
          find.text('Interview Practice & Rubric Coaching').last;
      await tester.tap(interviewChoice);
      await tester.pumpAndSettle();

      expect(controller.mode, equals(ApplicationMode.interviewPractice));
    });

    testWidgets('executes data purge in hygiene card', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final purgeBtn = find.text('Clear All Local Data');
      await tester.tap(purgeBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('expands advanced section and toggles appearance',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Expand Advanced: AI & Models
      final advancedTile = find.text('Advanced: AI & Models');
      await tester.tap(advancedTile);
      await tester.pumpAndSettle();

      expect(find.text('Architecture & Quantization'), findsOneWidget);
      expect(find.text('Network Gate Status'), findsOneWidget);

      // Toggle Theme
      final lightBtn = find.text('Light');
      await tester.tap(lightBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('AICore info dialog and action chips in settings',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Learn About Device Support
      final learnChip = find.text('Learn About Device Support');
      await tester.tap(learnChip);
      await tester.pumpAndSettle();

      expect(find.text('Android AICore Support'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Downloaded Local Models tile
      final modelsTile = find.text('Downloaded Local Models');
      await tester.tap(modelsTile);
      await tester.pumpAndSettle();

      // Pop back to settings
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // Tap All Providers button
      final allProvidersBtn = find.text('All Providers');
      await tester.tap(allProvidersBtn);
      await tester.pumpAndSettle();

      navigator.pop();
      await tester.pumpAndSettle();
    });
  });
}
