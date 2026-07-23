abstract class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException([super.message = "No internet connection"]);
}

class ServerException extends ApiException {
  ServerException([super.message = "Internal server error"]);
}

class TimeoutException extends ApiException {
  TimeoutException([super.message = "Request timed out"]);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = "Unauthorized request"]);
}

class NotFoundException extends ApiException {
  NotFoundException([super.message = "Resource not found"]);
}

class ValidationException extends ApiException {
  ValidationException([super.message = "Validation failed"]);
}

class UnknownException extends ApiException {
  UnknownException([super.message = "An unknown error occurred"]);
}
