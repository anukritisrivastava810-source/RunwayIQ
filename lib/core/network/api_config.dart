import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Resolves the correct base URL depending on platform and build mode.
  ///
  /// Priority order:
  ///   1. `--dart-define=API_BASE_URL=url`  (explicit override – use for physical devices or staging)
  ///   2. Android emulator → `http://10.0.2.2:8000/api/v1`
  ///   3. Everything else (web, desktop, macOS) → `http://localhost:8000/api/v1`
  ///
  /// Usage examples:
  ///   `flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8000/api/v1`
  ///   `flutter build apk --release --dart-define=API_BASE_URL=https://api.runwayiq.com/api/v1`
  static const String _dartDefineUrl = String.fromEnvironment('API_BASE_URL');


  static String get baseUrl {
    // 1. Explicit override always wins (physical device / staging / production)
    if (_dartDefineUrl.isNotEmpty) return _dartDefineUrl;

    // 2. Android emulator: the host machine is reachable at 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    // 3. Web, macOS desktop, iOS simulator — localhost works normally
    return 'http://localhost:8000/api/v1';
  }

  static const Duration receiveTimeout = Duration(milliseconds: 15000);
  static const Duration connectionTimeout = Duration(milliseconds: 15000);
  static const Duration sendTimeout = Duration(milliseconds: 15000);
}
