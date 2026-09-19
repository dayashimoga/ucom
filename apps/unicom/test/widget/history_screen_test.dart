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

    Widget createTestApp() {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: HistoryScreen(controller: controller),
      );
    }

    testWidgets('renders history screen and empty state', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('Conversation History'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays saved conversation and allows interaction',
        (tester) async {
      await controller.sendTextInput('Hello world');
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
      expect(find.byIcon(Icons.copy), findsWidgets);
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    });
  });
}
