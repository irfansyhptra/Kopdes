enum AppEnvironment { dev, staging, prod }

class EnvConfig {
  static const AppEnvironment environment = AppEnvironment.dev;

  // Read the API base URL directly from environment variables.
  // Defaults to production URL if not provided.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.kopdes.co/api/v1',
  );

  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms

  // Centralized flags
  static const bool enableLogging = environment != AppEnvironment.prod;
}
