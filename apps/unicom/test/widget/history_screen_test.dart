import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';
import 'package:unicom_app/features/history/history_screen.dart';
import 'package:unicom_app/providers/in_memory_storage_provider.dart';

void main() {
  group('HistoryScreen Widget Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController(
        storageProvider: LocalStorageProvider.inMemory(),
      );
    });

    Widget createTestApp({VoidCallback? onOpenLive}) {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: HistoryScreen(
          controller: controller,
          onOpenLive: onOpenLive,
        ),
      );
    }

    testWidgets('renders history screen and empty state', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('Conversation History'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('No Saved Conversations'), findsOneWidget);
    });

    testWidgets('displays saved conversation and filters with search',
        (tester) async {
      await controller.sendTextInput('Hello world');
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
      expect(find.byIcon(Icons.copy), findsWidgets);
      expect(find.byIcon(Icons.delete_outline), findsWidgets);

      // Search matching term
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Hello');
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsWidgets);

      // Search non-matching term
      await tester.enterText(searchField, 'NonexistentXYZ');
      await tester.pumpAndSettle();
      expect(find.text('No Saved Conversations'), findsOneWidget);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('loads conversation session on card tap', (tester) async {
      await controller.sendTextInput('Architecture session test');
      bool openedLive = false;

      await tester.pumpWidget(createTestApp(onOpenLive: () {
        openedLive = true;
      }));
      await tester.pumpAndSettle();

      final card = find.byType(Card).first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(openedLive, isTrue);
      expect(find.textContaining('Loaded session:'), findsOneWidget);
    });

    testWidgets('copies conversation to clipboard', (tester) async {
      await controller.sendTextInput('Copy test transcript');
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final copyBtn = find.byIcon(Icons.copy).first;
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Copied conversation to clipboard'), findsOneWidget);
    });

    testWidgets('deletes conversation after dialog confirmation',
        (tester) async {
      await controller.sendTextInput('Session to delete');
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final deleteBtn = find.byIcon(Icons.delete_outline).first;
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete Conversation'), findsOneWidget);

      // Tap Delete in dialog
      final confirmBtn = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('No Saved Conversations'), findsOneWidget);
    });

    testWidgets('clears all conversations from app bar action', (tester) async {
      await controller.sendTextInput('Session 1');
      await controller.sendTextInput('Session 2');
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final clearAllBtn = find.byIcon(Icons.delete_sweep_outlined);
      await tester.tap(clearAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('Clear All History'), findsOneWidget);

      // Tap Clear All in dialog
      final confirmClear = find.widgetWithText(FilledButton, 'Clear All');
      await tester.tap(confirmClear);
      await tester.pumpAndSettle();

      expect(find.text('No Saved Conversations'), findsOneWidget);
    });
  });
}
