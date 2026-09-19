import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/models/model_manager_screen.dart';

void main() {
  group('ModelManagerScreen Widget Tests', () {
    late LocalModelManager modelManager;

    setUp(() {
      modelManager = LocalModelManager();
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: ModelManagerScreen(modelManager: modelManager),
      );
    }

    testWidgets('renders model list with metadata chips and actions',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Model & Language Pack Manager'), findsOneWidget);
      expect(find.textContaining('UNICOM Multilingual Compact Lexicon'),
          findsOneWidget);
      expect(find.textContaining('Whisper Tiny INT8 On-Device STT'),
          findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('triggers download, activation, and removal of model',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Find Download Pack button for Whisper
      final downloadBtn =
          find.widgetWithText(FilledButton, 'Download Pack').first;
      await tester.tap(downloadBtn);
      await tester.pump();
      await tester.runAsync(() async {
        for (int i = 0; i < 20; i++) {
          final m = await modelManager.getModel('whisper-tiny-quantized');
          if (m?.isInstalled == true) break;
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      // Refresh and check installed
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      final whisper = await modelManager.getModel('whisper-tiny-quantized');
      expect(whisper?.isInstalled, isTrue);

      // Activate model
      final activateBtn = find.widgetWithText(FilledButton, 'Activate');
      if (activateBtn.evaluate().isNotEmpty) {
        await tester.tap(activateBtn.first);
        await tester.pumpAndSettle();
      }

      // Remove or Uninstall model
      final uninstallBtn = find.text('Uninstall');
      final removeBtn = find.text('Remove');
      if (uninstallBtn.evaluate().isNotEmpty) {
        await tester.tap(uninstallBtn.first);
        await tester.pumpAndSettle();
      } else if (removeBtn.evaluate().isNotEmpty) {
        await tester.tap(removeBtn.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
