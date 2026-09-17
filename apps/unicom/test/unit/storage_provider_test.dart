import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_app/providers/in_memory_storage_provider.dart';

void main() {
  group('InMemoryStorageProvider Unit Tests', () {
    late InMemoryStorageProvider storage;

    setUp(() {
      storage = InMemoryStorageProvider();
    });

    test('has expected id and name', () {
      expect(storage.id, equals('in_memory_web_storage'));
      expect(storage.name, equals('In-Memory Web Storage'));
    });

    test('saves, retrieves, and deletes conversations', () async {
      final now = DateTime.now().toIso8601String();
      final conv = Conversation(
        id: 'conv_1',
        title: 'Meeting 1',
        mode: ApplicationMode.meeting,
        executionMode: ExecutionMode.privateOffline,
        startedAt: now,
        segments: [
          ConversationSegment(
            id: 'seg_1',
            speakerId: 'user_1',
            speakerName: 'Alice',
            startTime: 0,
            originalText: 'Hello world',
            originalLanguage: 'en',
            translatedText: 'Hola mundo',
            targetLanguage: 'es',
          ),
        ],
      );

      await storage.saveConversation(conv);
      final retrieved = await storage.getConversation('conv_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('conv_1'));
      expect(retrieved.title, equals('Meeting 1'));

      final nonExistent = await storage.getConversation('none');
      expect(nonExistent, isNull);

      final deleted = await storage.deleteConversation('conv_1');
      expect(deleted, isTrue);
      expect(await storage.getConversation('conv_1'), isNull);

      final deletedAgain = await storage.deleteConversation('conv_1');
      expect(deletedAgain, isFalse);
    });

    test('lists conversations with filtering, searching, and pagination', () async {
      final t1 = DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String();
      final t2 = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
      final t3 = DateTime.now().toIso8601String();

      final c1 = Conversation(
        id: 'c1',
        title: 'Alpha Strategy',
        mode: ApplicationMode.meeting,
        executionMode: ExecutionMode.privateOffline,
        startedAt: t1,
        segments: [
          ConversationSegment(
            id: 's1',
            speakerId: 'spk_1',
            speakerName: 'Alice',
            startTime: 0,
            originalText: 'Budget discussion',
            originalLanguage: 'en',
            translatedText: 'Discusion de presupuesto',
            targetLanguage: 'es',
          ),
        ],
      );

      final c2 = Conversation(
        id: 'c2',
        title: 'Beta Interview',
        mode: ApplicationMode.interviewPractice,
        executionMode: ExecutionMode.cloud,
        startedAt: t2,
        segments: [
          ConversationSegment(
            id: 's2',
            speakerId: 'spk_2',
            speakerName: 'Bob',
            startTime: 0,
            originalText: 'Tell me about yourself',
            originalLanguage: 'en',
            translatedText: 'Parlez-moi de vous',
            targetLanguage: 'fr',
          ),
        ],
      );

      final c3 = Conversation(
        id: 'c3',
        title: 'Gamma General',
        mode: ApplicationMode.general,
        executionMode: ExecutionMode.hybrid,
        startedAt: t3,
        segments: [],
      );

      await storage.saveConversation(c1);
      await storage.saveConversation(c2);
      await storage.saveConversation(c3);

      // Default list (sorted descending by startedAt: c3, c2, c1)
      final all = await storage.listConversations();
      expect(all.length, equals(3));
      expect(all[0].id, equals('c3'));
      expect(all[1].id, equals('c2'));
      expect(all[2].id, equals('c1'));

      // Filter by mode
      final meetings = await storage.listConversations(mode: ApplicationMode.meeting);
      expect(meetings.length, equals(1));
      expect(meetings.first.id, equals('c1'));

      // Filter by executionMode
      final cloudOnly = await storage.listConversations(executionMode: ExecutionMode.cloud);
      expect(cloudOnly.length, equals(1));
      expect(cloudOnly.first.id, equals('c2'));

      // Filter by query matching title
      final searchBeta = await storage.searchConversations('Beta');
      expect(searchBeta.length, equals(1));
      expect(searchBeta.first.id, equals('c2'));

      // Filter by query matching segment original text
      final searchBudget = await storage.listConversations(query: 'budget');
      expect(searchBudget.length, equals(1));
      expect(searchBudget.first.id, equals('c1'));

      // Filter by query matching segment translated text
      final searchVous = await storage.listConversations(query: 'vous');
      expect(searchVous.length, equals(1));
      expect(searchVous.first.id, equals('c2'));

      // Pagination: limit and offset
      final page1 = await storage.listConversations(limit: 2, offset: 0);
      expect(page1.length, equals(2));
      expect(page1.map((c) => c.id).toList(), equals(['c3', 'c2']));

      final page2 = await storage.listConversations(limit: 2, offset: 2);
      expect(page2.length, equals(1));
      expect(page2.first.id, equals('c1'));

      final outOfBounds = await storage.listConversations(limit: 2, offset: 10);
      expect(outOfBounds, isEmpty);
    });

    test('saves and retrieves reports, and cleans up on conversation deletion', () async {
      final report1 = GeneratedReport(
        id: 'rep_1',
        conversationId: 'c_rep',
        reportType: ReportType.meetingMinutes,
        title: 'Meeting Minutes',
        content: 'Summary content',
        createdAt: DateTime.now().toIso8601String(),
      );

      final report2 = GeneratedReport(
        id: 'rep_2',
        conversationId: 'c_rep',
        reportType: ReportType.actionItems,
        title: 'Action Items',
        content: 'Action items',
        createdAt: DateTime.now().toIso8601String(),
      );

      await storage.saveReport(report1);
      await storage.saveReport(report2);

      final reports = await storage.getReportsByConversationId('c_rep');
      expect(reports.length, equals(2));

      final emptyReports = await storage.getReportsByConversationId('none');
      expect(emptyReports, isEmpty);

      // Deleting conversation cleans up associated reports
      await storage.saveConversation(Conversation(
        id: 'c_rep',
        title: 'Report Meeting',
        mode: ApplicationMode.meeting,
        executionMode: ExecutionMode.privateOffline,
        startedAt: DateTime.now().toIso8601String(),
      ));
      await storage.deleteConversation('c_rep');
      expect(await storage.getReportsByConversationId('c_rep'), isEmpty);
    });
  });

  group('LocalStorageProvider Delegation Unit Tests', () {
    test('inMemory delegates all operations', () async {
      final local = LocalStorageProvider.inMemory();
      expect(local.id, equals('in_memory_web_storage'));
      expect(local.name, equals('In-Memory Web Storage'));

      final conv = Conversation(
        id: 'c_local',
        title: 'Local Test',
        mode: ApplicationMode.general,
        executionMode: ExecutionMode.privateOffline,
        startedAt: DateTime.now().toIso8601String(),
      );

      await local.saveConversation(conv);
      final fetched = await local.getConversation('c_local');
      expect(fetched?.id, equals('c_local'));

      final list = await local.listConversations();
      expect(list.length, equals(1));

      final search = await local.searchConversations('Local');
      expect(search.length, equals(1));

      final report = GeneratedReport(
        id: 'r_local',
        conversationId: 'c_local',
        reportType: ReportType.quickSummary,
        title: 'Quick Summary',
        content: 'Content',
        createdAt: DateTime.now().toIso8601String(),
      );
      await local.saveReport(report);
      final reports = await local.getReportsByConversationId('c_local');
      expect(reports.length, equals(1));

      final deleted = await local.deleteConversation('c_local');
      expect(deleted, isTrue);
    });

    test('default constructor creates provider with custom temp directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('unicom_test_storage_');
      try {
        final provider = LocalStorageProvider(tempDir);
        expect(provider.id, isNotEmpty);
        expect(provider.name, isNotEmpty);

        final conv = Conversation(
          id: 'c_durable',
          title: 'Durable Test',
          mode: ApplicationMode.general,
          executionMode: ExecutionMode.privateOffline,
          startedAt: DateTime.now().toIso8601String(),
        );
        await provider.saveConversation(conv);
        final fetched = await provider.getConversation('c_durable');
        expect(fetched?.id, equals('c_durable'));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
