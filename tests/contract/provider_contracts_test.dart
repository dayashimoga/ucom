import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';

void main() {
  group('Domain Models & Contract Serialization Tests', () {
    test('Participant serialization round-trip', () {
      final p =
          Participant(id: 'p1', name: 'Alice', role: 'Architect', isHost: true);
      final json = p.toJson();
      final restored = Participant.fromJson(json);

      expect(restored.id, equals('p1'));
      expect(restored.name, equals('Alice'));
      expect(restored.role, equals('Architect'));
      expect(restored.isHost, isTrue);
    });

    test('Conversation serialization round-trip with nested segments', () {
      final conv = Conversation(
        id: 'c1',
        title: 'Strategy Review',
        startedAt: '2026-09-17T12:00:00Z',
        participants: [Participant(id: 'p1', name: 'Alice')],
        segments: [
          ConversationSegment(
            id: 's1',
            speakerId: 'p1',
            speakerName: 'Alice',
            startTime: 0,
            originalText: 'Hello world',
            originalLanguage: 'en',
            translatedText: 'Hola mundo',
            targetLanguage: 'es',
          ),
        ],
        actionItems: [
          ActionItem(id: 'a1', title: 'Publish release', assignee: 'Alice'),
        ],
      );

      final json = conv.toJson();
      final restored = Conversation.fromJson(json);

      expect(restored.id, equals('c1'));
      expect(restored.segments.length, equals(1));
      expect(restored.segments.first.translatedText, equals('Hola mundo'));
      expect(restored.actionItems.length, equals(1));
    });

    test('ReportType and ExplanationPersona parsing', () {
      expect(ReportType.fromJson('quick_summary'),
          equals(ReportType.quickSummary));
      expect(ReportType.fromJson('interview_report'),
          equals(ReportType.interviewReport));
      expect(ExplanationPersona.fromJson('child_friendly'),
          equals(ExplanationPersona.childFriendly));
    });
  });
}
