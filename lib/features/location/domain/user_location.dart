/// Tahapan izin & pengambilan lokasi pengguna.
///
/// Setiap state punya tampilan sendiri di beranda — pengguna yang menolak izin
/// harus melihat jalan keluar (pilih desa manual), bukan daftar kosong.
enum LocationStatus {
  initial,
  checkingService,
  requestingPermission,
  loadingLocation,
  locationAvailable,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  locationError,
  manualLocation,
}

/// Koordinat beserta asalnya.
class UserLocation {
  final double latitude;
  final double longitude;

  /// Label yang ditampilkan, mis. "Desa Lamteh, Banda Aceh".
  final String? label;

  /// True bila dipilih sendiri oleh pengguna, bukan dari GPS.
  final bool isManual;

  /// Kapan koordinat ini diperoleh — dipakai untuk memutuskan apakah lokasi
  /// terakhir masih layak dipakai sementara yang baru dimuat.
  final DateTime capturedAt;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.label,
    this.isManual = false,
  });

  /// Lokasi lama masih layak dipakai selama 30 menit. Di desa, pengguna jarang
  /// berpindah jauh dalam rentang itu, dan menampilkan hasil lama seketika
  /// jauh lebih baik daripada layar kosong menunggu GPS terkunci.
  bool get isFresh =>
      DateTime.now().difference(capturedAt) < const Duration(minutes: 30);

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'label': label,
    'isManual': isManual,
    'capturedAt': capturedAt.toIso8601String(),
  };

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    label: json['label'] as String?,
    isManual: json['isManual'] as bool? ?? false,
    capturedAt:
        DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
        DateTime.now(),
  );
}

/// Pilihan desa untuk pengguna yang menolak izin lokasi.
///
/// Sementara daftarnya tetap di sini; begitu ada endpoint wilayah, ganti
/// sumbernya tanpa mengubah UI.
class VillageOption {
  final String name;
  final String district;
  final String city;
  final double latitude;
  final double longitude;

  const VillageOption({
    required this.name,
    required this.district,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  String get label => '$name, $city';

  static const List<VillageOption> all = [
    VillageOption(
      name: 'Desa Lamteh',
      district: 'Ulee Kareng',
      city: 'Banda Aceh',
      latitude: 5.5483,
      longitude: 95.3441,
    ),
    VillageOption(
      name: 'Desa Lamglumpang',
      district: 'Ulee Kareng',
      city: 'Banda Aceh',
      latitude: 5.5539,
      longitude: 95.3391,
    ),
    VillageOption(
      name: 'Desa Ceurih',
      district: 'Ulee Kareng',
      city: 'Banda Aceh',
      latitude: 5.5561,
      longitude: 95.3502,
    ),
  ];
}

/// State lengkap lokasi pengguna.
class LocationState {
  final LocationStatus status;
  final UserLocation? location;
  final String? errorMessage;

  const LocationState({
    this.status = LocationStatus.initial,
    this.location,
    this.errorMessage,
  });

  /// Koordinat siap dipakai untuk pencarian terdekat.
  bool get hasCoordinates => location != null;

  /// Perlu tindakan pengguna sebelum ada koordinat.
  bool get needsAction =>
      status == LocationStatus.permissionDenied ||
      status == LocationStatus.permissionPermanentlyDenied ||
      status == LocationStatus.serviceDisabled ||
      status == LocationStatus.locationError;

  bool get isBusy =>
      status == LocationStatus.checkingService ||
      status == LocationStatus.requestingPermission ||
      status == LocationStatus.loadingLocation;

  LocationState copyWith({
    LocationStatus? status,
    UserLocation? location,
    String? errorMessage,
    bool clearError = false,
  }) => LocationState(
    status: status ?? this.status,
    location: location ?? this.location,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
