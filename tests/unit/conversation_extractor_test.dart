import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';

void main() {
  group('ConversationExtractor Tests', () {
    late ConversationExtractor extractor;

    setUp(() {
      extractor = ConversationExtractor();
    });

    test('extracts questions and tracks answers correctly', () {
      final segments = [
        ConversationSegment(
          id: 's1',
          speakerId: 'p1',
          speakerName: 'Alice',
          startTime: 1000,
          originalText: 'What is our primary latency target for offline translation?',
          originalLanguage: 'en',
          translatedText: '¿Cuál es nuestro objetivo de latencia principal?',
          targetLanguage: 'es',
        ),
        ConversationSegment(
          id: 's2',
          speakerId: 'p2',
          speakerName: 'Bob',
          startTime: 3000,
          originalText: 'Our target is strictly sub-50 milliseconds on modern CPUs.',
          originalLanguage: 'en',
          translatedText: 'Nuestro objetivo es estrictamente inferior a 50 milisegundos.',
          targetLanguage: 'es',
        ),
      ];

      final questions = extractor.extractQuestions(segments);
      expect(questions.length, equals(1));
      expect(questions.first.questionText, contains('primary latency target'));
      expect(questions.first.isAnswered, isTrue);
      expect(questions.first.answerText, contains('sub-50 milliseconds'));
      expect(questions.first.followUpQuestions, isNotEmpty);
    });

    test('extracts action items and assignees', () {
      final segments = [
        ConversationSegment(
          id: 's1',
          speakerId: 'p1',
          speakerName: 'Alice',
          startTime: 1000,
          originalText: 'Action item: @Bob please ensure all unit tests achieve 90% branch coverage before release.',
          originalLanguage: 'en',
          translatedText: 'Elemento de acción...',
          targetLanguage: 'es',
        ),
      ];

      final items = extractor.extractActionItems(segments);
      expect(items.length, equals(1));
      expect(items.first.assignee?.toLowerCase(), equals('bob'));
      expect(items.first.title, contains('branch coverage'));
      expect(items.first.status, equals('pending'));
    });

    test('extracts decisions reached', () {
      final segments = [
        ConversationSegment(
          id: 's1',
          speakerId: 'p1',
          speakerName: 'Alice',
          startTime: 1000,
          originalText: 'We decided to use Podman as the mandatory rootless container runtime.',
          originalLanguage: 'en',
          translatedText: 'Decidimos usar Podman...',
          targetLanguage: 'es',
        ),
      ];

      final decisions = extractor.extractDecisions(segments);
      expect(decisions.length, equals(1));
      expect(decisions.first.decisionText, contains('Podman as the mandatory rootless container runtime'));
    });

    test('extracts high-relevance topics from conversation', () {
      final segments = [
        ConversationSegment(
          id: 's1',
          speakerId: 'p1',
          speakerName: 'Alice',
          startTime: 1000,
          originalText: 'The architecture must prioritize offline-first privacy.',
          originalLanguage: 'en',
          translatedText: '...',
          targetLanguage: 'es',
        ),
        ConversationSegment(
          id: 's2',
          speakerId: 'p2',
          speakerName: 'Bob',
          startTime: 2000,
          originalText: 'Yes, offline architecture ensures zero data leakage.',
          originalLanguage: 'en',
          translatedText: '...',
          targetLanguage: 'es',
        ),
      ];

      final topics = extractor.extractTopics(segments);
      expect(topics.any((t) => t.name.toLowerCase() == 'architecture' || t.name.toLowerCase() == 'offline'), isTrue);
    });
  });
}
