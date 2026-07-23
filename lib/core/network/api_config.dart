class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const Duration receiveTimeout = Duration(milliseconds: 15000);
  static const Duration connectionTimeout = Duration(milliseconds: 15000);
  static const Duration sendTimeout = Duration(milliseconds: 15000);
}
