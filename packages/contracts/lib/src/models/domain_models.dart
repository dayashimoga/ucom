import 'enums.dart';

class Participant {
  final String id;
  final String name;
  final String? role;
  final bool isHost;
  final String? preferredLanguage;

  Participant({
    required this.id,
    required this.name,
    this.role,
    this.isHost = false,
    this.preferredLanguage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (role != null) 'role': role,
        'isHost': isHost,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
      };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String?,
        isHost: json['isHost'] as bool? ?? false,
        preferredLanguage: json['preferredLanguage'] as String?,
      );
}

class ExplanationEntry {
  final ExplanationPersona persona;
  final String content;
  final List<String> keyPoints;

  ExplanationEntry({
    required this.persona,
    required this.content,
    this.keyPoints = const [],
  });

  Map<String, dynamic> toJson() => {
        'persona': persona.toJson(),
        'content': content,
        'keyPoints': keyPoints,
      };

  factory ExplanationEntry.fromJson(Map<String, dynamic> json) =>
      ExplanationEntry(
        persona: ExplanationPersona.fromJson(json['persona'] as String),
        content: json['content'] as String,
        keyPoints: (json['keyPoints'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}

class ExplanationResult {
  final String id;
  final String? segmentId;
  final String originalText;
  final String? translatedText;
  final String? targetLanguage;
  final Map<ExplanationPersona, ExplanationEntry> explanations;
  final String createdAt;

  ExplanationResult({
    required this.id,
    this.segmentId,
    required this.originalText,
    this.translatedText,
    this.targetLanguage,
    required this.explanations,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (segmentId != null) 'segmentId': segmentId,
        'originalText': originalText,
        if (translatedText != null) 'translatedText': translatedText,
        if (targetLanguage != null) 'targetLanguage': targetLanguage,
        'explanations': explanations.map(
            (key, value) => MapEntry(key.toJson(), value.toJson())),
        'createdAt': createdAt,
      };

  factory ExplanationResult.fromJson(Map<String, dynamic> json) {
    final expMap = <ExplanationPersona, ExplanationEntry>{};
    if (json['explanations'] != null) {
      final raw = json['explanations'] as Map<String, dynamic>;
      raw.forEach((k, v) {
        final persona = ExplanationPersona.fromJson(k);
        expMap[persona] =
            ExplanationEntry.fromJson(v as Map<String, dynamic>);
      });
    }
    return ExplanationResult(
      id: json['id'] as String,
      segmentId: json['segmentId'] as String?,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String?,
      targetLanguage: json['targetLanguage'] as String?,
      explanations: expMap,
      createdAt: json['createdAt'] as String,
    );
  }
}

class ConversationSegment {
  final String id;
  final String speakerId;
  final String speakerName;
  final int startTime;
  final int? endTime;
  final String originalText;
  final String originalLanguage;
  final String translatedText;
  final String targetLanguage;
  final double confidence;
  final ExplanationResult? explanation;
  final bool isFinal;

  ConversationSegment({
    required this.id,
    required this.speakerId,
    required this.speakerName,
    required this.startTime,
    this.endTime,
    required this.originalText,
    required this.originalLanguage,
    required this.translatedText,
    required this.targetLanguage,
    this.confidence = 1.0,
    this.explanation,
    this.isFinal = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'speakerId': speakerId,
        'speakerName': speakerName,
        'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        'originalText': originalText,
        'originalLanguage': originalLanguage,
        'translatedText': translatedText,
        'targetLanguage': targetLanguage,
        'confidence': confidence,
        if (explanation != null) 'explanation': explanation!.toJson(),
        'isFinal': isFinal,
      };

  factory ConversationSegment.fromJson(Map<String, dynamic> json) =>
      ConversationSegment(
        id: json['id'] as String,
        speakerId: json['speakerId'] as String,
        speakerName: json['speakerName'] as String,
        startTime: json['startTime'] as int,
        endTime: json['endTime'] as int?,
        originalText: json['originalText'] as String,
        originalLanguage: json['originalLanguage'] as String,
        translatedText: json['translatedText'] as String,
        targetLanguage: json['targetLanguage'] as String,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        explanation: json['explanation'] != null
            ? ExplanationResult.fromJson(
                json['explanation'] as Map<String, dynamic>)
            : null,
        isFinal: json['isFinal'] as bool? ?? true,
      );
}

class ExtractedQuestion {
  final String id;
  final String? segmentId;
  final String questionText;
  final String? askedBySpeakerId;
  final String? answerText;
  final bool isAnswered;
  final List<String> followUpQuestions;

  ExtractedQuestion({
    required this.id,
    this.segmentId,
    required this.questionText,
    this.askedBySpeakerId,
    this.answerText,
    this.isAnswered = false,
    this.followUpQuestions = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (segmentId != null) 'segmentId': segmentId,
        'questionText': questionText,
        if (askedBySpeakerId != null) 'askedBySpeakerId': askedBySpeakerId,
        if (answerText != null) 'answerText': answerText,
        'isAnswered': isAnswered,
        'followUpQuestions': followUpQuestions,
      };

  factory ExtractedQuestion.fromJson(Map<String, dynamic> json) =>
      ExtractedQuestion(
        id: json['id'] as String,
        segmentId: json['segmentId'] as String?,
        questionText: json['questionText'] as String,
        askedBySpeakerId: json['askedBySpeakerId'] as String?,
        answerText: json['answerText'] as String?,
        isAnswered: json['isAnswered'] as bool? ?? false,
        followUpQuestions: (json['followUpQuestions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}

class ActionItem {
  final String id;
  final String title;
  final String? assignee;
  final String? dueDate;
  final String status; // pending, in_progress, completed
  final String? segmentId;

  ActionItem({
    required this.id,
    required this.title,
    this.assignee,
    this.dueDate,
    this.status = 'pending',
    this.segmentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (assignee != null) 'assignee': assignee,
        if (dueDate != null) 'dueDate': dueDate,
        'status': status,
        if (segmentId != null) 'segmentId': segmentId,
      };

  factory ActionItem.fromJson(Map<String, dynamic> json) => ActionItem(
        id: json['id'] as String,
        title: json['title'] as String,
        assignee: json['assignee'] as String?,
        dueDate: json['dueDate'] as String?,
        status: json['status'] as String? ?? 'pending',
        segmentId: json['segmentId'] as String?,
      );
}

class DecisionItem {
  final String id;
  final String decisionText;
  final String? context;
  final String? segmentId;

  DecisionItem({
    required this.id,
    required this.decisionText,
    this.context,
    this.segmentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'decisionText': decisionText,
        if (context != null) 'context': context,
        if (segmentId != null) 'segmentId': segmentId,
      };

  factory DecisionItem.fromJson(Map<String, dynamic> json) => DecisionItem(
        id: json['id'] as String,
        decisionText: json['decisionText'] as String,
        context: json['context'] as String?,
        segmentId: json['segmentId'] as String?,
      );
}

class TopicItem {
  final String id;
  final String name;
  final List<String> keywords;
  final double relevanceScore;

  TopicItem({
    required this.id,
    required this.name,
    this.keywords = const [],
    this.relevanceScore = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'keywords': keywords,
        'relevanceScore': relevanceScore,
      };

  factory TopicItem.fromJson(Map<String, dynamic> json) => TopicItem(
        id: json['id'] as String,
        name: json['name'] as String,
        keywords: (json['keywords'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        relevanceScore:
            (json['relevanceScore'] as num?)?.toDouble() ?? 1.0,
      );
}

class InterviewRubricScore {
  final String criterion;
  final int score; // 1-10
  final String feedback;

  InterviewRubricScore({
    required this.criterion,
    required this.score,
    required this.feedback,
  });

  Map<String, dynamic> toJson() => {
        'criterion': criterion,
        'score': score,
        'feedback': feedback,
      };

  factory InterviewRubricScore.fromJson(Map<String, dynamic> json) =>
      InterviewRubricScore(
        criterion: json['criterion'] as String,
        score: json['score'] as int,
        feedback: json['feedback'] as String,
      );
}

class InterviewAssessment {
  final String id;
  final String question;
  final String candidateAnswer;
  final int overallScore; // 1-10
  final List<InterviewRubricScore> rubrics;
  final List<String> strengths;
  final List<String> areasForImprovement;
  final List<String> recommendedFollowUps;
  final List<String> studyPlan;
  final String createdAt;

  InterviewAssessment({
    required this.id,
    required this.question,
    required this.candidateAnswer,
    required this.overallScore,
    this.rubrics = const [],
    this.strengths = const [],
    this.areasForImprovement = const [],
    this.recommendedFollowUps = const [],
    this.studyPlan = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'candidateAnswer': candidateAnswer,
        'overallScore': overallScore,
        'rubrics': rubrics.map((e) => e.toJson()).toList(),
        'strengths': strengths,
        'areasForImprovement': areasForImprovement,
        'recommendedFollowUps': recommendedFollowUps,
        'studyPlan': studyPlan,
        'createdAt': createdAt,
      };

  factory InterviewAssessment.fromJson(Map<String, dynamic> json) =>
      InterviewAssessment(
        id: json['id'] as String,
        question: json['question'] as String,
        candidateAnswer: json['candidateAnswer'] as String,
        overallScore: json['overallScore'] as int,
        rubrics: (json['rubrics'] as List<dynamic>?)
                ?.map((e) =>
                    InterviewRubricScore.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        strengths: (json['strengths'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        areasForImprovement: (json['areasForImprovement'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        recommendedFollowUps:
            (json['recommendedFollowUps'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                const [],
        studyPlan: (json['studyPlan'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        createdAt: json['createdAt'] as String,
      );
}

class Conversation {
  final String id;
  final String title;
  final ApplicationMode mode;
  final ExecutionMode executionMode;
  final String startedAt;
  final String? endedAt;
  final List<Participant> participants;
  final List<ConversationSegment> segments;
  final List<ExtractedQuestion> questions;
  final List<TopicItem> topics;
  final List<DecisionItem> decisions;
  final List<ActionItem> actionItems;
  final List<String> unresolvedQuestions;
  final List<InterviewAssessment> assessments;
  final Map<String, dynamic>? metadata;

  Conversation({
    required this.id,
    required this.title,
    this.mode = ApplicationMode.general,
    this.executionMode = ExecutionMode.privateOffline,
    required this.startedAt,
    this.endedAt,
    this.participants = const [],
    this.segments = const [],
    this.questions = const [],
    this.topics = const [],
    this.decisions = const [],
    this.actionItems = const [],
    this.unresolvedQuestions = const [],
    this.assessments = const [],
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'mode': mode.toJson(),
        'executionMode': executionMode.toJson(),
        'startedAt': startedAt,
        if (endedAt != null) 'endedAt': endedAt,
        'participants': participants.map((e) => e.toJson()).toList(),
        'segments': segments.map((e) => e.toJson()).toList(),
        'questions': questions.map((e) => e.toJson()).toList(),
        'topics': topics.map((e) => e.toJson()).toList(),
        'decisions': decisions.map((e) => e.toJson()).toList(),
        'actionItems': actionItems.map((e) => e.toJson()).toList(),
        'unresolvedQuestions': unresolvedQuestions,
        'assessments': assessments.map((e) => e.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        title: json['title'] as String,
        mode: ApplicationMode.fromJson(json['mode'] as String? ?? 'general'),
        executionMode: ExecutionMode.fromJson(
            json['executionMode'] as String? ?? 'private_offline'),
        startedAt: json['startedAt'] as String,
        endedAt: json['endedAt'] as String?,
        participants: (json['participants'] as List<dynamic>?)
                ?.map((e) => Participant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        segments: (json['segments'] as List<dynamic>?)
                ?.map((e) =>
                    ConversationSegment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        questions: (json['questions'] as List<dynamic>?)
                ?.map((e) =>
                    ExtractedQuestion.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        topics: (json['topics'] as List<dynamic>?)
                ?.map((e) => TopicItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        decisions: (json['decisions'] as List<dynamic>?)
                ?.map((e) => DecisionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        actionItems: (json['actionItems'] as List<dynamic>?)
                ?.map((e) => ActionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        unresolvedQuestions: (json['unresolvedQuestions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        assessments: (json['assessments'] as List<dynamic>?)
                ?.map((e) =>
                    InterviewAssessment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

class GeneratedReport {
  final String id;
  final String conversationId;
  final ReportType reportType;
  final String title;
  final String content;
  final String createdAt;
  final Map<String, dynamic>? metadata;

  GeneratedReport({
    required this.id,
    required this.conversationId,
    required this.reportType,
    required this.title,
    required this.content,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'reportType': reportType.toJson(),
        'title': title,
        'content': content,
        'createdAt': createdAt,
        if (metadata != null) 'metadata': metadata,
      };

  factory GeneratedReport.fromJson(Map<String, dynamic> json) =>
      GeneratedReport(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        reportType: ReportType.fromJson(json['reportType'] as String),
        title: json['title'] as String,
        content: json['content'] as String,
        createdAt: json['createdAt'] as String,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

class ModelMetadata {
  final String id;
  final String name;
  final String version;
  final String type; // stt, translation, tts, llm, embeddings
  final int sizeBytes;
  final String sha256;
  final String license;
  final bool isInstalled;
  final bool isActive;
  final bool isDownloadable;
  final String? downloadUrl;
  final List<String> supportedLanguages;
  final List<String> capabilities;

  ModelMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.type,
    required this.sizeBytes,
    required this.sha256,
    required this.license,
    this.isInstalled = false,
    this.isActive = false,
    this.isDownloadable = true,
    this.downloadUrl,
    this.supportedLanguages = const [],
    this.capabilities = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'type': type,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'license': license,
        'isInstalled': isInstalled,
        'isActive': isActive,
        'isDownloadable': isDownloadable,
        if (downloadUrl != null) 'downloadUrl': downloadUrl,
        'supportedLanguages': supportedLanguages,
        'capabilities': capabilities,
      };

  factory ModelMetadata.fromJson(Map<String, dynamic> json) => ModelMetadata(
        id: json['id'] as String,
        name: json['name'] as String,
        version: json['version'] as String,
        type: json['type'] as String,
        sizeBytes: json['sizeBytes'] as int,
        sha256: json['sha256'] as String,
        license: json['license'] as String,
        isInstalled: json['isInstalled'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? false,
        isDownloadable: json['isDownloadable'] as bool? ?? true,
        downloadUrl: json['downloadUrl'] as String?,
        supportedLanguages: (json['supportedLanguages'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        capabilities: (json['capabilities'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}
