import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

/// Production storage provider for UNICOM AI application.
/// Uses DurableFileStorageProvider on desktop/mobile platforms for atomic writes,
/// corrupt file quarantine, quota enforcement, and retention cleanup.
class LocalStorageProvider implements StorageProvider {
  final StorageProvider _delegate;

  LocalStorageProvider([Directory? storageDirectory])
      : _delegate = (!kIsWeb)
            ? DurableFileStorageProvider(
                baseDirectory: storageDirectory ??
                    Directory('${Directory.systemTemp.path}/unicom_app_data'),
              )
            : InMemoryStorageProvider();

  LocalStorageProvider.inMemory() : _delegate = InMemoryStorageProvider();

  @override
  String get id => _delegate.id;

  @override
  String get name => _delegate.name;

  @override
  Future<void> saveConversation(Conversation conversation) =>
      _delegate.saveConversation(conversation);

  @override
  Future<Conversation?> getConversation(String id) =>
      _delegate.getConversation(id);

  @override
  Future<List<Conversation>> listConversations({
    String? query,
    ApplicationMode? mode,
    ExecutionMode? executionMode,
    int limit = 50,
    int offset = 0,
  }) =>
      _delegate.listConversations(
        query: query,
        mode: mode,
        executionMode: executionMode,
        limit: limit,
        offset: offset,
      );

  @override
  Future<bool> deleteConversation(String id) =>
      _delegate.deleteConversation(id);

  @override
  Future<void> saveReport(GeneratedReport report) =>
      _delegate.saveReport(report);

  @override
  Future<List<GeneratedReport>> getReportsByConversationId(
          String conversationId) =>
      _delegate.getReportsByConversationId(conversationId);

  @override
  Future<List<Conversation>> searchConversations(String query,
          {int limit = 20}) =>
      _delegate.searchConversations(query, limit: limit);
}

class InMemoryStorageProvider implements StorageProvider {
  final Map<String, Conversation> _conversations = {};
  final List<GeneratedReport> _reports = [];

  @override
  String get id => 'in_memory_web_storage';

  @override
  String get name => 'In-Memory Web Storage';

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
    if (mode != null) items = items.where((c) => c.mode == mode).toList();
    if (executionMode != null) {
      items = items.where((c) => c.executionMode == executionMode).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      items = items
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              c.segments.any((s) =>
                  s.originalText.toLowerCase().contains(q) ||
                  s.translatedText.toLowerCase().contains(q)))
          .toList();
    }
    items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (offset >= items.length) return [];
    return items.sublist(offset, (offset + limit).clamp(0, items.length));
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
  Future<List<GeneratedReport>> getReportsByConversationId(
      String conversationId) async {
    return _reports.where((r) => r.conversationId == conversationId).toList();
  }

  @override
  Future<List<Conversation>> searchConversations(String query,
      {int limit = 20}) async {
    return listConversations(query: query, limit: limit);
  }
}
