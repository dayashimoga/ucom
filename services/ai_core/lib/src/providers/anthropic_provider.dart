import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'cloud_llm_provider.dart';

/// Production Anthropic Claude LLM Provider.
class AnthropicProvider implements LLMProvider {
  final ExecutionMode executionMode;
  final String? apiKey;
  final String modelName;
  final String endpoint;
  final int timeoutMs;
  final HttpClient Function()? httpClientFactory;
  final PrivacyLogger _logger = const PrivacyLogger(context: 'ANTHROPIC_LLM');

  AnthropicProvider({
    required this.executionMode,
    this.apiKey,
    this.modelName = 'claude-3-5-sonnet-20241022',
    this.endpoint = 'https://api.anthropic.com/v1/messages',
    this.timeoutMs = 15000,
    this.httpClientFactory,
  });

  @override
  String get id => 'anthropic_llm';

  @override
  String get name => 'Anthropic Claude ($modelName)';

  @override
  bool get isOfflineCapable => false;

  HttpClient _createClient() {
    if (httpClientFactory != null) {
      return httpClientFactory!();
    }
    return HttpClient()..connectionTimeout = Duration(milliseconds: timeoutMs);
  }

  Future<ConnectionTestResult> testConnection() async {
    if (executionMode == ExecutionMode.privateOffline) {
      return ConnectionTestResult(
        isSuccessful: false,
        providerId: id,
        modelName: modelName,
        latencyMs: 0,
        errorMessage:
            'Cannot test cloud connection while in private_offline mode.',
      );
    }

    if (apiKey == null || apiKey!.trim().isEmpty) {
      return ConnectionTestResult(
        isSuccessful: false,
        providerId: id,
        modelName: modelName,
        latencyMs: 0,
        errorMessage:
            'Missing Anthropic API key. Please configure in settings.',
      );
    }

    final sw = Stopwatch()..start();
    try {
      NetworkGate().checkOutboundAccess(endpoint, method: 'POST');

      final client = _createClient();
      try {
        final uri = Uri.parse(endpoint);
        final request = await client
            .postUrl(uri)
            .timeout(Duration(milliseconds: timeoutMs));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set('x-api-key', apiKey!.trim());
        request.headers.set('anthropic-version', '2023-06-01');

        final payload = jsonEncode({
          'model': modelName,
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'healthcheck'}
          ],
        });
        request.write(payload);

        final response =
            await request.close().timeout(Duration(milliseconds: timeoutMs));
        final responseBody = await response.transform(utf8.decoder).join();
        sw.stop();

        if (response.statusCode == HttpStatus.ok) {
          _logger.info('Anthropic connection verified successfully', {
            'model': modelName,
            'latencyMs': sw.elapsedMilliseconds,
          });
          return ConnectionTestResult(
            isSuccessful: true,
            providerId: id,
            modelName: modelName,
            latencyMs: sw.elapsedMilliseconds,
          );
        } else {
          final errorData = _parseError(responseBody);
          return ConnectionTestResult(
            isSuccessful: false,
            providerId: id,
            modelName: modelName,
            latencyMs: sw.elapsedMilliseconds,
            errorMessage:
                'Anthropic API HTTP ${response.statusCode}: $errorData',
          );
        }
      } finally {
        client.close();
      }
    } on OfflineViolationException catch (e) {
      sw.stop();
      return ConnectionTestResult(
        isSuccessful: false,
        providerId: id,
        modelName: modelName,
        latencyMs: sw.elapsedMilliseconds,
        errorMessage: e.message,
      );
    } catch (e) {
      sw.stop();
      return ConnectionTestResult(
        isSuccessful: false,
        providerId: id,
        modelName: modelName,
        latencyMs: sw.elapsedMilliseconds,
        errorMessage: 'Connection failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<String> complete(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    if (executionMode == ExecutionMode.privateOffline) {
      throw const OfflineViolationException(
        'Privacy Violation: Cloud LLM completion attempted while in private_offline mode.',
      );
    }

    if (apiKey == null || apiKey!.trim().isEmpty) {
      throw ProviderException(id, 'Anthropic API key not configured.');
    }

    NetworkGate().checkOutboundAccess(
      endpoint,
      method: 'POST',
      payloadBytes: prompt.length,
    );

    _logger.info('Executing Anthropic Claude inference', {
      'model': modelName,
      'temperature': temperature,
      'maxTokens': maxTokens,
    });

    final payloadMap = <String, dynamic>{
      'model': modelName,
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      payloadMap['system'] = systemPrompt;
    }

    final payloadStr = jsonEncode(payloadMap);
    return _postWithRetry(payloadStr);
  }

  Future<String> _postWithRetry(String payload, {int maxRetries = 2}) async {
    int attempts = 0;
    while (true) {
      attempts++;
      final client = _createClient();
      try {
        final uri = Uri.parse(endpoint);
        final request = await client
            .postUrl(uri)
            .timeout(Duration(milliseconds: timeoutMs));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set('x-api-key', apiKey!.trim());
        request.headers.set('anthropic-version', '2023-06-01');
        request.write(payload);

        final response =
            await request.close().timeout(Duration(milliseconds: timeoutMs));
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == HttpStatus.ok) {
          final parsed = jsonDecode(responseBody) as Map<String, dynamic>;
          final contentList = parsed['content'] as List<dynamic>?;
          if (contentList != null && contentList.isNotEmpty) {
            final firstPart = contentList[0] as Map<String, dynamic>;
            final text = firstPart['text'] as String?;
            if (text != null) return text.trim();
          }
          return 'No response generated.';
        }

        if ((response.statusCode == 429 ||
                response.statusCode == HttpStatus.serviceUnavailable) &&
            attempts <= maxRetries) {
          _logger.warn(
              'Anthropic API rate limited/unavailable, retrying attempt $attempts');
          await Future.delayed(Duration(milliseconds: 300 * attempts));
          continue;
        }

        final errorMsg = _parseError(responseBody);
        throw ProviderException(
            id, 'Anthropic API error (HTTP ${response.statusCode}): $errorMsg');
      } on SocketException catch (e) {
        if (attempts <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * attempts));
          continue;
        }
        throw ProviderException(
            id, 'Network error reaching Anthropic service: ${e.message}');
      } finally {
        client.close();
      }
    }
  }

  @override
  Stream<String> completeStream(
    String prompt, {
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async* {
    if (executionMode == ExecutionMode.privateOffline) {
      throw const OfflineViolationException(
        'Privacy Violation: Cloud LLM stream attempted while in private_offline mode.',
      );
    }

    final fullResponse = await complete(
      prompt,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final chunks = fullResponse.split(' ');
    for (int i = 0; i < chunks.length; i++) {
      yield (i == 0 ? '' : ' ') + chunks[i];
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final err = json['error'] as Map<String, dynamic>?;
      return err?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}
