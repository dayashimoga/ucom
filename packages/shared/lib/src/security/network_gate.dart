import 'dart:async';
import 'dart:io';
import '../errors/exceptions.dart';
import '../logging/privacy_logger.dart';

/// Telemetry record for outbound network activity inspection.
class NetworkRequestRecord {
  final String destination;
  final String method;
  final DateTime timestamp;
  final bool blocked;
  final String reason;
  final int payloadBytes;

  const NetworkRequestRecord({
    required this.destination,
    required this.method,
    required this.timestamp,
    required this.blocked,
    required this.reason,
    this.payloadBytes = 0,
  });

  Map<String, dynamic> toJson() => {
        'destination': destination,
        'method': method,
        'timestamp': timestamp.toIso8601String(),
        'blocked': blocked,
        'reason': reason,
        'payloadBytes': payloadBytes,
      };
}

/// Defense-in-depth network gate enforcing offline privacy invariant below AI providers.
/// Intercepts network creation requests and prevents data egress in private/offline mode.
class NetworkGate {
  static final NetworkGate _instance = NetworkGate._internal();
  factory NetworkGate() => _instance;
  NetworkGate._internal();

  bool _isOfflineEnforced = true;
  final List<NetworkRequestRecord> _auditLog = [];
  final PrivacyLogger _logger = const PrivacyLogger(context: 'NETWORK_GATE');

  bool get isOfflineEnforced => _isOfflineEnforced;
  List<NetworkRequestRecord> get auditLog => List.unmodifiable(_auditLog);

  /// Configure whether strict offline isolation is active.
  void setOfflineEnforcement(bool enforce) {
    _isOfflineEnforced = enforce;
    _logger.info('Network gate mode updated', {'offlineEnforced': enforce});
  }

  /// Evaluates whether an outbound connection to [destination] is permitted.
  /// Throws [NetworkBlockedException] or [OfflineViolationException] if blocked.
  void checkOutboundAccess(String destination,
      {String method = 'GET', int payloadBytes = 0}) {
    if (_isOfflineEnforced) {
      final record = NetworkRequestRecord(
        destination: destination,
        method: method,
        timestamp: DateTime.now(),
        blocked: true,
        reason: 'Strict private_offline mode enforced by NetworkGate',
        payloadBytes: payloadBytes,
      );
      _auditLog.add(record);
      _logger.warn('Blocked outbound network attempt in offline mode', {
        'destination': destination,
        'method': method,
      });
      throw OfflineViolationException(
        "Privacy Invariant Violation: Outbound network request to '$destination' blocked by NetworkGate.",
      );
    }

    final record = NetworkRequestRecord(
      destination: destination,
      method: method,
      timestamp: DateTime.now(),
      blocked: false,
      reason: 'Allowed in hybrid/cloud mode',
      payloadBytes: payloadBytes,
    );
    _auditLog.add(record);
  }

  /// Installs global HttpOverrides to intercept Dart IO HTTP clients.
  void installGlobalInterceptor() {
    HttpOverrides.global = _GateHttpOverrides(this);
  }

  /// Removes global HttpOverrides.
  void removeGlobalInterceptor() {
    if (HttpOverrides.current is _GateHttpOverrides) {
      HttpOverrides.global = null;
    }
  }

  /// Clears telemetry log.
  void clearAuditLog() {
    _auditLog.clear();
  }
}

class _GateHttpOverrides extends HttpOverrides {
  final NetworkGate gate;
  _GateHttpOverrides(this.gate);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _GatedHttpClient(super.createHttpClient(context), gate);
  }
}

class _GatedHttpClient implements HttpClient {
  final HttpClient _inner;
  final NetworkGate _gate;

  _GatedHttpClient(this._inner, this._gate);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    try {
      // Forward members dynamically to inner client
      return (invocation.isMethod ||
          invocation.isGetter ||
          invocation.isSetter);
    } catch (_) {
      return null;
    }
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    _gate.checkOutboundAccess('$host:$port$path', method: method);
    return _inner.open(method, host, port, path);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    _gate.checkOutboundAccess(url.toString(), method: method);
    return _inner.openUrl(method, url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);
}
