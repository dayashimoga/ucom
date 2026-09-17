import 'package:unicom_contracts/contracts.dart';

class ReportGenerator {
  GeneratedReport generateReport({
    required Conversation conversation,
    required ReportType type,
    String? customTitle,
    String providerId = 'unicom_ai_core',
    String modelName = 'unicom-local-v1',
    String modelVersion = '1.0.0',
  }) {
    final reportId = 'rep_${DateTime.now().millisecondsSinceEpoch}_${type.toJson()}';
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final title = customTitle ?? _defaultTitleForType(type, conversation.title);
    final content = _buildContentForType(
      type,
      conversation,
      title,
      providerId: providerId,
      modelName: modelName,
      modelVersion: modelVersion,
    );

    return GeneratedReport(
      id: reportId,
      conversationId: conversation.id,
      reportType: type,
      title: title,
      content: content,
      createdAt: nowIso,
      metadata: {
        'segmentCount': conversation.segments.length,
        'mode': conversation.mode.toJson(),
        'executionMode': conversation.executionMode.toJson(),
        'providerId': providerId,
        'modelName': modelName,
        'modelVersion': modelVersion,
      },
    );
  }

  String _defaultTitleForType(ReportType type, String conversationTitle) {
    switch (type) {
      case ReportType.quickSummary:
        return 'Executive Summary — $conversationTitle';
      case ReportType.detailedSummary:
        return 'Comprehensive Analysis — $conversationTitle';
      case ReportType.fullTranscript:
        return 'Full Verified Transcript — $conversationTitle';
      case ReportType.questionsReport:
        return 'Inquiries & Follow-ups Report — $conversationTitle';
      case ReportType.learningReport:
        return 'Learning & Key Insights — $conversationTitle';
      case ReportType.actionItems:
        return 'Action Items & Deliverables — $conversationTitle';
      case ReportType.meetingMinutes:
        return 'Formal Meeting Minutes — $conversationTitle';
      case ReportType.interviewReport:
        return 'Interview Practice Evaluation & Study Plan — $conversationTitle';
      case ReportType.vocabularyReport:
        return 'Terminology & Vocabulary Report — $conversationTitle';
    }
  }

  String _buildContentForType(
    ReportType type,
    Conversation conv,
    String title, {
    required String providerId,
    required String modelName,
    required String modelVersion,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# $title\n');

    // Provenance metadata header
    buffer.writeln('### PROVENANCE & EXECUTION AUDIT');
    buffer.writeln('- **Conversation ID**: `${conv.id}`');
    buffer.writeln('- **Timestamp**: `${conv.startedAt}`');
    buffer.writeln('- **Application Mode**: `${conv.mode.toJson().toUpperCase()}`');
    buffer.writeln('- **Privacy Execution Tier**: `${conv.executionMode.toJson().toUpperCase()}`');
    buffer.writeln('- **Active Provider**: `$providerId`');
    buffer.writeln('- **Model & Version**: `$modelName (v$modelVersion)`');
    buffer.writeln('- **Participants**: ${conv.participants.map((p) => "${p.name} (${p.preferredLanguage?.toUpperCase() ?? 'EN'})").join(", ")}\n');
    buffer.writeln('---\n');

    switch (type) {
      case ReportType.quickSummary:
        buffer.writeln('## AI SUMMARY');
        buffer.writeln('This conversation encompassed ${conv.segments.length} exchanges with ${conv.participants.length} active participants.');
        if (conv.topics.isNotEmpty) {
          buffer.writeln('\n### Primary Focus Areas');
          for (final t in conv.topics) {
            buffer.writeln('- **${t.name}** (Relevance: ${(t.relevanceScore * 100).round()}%)');
          }
        }
        if (conv.decisions.isNotEmpty) {
          buffer.writeln('\n### Key Decisions');
          for (final d in conv.decisions) {
            buffer.writeln('- ${d.decisionText}');
          }
        }
        break;

      case ReportType.detailedSummary:
        buffer.writeln('## AI SUMMARY & DIALOGUE BREAKDOWN');
        buffer.writeln('Detailed breakdown across timeline and thematic topics.\n');
        for (final seg in conv.segments) {
          buffer.writeln('#### VERBATIM TRANSCRIPT [${seg.speakerName}] (${seg.originalLanguage.toUpperCase()}):');
          buffer.writeln('> "${seg.originalText}"');
          if (seg.translatedText.isNotEmpty && seg.translatedText != seg.originalText) {
            buffer.writeln('#### TRANSLATION (${seg.targetLanguage.toUpperCase()}):');
            buffer.writeln('> "${seg.translatedText}"');
          }
          buffer.writeln();
        }
        break;

      case ReportType.fullTranscript:
        buffer.writeln('## VERBATIM TRANSCRIPT');
        for (final seg in conv.segments) {
          buffer.writeln('**[${seg.startTime}ms] ${seg.speakerName}**:');
          buffer.writeln('- **VERBATIM TRANSCRIPT**: ${seg.originalText}');
          if (seg.translatedText.isNotEmpty) {
            buffer.writeln('- **TRANSLATION**: ${seg.translatedText}');
          }
          buffer.writeln();
        }
        break;

      case ReportType.questionsReport:
        buffer.writeln('## INQUIRIES & AI ANSWERS');
        if (conv.questions.isEmpty) {
          buffer.writeln('No explicit inquiries detected in this session.');
        } else {
          for (final q in conv.questions) {
            buffer.writeln('### Question: "${q.questionText}"');
            buffer.writeln('- **Status**: ${q.isAnswered ? "Answered" : "Unresolved"}');
            if (q.answerText != null) {
              buffer.writeln('- **AI ANSWER**: ${q.answerText}');
            }
            if (q.followUpQuestions.isNotEmpty) {
              buffer.writeln('- **Recommended Follow-Ups**:');
              for (final f in q.followUpQuestions) {
                buffer.writeln('  - $f');
              }
            }
            buffer.writeln();
          }
        }
        break;

      case ReportType.learningReport:
        buffer.writeln('## AI EXPLANATION & LINGUISTIC INSIGHTS');
        buffer.writeln('Key grammatical, cultural, and conceptual learnings from this exchange.\n');
        for (final seg in conv.segments) {
          if (seg.explanation != null) {
            buffer.writeln('### Concept: "${seg.originalText}"');
            final exp = seg.explanation!.explanations;
            if (exp.containsKey(ExplanationPersona.simple)) {
              buffer.writeln('- **AI EXPLANATION (Simple)**: ${exp[ExplanationPersona.simple]!.content}');
            }
            if (exp.containsKey(ExplanationPersona.grammar)) {
              buffer.writeln('- **AI EXPLANATION (Grammar)**: ${exp[ExplanationPersona.grammar]!.content}');
            }
            if (exp.containsKey(ExplanationPersona.culturalContext)) {
              buffer.writeln('- **AI EXPLANATION (Culture)**: ${exp[ExplanationPersona.culturalContext]!.content}');
            }
            buffer.writeln();
          }
        }
        break;

      case ReportType.actionItems:
        buffer.writeln('## Assigned Deliverables & Action Items');
        if (conv.actionItems.isEmpty) {
          buffer.writeln('No outstanding action items recorded.');
        } else {
          for (final item in conv.actionItems) {
            buffer.writeln('- [ ] **${item.title}** (Assignee: ${item.assignee ?? "Unassigned"})');
            if (item.dueDate != null) buffer.writeln('  Due: ${item.dueDate}');
          }
        }
        break;

      case ReportType.meetingMinutes:
        buffer.writeln('## FORMAL MEETING MINUTES');
        buffer.writeln('### 1. Attendees');
        for (final p in conv.participants) {
          final roleStr = (p.role != null && p.role!.isNotEmpty) ? ' (${p.role})' : '';
          buffer.writeln('- ${p.name}$roleStr ${p.isHost ? "(Host)" : ""}'.trim());
        }
        buffer.writeln('\n### 2. Decisions Reached & Key Resolutions');
        if (conv.decisions.isEmpty) {
          buffer.writeln('- None formally recorded');
        } else {
          for (final d in conv.decisions) {
            buffer.writeln('- ${d.decisionText}');
          }
        }
        buffer.writeln('\n### 3. Action Items');
        if (conv.actionItems.isEmpty) {
          buffer.writeln('- None pending');
        } else {
          for (final a in conv.actionItems) {
            buffer.writeln('- [ ] ${a.title} (${a.assignee ?? "Unassigned"})');
          }
        }
        break;

      case ReportType.interviewReport:
        buffer.writeln('## INTERVIEW PRACTICE EVALUATION');
        if (conv.assessments.isEmpty) {
          buffer.writeln('No practice assessments logged.');
        } else {
          for (final a in conv.assessments) {
            buffer.writeln('### Target Question: "${a.question}"');
            buffer.writeln('**Overall Score**: ${a.overallScore}/10');
            buffer.writeln('### Rubric Breakdown');
            buffer.writeln('**Strengths**: ${a.strengths.join(", ")}');
            buffer.writeln('**Improvements Needed**: ${a.areasForImprovement.join(", ")}');
            if (a.studyPlan.isNotEmpty) {
              buffer.writeln('### Targeted Study Plan');
              buffer.writeln('**Study Plan**: ${a.studyPlan.join(", ")}\n');
            }
          }
        }
        break;

      case ReportType.vocabularyReport:
        buffer.writeln('## VOCABULARY & TERMINOLOGY INDEX');
        final recordedWords = <String>{};
        for (final seg in conv.segments) {
          final words = seg.originalText.toLowerCase().split(RegExp(r'\s+'));
          for (final w in words) {
            final clean = w.replaceAll(RegExp(r'[^\w]'), '');
            if (clean.length > 4 && recordedWords.add(clean)) {
              buffer.writeln('- **$clean** (${seg.originalLanguage.toUpperCase()} → ${seg.targetLanguage.toUpperCase()})');
            }
          }
        }
        if (recordedWords.isEmpty) {
          buffer.writeln('No specific technical terminology isolated.');
        }
        break;
    }

    return buffer.toString();
  }
}
