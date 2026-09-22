import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/settings/settings_screen.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';
import 'package:unicom_app/providers/in_memory_storage_provider.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController(
        storageProvider: LocalStorageProvider.inMemory(),
      );
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: SettingsScreen(controller: controller),
      );
    }

    testWidgets('renders all 7 required settings sections', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language & Voice'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Offline Downloads'), findsOneWidget);
      expect(find.text('Privacy & History'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('selects languages via modal bottom sheet and toggles auto-tts',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open Primary Language picker
      await tester.tap(find.text('Primary Language'));
      await tester.pumpAndSettle();

      expect(find.text('Select Primary Language'), findsOneWidget);
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

      // Toggle Auto-TTS
      final initialTts = controller.autoTts;
      await tester.tap(find.text('Audible Speech Output (Auto-TTS)'));
      await tester.pumpAndSettle();
      expect(controller.autoTts, equals(!initialTts));
    });

    testWidgets('switches AI execution modes via radio buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Automatic (Best Available)
      final autoTile = find.text('Automatic (Best Available)');
      await tester.tap(autoTile);
      await tester.pumpAndSettle();
      expect(controller.executionMode, equals(ExecutionMode.auto));

      // Tap Cloud Enhanced
      final cloudTile = find.text('Cloud Enhanced');
      await tester.tap(cloudTile);
      await tester.pumpAndSettle();
      expect(controller.executionMode, equals(ExecutionMode.cloud));

      // Tap Private Offline
      final offlineTile = find.text('Private Offline');
      await tester.tap(offlineTile);
      await tester.pumpAndSettle();
      expect(controller.executionMode, equals(ExecutionMode.privateOffline));
    });

    testWidgets('navigates to AI providers screen', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final manageBtn = find.text('Manage AI Providers & Routing');
      await tester.tap(manageBtn);
      await tester.pumpAndSettle();

      // Should be on AI Providers screen
      expect(find.text('AI Providers'), findsOneWidget);

      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.pop();
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to Model & Language Pack Manager', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final modelTile = find.text('Model & Language Pack Manager');
      await tester.tap(modelTile);
      await tester.pumpAndSettle();

      // Should be on Model & Language Pack Manager screen
      expect(find.text('Model & Language Pack Manager'), findsWidgets);

      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.pop();
      await tester.pumpAndSettle();
    });

    testWidgets('executes data purge in Privacy & History', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final clearBtn = find.widgetWithText(OutlinedButton, 'Clear All');
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Clear All Conversation Data?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('All local conversation data cleared.'), findsOneWidget);
    });

    testWidgets('toggles visual appearance themes', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Switch to Light theme
      final lightBtn = find.text('Light');
      await tester.tap(lightBtn);
      await tester.pumpAndSettle();
      expect(controller.themeMode, equals(ThemeMode.light));

      // Switch to Dark theme
      final darkBtn = find.text('Dark');
      await tester.tap(darkBtn);
      await tester.pumpAndSettle();
      expect(controller.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('expands Advanced section and displays AICore status & specs',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Expand Advanced
      final advancedTile = find.text('Advanced');
      await tester.tap(advancedTile);
      await tester.pumpAndSettle();

      expect(find.text('Android AICore (Gemini Nano)'), findsOneWidget);
      expect(find.text('Architecture & Quantization Specs'), findsOneWidget);
      expect(find.text('Zero-Network Gate Status'), findsOneWidget);
    });
  });
}
