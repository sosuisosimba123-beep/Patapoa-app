import 'dart:async';
import 'package:http/http.dart' as http;
import 'crashlytics_service.dart';

/// Base class for all application-specific exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, [this.code, this.details]);

  @override
  String toString() => message;
}

/// Thrown when there is no internet connection or a socket failure
class NetworkException extends AppException {
  NetworkException([String message = 'No internet connection. Please check your settings.'])
      : super(message, 'network_error');
}

/// Thrown for 5xx server errors
class ServerException extends AppException {
  final int statusCode;
  ServerException(String message, this.statusCode)
      : super(message, 'server_error_$statusCode');
}

/// Thrown for 401/403 errors
class AuthException extends AppException {
  AuthException([String message = 'Session expired. Please login again.'])
      : super(message, 'auth_error');
}

/// Thrown for 422 Validation errors
class ValidationException extends AppException {
  final Map<String, dynamic> errors;
  ValidationException(String message, this.errors)
      : super(message, 'validation_error', errors);
}

/// Thrown when a request takes too long
class RequestTimeoutException extends AppException {
  RequestTimeoutException([String message = 'The server is taking too long to respond.'])
      : super(message, 'timeout_error');
}

class ApiErrorHandler {
  /// Wraps any asynchronous API call and translates low-level errors
  /// into predictable AppExceptions.
  static Future<T> handle<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on TimeoutException {
      throw RequestTimeoutException();
    } on http.ClientException catch (e) {
      throw NetworkException('Connection issue: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      // Check for SocketException without importing dart:io to support Web
      final errorString = e.toString();
      if (errorString.contains('SocketException')) {
        throw NetworkException();
      }
      final appException = AppException('An unexpected error occurred: $e');
      CrashlyticsService().recordError(e, stackTrace);
      throw appException;
    }
  }

  /// Retries a request with exponential backoff.
  /// Standard delay: 1s, 2s, 4s...
  static Future<T> withRetry<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        // We use handle() inside withRetry to ensure errors are already translated
        return await handle(request);
      } catch (e) {
        final isLastAttempt = attempts >= maxRetries;
        final isRetryable = _shouldRetry(e);

        if (isLastAttempt || !isRetryable) {
          rethrow;
        }

        // Calculate backoff: delay * 2^(attempts-1)
        final backoffMillis = initialDelay.inMilliseconds * (1 << (attempts - 1));
        await Future.delayed(Duration(milliseconds: backoffMillis));
      }
    }
  }

  /// Determines if an error is worth retrying (Network issues or Server 5xx)
  static bool _shouldRetry(dynamic e) {
    if (e is NetworkException || e is RequestTimeoutException) return true;
    if (e is ServerException) {
      // Retry on internal server errors, bad gateways, etc.
      return e.statusCode >= 500 && e.statusCode <= 504;
    }
    return false;
  }
}
