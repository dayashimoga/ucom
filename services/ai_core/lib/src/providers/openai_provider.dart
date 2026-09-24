import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'cloud_llm_provider.dart';

/// Production OpenAI / OpenAI-Compatible LLM Provider.
/// Compatible with OpenAI, Groq, Together, Ollama, DeepSeek, and custom endpoints.
class OpenAIProvider implements LLMProvider {
  final ExecutionMode executionMode;
  final String? apiKey;
  final String modelName;
  final String baseUrl;
  final int timeoutMs;
  final HttpClient Function()? httpClientFactory;
  final PrivacyLogger _logger = const PrivacyLogger(context: 'OPENAI_LLM');

  OpenAIProvider({
    required this.executionMode,
    this.apiKey,
    this.modelName = 'gpt-4o-mini',
    String? baseUrl,
    this.timeoutMs = 15000,
    this.httpClientFactory,
  }) : baseUrl = (baseUrl != null && baseUrl.trim().isNotEmpty)
            ? baseUrl.trim().replaceAll(RegExp(r'/+$'), '')
            : 'https://api.openai.com';

  @override
  String get id => 'openai_llm';

  @override
  String get name => 'OpenAI-Compatible ($modelName)';

  @override
  bool get isOfflineCapable => false;

  HttpClient _createClient() {
    if (httpClientFactory != null) {
      return httpClientFactory!();
    }
    return HttpClient()..connectionTimeout = Duration(milliseconds: timeoutMs);
  }

  String get _endpoint => '$baseUrl/v1/chat/completions';

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

    final sw = Stopwatch()..start();
    try {
      NetworkGate().checkOutboundAccess(_endpoint, method: 'POST');

      final client = _createClient();
      try {
        final uri = Uri.parse(_endpoint);
        final request = await client
            .postUrl(uri)
            .timeout(Duration(milliseconds: timeoutMs));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        if (apiKey != null && apiKey!.trim().isNotEmpty) {
          request.headers
              .set(HttpHeaders.authorizationHeader, 'Bearer ${apiKey!.trim()}');
        }

        final payload = jsonEncode({
          'model': modelName,
          'messages': [
            {'role': 'user', 'content': 'healthcheck'}
          ],
          'max_tokens': 1,
        });
        request.write(payload);

        final response =
            await request.close().timeout(Duration(milliseconds: timeoutMs));
        final responseBody = await response.transform(utf8.decoder).join();
        sw.stop();

        if (response.statusCode == HttpStatus.ok) {
          _logger.info('OpenAI connection verified successfully', {
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
            errorMessage: 'OpenAI API HTTP ${response.statusCode}: $errorData',
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

    NetworkGate().checkOutboundAccess(
      _endpoint,
      method: 'POST',
      payloadBytes: prompt.length,
    );

    _logger.info('Executing OpenAI inference', {
      'model': modelName,
      'temperature': temperature,
      'maxTokens': maxTokens,
    });

    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    final payloadMap = <String, dynamic>{
      'model': modelName,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final payloadStr = jsonEncode(payloadMap);
    return _postWithRetry(payloadStr);
  }

  Future<String> _postWithRetry(String payload, {int maxRetries = 2}) async {
    int attempts = 0;
    while (true) {
      attempts++;
      final client = _createClient();
      try {
        final uri = Uri.parse(_endpoint);
        final request = await client
            .postUrl(uri)
            .timeout(Duration(milliseconds: timeoutMs));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        if (apiKey != null && apiKey!.trim().isNotEmpty) {
          request.headers
              .set(HttpHeaders.authorizationHeader, 'Bearer ${apiKey!.trim()}');
        }
        request.write(payload);

        final response =
            await request.close().timeout(Duration(milliseconds: timeoutMs));
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == HttpStatus.ok) {
          final parsed = jsonDecode(responseBody) as Map<String, dynamic>;
          final choices = parsed['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final firstChoice = choices[0] as Map<String, dynamic>;
            final message = firstChoice['message'] as Map<String, dynamic>?;
            final content = message?['content'] as String?;
            if (content != null) return content.trim();
          }
          return 'No response generated.';
        }

        if ((response.statusCode == 429 ||
                response.statusCode == HttpStatus.serviceUnavailable) &&
            attempts <= maxRetries) {
          _logger.warn(
              'OpenAI API rate limited/unavailable, retrying attempt $attempts');
          await Future.delayed(Duration(milliseconds: 300 * attempts));
          continue;
        }

        final errorMsg = _parseError(responseBody);
        throw ProviderException(
            id, 'OpenAI API error (HTTP ${response.statusCode}): $errorMsg');
      } on SocketException catch (e) {
        if (attempts <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * attempts));
          continue;
        }
        throw ProviderException(
            id, 'Network error reaching OpenAI service: ${e.message}');
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
