import 'package:unicom_contracts/contracts.dart';

class LocalStorageProvider implements StorageProvider {
  final Map<String, Conversation> _conversations = {};
  final List<GeneratedReport> _reports = [];

  @override
  String get id => 'local_storage_provider';

  @override
  String get name => 'On-Device Local Storage';

  @override
  Future<void> saveConversation(Conversation conversation) async {
    _conversations[conversation.id] = conversation;
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    return _conversations[id];
  }

  @override
  Future<List<Conversation>> listConversations({
    String? query,
    ApplicationMode? mode,
    ExecutionMode? executionMode,
    int limit = 50,
    int offset = 0,
  }) async {
    var items = _conversations.values.toList();

    if (mode != null) {
      items = items.where((c) => c.mode == mode).toList();
    }
    if (executionMode != null) {
      items = items.where((c) => c.executionMode == executionMode).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      items = items.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.segments.any((s) => s.originalText.toLowerCase().contains(q) || s.translatedText.toLowerCase().contains(q));
      }).toList();
    }

    items.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    if (offset >= items.length) return [];
    final end = (offset + limit).clamp(0, items.length);
    return items.sublist(offset, end);
  }

  @override
  Future<bool> deleteConversation(String id) async {
    final existed = _conversations.remove(id) != null;
    _reports.removeWhere((r) => r.conversationId == id);
    return existed;
  }

  @override
  Future<void> saveReport(GeneratedReport report) async {
    _reports.add(report);
  }

  @override
  Future<List<GeneratedReport>> getReportsByConversationId(String conversationId) async {
    return _reports.where((r) => r.conversationId == conversationId).toList();
  }

  @override
  Future<List<Conversation>> searchConversations(String query, {int limit = 20}) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final matches = _conversations.values.where((c) {
      if (c.title.toLowerCase().contains(q)) return true;
      for (final s in c.segments) {
        if (s.originalText.toLowerCase().contains(q) || s.translatedText.toLowerCase().contains(q)) {
          return true;
        }
      }
      for (final t in c.topics) {
        if (t.name.toLowerCase().contains(q)) return true;
      }
      return false;
    }).take(limit).toList();

    return matches;
  }
}
