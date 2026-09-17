import 'package:unicom_contracts/contracts.dart';

class ConversationExtractor {
  List<ExtractedQuestion> extractQuestions(List<ConversationSegment> segments) {
    final questions = <ExtractedQuestion>[];

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sentences = seg.originalText.split(RegExp(r'(?<=[.?!])\s+'));

      for (final sentence in sentences) {
        final trimmed = sentence.trim();
        if (_isQuestion(trimmed)) {
          // Check if subsequent segment answered it
          String? answer;
          bool isAnswered = false;
          if (i + 1 < segments.length) {
            final nextSeg = segments[i + 1];
            if (nextSeg.speakerId != seg.speakerId) {
              answer = nextSeg.originalText;
              isAnswered = true;
            }
          }

          final followUps = _generateFollowUps(trimmed);

          questions.add(ExtractedQuestion(
            id: 'q_${questions.length + 1}_${seg.id}',
            segmentId: seg.id,
            questionText: trimmed,
            askedBySpeakerId: seg.speakerId,
            answerText: answer,
            isAnswered: isAnswered,
            followUpQuestions: followUps,
          ));
        }
      }
    }

    return questions;
  }

  List<ActionItem> extractActionItems(List<ConversationSegment> segments) {
    final items = <ActionItem>[];
    final actionRegex = RegExp(
      r'\b(todo|action item|will|must|need to|should|assigned to|please ensure|take care of)\b[:\s]*(.+)',
      caseSensitive: false,
    );

    for (final seg in segments) {
      final match = actionRegex.firstMatch(seg.originalText);
      if (match != null) {
        final title = match.group(2)?.trim() ?? seg.originalText;
        // Check for assignee like @John or assigned to John
        final assigneeMatch = RegExp(r'@(\w+)|assigned to (\w+)', caseSensitive: false)
            .firstMatch(seg.originalText);
        final assignee = assigneeMatch?.group(1) ?? assigneeMatch?.group(2);

        items.add(ActionItem(
          id: 'act_${items.length + 1}',
          title: title,
          assignee: assignee ?? seg.speakerName,
          status: 'pending',
          segmentId: seg.id,
        ));
      }
    }

    return items;
  }

  List<DecisionItem> extractDecisions(List<ConversationSegment> segments) {
    final decisions = <DecisionItem>[];
    final decisionRegex = RegExp(
      r'\b(we decided|decided that|agreed to|agreed that|final decision|conclusion is|we will go with)\b[:\s]*(.+)',
      caseSensitive: false,
    );

    for (final seg in segments) {
      final match = decisionRegex.firstMatch(seg.originalText);
      if (match != null) {
        final dec = match.group(2)?.trim() ?? seg.originalText;
        decisions.add(DecisionItem(
          id: 'dec_${decisions.length + 1}',
          decisionText: dec,
          context: seg.originalText,
          segmentId: seg.id,
        ));
      }
    }

    return decisions;
  }

  List<TopicItem> extractTopics(List<ConversationSegment> segments) {
    final wordFreq = <String, int>{};
    final stopWords = {
      'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i', 'it', 'for', 'not',
      'on', 'with', 'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his', 'by', 'from',
      'they', 'we', 'say', 'her', 'she', 'or', 'an', 'will', 'my', 'one', 'all', 'would',
      'there', 'their', 'what', 'so', 'up', 'out', 'if', 'about', 'who', 'get', 'which', 'go', 'me'
    };

    for (final seg in segments) {
      final words = seg.originalText
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(RegExp(r'\s+'));

      for (final w in words) {
        if (w.length > 3 && !stopWords.contains(w)) {
          wordFreq[w] = (wordFreq[w] ?? 0) + 1;
        }
      }
    }

    final sortedEntries = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topics = <TopicItem>[];
    final topEntries = sortedEntries.take(5);

    for (final entry in topEntries) {
      topics.add(TopicItem(
        id: 'top_${topics.length + 1}',
        name: entry.key.toUpperCase(),
        keywords: [entry.key],
        relevanceScore: double.parse((entry.value / (segments.length + 1)).clamp(0.1, 1.0).toStringAsFixed(2)),
      ));
    }

    return topics;
  }

  List<String> extractUnresolvedQuestions(List<ExtractedQuestion> questions) {
    return questions
        .where((q) => !q.isAnswered)
        .map((q) => q.questionText)
        .toList();
  }

  bool _isQuestion(String text) {
    if (text.endsWith('?')) return true;
    final startsWithInterrogative = RegExp(
      r'^(who|what|where|when|why|how|is|are|can|could|would|should|do|does|did)\b',
      caseSensitive: false,
    );
    return startsWithInterrogative.hasMatch(text);
  }

  List<String> _generateFollowUps(String questionText) {
    return [
      'Could you elaborate further on that?',
      'What are the key trade-offs to consider here?',
      'How does this impact the overall timeline or outcome?',
    ];
  }
}
