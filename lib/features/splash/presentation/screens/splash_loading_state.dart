/// Represents the lifecycle of app initialization that the splash
/// screen reacts to. Wire [SplashLoadingState.connectingKoperasi] -> ... ->
/// [SplashLoadingState.ready] from your real bootstrap/init code
/// (auth check, config fetch, local DB open, etc).
enum SplashLoadingState {
  connectingKoperasi,
  loadingVillageData,
  checkingUserSession,
  connectingAiAssistant,
  preparingServices,
  ready,
  unreachable,
}

extension SplashLoadingStateMessage on SplashLoadingState {
  String get message {
    switch (this) {
      case SplashLoadingState.connectingKoperasi:
        return 'Menghubungkan Koperasi...';
      case SplashLoadingState.loadingVillageData:
        return 'Memuat Data Desa...';
      case SplashLoadingState.checkingUserSession:
        return 'Memeriksa Sesi Pengguna...';
      case SplashLoadingState.connectingAiAssistant:
        return 'Menghubungkan AI Assistant...';
      case SplashLoadingState.preparingServices:
        return 'Menyiapkan Layanan...';
      case SplashLoadingState.ready:
        return 'Selamat Datang di KOPDES';
      case SplashLoadingState.unreachable:
        return 'Mencoba menghubungkan kembali...';
    }
  }
}
