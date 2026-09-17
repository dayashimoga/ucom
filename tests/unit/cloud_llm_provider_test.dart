import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  final _FakeHttpHeaders _headers = _FakeHttpHeaders();
  final Completer<HttpClientResponse> _completer =
      Completer<HttpClientResponse>();
  final List<String> writtenData = [];

  void completeWith(HttpClientResponse response) {
    if (!_completer.isCompleted) {
      _completer.complete(response);
    }
  }

  void completeError(Object error) {
    if (!_completer.isCompleted) {
      _completer.completeError(error);
    }
  }

  @override
  HttpHeaders get headers => _headers;

  @override
  void write(Object? obj) {
    if (obj != null) writtenData.add(obj.toString());
  }

  @override
  Future<HttpClientResponse> close() => _completer.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  _FakeHttpClientResponse({required this.statusCode, required this.body});

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final stream = Stream.value(utf8.encode(body));
    return stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClient implements HttpClient {
  final Future<HttpClientResponse> Function(Uri uri, String? method) onPost;
  bool isClosed = false;

  _MockHttpClient({required this.onPost});

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final req = _FakeHttpClientRequest();
    onPost(url, 'POST').then(req.completeWith, onError: req.completeError);
    return req;
  }

  @override
  void close({bool force = false}) {
    isClosed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CloudLLMProvider Production Gemini Tests', () {
    setUp(() {
      NetworkGate().setOfflineEnforcement(false);
      NetworkGate().clearAuditLog();
    });

    test('testConnection handles 200 OK token count response', () async {
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          return _FakeHttpClientResponse(
            statusCode: HttpStatus.ok,
            body: jsonEncode({'totalTokens': 1}),
          );
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'actual-gemini-key-xyz',
        httpClientFactory: () => mockClient,
      );

      final result = await provider.testConnection();
      expect(result.isSuccessful, isTrue);
      expect(result.providerId, equals('cloud_gemini_llm'));
      expect(result.modelName, equals('gemini-1.5-flash'));
      expect(result.latencyMs, greaterThanOrEqualTo(0));
    });

    test('testConnection handles HTTP error response', () async {
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          return _FakeHttpClientResponse(
            statusCode: HttpStatus.forbidden,
            body: jsonEncode({
              'error': {'message': 'API_KEY_INVALID', 'code': 403}
            }),
          );
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'invalid-key-xyz',
        httpClientFactory: () => mockClient,
      );

      final result = await provider.testConnection();
      expect(result.isSuccessful, isFalse);
      expect(result.errorMessage, contains('API_KEY_INVALID'));
    });

    test(
        'complete generates text from Gemini API and handles systemInstruction',
        () async {
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          return _FakeHttpClientResponse(
            statusCode: HttpStatus.ok,
            body: jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text':
                            'Kubernetes schedules pods according to resource requests and affinity.'
                      }
                    ]
                  }
                }
              ]
            }),
          );
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'live-test-key-abc',
        httpClientFactory: () => mockClient,
      );

      final answer = await provider.complete(
        'What is Kubernetes?',
        systemPrompt: 'You are an expert cloud architect.',
      );
      expect(answer, contains('Kubernetes schedules pods'));

      // Test streaming
      final streamWords =
          await provider.completeStream('What is Kubernetes?').toList();
      expect(streamWords.join(''), contains('Kubernetes schedules pods'));
    });

    test('complete handles empty candidates gracefully', () async {
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          return _FakeHttpClientResponse(
            statusCode: HttpStatus.ok,
            body: jsonEncode({'candidates': []}),
          );
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'live-test-key-abc',
        httpClientFactory: () => mockClient,
      );

      final answer = await provider.complete('Hello');
      expect(answer, equals('No content generated by Gemini model.'));
    });

    test('complete retries on 429 rate limit then succeeds', () async {
      int calls = 0;
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          calls++;
          if (calls == 1) {
            return _FakeHttpClientResponse(
              statusCode: 429,
              body: jsonEncode({
                'error': {'message': 'Resource has been exhausted'}
              }),
            );
          }
          return _FakeHttpClientResponse(
            statusCode: HttpStatus.ok,
            body: jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Success after backoff'}
                    ]
                  }
                }
              ]
            }),
          );
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'live-test-key-abc',
        httpClientFactory: () => mockClient,
      );

      final answer = await provider.complete('Test retry');
      expect(answer, equals('Success after backoff'));
      expect(calls, equals(2));
    });

    test('complete throws ProviderException on permanent HTTP error', () async {
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          return _FakeHttpClientResponse(
            statusCode: HttpStatus.badRequest,
            body: 'Malformed request syntax',
          );
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'live-test-key-abc',
        httpClientFactory: () => mockClient,
      );

      expect(
        () => provider.complete('Bad prompt'),
        throwsA(isA<ProviderException>()),
      );
    });

    test('complete throws SocketException after retries', () async {
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          throw const SocketException('Connection reset by peer');
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'live-test-key-abc',
        httpClientFactory: () => mockClient,
      );

      expect(
        () => provider.complete('Socket test'),
        throwsA(isA<ProviderException>()),
      );
    });

    test('complete supports valid-gemini-test mode across domain prompts',
        () async {
      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'valid-gemini-test-sample-key',
      );

      final k8s = await provider.complete('Explain kubernetes scheduler');
      expect(k8s, contains('kube-scheduler assigns pods'));

      final quantum = await provider.complete('Explain quantum entanglement');
      expect(quantum, contains('correlated'));

      final other = await provider.complete('What is gravity?');
      expect(other, contains('Cloud response to: What is gravity?'));
    });

    test('complete retries on 503 service unavailable then succeeds', () async {
      int calls = 0;
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          calls++;
          if (calls == 1) {
            return _FakeHttpClientResponse(
              statusCode: HttpStatus.serviceUnavailable,
              body: jsonEncode({
                'error': {'message': 'Service temporarily overloaded'}
              }),
            );
          }
          return _FakeHttpClientResponse(
            statusCode: HttpStatus.ok,
            body: jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Success after 503'}
                    ]
                  }
                }
              ]
            }),
          );
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'live-test-key-503',
        httpClientFactory: () => mockClient,
      );

      final answer = await provider.complete('Test 503');
      expect(answer, equals('Success after 503'));
      expect(calls, equals(2));
    });

    test('complete handles candidate with null parts or text', () async {
      final mockClient = _MockHttpClient(
        onPost: (uri, method) async {
          return _FakeHttpClientResponse(
            statusCode: HttpStatus.ok,
            body: jsonEncode({
              'candidates': [
                {
                  'content': {'parts': []}
                }
              ]
            }),
          );
        },
      );

      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: 'live-test-key-empty-parts',
        httpClientFactory: () => mockClient,
      );

      final answer = await provider.complete('Test empty parts');
      expect(answer, equals('No content generated by Gemini model.'));
    });

    test('complete throws ValidationException when apiKey is empty or missing',
        () async {
      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.hybrid,
        apiKey: '  ',
      );

      expect(() => provider.complete('Test empty key'),
          throwsA(isA<ProviderException>()));
    });

    test(
        'complete and completeStream throw OfflineViolationException in privateOffline mode',
        () async {
      final provider = CloudLLMProvider(
        executionMode: ExecutionMode.privateOffline,
        apiKey: 'valid-gemini-test-key',
      );

      expect(() => provider.complete('Test offline'),
          throwsA(isA<OfflineViolationException>()));
      expect(() => provider.completeStream('Test offline').toList(),
          throwsA(isA<OfflineViolationException>()));
    });

    test('ConnectionTestResult serializes with and without error', () {
      const resOk = ConnectionTestResult(
        isSuccessful: true,
        providerId: 'p1',
        modelName: 'm1',
        latencyMs: 120,
      );
      final jsonOk = resOk.toJson();
      expect(jsonOk['isSuccessful'], isTrue);
      expect(jsonOk.containsKey('errorMessage'), isFalse);

      const resErr = ConnectionTestResult(
        isSuccessful: false,
        providerId: 'p1',
        modelName: 'm1',
        latencyMs: 50,
        errorMessage: 'Quota exceeded',
      );
      final jsonErr = resErr.toJson();
      expect(jsonErr['isSuccessful'], isFalse);
      expect(jsonErr['errorMessage'], equals('Quota exceeded'));
    });
  });
}
