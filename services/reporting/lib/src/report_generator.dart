import 'package:unicom_contracts/contracts.dart';

class ReportGenerator {
  GeneratedReport generateReport({
    required Conversation conversation,
    required ReportType type,
    String? customTitle,
  }) {
    final reportId = 'rep_${DateTime.now().millisecondsSinceEpoch}_${type.toJson()}';
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final title = customTitle ?? _defaultTitleForType(type, conversation.title);
    final content = _buildContentForType(type, conversation, title);

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

  String _buildContentForType(ReportType type, Conversation conv, String title) {
    final buffer = StringBuffer();
    buffer.writeln('# $title\n');
    buffer.writeln('**Date**: ${conv.startedAt}  ');
    buffer.writeln('**Mode**: ${conv.mode.toJson().toUpperCase()}  ');
    buffer.writeln('**Privacy Tier**: ${conv.executionMode.toJson().toUpperCase()}  ');
    buffer.writeln('**Participants**: ${conv.participants.map((p) => p.name).join(", ")}\n');
    buffer.writeln('---\n');

    switch (type) {
      case ReportType.quickSummary:
        buffer.writeln('## Overview');
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
        buffer.writeln('## Comprehensive Synthesis');
        buffer.writeln('Detailed breakdown across timeline and thematic topics.\n');
        buffer.writeln('### Discussion Highlights');
        for (final seg in conv.segments) {
          buffer.writeln('**${seg.speakerName}** (${seg.originalLanguage.toUpperCase()} → ${seg.targetLanguage.toUpperCase()}):');
          buffer.writeln('> "${seg.originalText}"');
          if (seg.translatedText.isNotEmpty && seg.translatedText != seg.originalText) {
            buffer.writeln('> *Translation*: "${seg.translatedText}"');
          }
          buffer.writeln();
        }
        break;

      case ReportType.fullTranscript:
        buffer.writeln('## Verified Dialogue Record');
        for (final seg in conv.segments) {
          buffer.writeln('**[${seg.startTime}ms] ${seg.speakerName}**:');
          buffer.writeln('- **Original**: ${seg.originalText}');
          if (seg.translatedText.isNotEmpty) {
            buffer.writeln('- **Translated**: ${seg.translatedText}');
          }
          buffer.writeln();
        }
        break;

      case ReportType.questionsReport:
        buffer.writeln('## Questions & Follow-Up Tracking');
        if (conv.questions.isEmpty) {
          buffer.writeln('No explicit inquiries detected in this session.');
        } else {
          for (final q in conv.questions) {
            buffer.writeln('### Question: "${q.questionText}"');
            buffer.writeln('- **Status**: ${q.isAnswered ? "Answered" : "Unresolved"}');
            if (q.answerText != null) {
              buffer.writeln('- **Recorded Answer**: ${q.answerText}');
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
        buffer.writeln('## Educational & Linguistic Insights');
        buffer.writeln('Key grammatical, cultural, and conceptual learnings from this exchange.\n');
        for (final seg in conv.segments) {
          if (seg.explanation != null) {
            buffer.writeln('### Concept: "${seg.originalText}"');
            final exp = seg.explanation!.explanations;
            if (exp.containsKey(ExplanationPersona.simple)) {
              buffer.writeln('- **Simple**: ${exp[ExplanationPersona.simple]!.content}');
            }
            if (exp.containsKey(ExplanationPersona.grammar)) {
              buffer.writeln('- **Grammar**: ${exp[ExplanationPersona.grammar]!.content}');
            }
            if (exp.containsKey(ExplanationPersona.culturalContext)) {
              buffer.writeln('- **Culture**: ${exp[ExplanationPersona.culturalContext]!.content}');
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
          buffer.writeln('| Status | Assignee | Task |');
          buffer.writeln('|:-------|:---------|:-----|');
          for (final act in conv.actionItems) {
            final icon = act.status == 'completed' ? '✓' : '○';
            buffer.writeln('| $icon ${act.status} | **${act.assignee ?? "Unassigned"}** | ${act.title} |');
          }
        }
        break;

      case ReportType.meetingMinutes:
        buffer.writeln('## Meeting Minutes');
        buffer.writeln('### 1. Attendance');
        for (final p in conv.participants) {
          buffer.writeln('- ${p.name} ${p.isHost ? "(Host)" : ""} ${p.role != null ? "- ${p.role}" : ""}');
        }
        buffer.writeln('\n### 2. Agenda Topics Discussed');
        for (final t in conv.topics) {
          buffer.writeln('- **${t.name}**');
        }
        buffer.writeln('\n### 3. Decisions Reached');
        for (final d in conv.decisions) {
          buffer.writeln('- ${d.decisionText}');
        }
        buffer.writeln('\n### 4. Action Items');
        for (final a in conv.actionItems) {
          buffer.writeln('- [ ] **${a.assignee}**: ${a.title}');
        }
        break;

      case ReportType.interviewReport:
        buffer.writeln('## Interview Practice Assessment & Study Plan');
        buffer.writeln('> *Note: This report is designed for self-assessment, transparent coaching, and skill enhancement. Permitted transcription and post-session study adhere strictly to candidate consent and assessment integrity policies.*\n');
        if (conv.assessments.isEmpty) {
          buffer.writeln('No formal interview question evaluations recorded in this session.');
        } else {
          for (final a in conv.assessments) {
            buffer.writeln('### Question Evaluated: "${a.question}"');
            buffer.writeln('**Candidate Answer**: "${a.candidateAnswer}"  ');
            buffer.writeln('**Overall Score**: ${a.overallScore}/10\n');
            buffer.writeln('#### Rubric Breakdown');
            for (final r in a.rubrics) {
              buffer.writeln('- **${r.criterion.toUpperCase()}** (${r.score}/10): ${r.feedback}');
            }
            buffer.writeln('\n#### Key Strengths');
            for (final s in a.strengths) {
              buffer.writeln('- $s');
            }
            buffer.writeln('\n#### Recommended Areas for Improvement');
            for (final imp in a.areasForImprovement) {
              buffer.writeln('- $imp');
            }
            buffer.writeln('\n#### Targeted Study Plan');
            for (final sp in a.studyPlan) {
              buffer.writeln('- $sp');
            }
            buffer.writeln();
          }
        }
        break;

      case ReportType.vocabularyReport:
        buffer.writeln('## Vocabulary & Terminology Glossary');
        for (final seg in conv.segments) {
          if (seg.explanation != null &&
              seg.explanation!.explanations.containsKey(ExplanationPersona.terminology)) {
            final termExp = seg.explanation!.explanations[ExplanationPersona.terminology]!;
            buffer.writeln('### Source Phrase: "${seg.originalText}"');
            buffer.writeln('${termExp.content}\n');
          }
        }
        break;
    }

    buffer.writeln('\n---\n*Report generated by Universal Communication Intelligence.*');
    return buffer.toString();
  }
}
