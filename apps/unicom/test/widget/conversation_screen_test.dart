import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/conversation/conversation_screen.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';
import 'package:unicom_app/providers/in_memory_storage_provider.dart';

void main() {
  group('ConversationScreen Widget Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController(
        storageProvider: LocalStorageProvider.inMemory(),
      );
    });

    Widget createTestApp({Size size = const Size(390, 844)}) {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ConversationScreen(controller: controller),
        ),
      );
    }

    testWidgets(
        'renders phone layout with app bar, language selector and action bar',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(ConversationScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('sends message via text field input', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.textContaining('Hola'), findsWidgets);
    });

    testWidgets('triggers voice input on mic icon tap', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(controller.currentConversation.segments, isNotEmpty);
    });

    testWidgets('renders split layout on tablet / desktop viewports',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.byType(ConversationScreen), findsOneWidget);
      expect(find.text('Active Intelligence & Nuance'), findsOneWidget);
    });

    testWidgets('displays actionable error snackbar when error occurs',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      controller.setActionableError(
          'Microphone permission denied. Grant access in system settings.');
      await tester.pump();

      expect(
          find.textContaining('Microphone permission denied'), findsOneWidget);
    });
  });
}
