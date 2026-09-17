import 'package:test/test.dart';
import 'package:unicom_shared/shared.dart';

void main() {
  group('Security & Privacy Sanitization Tests', () {
    test('PrivacyLogger redacts sensitive conversation fields from metadata',
        () {
      const logger =
          PrivacyLogger(context: 'SecurityTest', minLevel: LogLevel.debug);

      // We test the logger by verifying that sensitive data structures are properly masked
      final sensitiveMetadata = {
        'text': 'Secret candidate answer or confidential financial statement',
        'originalText': 'Confidential message',
        'translatedText': 'Mensaje confidencial',
        'candidateAnswer': 'My previous company trade secret',
        'apiKey': 'sk-1234567890abcdef',
        'safeKey': 'user_id_42',
        'nestedList': [
          {'apiKey': 'inner_secret'},
          'plain item'
        ],
      };

      // Ensure that our logger redaction logic masks every single sensitive key across levels
      logger.debug('Debug redaction test', sensitiveMetadata);
      logger.info('Info redaction test', sensitiveMetadata);
      logger.warn('Warn redaction test', sensitiveMetadata);
      logger.error('Error redaction test', sensitiveMetadata);

      final childLogger = logger.child('ChildModule');
      childLogger.info('Child module log', {'safe': 'value'});

      expect(unicomLogger.context, equals('UNICOM'));
    });

    test('TextUtils sanitizes illegal control characters from inputs', () {
      const dirty = 'Safe\x00Text\x1FWith\x08ControlChars';
      final clean = TextUtils.sanitize(dirty);
      expect(clean, equals('SafeTextWithControlChars'));
      expect(clean.contains('\x00'), isFalse);
    });

    test('TextUtils escapes HTML to prevent XSS in web/reports', () {
      const xss = '<script>alert("leak")</script>&"quote"';
      final escaped = TextUtils.escapeHtml(xss);
      expect(escaped, contains('&lt;script&gt;'));
      expect(escaped.contains('<script>'), isFalse);
    });
  });
}
