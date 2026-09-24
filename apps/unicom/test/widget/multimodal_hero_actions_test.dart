import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/conversation/conversation_screen.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';
import 'package:unicom_app/providers/in_memory_storage_provider.dart';
import 'package:unicom_app/ui/components/understand_modal.dart';

void main() {
  group('Multimodal Hero Actions & Understand Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController(
        storageProvider: LocalStorageProvider.inMemory(),
      );
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: Scaffold(
          body: ConversationScreen(controller: controller),
        ),
      );
    }

    testWidgets(
        'Switches to Camera mode, renders viewfinder and processes Korean sample OCR',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Camera Hero Tab
      final cameraTab = find.text('Camera');
      expect(cameraTab, findsOneWidget);
      await tester.tap(cameraTab);
      await tester.pumpAndSettle();

      expect(controller.activeHeroMode, equals('camera'));
      expect(find.text('Real-Time Camera Visual Interpreter'), findsOneWidget);

      // Tap Korean Menu sample chip
      final koreanChip = find.text('Korean Menu');
      expect(koreanChip, findsOneWidget);
      await tester.tap(koreanChip);
      await tester.pumpAndSettle();

      // OCR result should now be displayed
      expect(controller.currentOcrResult, isNotNull);
      expect(controller.currentOcrResult!.detectedLanguage, equals('ko'));
      expect(find.textContaining('Visual Recognition'), findsOneWidget);
      expect(find.text('Read Aloud'), findsOneWidget);
      expect(find.text('Understand'), findsOneWidget);

      // Toggle overlay mode
      final toggleChip = find.text('Show Original');
      expect(toggleChip, findsOneWidget);
      await tester.tap(toggleChip);
      await tester.pumpAndSettle();
      expect(controller.isOverlayOriginal, isTrue);

      final showTransChip = find.text('Show Translated');
      expect(showTransChip, findsOneWidget);
      await tester.tap(showTransChip);
      await tester.pumpAndSettle();
      expect(controller.isOverlayOriginal, isFalse);
    });

    testWidgets(
        'Switches to Listen mode, toggles ambient listening and shows radar visualizer',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Listen Hero Tab
      final listenTab = find.text('Listen');
      expect(listenTab, findsOneWidget);
      await tester.tap(listenTab);
      await tester.pumpAndSettle();

      expect(controller.activeHeroMode, equals('listen'));
      expect(find.text('Listen & Understand'), findsOneWidget);

      // Tap Start Listening button
      final startBtn = find.text('Start Listening');
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(controller.isAmbientListening, isTrue);
      expect(find.text('Ambient Listening Active'), findsOneWidget);

      // Stop listening
      final stopBtn = find.text('Stop Ambient Listening');
      expect(stopBtn, findsOneWidget);
      await tester.tap(stopBtn);
      await tester.pumpAndSettle();

      expect(controller.isAmbientListening, isFalse);
    });

    testWidgets(
        'Opens shared Understand Modal and displays multi-perspective breakdown',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(
        MaterialApp(
          theme: UnicomTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    UnderstandModal.show(
                      ctx,
                      originalText: '¿Dónde está la estación de tren?',
                      translatedText: 'Where is the train station?',
                      sourceLanguage: 'es',
                      targetLanguage: 'en',
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Modal elements
      expect(find.text('Understand'), findsOneWidget);
      expect(find.text('AI EXPLANATION'), findsOneWidget);
      expect(find.text('¿Dónde está la estación de tren?'), findsOneWidget);
      expect(find.text('Where is the train station?'), findsOneWidget);
      expect(find.text('SUGGESTED RESPONSE'), findsOneWidget);

      // Switch perspectives
      final culturalChip = find.text('Cultural Context');
      expect(culturalChip, findsOneWidget);
      await tester.tap(culturalChip);
      await tester.pumpAndSettle();

      final keyTermsChip = find.text('Key Terms');
      expect(keyTermsChip, findsOneWidget);
      await tester.tap(keyTermsChip);
      await tester.pumpAndSettle();

      // Drag up to reveal actions
      await tester.drag(find.byType(UnderstandModal), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Copy translation
      final copyBtn = find.text('Copy Translation');
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();
      expect(find.text('Translation copied to clipboard'), findsOneWidget);
    });
  });
}
