import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/ui/components/status_badge.dart';
import 'package:unicom_app/ui/components/conversation_bubble.dart';
import 'package:unicom_app/ui/components/explanation_card.dart';
import 'package:unicom_app/ui/adaptive/responsive_breakpoints.dart';

void main() {
  group('UI Components & Widgets Tests', () {
    testWidgets('StatusBadge renders for all execution modes and states',
        (tester) async {
      for (final mode in ExecutionMode.values) {
        for (final state in ConversationState.values) {
          await tester.pumpWidget(MaterialApp(
            theme: UnicomTheme.darkTheme,
            home: Scaffold(
              body: StatusBadge(executionMode: mode, state: state),
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(StatusBadge), findsOneWidget);
        }
      }
    });

    testWidgets(
        'ConversationBubble renders speaker, original, translated text, buttons, and handles interactions',
        (tester) async {
      bool spoken = false;
      bool explained = false;
      bool translated = false;

      // 1. User Translation Segment
      final exp = ExplanationResult(
        id: 'exp_bubble',
        originalText: 'Hello world',
        explanations: {
          ExplanationPersona.simple: ExplanationEntry(
            persona: ExplanationPersona.simple,
            content: 'Simple explanation',
          ),
        },
        createdAt: '2026-09-22T10:00',
      );

      final userSegment = ConversationSegment(
        id: 'seg_1',
        speakerId: 'p1',
        speakerName: 'You',
        startTime: 1000,
        originalText: 'Hello world',
        originalLanguage: 'en',
        translatedText: 'Hola mundo',
        targetLanguage: 'es',
        confidence: 0.95,
        isFinal: true,
        intent: InteractionIntent.translation,
        explanation: exp,
      );

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: Scaffold(
          body: ConversationBubble(
            segment: userSegment,
            onSpeak: () => spoken = true,
            onExplain: () => explained = true,
            isExplanationActive: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('You'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
      expect(find.text('Hola mundo'), findsOneWidget);
      expect(find.text('ES TRANSLATION'), findsOneWidget);

      // Tap Copy
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();
      expect(find.text('Copied to clipboard'), findsOneWidget);

      // Tap Listen
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pumpAndSettle();
      expect(spoken, isTrue);

      // Tap Explain
      await tester.tap(find.byIcon(Icons.lightbulb_outline));
      await tester.pumpAndSettle();
      expect(explained, isTrue);

      // 2. AI Answer Segment
      final aiSegment = ConversationSegment(
        id: 'seg_ai',
        speakerId: 'ai_assistant',
        speakerName: 'UniCom AI',
        startTime: 2000,
        originalText: 'Zoology is the scientific study of animals.',
        originalLanguage: 'en',
        translatedText: '',
        targetLanguage: 'es',
        confidence: 1.0,
        isFinal: true,
        intent: InteractionIntent.qa,
        isAiResponse: true,
        aiModelName: 'Local LLM INT4',
      );

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.lightTheme,
        home: Scaffold(
          body: ConversationBubble(
            segment: aiSegment,
            onSpeak: () {},
            onExplain: () {},
            onTranslate: () => translated = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('UniCom AI'), findsOneWidget);
      expect(find.text('Local LLM INT4'), findsOneWidget);
      expect(find.text('Zoology is the scientific study of animals.'), findsOneWidget);
      expect(find.text('Translate to ES'), findsOneWidget);

      // Tap AI Translate button
      await tester.tap(find.text('Translate to ES'));
      await tester.pumpAndSettle();
      expect(translated, isTrue);

      // Tap Copy on AI segment
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('ExplanationCard renders all personas, keypoints, and empty states',
        (tester) async {
      final expResult = ExplanationResult(
        id: 'exp_full',
        originalText: 'Architecture',
        explanations: {
          ExplanationPersona.simple: ExplanationEntry(
            persona: ExplanationPersona.simple,
            content: 'Simple explanation content',
            keyPoints: ['Core structure', 'Blueprint'],
          ),
          ExplanationPersona.detailed: ExplanationEntry(
            persona: ExplanationPersona.detailed,
            content: 'Detailed technical explanation',
          ),
          ExplanationPersona.terminology: ExplanationEntry(
            persona: ExplanationPersona.terminology,
            content: 'Terminology and nomenclature',
          ),
          ExplanationPersona.grammar: ExplanationEntry(
            persona: ExplanationPersona.grammar,
            content: 'Grammar analysis',
          ),
          ExplanationPersona.culturalContext: ExplanationEntry(
            persona: ExplanationPersona.culturalContext,
            content: 'Cultural context insights',
          ),
          ExplanationPersona.examples: ExplanationEntry(
            persona: ExplanationPersona.examples,
            content: 'Practical real-world examples',
          ),
          // childFriendly omitted intentionally to test unavailable fallback
        },
        createdAt: '12:30', // < 16 chars branch
      );

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExplanationCard(explanation: expResult),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Simple explanation content'), findsOneWidget);
      expect(find.text('Core structure'), findsOneWidget);
      expect(find.text('Blueprint'), findsOneWidget);
      expect(find.text('12:30'), findsOneWidget);

      // Test switching through each persona chip
      final personaChips = ['Detailed', 'Terms', 'Grammar', 'Culture', 'Examples', 'Child-Friendly'];
      for (final label in personaChips) {
        final chip = find.text(label);
        expect(chip, findsOneWidget);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }

      // Child-friendly was omitted, so it should render fallback message
      expect(find.text('Explanation unavailable for this persona.'), findsOneWidget);
    });

    testWidgets(
        'ResponsiveLayout correctly identifies phone, tablet, desktop, and contentPadding',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(builder: (context) {
            expect(ResponsiveLayout.isPhone(context), isTrue);
            expect(ResponsiveLayout.isTablet(context), isFalse);
            expect(ResponsiveLayout.isDesktop(context), isFalse);
            expect(ResponsiveLayout.contentPadding(context), equals(12.0));
            return const SizedBox();
          }),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 1280)),
          child: Builder(builder: (context) {
            expect(ResponsiveLayout.isPhone(context), isFalse);
            expect(ResponsiveLayout.isTablet(context), isTrue);
            expect(ResponsiveLayout.isDesktop(context), isFalse);
            expect(ResponsiveLayout.contentPadding(context), equals(20.0));
            return const SizedBox();
          }),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(builder: (context) {
            expect(ResponsiveLayout.isPhone(context), isFalse);
            expect(ResponsiveLayout.isTablet(context), isFalse);
            expect(ResponsiveLayout.isDesktop(context), isTrue);
            expect(ResponsiveLayout.contentPadding(context), equals(32.0));
            return const SizedBox();
          }),
        ),
      ));
      await tester.pumpAndSettle();
    });
  });
}
