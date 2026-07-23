import 'package:dio/dio.dart';
import 'api_exceptions.dart';
import 'dio_client.dart';

class ApiClient {
  final DioClient _dioClient;

  ApiClient({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Dio get _dio => _dioClient.dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  dynamic _handleResponse(Response response) {
    // 200, 201, 204 are typical success codes handled smoothly by Dio
    return response.data;
  }

  Exception _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return TimeoutException();
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return NetworkException();
    }

    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      String message = "An error occurred";
      
      if (responseData is Map<String, dynamic> && responseData['message'] != null) {
        message = responseData['message'].toString();
      }

      switch (statusCode) {
        case 400:
          return ValidationException(message.isNotEmpty ? message : "Bad Request");
        case 401:
          return UnauthorizedException(message.isNotEmpty ? message : "Unauthorized");
        case 403:
          return UnauthorizedException(message.isNotEmpty ? message : "Forbidden");
        case 404:
          return NotFoundException(message.isNotEmpty ? message : "Resource not found");
        case 409:
          return ServerException(message.isNotEmpty ? message : "Conflict");
        case 422:
          return ValidationException(message.isNotEmpty ? message : "Unprocessable Entity");
        case 500:
        case 501:
        case 502:
        case 503:
        case 505:
          return ServerException(message.isNotEmpty ? message : "Internal Server Error");
        default:
          return UnknownException("Received invalid status code: $statusCode");
      }
    }

    return UnknownException(error.message ?? "Unknown network error occurred");
  }
}
