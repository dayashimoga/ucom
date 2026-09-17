/// Base exception for Universal Communication Intelligence.
class UnicomException implements Exception {
  final String message;
  final String code;
  final int statusCode;
  final dynamic details;

  const UnicomException(
    this.message, {
    this.code = 'INTERNAL_ERROR',
    this.statusCode = 500,
    this.details,
  });

  @override
  String toString() => 'UnicomException($code, $statusCode): $message';

  Map<String, dynamic> toJson() => {
        'error': code,
        'message': message,
        'statusCode': statusCode,
        if (details != null) 'details': details,
      };
}

class ValidationException extends UnicomException {
  const ValidationException(String message, [dynamic details])
      : super(
          message,
          code: 'VALIDATION_ERROR',
          statusCode: 400,
          details: details,
        );
}

class NotFoundException extends UnicomException {
  const NotFoundException(String resource, [String? id])
      : super(
          id != null ? "$resource with ID '$id' was not found." : "$resource not found.",
          code: 'NOT_FOUND',
          statusCode: 404,
        );
}

class OfflineViolationException extends UnicomException {
  const OfflineViolationException(
      [String message = 'Privacy Violation: Network access attempted while in private_offline mode.'])
      : super(
          message,
          code: 'OFFLINE_POLICY_VIOLATION',
          statusCode: 403,
        );
}

class ProviderException extends UnicomException {
  final String providerId;

  const ProviderException(this.providerId, String message, [dynamic details])
      : super(
          "Provider '$providerId' error: $message",
          code: 'PROVIDER_ERROR',
          statusCode: 502,
          details: details,
        );
}

class ChecksumMismatchException extends UnicomException {
  const ChecksumMismatchException(String modelId, String expected, String actual)
      : super(
          "Model '$modelId' checksum mismatch. Expected: $expected, Actual: $actual",
          code: 'CHECKSUM_MISMATCH',
          statusCode: 422,
        );
}
