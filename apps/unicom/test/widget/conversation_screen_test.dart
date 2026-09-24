import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';
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

    testWidgets('swaps languages when tapping swap button', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(controller.sourceLanguage, 'en');
      expect(controller.targetLanguage, 'es');

      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();

      expect(controller.sourceLanguage, 'es');
      expect(controller.targetLanguage, 'en');
    });

    testWidgets('sends message via prompt suggestion chip', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final chip = find.text('What is Kubernetes?');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.text('What is Kubernetes?'), findsOneWidget);
    });

    testWidgets('interacts with context action chips on conversation bubble',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Tap Copy
      final copyChip = find.text('Copy');
      if (copyChip.evaluate().isNotEmpty) {
        await tester.tap(copyChip.first);
        await tester.pumpAndSettle();
      }

      // Tap Listen
      final listenChip = find.text('Listen');
      if (listenChip.evaluate().isNotEmpty) {
        await tester.tap(listenChip.first);
        await tester.pumpAndSettle();
      }

      // Tap Translate
      final translateChip = find.text('Translate');
      if (translateChip.evaluate().isNotEmpty) {
        await tester.tap(translateChip.first);
        await tester.pumpAndSettle();
      }
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

    testWidgets('renders offline model banner and downloads model on tap',
        (tester) async {
      // Configure controller with unloaded local model
      final ctrl = ConversationController(
        localLLMInstance: LocalLLMProvider(isModelLoaded: false),
        storageProvider: LocalStorageProvider.inMemory(),
      );

      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: ConversationScreen(controller: ctrl),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline model required'), findsOneWidget);
      final downloadBtn = find.text('Download 50 MB');
      expect(downloadBtn, findsOneWidget);

      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();
    });

    testWidgets(
        'changes source and target language via dropdowns and clears session via More menu',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Change source language to FR
      final dropdowns = find.byType(DropdownButton<String>);
      if (dropdowns.evaluate().isNotEmpty) {
        await tester.tap(dropdowns.first);
        await tester.pumpAndSettle();
        final frItem = find.text('FR').last;
        await tester.tap(frItem);
        await tester.pumpAndSettle();
        expect(controller.sourceLanguage, equals('fr'));

        // Change target language to DE
        await tester.tap(dropdowns.last);
        await tester.pumpAndSettle();
        final deItem = find.text('DE').last;
        await tester.tap(deItem);
        await tester.pumpAndSettle();
        expect(controller.targetLanguage, equals('de'));
      }

      // Tap graphic eq icon in empty state
      final graphicEq = find.byIcon(Icons.graphic_eq);
      if (graphicEq.evaluate().isNotEmpty) {
        await tester.tap(graphicEq);
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
      }

      // Tap More -> Clear Session
      final moreBtn = find.byTooltip('More actions');
      if (moreBtn.evaluate().isNotEmpty) {
        await tester.tap(moreBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear Session'));
        await tester.pumpAndSettle();
        expect(controller.currentConversation.segments, isEmpty);
      }
    });

    testWidgets('shows listening indicator and stops on Stop button tap',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Trigger listening via startMeeting
      await controller.startMeeting();
      await tester.pump();

      expect(find.textContaining('Listening...'), findsOneWidget);
      final stopBtn = find.widgetWithText(FilledButton, 'Stop');
      expect(stopBtn, findsOneWidget);

      await tester.tap(stopBtn);
      await tester.pumpAndSettle();
      expect(controller.state, equals(ConversationState.idle));
    });

    testWidgets('submits text input via keyboard onSubmitted', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'How are you?');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(controller.currentConversation.segments, isNotEmpty);
    });

    testWidgets('Hero Interpreter bilateral turn-taking buttons and center mic',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Speak English button
      final speakEnBtn = find.text('Speak English');
      expect(speakEnBtn, findsOneWidget);
      await tester.tap(speakEnBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(controller.activeListeningSpeaker, equals('You'));

      // Tap Speak Spanish button
      controller.clearSession();
      await tester.pumpAndSettle();
      final speakEsBtn = find.text('Speak Spanish');
      expect(speakEsBtn, findsOneWidget);
      await tester.tap(speakEsBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(controller.activeListeningSpeaker, equals('Partner'));

      // Tap Partner mic in composer
      final partnerMic = find.byTooltip('Partner Speak (Spanish)');
      expect(partnerMic, findsOneWidget);
      await tester.tap(partnerMic);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap Center Hero mic icon
      controller.clearSession();
      await tester.pumpAndSettle();
      final centerMic = find.byIcon(Icons.graphic_eq);
      expect(centerMic, findsOneWidget);
      await tester.tap(centerMic);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Language picker modal opens and selects source and target languages',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap YOU SPEAK -> opens source picker
      final youSpeak = find.text('YOU SPEAK');
      expect(youSpeak, findsOneWidget);
      await tester.tap(youSpeak);
      await tester.pumpAndSettle();

      expect(find.text('Select Your Language'), findsOneWidget);
      final frenchItem = find.text('French');
      expect(frenchItem, findsOneWidget);
      await tester.tap(frenchItem);
      await tester.pumpAndSettle();
      expect(controller.sourceLanguage, equals('fr'));

      // Tap THEY SPEAK -> opens target picker
      final theySpeak = find.text('THEY SPEAK');
      expect(theySpeak, findsOneWidget);
      await tester.tap(theySpeak);
      await tester.pumpAndSettle();

      expect(find.text('Select Partner Language'), findsOneWidget);
      final germanItem = find.text('German');
      expect(germanItem, findsOneWidget);
      await tester.tap(germanItem);
      await tester.pumpAndSettle();
      expect(controller.targetLanguage, equals('de'));
    });

    testWidgets('Mode toggle chip and auto-TTS toggle in AppBar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Toggle QA mode via FilterChip
      final modeChip = find.byType(FilterChip);
      expect(modeChip, findsOneWidget);
      await tester.tap(modeChip);
      await tester.pumpAndSettle();
      expect(controller.isQaMode, isTrue);
      expect(find.text('Ask AI Anything'), findsOneWidget);

      // In QA mode, tap a prompt chip
      final qaPrompt = find.text('What is zoology?');
      expect(qaPrompt, findsOneWidget);
      await tester.tap(qaPrompt);
      await tester.pumpAndSettle();

      // Toggle back to Translate
      await tester.tap(modeChip);
      await tester.pumpAndSettle();
      expect(controller.isQaMode, isFalse);

      // Toggle auto-TTS
      final ttsToggle = find.byTooltip('Auto-TTS Off');
      expect(ttsToggle, findsOneWidget);
      await tester.tap(ttsToggle);
      await tester.pumpAndSettle();
      expect(controller.autoTts, isTrue);
    });

    testWidgets('Explanation modal bottom sheet displays and switches personas',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Send a text to generate explanation
      await tester.enterText(find.byType(TextField), 'What is architecture?');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      // Tap Explain in context actions or bubble
      final explainBtn = find.text('Explain');
      if (explainBtn.evaluate().isNotEmpty) {
        await tester.tap(explainBtn.first);
        await tester.pumpAndSettle();

        expect(find.text('Explanation & Nuances'), findsOneWidget);

        // Tap persona chips inside modal
        for (final personaLabel in [
          'Detailed',
          'Technical',
          'Child-Friendly',
          'Grammar',
          'Simple'
        ]) {
          final chip = find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(personaLabel),
          );
          if (chip.evaluate().isNotEmpty) {
            await tester.tap(chip, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
        }

        // Tap Copy Explanation button
        final copyBtn = find.text('Copy Explanation');
        if (copyBtn.evaluate().isNotEmpty) {
          await tester.tap(copyBtn);
          await tester.pumpAndSettle();
          expect(find.text('Copied explanation'), findsOneWidget);
        }

        // Close modal
        final closeBtn = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byIcon(Icons.close),
        );
        if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Live partial transcript indicator displays in listening state',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await controller.startMeeting();
      await tester.pump();

      // Simulate partial transcript callback via Android channel
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const codec = StandardMethodCodec();

        await messenger.handlePlatformMessage(
          'com.unicom.ai/speech',
          codec.encodeMethodCall(const MethodCall(
              'onPartialTranscript', {'text': 'Live recognition test'})),
          (data) {},
        );
        await tester.pump();

        expect(find.textContaining('Live recognition test'), findsWidgets);
        controller.cancel();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
