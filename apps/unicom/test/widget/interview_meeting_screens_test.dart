import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    testWidgets(
        'InterviewPracticeScreen renders question and evaluates candidate answer',
        (tester) async {
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

      // Test empty answer validation
      final evalBtn = find.text('Evaluate Answer & Study Plan');
      await tester.tap(evalBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter or dictate an answer first.'),
          findsOneWidget);

      // Cycle question via skip_next icon
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      // Cycle question via New Question text button
      await tester.tap(find.text('New Question'));
      await tester.pumpAndSettle();

      // Tap Speak button
      await tester.tap(find.text('Speak'));
      await tester.pumpAndSettle();

      // Cycle question via popup menu
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuItem<String>).last);
      await tester.pumpAndSettle();

      // Submit an answer
      final answerField = find.byType(TextField);
      await tester.enterText(answerField,
          'In my previous project, we faced high latency so I migrated to an asynchronous event pipeline.');
      await tester.pumpAndSettle();

      await tester.tap(evalBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Overall Score'), findsOneWidget);
      expect(find.text('Rubric Breakdown'), findsOneWidget);

      // Tap Next Interview Question button
      await tester.tap(find.text('Next Interview Question'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'MeetingScreen renders participants, adds statement, and generates minutes',
        (tester) async {
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
      await tester.enterText(inputField,
          'We decided to deploy on Friday. Action item: Bob will verify testing.');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('We decided to deploy on Friday'), findsWidgets);

      // Generate Minutes
      final minutesBtn = find.text('Minutes');
      await tester.tap(minutesBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
        'MeetingScreen lifecycle: Start Meeting, Pause, Resume, End Meeting, and Speaker selection',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: MeetingScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      // Initially inactive
      expect(find.text('Start Meeting'), findsOneWidget);
      expect(find.textContaining('Tap "Start Meeting" to capture live audio'),
          findsOneWidget);

      // Start meeting
      await tester.tap(find.text('Start Meeting'));
      await tester.pumpAndSettle();

      expect(find.text('End Meeting'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Recording Continuous Audio...'), findsOneWidget);

      // Pause meeting
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();

      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Meeting Paused'), findsOneWidget);

      // Resume meeting
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Recording Continuous Audio...'), findsOneWidget);

      // Change speaker
      final speakerDropdown = find.byType(DropdownButton<String>);
      expect(speakerDropdown, findsOneWidget);
      await tester.tap(speakerDropdown);
      await tester.pumpAndSettle();

      final speaker2Item = find.text('Speaker 2').last;
      await tester.tap(speaker2Item);
      await tester.pumpAndSettle();

      // Submit via onSubmitted
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Speaker 2 contribution.');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Submit empty text (does nothing)
      await tester.enterText(inputField, '   ');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // End meeting
      await tester.tap(find.text('End Meeting'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
          find.textContaining('Meeting ended. Report saved'), findsOneWidget);
      expect(find.text('Start Meeting'), findsOneWidget);
    });

    testWidgets('MeetingScreen renders phone layout with TabBar and TabBarView',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.setApplicationMode(ApplicationMode.meeting);
      await controller.sendTextInput('Phone meeting point',
          speakerName: 'Speaker 1');

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: MeetingScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Transcript'), findsOneWidget);
      expect(find.text('Decisions & Actions'), findsOneWidget);

      // Switch tab
      await tester.tap(find.text('Decisions & Actions'));
      await tester.pumpAndSettle();

      expect(find.text('Decisions Reached'), findsOneWidget);
      expect(find.text('Action Items & Deliverables'), findsOneWidget);
    });

    testWidgets(
        'InterviewPracticeScreen exercises role, topic, difficulty dropdowns and displays full assessment cards',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: InterviewPracticeScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      // Change Role dropdown
      final roleDropdown = find.widgetWithText(
          DropdownButtonFormField<String>, 'Principal Systems Architect');
      if (roleDropdown.evaluate().isNotEmpty) {
        await tester.tap(roleDropdown);
        await tester.pumpAndSettle();
        final seniorRole = find.text('Senior AI / ML Engineer').last;
        await tester.tap(seniorRole);
        await tester.pumpAndSettle();
      }

      // Change Topic dropdown
      final topicDropdown = find.widgetWithText(
          DropdownButtonFormField<String>, 'System Architecture & Concurrency');
      if (topicDropdown.evaluate().isNotEmpty) {
        await tester.tap(topicDropdown);
        await tester.pumpAndSettle();
        final privacyTopic = find.text('Data Privacy & Local-First AI').last;
        await tester.tap(privacyTopic);
        await tester.pumpAndSettle();
      }

      // Change Difficulty dropdown
      final diffDropdown =
          find.widgetWithText(DropdownButtonFormField<String>, 'Staff / Lead');
      if (diffDropdown.evaluate().isNotEmpty) {
        await tester.tap(diffDropdown);
        await tester.pumpAndSettle();
        final prinDiff = find.text('Principal / Distinguished').last;
        await tester.tap(prinDiff);
        await tester.pumpAndSettle();
      }

      // Generate question with new parameters
      await tester.tap(find.text('New Question'));
      await tester.pumpAndSettle();

      // Submit comprehensive STAR answer
      final answerField = find.byType(TextField);
      await tester.enterText(
        answerField,
        'Situation: We had high latency in cloud LLM requests. '
        'Task: Reduce response latency to under 50ms while ensuring strict privacy. '
        'Action: I integrated local on-device INT4 quantization and a local RAG cache. '
        'Result: Decreased p99 latency by 85% and eliminated all cloud network dependencies.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Evaluate Answer & Study Plan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Identified Strengths'), findsOneWidget);
      expect(find.text('Missing Concepts & Improvements'), findsOneWidget);
      expect(find.text('Targeted Study Plan'), findsOneWidget);
    });

    testWidgets(
        'MeetingScreen exercises phone controls and status bar with partial transcript',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: MeetingScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      // Start meeting on phone
      final startBtn = find.text('Start');
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(controller.isMeetingActive, isTrue);

      // Simulate partial transcript in status bar
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const codec = StandardMethodCodec();

        await messenger.handlePlatformMessage(
          'com.unicom.ai/speech',
          codec.encodeMethodCall(const MethodCall(
              'onPartialTranscript', {'text': 'Phone partial meeting speech'})),
          (data) {},
        );
        await tester.pump();
        expect(find.textContaining('Phone partial meeting speech'),
            findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      // Pause via phone icon button
      final pauseBtn = find.byIcon(Icons.pause);
      expect(pauseBtn, findsOneWidget);
      await tester.tap(pauseBtn);
      await tester.pumpAndSettle();
      expect(controller.isMeetingPaused, isTrue);

      // Resume via phone icon button
      final resumeBtn = find.byIcon(Icons.play_arrow);
      expect(resumeBtn, findsOneWidget);
      await tester.tap(resumeBtn);
      await tester.pumpAndSettle();
      expect(controller.isMeetingPaused, isFalse);

      // Tap Minutes on phone
      final minutesBtn = find.byIcon(Icons.description_outlined);
      expect(minutesBtn, findsOneWidget);
      await tester.tap(minutesBtn);
      await tester.pumpAndSettle();

      // End meeting via phone button
      final endBtn = find.text('End');
      expect(endBtn, findsOneWidget);
      await tester.tap(endBtn);
      await tester.pumpAndSettle();
      expect(controller.isMeetingActive, isFalse);
    });
  });
}
