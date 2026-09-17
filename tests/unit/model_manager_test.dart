import 'package:test/test.dart';
import 'package:unicom_model_runtime/model_runtime.dart';

void main() {
  group('LocalModelManager Tests', () {
    late LocalModelManager manager;

    setUp(() {
      manager = LocalModelManager();
    });

    test('initializes default catalog with valid models', () async {
      final models = await manager.listModels();
      expect(models.length, greaterThanOrEqualTo(3));
      expect(models.any((m) => m.id == 'unicom-lexicon-v1' && m.isInstalled), isTrue);
    });

    test('verifies checksum for installed models', () async {
      final isValid = await manager.verifyChecksum('unicom-lexicon-v1');
      expect(isValid, isTrue);
    });

    test('downloads model and reports progress', () async {
      double lastProgress = 0.0;
      final downloaded = await manager.downloadModel('whisper-tiny-quantized', onProgress: (p) {
        lastProgress = p;
      });

      expect(downloaded.isInstalled, isTrue);
      expect(lastProgress, equals(1.0));
    });

    test('activates installed model and deactivates siblings', () async {
      await manager.downloadModel('whisper-tiny-quantized');
      final activated = await manager.activateModel('whisper-tiny-quantized');
      expect(activated, isTrue);

      final model = await manager.getModel('whisper-tiny-quantized');
      expect(model?.isActive, isTrue);
    });

    test('removes model and updates catalog state', () async {
      await manager.downloadModel('whisper-tiny-quantized');
      final removed = await manager.removeModel('whisper-tiny-quantized');
      expect(removed, isTrue);

      final model = await manager.getModel('whisper-tiny-quantized');
      expect(model?.isInstalled, isFalse);
    });
  });
}
