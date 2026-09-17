import 'dart:math';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

/// In-memory & local storage retrieval provider implementing vector/token-based RAG.
/// Operates 100% on-device for private offline knowledge search.
class RagRetrievalProvider implements RetrievalProvider {
  final Map<String, RetrievalDocument> _corpus = {};
  final PrivacyLogger _logger = const PrivacyLogger(context: 'RAG_RETRIEVAL');

  RagRetrievalProvider([List<RetrievalDocument>? initialDocs]) {
    if (initialDocs != null) {
      for (final doc in initialDocs) {
        _corpus[doc.id] = doc;
      }
    }
  }

  @override
  String get id => 'rag_local_retrieval_provider';

  @override
  String get name => 'Local Grounded RAG Retrieval Provider';

  @override
  bool get isOfflineCapable => true;

  @override
  Future<void> indexDocument(RetrievalDocument doc) async {
    _corpus[doc.id] = doc;
    _logger.info('Indexed document for local retrieval', {'id': doc.id, 'title': doc.title});
  }

  @override
  Future<bool> deleteDocument(String id) async {
    final removed = _corpus.remove(id);
    return removed != null;
  }

  @override
  Future<List<RetrievalDocument>> retrieve(String query, {int topK = 5}) async {
    if (_corpus.isEmpty || query.trim().isEmpty) {
      return [];
    }

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return [];

    final scoredDocs = <RetrievalDocument>[];

    for (final doc in _corpus.values) {
      final docTokens = _tokenize('${doc.title} ${doc.content}');
      double score = 0.0;

      // Token overlap & frequency scoring
      for (final qToken in queryTokens) {
        final matches = docTokens.where((t) => t == qToken).length;
        if (matches > 0) {
          // Weight title matches higher
          final titleMatches = _tokenize(doc.title).where((t) => t == qToken).length;
          score += 1.0 + (matches * 0.5) + (titleMatches * 2.0);
        }
      }

      if (score > 0) {
        // Normalize score between 0.0 and 1.0
        final normalizedScore = min(1.0, score / (queryTokens.length * 3.0));
        scoredDocs.add(RetrievalDocument(
          id: doc.id,
          title: doc.title,
          content: doc.content,
          sourceUri: doc.sourceUri,
          score: normalizedScore,
          metadata: doc.metadata,
        ));
      }
    }

    // Sort descending by relevance score
    scoredDocs.sort((a, b) => b.score.compareTo(a.score));

    return scoredDocs.take(topK).toList();
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
