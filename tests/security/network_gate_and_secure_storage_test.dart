import 'dart:io';
import 'package:test/test.dart';
import 'package:unicom_shared/shared.dart';

void main() {
  group('NetworkGate Defense-In-Depth Security Tests', () {
    late NetworkGate gate;

    setUp(() {
      gate = NetworkGate();
      gate.clearAuditLog();
    });

    test('enforces strict private_offline blocking and records audit telemetry',
        () {
      gate.setOfflineEnforcement(true);
      expect(gate.isOfflineEnforced, isTrue);

      expect(
        () => gate.checkOutboundAccess(
            'https://generativelanguage.googleapis.com',
            method: 'POST',
            payloadBytes: 128),
        throwsA(isA<OfflineViolationException>()),
      );

      final logs = gate.auditLog;
      expect(logs.length, equals(1));
      expect(logs.first.blocked, isTrue);
      expect(logs.first.destination, contains('googleapis.com'));
      expect(logs.first.method, equals('POST'));
      expect(logs.first.payloadBytes, equals(128));
      expect(logs.first.reason, contains('Strict private_offline'));

      final json = logs.first.toJson();
      expect(json['blocked'], isTrue);
      expect(json['method'], equals('POST'));
    });

    test('permits outbound requests when offline enforcement is disabled', () {
      gate.setOfflineEnforcement(false);
      expect(gate.isOfflineEnforced, isFalse);

      expect(
        () => gate.checkOutboundAccess(
            'https://generativelanguage.googleapis.com',
            method: 'GET'),
        returnsNormally,
      );

      final logs = gate.auditLog;
      expect(logs.length, equals(1));
      expect(logs.first.blocked, isFalse);
      expect(logs.first.reason, contains('Allowed'));

      gate.clearAuditLog();
      expect(gate.auditLog, isEmpty);
    });

    test(
        'HttpOverrides interceptor installs, intercepts all HTTP methods, and removes safely',
        () async {
      gate.setOfflineEnforcement(true);
      gate.installGlobalInterceptor();
      expect(HttpOverrides.current, isNotNull);

      final client = HttpClient();

      expect(() => client.getUrl(Uri.parse('https://example.com/test')),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.postUrl(Uri.parse('https://example.com/test')),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.putUrl(Uri.parse('https://example.com/test')),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.deleteUrl(Uri.parse('https://example.com/test')),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.patchUrl(Uri.parse('https://example.com/test')),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.headUrl(Uri.parse('https://example.com/test')),
          throwsA(isA<OfflineViolationException>()));

      expect(() => client.get('example.com', 80, '/test'),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.post('example.com', 80, '/test'),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.put('example.com', 80, '/test'),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.delete('example.com', 80, '/test'),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.patch('example.com', 80, '/test'),
          throwsA(isA<OfflineViolationException>()));
      expect(() => client.head('example.com', 80, '/test'),
          throwsA(isA<OfflineViolationException>()));

      client.close(force: true);

      // Verify removal
      gate.removeGlobalInterceptor();
      expect(HttpOverrides.current, isNull);
    });
  });

  group('SecureKeyStorage Cryptographic Vault Tests', () {
    late Directory tempDir;
    late SecureKeyStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('unicom_vault_test_');
      storage = SecureKeyStorage(storageDir: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves, verifies, reads, and deletes encrypted API key secrets',
        () async {
      expect(await storage.hasKey('gemini_api_key'), isFalse);
      expect(await storage.getKey('gemini_api_key'), isNull);

      await storage.saveKey(
          'gemini_api_key', 'AIzaSy_production_secret_key_12345');
      expect(await storage.hasKey('gemini_api_key'), isTrue);

      final retrieved = await storage.getKey('gemini_api_key');
      expect(retrieved, equals('AIzaSy_production_secret_key_12345'));

      // Check on disk: must NOT be stored in plain text
      final vaultFile = File('${tempDir.path}/.secure_vault.dat');
      expect(await vaultFile.exists(), isTrue);
      final rawContent = await vaultFile.readAsString();
      expect(rawContent, isNot(contains('AIzaSy_production_secret_key_12345')));

      // Delete key
      await storage.removeKey('gemini_api_key');
      expect(await storage.hasKey('gemini_api_key'), isFalse);
      expect(await storage.getKey('gemini_api_key'), isNull);
    });

    test('handles empty secret value by removing key', () async {
      await storage.saveKey('test_key', 'some-value');
      expect(await storage.hasKey('test_key'), isTrue);

      await storage.saveKey('test_key', '  ');
      expect(await storage.hasKey('test_key'), isFalse);
      expect(await storage.getKey('test_key'), isNull);
    });

    test('detects ciphertext tampering and rejects corrupted vault payload',
        () async {
      await storage.saveKey('test_alias', 'uncompromised_data');

      final vaultFile = File('${tempDir.path}/.secure_vault.dat');
      // Corrupt file contents
      await vaultFile.writeAsString('CORRUPTED_CIPHERTEXT_INVALID_PAYLOAD');

      // Subsequent read should safely fail / return null instead of crashing
      final key = await storage.getKey('test_alias');
      expect(key, isNull);
    });
  });

  group('Unicom Exceptions Model Coverage Tests', () {
    test('UnicomException base and subclasses serialize and formats correctly',
        () {
      const baseEx = UnicomException('Base error message',
          code: 'BASE_ERR', statusCode: 500, details: {'hint': 'try again'});
      expect(baseEx.toString(), contains('Base error message'));
      final baseJson = baseEx.toJson();
      expect(baseJson['error'], equals('BASE_ERR'));
      expect(baseJson['statusCode'], equals(500));
      expect(baseJson['details']['hint'], equals('try again'));

      const valEx = ValidationException('Invalid parameter', 'name');
      expect(valEx.statusCode, equals(400));
      expect(valEx.code, equals('VALIDATION_ERROR'));

      const notFoundEx = NotFoundException('Model', 'm_123');
      expect(notFoundEx.statusCode, equals(404));
      expect(notFoundEx.message, contains('m_123'));

      const notFoundNoId = NotFoundException('Session');
      expect(notFoundNoId.message, equals('Session not found.'));

      const provEx = ProviderException('p_cloud', 'Timeout during query');
      expect(provEx.providerId, equals('p_cloud'));
      expect(provEx.message, contains('Timeout during query'));

      const csEx =
          ChecksumMismatchException('whisper-tiny', 'exp123', 'act456');
      expect(csEx.statusCode, equals(422));
      expect(csEx.message, contains('whisper-tiny'));

      const sfEx = StorageFullException('Disk space full');
      expect(sfEx.statusCode, equals(507));

      const corruptEx = CorruptedDataException('Data corrupted');
      expect(corruptEx.statusCode, equals(422));

      const piEx = PromptInjectionException('Malicious prompt detected');
      expect(piEx.statusCode, equals(400));

      const mcEx = ModelCorruptedException('mod1', 'missing weights');
      expect(mcEx.statusCode, equals(422));

      const nbEx = NetworkBlockedException('api.google.com');
      expect(nbEx.statusCode, equals(403));
    });
  });
}
