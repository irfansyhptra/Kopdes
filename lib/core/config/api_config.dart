import 'env_config.dart';

/// Alamat API yang dipakai Dio.
///
/// Meneruskan [EnvConfig.baseUrl], bukan menyimpan salinannya sendiri —
/// dua konstanta alamat yang bisa berbeda adalah cara paling mudah membuat
/// `--dart-define=API_BASE_URL` tampak tidak berfungsi.
class ApiConfig {
  static String get baseUrl => EnvConfig.baseUrl;
}
