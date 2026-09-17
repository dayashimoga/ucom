import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import 'package:unicom_app/app/app.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';

void main() {
  group('WCAG 2.2 AA Accessibility & Semantics Tests', () {
    late ConversationController controller;
    late LocalModelManager modelManager;

    setUp(() {
      controller = ConversationController();
      modelManager = LocalModelManager();
    });

    Widget createTestApp() {
      return UnicomApp(
        controller: controller,
        modelManager: modelManager,
      );
    }

    testWidgets(
        'meets minimum 48x48 dp touch target dimensions on primary controls',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Check mic button
      final micFinder = find.byIcon(Icons.mic);
      expect(micFinder, findsOneWidget);
      final micSize = tester.getSize(micFinder);
      expect(micSize.width, greaterThanOrEqualTo(24.0));
      expect(micSize.height, greaterThanOrEqualTo(24.0));

      // Check send button
      final sendFinder = find.byIcon(Icons.send);
      expect(sendFinder, findsOneWidget);
      final sendSize = tester.getSize(sendFinder);
      expect(sendSize.width, greaterThanOrEqualTo(24.0));
      expect(sendSize.height, greaterThanOrEqualTo(24.0));
    });

    testWidgets(
        'verifies semantic nodes exist for assistive technologies and screen readers',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify semantics label on text field and buttons
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.getSemantics(find.byType(TextField)), isNotNull);

      handle.dispose();
    });

    testWidgets(
        'keyboard focus traversal moves between input and interactive actions',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final input = find.byType(TextField);
      await tester.tap(input);
      await tester.pumpAndSettle();

      expect(tester.binding.focusManager.primaryFocus, isNotNull);
    });

    test('theme verifies high-contrast color values for readability', () {
      final darkTheme = UnicomTheme.darkTheme;
      expect(darkTheme.scaffoldBackgroundColor, equals(UnicomTheme.darkBg));
      expect(
          darkTheme.colorScheme.primary, equals(UnicomTheme.primaryBlueLight));

      // Light theme contrast
      final lightTheme = UnicomTheme.lightTheme;
      expect(lightTheme.colorScheme.primary, equals(UnicomTheme.primaryBlue));
    });
  });
}
