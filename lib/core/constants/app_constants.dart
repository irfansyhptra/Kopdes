import '../config/env_config.dart';

class AppConstants {
  static const String appName = 'KOPDES Smart Cooperative';

  // API Config pointing directly to EnvConfig to avoid duplication
  static String get baseUrl => EnvConfig.baseUrl;
  static const int connectTimeout = EnvConfig.connectTimeout;
  static const int receiveTimeout = EnvConfig.receiveTimeout;

  // Secure Storage Keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';

  // Cache Names/Paths
  static const String isarDbName = 'kopdes_local_db';
}
