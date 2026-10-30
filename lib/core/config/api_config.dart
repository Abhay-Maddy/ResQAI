/// Centralized, environment-aware API Configuration for ResQAI.
///
/// Supports Flutter compile-time defines (`--dart-define=API_BASE_URL=...`).
/// Defaults safely to the production Render HTTPS backend for all release and default builds.
class ApiConfig {
  ApiConfig._();

  /// Canonical production Render API endpoint
  static const String productionBaseUrl = 'https://resqai-api-7aot.onrender.com/api/v1';

  /// Standard Android Emulator loopback mapping to host machine's port 5000
  static const String emulatorBaseUrl = 'http://10.0.2.2:5000/api/v1';

  /// Standard localhost mapping for Flutter Web / Desktop
  static const String localhostBaseUrl = 'http://localhost:5000/api/v1';

  /// Active base URL. Can be overridden at build/run time via:
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1` (Android Emulator)
  /// `--dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:5000/api/v1` (Physical Android Device)
  /// `--dart-define=API_BASE_URL=https://resqai-api-7aot.onrender.com/api/v1` (Production)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  /// Helper to build a full endpoint Uri safely.
  /// Automatically ensures leading slashes are handled without duplicate slashes.
  static Uri endpoint(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  /// Diagnostic helper to inspect active connection mode
  static bool get isProduction => baseUrl.contains('onrender.com') || baseUrl.startsWith('https://');
  static bool get isLocal => !isProduction;
}

