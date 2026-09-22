import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import 'package:unicom_app/app/theme.dart';
import 'package:unicom_app/features/models/model_manager_screen.dart';

class _FailingModelManager extends LocalModelManager {
  @override
  Future<ModelMetadata> downloadModel(
    String id, {
    void Function(double progress)? onProgress,
    List<int>? mockDownloadedBytes,
  }) async {
    throw Exception('Simulated download network error');
  }
}

class _CancellingModelManager extends LocalModelManager {
  Completer<ModelMetadata>? downloadCompleter;

  @override
  Future<ModelMetadata> downloadModel(
    String id, {
    void Function(double progress)? onProgress,
    List<int>? mockDownloadedBytes,
  }) async {
    onProgress?.call(0.5);
    downloadCompleter = Completer<ModelMetadata>();
    return downloadCompleter!.future;
  }
}

void main() {
  group('ModelManagerScreen Widget Tests', () {
    late LocalModelManager modelManager;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('model_test_dir_');
      modelManager = LocalModelManager(storageDirectory: tempDir);
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    Widget createTestApp({LocalModelManager? mgr}) {
      return MaterialApp(
        theme: UnicomTheme.darkTheme,
        home: ModelManagerScreen(modelManager: mgr ?? modelManager),
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
      final whisperCard = find.ancestor(
        of: find.textContaining('Whisper Tiny'),
        matching: find.byType(Card),
      );
      final downloadBtn = find.descendant(
        of: whisperCard,
        matching: find.widgetWithText(FilledButton, 'Download Pack'),
      );
      await tester.tap(downloadBtn.first);
      await tester.pump();
      await tester.runAsync(() async {
        for (int i = 0; i < 20; i++) {
          final m = await modelManager.getModel('whisper-tiny-quantized');
          if (m?.isInstalled == true) break;
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      // Refresh
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Activate model
      final activateBtn = find.text('Activate');
      if (activateBtn.evaluate().isNotEmpty) {
        await tester.tap(activateBtn.first);
        await tester.pumpAndSettle();
      }

      // Uninstall model
      final uninstallBtn = find.text('Uninstall');
      if (uninstallBtn.evaluate().isNotEmpty) {
        await tester.tap(uninstallBtn.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('handles download error and displays failure snackbar',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final failingMgr = _FailingModelManager();
      await tester.pumpWidget(createTestApp(mgr: failingMgr));
      await tester.pumpAndSettle();

      final downloadBtn = find.widgetWithText(FilledButton, 'Download Pack').first;
      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Download failed'), findsOneWidget);
    });

    testWidgets('handles download progress and cancellation', (tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cancellingMgr = _CancellingModelManager();
      await tester.pumpWidget(createTestApp(mgr: cancellingMgr));
      await tester.pumpAndSettle();

      final downloadBtn = find.widgetWithText(FilledButton, 'Download Pack').first;
      await tester.tap(downloadBtn);
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('50% downloaded'), findsOneWidget);

      final cancelBtn = find.text('Cancel');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pump();

      // Complete future to clean up
      cancellingMgr.downloadCompleter?.completeError('Cancelled');
      await tester.pumpAndSettle();
    });
  });
}
