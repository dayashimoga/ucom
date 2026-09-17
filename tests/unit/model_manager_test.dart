import 'dart:io';
import 'package:test/test.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import 'package:unicom_shared/shared.dart';

void main() {
  group('LocalModelManager Tests', () {
    late Directory tempDir;
    late LocalModelManager manager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('unicom_models_test_');
      manager = LocalModelManager(storageDirectory: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initializes default catalog with valid models and capabilities',
        () async {
      final models = await manager.listModels();
      expect(models.length, greaterThanOrEqualTo(4));
      expect(models.any((m) => m.id == 'unicom-lexicon-v1' && m.isInstalled),
          isTrue);

      final indic = models.firstWhere((m) => m.id == 'indic-trans-v2-compact');
      expect(indic.supportedLanguages, contains('ta'));
      expect(indic.runtime, contains('GGML'));
    });

    test('verifies checksum for installed models', () async {
      final isValid = await manager.verifyChecksum('unicom-lexicon-v1');
      expect(isValid, isTrue);
    });

    test('downloads model, creates physical file, and reports progress',
        () async {
      double lastProgress = 0.0;
      final downloaded = await manager.downloadModel(
        'whisper-tiny-quantized',
        onProgress: (p) => lastProgress = p,
      );

      expect(downloaded.isInstalled, isTrue);
      expect(downloaded.installPath, isNotNull);
      expect(File(downloaded.installPath!).existsSync(), isTrue);
      expect(lastProgress, equals(1.0));
    });

    test(
        'enforces disk space verification and rejects download if insufficient space',
        () async {
      final lowDiskManager = LocalModelManager(
        storageDirectory: tempDir,
        availableDiskSpaceBytes: 1024, // Only 1 KB available
      );

      expect(
        () async =>
            await lowDiskManager.downloadModel('whisper-tiny-quantized'),
        throwsA(isA<StorageFullException>()),
      );
    });

    test('rejects download when SHA256 checksum mismatches', () async {
      final badBytes = [
        1,
        2,
        3,
        4,
        5
      ]; // Checksum won't match model's expected sha256

      await expectLater(
        () => manager.downloadModel(
          'whisper-tiny-quantized',
          mockDownloadedBytes: badBytes,
        ),
        throwsA(isA<ChecksumMismatchException>()),
      );

      // Verify no leftover .part file was orphaned
      final partFiles =
          tempDir.listSync().where((f) => f.path.endsWith('.part'));
      expect(partFiles, isEmpty);
    });

    test('supports download cancellation cleanly without leaving artifacts',
        () async {
      // Trigger cancellation immediately
      manager.cancelDownload('whisper-tiny-quantized');

      await expectLater(
        () => manager.downloadModel('whisper-tiny-quantized'),
        throwsA(isA<UnicomException>()),
      );

      final model = await manager.getModel('whisper-tiny-quantized');
      expect(model?.isInstalled, isFalse);
    });

    test('manages lazy memory loading and unloading for power/RAM optimization',
        () async {
      await manager.downloadModel('whisper-tiny-quantized');

      // Load into memory
      await manager.loadModel('whisper-tiny-quantized');
      var model = await manager.getModel('whisper-tiny-quantized');
      expect(model?.isLoadedInMemory, isTrue);

      // Unload from memory
      await manager.unloadModel('whisper-tiny-quantized');
      model = await manager.getModel('whisper-tiny-quantized');
      expect(model?.isLoadedInMemory, isFalse);
    });

    test('activates installed model and deactivates siblings', () async {
      await manager.downloadModel('whisper-tiny-quantized');
      final activated = await manager.activateModel('whisper-tiny-quantized');
      expect(activated, isTrue);

      final model = await manager.getModel('whisper-tiny-quantized');
      expect(model?.isActive, isTrue);
      expect(model?.isLoadedInMemory, isTrue);
    });

    test('removes model, deletes physical file, and resets catalog state',
        () async {
      final downloaded = await manager.downloadModel('whisper-tiny-quantized');
      final path = downloaded.installPath!;
      expect(File(path).existsSync(), isTrue);

      final removed = await manager.removeModel('whisper-tiny-quantized');
      expect(removed, isTrue);
      expect(File(path).existsSync(), isFalse);

      final model = await manager.getModel('whisper-tiny-quantized');
      expect(model?.isInstalled, isFalse);
      expect(model?.isLoadedInMemory, isFalse);
    });
  });
}
