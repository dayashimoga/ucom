import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_app/providers/in_memory_storage_provider.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/reports/report_screen.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';

void main() {
  group('ReportScreen Widget Tests', () {
    late ConversationController controller;

    setUp(() async {
      controller = ConversationController(
        storageProvider: InMemoryStorageProvider(),
      );
      await controller
          .sendTextInput('We agreed on the sprint plan and assigned tasks.');
      await controller.createReport(ReportType.quickSummary);
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: ReportScreen(controller: controller),
      );
    }

    testWidgets('renders report screen and content preview', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Reports & Intelligence Exports'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(
          find.textContaining('PROVENANCE & EXECUTION AUDIT'), findsOneWidget);
    });

    testWidgets('switches report types via choice chips', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final fullTranscriptChip = find.byType(ChoiceChip).at(2);
      expect(fullTranscriptChip, findsOneWidget);
      await tester.tap(fullTranscriptChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.textContaining('VERBATIM TRANSCRIPT'), findsWidgets);
    });

    testWidgets('exports report via popup menu', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open export menu
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      final mdItem = find.text('Export Markdown (.md)');
      expect(mdItem, findsOneWidget);
      await tester.tap(mdItem);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
