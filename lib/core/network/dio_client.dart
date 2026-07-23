import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'api_config.dart';

class DioClient {
  late final Dio _dio;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            _logger.i(
                "--> ${options.method.toUpperCase()} ${options.uri}\nHeaders: ${options.headers}\nBody: ${options.data}");
            return handler.next(options);
          },
          onResponse: (response, handler) {
            _logger.i(
                "<-- ${response.statusCode} ${response.requestOptions.uri}\nResponse: ${response.data}");
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            _logger.e(
                "<-- ${e.message} ${e.requestOptions.uri}\nStatus: ${e.response?.statusCode}\nError: ${e.response?.data}");
            return handler.next(e);
          },
        ),
      );
    }
  }

  Dio get dio => _dio;
}
