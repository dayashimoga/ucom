import 'dart:convert';
import 'dart:io';
import 'package:unicom_contracts/contracts.dart';
import '../errors/exceptions.dart';
import '../logging/privacy_logger.dart';

/// A robust, file-backed, durable implementation of [StorageProvider].
///
/// Features:
/// - Atomic writes using `.tmp` files and atomic filesystem rename to prevent corruption on crash/power-cut.
/// - Self-healing and corrupt record quarantining to prevent data loss cascades.
/// - Disk quota and storage-full enforcement.
/// - Data retention, auto-expiry, and audit metadata.
/// - Schema versioning and migration hooks.
class DurableFileStorageProvider implements StorageProvider {
  final Directory baseDirectory;
  final int? maxStorageBytes;
  final int schemaVersion;
  final PrivacyLogger _logger = const PrivacyLogger();

  static const int currentSchemaVersion = 1;

  DurableFileStorageProvider({
    required this.baseDirectory,
    this.maxStorageBytes,
    this.schemaVersion = currentSchemaVersion,
  }) {
    _ensureDirectories();
  }

  @override
  String get id => 'durable_file_storage_provider';

  @override
  String get name => 'Durable Local File Storage';

  Directory get _conversationsDir =>
      Directory('${baseDirectory.path}/conversations');
  Directory get _reportsDir => Directory('${baseDirectory.path}/reports');
  Directory get _quarantineDir => Directory('${baseDirectory.path}/quarantine');
  File get _metadataFile => File('${baseDirectory.path}/metadata.json');

  void _ensureDirectories() {
    if (!baseDirectory.existsSync()) baseDirectory.createSync(recursive: true);
    if (!_conversationsDir.existsSync())
      _conversationsDir.createSync(recursive: true);
    if (!_reportsDir.existsSync()) _reportsDir.createSync(recursive: true);
    if (!_quarantineDir.existsSync())
      _quarantineDir.createSync(recursive: true);

    if (!_metadataFile.existsSync()) {
      _metadataFile.writeAsStringSync(jsonEncode({
        'schemaVersion': schemaVersion,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'app': 'UNICOM AI',
      }));
    }
  }

  Future<void> _checkStorageQuota(int additionalBytes) async {
    if (maxStorageBytes == null) return;
    final currentBytes = await getTotalStorageBytes();
    if (currentBytes + additionalBytes > maxStorageBytes!) {
      throw StorageFullException(
        'Storage quota exceeded: current=$currentBytes bytes, additional=$additionalBytes bytes, limit=$maxStorageBytes bytes',
      );
    }
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final payload = {
      '_schemaVersion': schemaVersion,
      '_updatedAt': DateTime.now().toUtc().toIso8601String(),
      'data': conversation.toJson(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final bytes = utf8.encode(jsonStr);

    await _checkStorageQuota(bytes.length);

    final targetFile =
        File('${_conversationsDir.path}/${conversation.id}.json');
    final tempFile = File('${_conversationsDir.path}/${conversation.id}.tmp');

    // Atomic write
    await tempFile.writeAsBytes(bytes, flush: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);

    _logger.info(
      'conversation_saved',
      {'conversationId': conversation.id, 'bytes': bytes.length},
    );
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    final file = File('${_conversationsDir.path}/$id.json');
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;

      // Migrate if older schema
      final migratedData = _applyMigrations(map);
      return Conversation.fromJson(
          migratedData['data'] as Map<String, dynamic>);
    } catch (e) {
      // Quarantine corrupt record
      final quarantinePath =
          '${_quarantineDir.path}/${id}_${DateTime.now().millisecondsSinceEpoch}.corrupt';
      await file.rename(quarantinePath);

      _logger.warn(
        'corrupt_record_quarantined',
        {
          'id': id,
          'quarantinePath': quarantinePath,
          'error': e.toString(),
        },
      );
      return null;
    }
  }

  @override
  Future<List<Conversation>> listConversations({
    String? query,
    ApplicationMode? mode,
    ExecutionMode? executionMode,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!await _conversationsDir.exists()) return [];

    final files = await _conversationsDir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final conversations = <Conversation>[];

    for (final file in files) {
      final id = file.uri.pathSegments.last.replaceAll('.json', '');
      final conv = await getConversation(id);
      if (conv != null) {
        conversations.add(conv);
      }
    }

    var filtered = conversations;

    if (mode != null) {
      filtered = filtered.where((c) => c.mode == mode).toList();
    }
    if (executionMode != null) {
      filtered =
          filtered.where((c) => c.executionMode == executionMode).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.segments.any((s) =>
                s.originalText.toLowerCase().contains(q) ||
                s.translatedText.toLowerCase().contains(q));
      }).toList();
    }

    filtered.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    if (offset >= filtered.length) return [];
    final end = (offset + limit).clamp(0, filtered.length);
    return filtered.sublist(offset, end);
  }

  @override
  Future<bool> deleteConversation(String id) async {
    final convFile = File('${_conversationsDir.path}/$id.json');
    var existed = false;
    if (await convFile.exists()) {
      await convFile.delete();
      existed = true;
    }

    // Delete associated reports
    if (await _reportsDir.exists()) {
      final reportFiles = await _reportsDir
          .list()
          .where(
              (e) => e is File && e.uri.pathSegments.last.startsWith('${id}_'))
          .cast<File>()
          .toList();
      for (final rf in reportFiles) {
        await rf.delete();
      }
    }

    return existed;
  }

  @override
  Future<void> saveReport(GeneratedReport report) async {
    final payload = {
      '_schemaVersion': schemaVersion,
      '_createdAt': DateTime.now().toUtc().toIso8601String(),
      'data': report.toJson(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final bytes = utf8.encode(jsonStr);

    await _checkStorageQuota(bytes.length);

    final targetFile =
        File('${_reportsDir.path}/${report.conversationId}_${report.id}.json');
    final tempFile =
        File('${_reportsDir.path}/${report.conversationId}_${report.id}.tmp');

    await tempFile.writeAsBytes(bytes, flush: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);
  }

  @override
  Future<List<GeneratedReport>> getReportsByConversationId(
      String conversationId) async {
    if (!await _reportsDir.exists()) return [];

    final files = await _reportsDir
        .list()
        .where((e) =>
            e is File &&
            e.uri.pathSegments.last.startsWith('${conversationId}_') &&
            e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final reports = <GeneratedReport>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        final reportData =
            map.containsKey('data') ? map['data'] as Map<String, dynamic> : map;
        reports.add(GeneratedReport.fromJson(reportData));
      } catch (e) {
        // Quarantine corrupt report
        final qPath =
            '${_quarantineDir.path}/${file.uri.pathSegments.last}.corrupt';
        await file.rename(qPath);
      }
    }

    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  @override
  Future<List<Conversation>> searchConversations(String query,
      {int limit = 20}) async {
    return listConversations(query: query, limit: limit);
  }

  /// Purges conversations and reports older than [maxAge].
  Future<int> purgeExpired(Duration maxAge) async {
    final threshold = DateTime.now().toUtc().subtract(maxAge);
    final all = await listConversations(limit: 10000);
    var purgedCount = 0;

    for (final conv in all) {
      final startedAt = DateTime.tryParse(conv.startedAt);
      if (startedAt != null && startedAt.isBefore(threshold)) {
        await deleteConversation(conv.id);
        purgedCount++;
      }
    }
    return purgedCount;
  }

  /// Enforces a maximum number of conversations retained on device.
  Future<int> enforceRetentionLimit({int maxConversations = 1000}) async {
    final all = await listConversations(limit: 10000);
    if (all.length <= maxConversations) return 0;

    final toRemove = all.sublist(maxConversations);
    for (final conv in toRemove) {
      await deleteConversation(conv.id);
    }
    return toRemove.length;
  }

  /// Calculates the total disk space utilized by local conversations, reports, and quarantine.
  Future<int> getTotalStorageBytes() async {
    var total = 0;
    for (final dir in [_conversationsDir, _reportsDir, _quarantineDir]) {
      if (await dir.exists()) {
        await for (final entity
            in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
    }
    return total;
  }

  /// Retrieves list of quarantined corrupt files.
  Future<List<String>> getQuarantinedFiles() async {
    if (!await _quarantineDir.exists()) return [];
    return _quarantineDir
        .list()
        .where((e) => e is File)
        .map((e) => e.path)
        .toList();
  }

  Map<String, dynamic> _applyMigrations(Map<String, dynamic> raw) {
    var version = raw['_schemaVersion'] as int? ?? 0;
    var data = raw['data'] as Map<String, dynamic>? ?? raw;

    // Upward migration steps
    if (version < 1) {
      data['metadata'] ??= <String, dynamic>{'migratedFromV0': true};
      data['executionMode'] ??= 'private_offline';
      version = 1;
    }

    return {'_schemaVersion': version, 'data': data};
  }
}
