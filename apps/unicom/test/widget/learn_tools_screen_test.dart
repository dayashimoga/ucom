import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';
import 'package:unicom_app/features/tools/learn_tools_screen.dart';
import 'package:unicom_app/providers/in_memory_storage_provider.dart';

void main() {
  group('LearnToolsScreen Widget Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController(
        storageProvider: LocalStorageProvider.inMemory(),
      );
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: LearnToolsScreen(controller: controller),
      );
    }

    testWidgets('renders all tabs and switches views on tap', (tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Intelligence Tools'), findsOneWidget);
      expect(find.text('Interview'), findsOneWidget);
      expect(find.text('Meeting'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      // Switch to Meeting tab
      await tester.tap(find.text('Meeting'));
      await tester.pumpAndSettle();
      expect(find.text('Meeting Intelligence & Minutes'), findsOneWidget);

      // Switch to Reports tab
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.text('Reports & Intelligence Exports'), findsOneWidget);

      // Switch back to Interview tab
      await tester.tap(find.text('Interview'));
      await tester.pumpAndSettle();
      expect(find.text('Interview Practice & Coaching'), findsOneWidget);
    });
  });
}
