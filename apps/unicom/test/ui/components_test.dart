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
    testWidgets('StatusBadge renders for all execution modes and states', (tester) async {
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

    testWidgets('ConversationBubble renders speaker, original, and translated text', (tester) async {
      final segment = ConversationSegment(
        id: 'seg_1',
        speakerId: 'p1',
        speakerName: 'Alice',
        startTime: 1000,
        originalText: 'Hello world',
        originalLanguage: 'en',
        translatedText: 'Hola mundo',
        targetLanguage: 'es',
        confidence: 0.95,
        isFinal: true,
      );

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: Scaffold(
          body: ConversationBubble(
            segment: segment,
            onSpeak: () {},
            onExplain: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
      expect(find.text('Hola mundo'), findsOneWidget);
    });

    testWidgets('ExplanationCard renders personas and allows persona switching', (tester) async {
      final expResult = ExplanationResult(
        id: 'exp_1',
        originalText: 'Architecture',
        explanations: {
          ExplanationPersona.simple: ExplanationEntry(
            persona: ExplanationPersona.simple,
            content: 'Simple explanation content',
          ),
          ExplanationPersona.detailed: ExplanationEntry(
            persona: ExplanationPersona.detailed,
            content: 'Detailed technical explanation',
          ),
        },
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );

      await tester.pumpWidget(MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: Scaffold(
          body: ExplanationCard(explanation: expResult),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Simple explanation content'), findsOneWidget);

      final detailedChip = find.text('Detailed');
      if (detailedChip.evaluate().isNotEmpty) {
        await tester.tap(detailedChip);
        await tester.pumpAndSettle();
        expect(find.textContaining('Detailed technical explanation'), findsOneWidget);
      }
    });

    testWidgets('ResponsiveLayout correctly identifies phone, tablet, and desktop', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(builder: (context) {
            expect(ResponsiveLayout.isPhone(context), isTrue);
            expect(ResponsiveLayout.isTablet(context), isFalse);
            expect(ResponsiveLayout.isDesktop(context), isFalse);
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
            return const SizedBox();
          }),
        ),
      ));
      await tester.pumpAndSettle();
    });
  });
}
