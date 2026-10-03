enum AppEnvironment { dev, staging, prod }

class EnvConfig {
  static const AppEnvironment environment = AppEnvironment.dev;

  /// Alamat API. Bisa ditimpa saat build:
  /// `flutter build apk --dart-define=API_BASE_URL=...`
  ///
  /// Bawaannya deployment Vercel yang benar-benar melayani aplikasi ini.
  /// Sebelumnya `https://api.kopdes.co/api/v1` — domain yang tidak pernah
  /// resolve. Nilai itu tidak pernah menyebabkan kerusakan hanya karena
  /// tidak ada yang memakainya: Dio memakai `ApiConfig.baseUrl` yang
  /// terpisah, dan `AppConstants.baseUrl` yang menunjuk ke sini tidak
  /// dipanggil satu kali pun. Dua sumber alamat, satu di antaranya salah
  /// dan diam — persis bentuk jebakan yang meledak di tangan orang
  /// berikutnya.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-kopdes.vercel.app/api/v1',
  );

  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms

  // Centralized flags
  static const bool enableLogging = environment != AppEnvironment.prod;
}
