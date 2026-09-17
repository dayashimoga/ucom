import 'dart:convert';

enum LogLevel { debug, info, warn, error }

/// Structured logger that strictly masks sensitive conversation content from logs.
class PrivacyLogger {
  final String context;
  final LogLevel minLevel;

  static const Set<String> _sensitiveKeys = {
    'text',
    'originalText',
    'translatedText',
    'content',
    'candidateAnswer',
    'audio',
    'audioBytes',
    'apiKey',
    'secret',
    'authorization',
  };

  const PrivacyLogger({
    this.context = 'UNICOM',
    this.minLevel = LogLevel.info,
  });

  bool _shouldLog(LogLevel level) => level.index >= minLevel.index;

  dynamic _sanitize(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final clean = <String, dynamic>{};
      data.forEach((k, v) {
        final keyStr = k.toString();
        if (_sensitiveKeys.contains(keyStr)) {
          clean[keyStr] = '[REDACTED_CONTENT]';
        } else {
          clean[keyStr] = _sanitize(v);
        }
      });
      return clean;
    }
    if (data is List) {
      return data.map(_sanitize).toList();
    }
    return data;
  }

  void _output(LogLevel level, String message, [Map<String, dynamic>? meta]) {
    if (!_shouldLog(level)) return;
    final logPayload = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level.name.toUpperCase(),
      'context': context,
      'message': message,
      if (meta != null) 'metadata': _sanitize(meta),
    };
    print(jsonEncode(logPayload));
  }

  void debug(String message, [Map<String, dynamic>? meta]) =>
      _output(LogLevel.debug, message, meta);

  void info(String message, [Map<String, dynamic>? meta]) =>
      _output(LogLevel.info, message, meta);

  void warn(String message, [Map<String, dynamic>? meta]) =>
      _output(LogLevel.warn, message, meta);

  void error(String message, [Map<String, dynamic>? meta]) =>
      _output(LogLevel.error, message, meta);

  PrivacyLogger child(String subContext) =>
      PrivacyLogger(context: '$context:$subContext', minLevel: minLevel);
}

const unicomLogger = PrivacyLogger();
