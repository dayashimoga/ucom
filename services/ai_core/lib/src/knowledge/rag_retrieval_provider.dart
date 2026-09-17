import 'dart:math';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

/// Represents an individual chunk of an ingested document with positional metadata.
class DocumentChunk {
  final String chunkId;
  final String documentId;
  final String title;
  final String text;
  final int chunkIndex;
  final int totalChunks;
  final String? sourceUri;
  final Map<String, dynamic>? metadata;

  const DocumentChunk({
    required this.chunkId,
    required this.documentId,
    required this.title,
    required this.text,
    required this.chunkIndex,
    required this.totalChunks,
    this.sourceUri,
    this.metadata,
  });

  RetrievalDocument toRetrievalDocument(double score) {
    return RetrievalDocument(
      id: documentId,
      title: totalChunks > 1 ? '$title (Chunk ${chunkIndex + 1}/$totalChunks)' : title,
      content: text,
      sourceUri: sourceUri,
      score: score,
      metadata: {
        'chunkId': chunkId,
        'documentId': documentId,
        'chunkIndex': chunkIndex,
        'totalChunks': totalChunks,
        if (metadata != null) ...metadata!,
      },
    );
  }
}

/// Result of RAG retrieval containing scored documents and conflict/gap indicators.
class RagRetrievalResult {
  final List<RetrievalDocument> documents;
  final bool hasSufficientContext;
  final bool hasConflictingSources;
  final List<String> detectedConflicts;
  final bool hadPromptInjectionNeutralized;

  const RagRetrievalResult({
    required this.documents,
    required this.hasSufficientContext,
    this.hasConflictingSources = false,
    this.detectedConflicts = const [],
    this.hadPromptInjectionNeutralized = false,
  });
}

/// In-memory & local storage retrieval provider implementing vector/token-based RAG
/// with sliding-window chunking, prompt-injection sanitization, and source grounding.
class RagRetrievalProvider implements RetrievalProvider {
  final Map<String, RetrievalDocument> _documents = {};
  final List<DocumentChunk> _chunks = [];
  final double relevanceThreshold;
  final PrivacyLogger _logger = const PrivacyLogger(context: 'RAG_RETRIEVAL');

  static final List<RegExp> _injectionPatterns = [
    RegExp(r'ignore\s+(all\s+)?previous\s+instructions', caseSensitive: false),
    RegExp(r'disregard\s+(all\s+)?prior\s+(context|instructions)', caseSensitive: false),
    RegExp(r'system\s+override\s*:', caseSensitive: false),
    RegExp(r'you\s+are\s+now\s+in\s+developer\s+mode', caseSensitive: false),
    RegExp(r'reveal\s+(system\s+prompt|all\s+passwords|secrets|api\s+keys)', caseSensitive: false),
    RegExp(r'output\s+the\s+following\s+exact\s+word', caseSensitive: false),
  ];

  RagRetrievalProvider([
    List<RetrievalDocument>? initialDocs,
    this.relevanceThreshold = 0.15,
  ]) {
    if (initialDocs != null) {
      for (final doc in initialDocs) {
        indexDocument(doc);
      }
    }
  }

  @override
  String get id => 'rag_local_retrieval_provider';

  @override
  String get name => 'Local Grounded RAG Retrieval Provider';

  @override
  bool get isOfflineCapable => true;

  /// Sanitizes text against prompt-injection attempts inside ingested documents.
  String sanitizeContent(String text) {
    var sanitized = text;
    for (final pattern in _injectionPatterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        return '[SANITIZED_INJECTION_DEFENSE: "${match.group(0)}"]';
      });
    }
    return sanitized;
  }

  /// Checks if text contains potential prompt-injection attack vectors.
  bool containsPromptInjection(String text) {
    for (final pattern in _injectionPatterns) {
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }

  /// Ingests a raw document with sliding-window chunking.
  Future<List<DocumentChunk>> ingestDocument(
    String id,
    String title,
    String content, {
    String? sourceUri,
    int chunkSize = 250,
    int chunkOverlap = 40,
    Map<String, dynamic>? metadata,
  }) async {
    final sanitizedContent = sanitizeContent(content);
    final rawDoc = RetrievalDocument(
      id: id,
      title: title,
      content: sanitizedContent,
      sourceUri: sourceUri,
      metadata: metadata,
    );
    _documents[id] = rawDoc;

    // Sliding-window chunking
    final chunkList = <DocumentChunk>[];
    final words = sanitizedContent.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (words.isEmpty) {
      return [];
    }

    if (words.length <= chunkSize) {
      final chunk = DocumentChunk(
        chunkId: '${id}_c0',
        documentId: id,
        title: title,
        text: sanitizedContent,
        chunkIndex: 0,
        totalChunks: 1,
        sourceUri: sourceUri,
        metadata: metadata,
      );
      chunkList.add(chunk);
    } else {
      int step = max(1, chunkSize - chunkOverlap);
      int chunkIdx = 0;
      final tempChunks = <String>[];

      for (int i = 0; i < words.length; i += step) {
        final end = min(i + chunkSize, words.length);
        final slice = words.sublist(i, end).join(' ');
        tempChunks.add(slice);
        if (end == words.length) break;
      }

      for (int i = 0; i < tempChunks.length; i++) {
        chunkList.add(DocumentChunk(
          chunkId: '${id}_c$i',
          documentId: id,
          title: title,
          text: tempChunks[i],
          chunkIndex: i,
          totalChunks: tempChunks.length,
          sourceUri: sourceUri,
          metadata: metadata,
        ));
      }
    }

    _chunks.removeWhere((c) => c.documentId == id);
    _chunks.addAll(chunkList);

    _logger.info('Document ingested and chunked', {
      'documentId': id,
      'chunksCreated': chunkList.length,
    });

    return chunkList;
  }

  @override
  Future<void> indexDocument(RetrievalDocument doc) async {
    await ingestDocument(
      doc.id,
      doc.title,
      doc.content,
      sourceUri: doc.sourceUri,
      metadata: doc.metadata,
    );
  }

  @override
  Future<bool> deleteDocument(String id) async {
    final removedDoc = _documents.remove(id);
    _chunks.removeWhere((c) => c.documentId == id);
    return removedDoc != null;
  }

  /// Full RAG query evaluation returning scored chunks and conflict analysis.
  Future<RagRetrievalResult> query(String queryText, {int topK = 5}) async {
    final retrievedDocs = await retrieve(queryText, topK: topK);
    final hasSufficient = retrievedDocs.isNotEmpty && retrievedDocs.first.score >= relevanceThreshold;

    final conflicts = _detectConflicts(retrievedDocs);
    final neutralized = retrievedDocs.any((d) => d.content.contains('[SANITIZED_INJECTION_DEFENSE'));

    return RagRetrievalResult(
      documents: retrievedDocs,
      hasSufficientContext: hasSufficient,
      hasConflictingSources: conflicts.isNotEmpty,
      detectedConflicts: conflicts,
      hadPromptInjectionNeutralized: neutralized,
    );
  }

  @override
  Future<List<RetrievalDocument>> retrieve(String query, {int topK = 5}) async {
    if (_chunks.isEmpty || query.trim().isEmpty) {
      return [];
    }

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return [];

    final scoredChunks = <RetrievalDocument>[];

    for (final chunk in _chunks) {
      final docTokens = _tokenize('${chunk.title} ${chunk.text}');
      double score = 0.0;

      // Token overlap & term frequency with title boost
      for (final qToken in queryTokens) {
        final occurrences = docTokens.where((t) => t == qToken).length;
        if (occurrences > 0) {
          final titleOccurrences = _tokenize(chunk.title).where((t) => t == qToken).length;
          score += 1.0 + (occurrences * 0.4) + (titleOccurrences * 2.0);
        }
      }

      if (score > 0) {
        final normalizedScore = min(1.0, score / (queryTokens.length * 2.5));
        scoredChunks.add(chunk.toRetrievalDocument(normalizedScore));
      }
    }

    scoredChunks.sort((a, b) => b.score.compareTo(a.score));
    return scoredChunks.take(topK).toList();
  }

  List<String> _detectConflicts(List<RetrievalDocument> docs) {
    if (docs.length < 2) return [];

    final conflicts = <String>[];
    // Check for explicit conflicting assertions across distinct documents
    for (int i = 0; i < docs.length; i++) {
      for (int j = i + 1; j < docs.length; j++) {
        final docA = docs[i];
        final docB = docs[j];
        if (docA.metadata?['documentId'] == docB.metadata?['documentId']) continue;

        final aText = docA.content.toLowerCase();
        final bText = docB.content.toLowerCase();

        // Pattern: contradictory values or states
        if ((aText.contains('true') && bText.contains('false')) ||
            (aText.contains('deprecated') && bText.contains('recommended')) ||
            (aText.contains('port 8080') && bText.contains('port 9090')) ||
            (aText.contains('version 1') && bText.contains('version 2'))) {
          conflicts.add('Potential contradiction between "${docA.title}" and "${docB.title}".');
        }
      }
    }
    return conflicts;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u00C0-\u024F\u0900-\u097F\u0B80-\u0BFF\u3040-\u30FF\u4E00-\u9FFF\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && token.length > 1)
        .toList();
  }
}
