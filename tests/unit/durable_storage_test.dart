import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

void main() {
  group('DurableFileStorageProvider Tests', () {
    late Directory tempDir;
    late DurableFileStorageProvider storage;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('unicom_storage_test_');
      storage = DurableFileStorageProvider(baseDirectory: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Conversation makeSampleConversation({
      String id = 'conv_1',
      String title = 'Test Dialogue',
      DateTime? time,
    }) {
      final t = time ?? DateTime.now().toUtc();
      return Conversation(
        id: id,
        title: title,
        mode: ApplicationMode.general,
        executionMode: ExecutionMode.privateOffline,
        startedAt: t.toIso8601String(),
        segments: [
          ConversationSegment(
            id: 'seg_1',
            speakerId: 'spk_1',
            speakerName: 'Speaker A',
            startTime: 0,
            originalText: 'Hello world',
            originalLanguage: 'en',
            translatedText: 'Hola mundo',
            targetLanguage: 'es',
            confidence: 0.98,
            isFinal: true,
          ),
        ],
        metadata: {'test': true, 'audio': true},
      );
    }

    test('Persists and retrieves conversations across simulated process restarts', () async {
      final conv = makeSampleConversation(id: 'conv_durability_1', title: 'Critical Strategy');
      await storage.saveConversation(conv);

      // Simulate app restart by creating a new provider instance pointing to the same folder
      final restartedStorage = DurableFileStorageProvider(baseDirectory: tempDir);
      final retrieved = await restartedStorage.getConversation('conv_durability_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('conv_durability_1'));
      expect(retrieved.title, equals('Critical Strategy'));
      expect(retrieved.segments.length, equals(1));
      expect(retrieved.segments.first.originalText, equals('Hello world'));
      expect(retrieved.segments.first.translatedText, equals('Hola mundo'));
    });

    test('Performs atomic write without leaving temporary files', () async {
      final conv = makeSampleConversation(id: 'conv_atomic_1');
      await storage.saveConversation(conv);

      final convDir = Directory('${tempDir.path}/conversations');
      final files = convDir.listSync();

      expect(files.any((f) => f.path.endsWith('conv_atomic_1.json')), isTrue);
      expect(files.any((f) => f.path.endsWith('.tmp')), isFalse);
    });

    test('Quarantines corrupted files and maintains graceful degradation', () async {
      final conv1 = makeSampleConversation(id: 'conv_good');
      await storage.saveConversation(conv1);

      // Artificially create a corrupted, malformed file in the conversations directory
      final corruptFile = File('${tempDir.path}/conversations/conv_corrupt.json');
      await corruptFile.writeAsString('{"corrupted_data": [UNTERMINATED_JSON');

      // The corrupt file should not crash listConversations
      final all = await storage.listConversations();
      expect(all.length, equals(1));
      expect(all.first.id, equals('conv_good'));

      // The corrupt file should have been quarantined
      final quarantined = await storage.getQuarantinedFiles();
      expect(quarantined.length, equals(1));
      expect(quarantined.first, contains('conv_corrupt'));
    });

    test('Applies schema migration seamlessly from v0 legacy format', () async {
      // Create a legacy v0 JSON record lacking executionMode and tags
      final legacyFile = File('${tempDir.path}/conversations/conv_legacy.json');
      final legacyJson = {
        '_schemaVersion': 0,
        'data': {
          'id': 'conv_legacy',
          'title': 'Legacy Meeting',
          'mode': 'general',
          'startedAt': DateTime.now().toUtc().toIso8601String(),
          'segments': [],
        },
      };
      await legacyFile.writeAsString(jsonEncode(legacyJson));

      final retrieved = await storage.getConversation('conv_legacy');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('conv_legacy'));
      expect(retrieved.executionMode, equals(ExecutionMode.privateOffline));
      expect(retrieved.metadata, isNotNull);
    });

    test('Enforces storage quota and throws StorageFullException', () async {
      final smallQuotaStorage = DurableFileStorageProvider(
        baseDirectory: tempDir,
        maxStorageBytes: 1200, // Enough for 1 conversation (~830 bytes), but 2 exceeds quota
      );

      final conv1 = makeSampleConversation(id: 'conv_q1');
      await smallQuotaStorage.saveConversation(conv1);

      final conv2 = makeSampleConversation(id: 'conv_q2');
      expect(
        () async => await smallQuotaStorage.saveConversation(conv2),
        throwsA(isA<StorageFullException>()),
      );
    });

    test('Purges expired records according to data retention policy', () async {
      final oldDate = DateTime.now().toUtc().subtract(const Duration(days: 45));
      final recentDate = DateTime.now().toUtc().subtract(const Duration(days: 2));

      final oldConv = makeSampleConversation(id: 'conv_old', time: oldDate);
      final recentConv = makeSampleConversation(id: 'conv_recent', time: recentDate);

      await storage.saveConversation(oldConv);
      await storage.saveConversation(recentConv);

      expect((await storage.listConversations()).length, equals(2));

      // Purge records older than 30 days
      final purged = await storage.purgeExpired(const Duration(days: 30));
      expect(purged, equals(1));

      final remaining = await storage.listConversations();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('conv_recent'));
    });

    test('Enforces retention limit to keep most recent records', () async {
      for (var i = 1; i <= 5; i++) {
        final conv = makeSampleConversation(
          id: 'conv_item_$i',
          time: DateTime.now().toUtc().add(Duration(minutes: i)),
        );
        await storage.saveConversation(conv);
      }

      expect((await storage.listConversations()).length, equals(5));

      final evicted = await storage.enforceRetentionLimit(maxConversations: 3);
      expect(evicted, equals(2));

      final remaining = await storage.listConversations();
      expect(remaining.length, equals(3));
    });

    test('Saves and retrieves reports, and cascades report deletion on conversation delete', () async {
      final conv = makeSampleConversation(id: 'conv_with_rep');
      await storage.saveConversation(conv);

      final report = GeneratedReport(
        id: 'rep_1',
        conversationId: 'conv_with_rep',
        title: 'Meeting Executive Summary',
        reportType: ReportType.meetingMinutes,
        content: '# Meeting Minutes\nAll decisions reached.',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        metadata: {
          'executionMode': 'private_offline',
          'modelName': 'OfflineExtractor-1.0',
        },
      );

      await storage.saveReport(report);

      final reports = await storage.getReportsByConversationId('conv_with_rep');
      expect(reports.length, equals(1));
      expect(reports.first.title, equals('Meeting Executive Summary'));

      // Delete conversation should delete associated report
      final deleted = await storage.deleteConversation('conv_with_rep');
      expect(deleted, isTrue);

      expect(await storage.getConversation('conv_with_rep'), isNull);
      expect(await storage.getReportsByConversationId('conv_with_rep'), isEmpty);
    });
  });
}
