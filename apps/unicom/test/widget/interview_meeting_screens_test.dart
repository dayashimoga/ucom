import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_app/providers/in_memory_storage_provider.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/interview/interview_practice_screen.dart';
import 'package:unicom_app/features/meeting/meeting_screen.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';

void main() {
  group('Interview & Meeting Screens Widget Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController(
        storageProvider: InMemoryStorageProvider(),
      );
    });

    testWidgets('InterviewPracticeScreen renders question and evaluates candidate answer', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: InterviewPracticeScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Interview Practice & Coaching'), findsOneWidget);
      expect(find.textContaining('Transparency Notice'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

      // Cycle question via popup menu
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuItem<String>).last);
      await tester.pumpAndSettle();

      // Submit an answer
      final answerField = find.byType(TextField);
      await tester.enterText(answerField, 'In my previous project, we faced high latency so I migrated to an asynchronous event pipeline.');
      await tester.pumpAndSettle();

      final evalBtn = find.text('Evaluate Answer & Study Plan');
      await tester.tap(evalBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Overall Score'), findsOneWidget);
      expect(find.text('Rubric Breakdown'), findsOneWidget);
    });

    testWidgets('MeetingScreen renders participants, adds statement, and generates minutes', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.setApplicationMode(ApplicationMode.meeting);

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: MeetingScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Meeting Intelligence & Minutes'), findsOneWidget);
      expect(find.text('Decisions Reached'), findsOneWidget);
      expect(find.text('Action Items & Deliverables'), findsOneWidget);

      // Add a meeting statement
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'We decided to deploy on Friday. Action item: Bob will verify testing.');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.textContaining('We decided to deploy on Friday'), findsWidgets);

      // Generate Minutes
      final minutesBtn = find.text('Minutes');
      await tester.tap(minutesBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
