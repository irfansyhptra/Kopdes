import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/storage/api_cache.dart';
import '../../data/place_name.dart';
import '../../domain/user_location.dart';

/// Kunci penyimpanan pilihan lokasi manual.
///
/// Memakai [ApiCache] yang sudah ada, bukan koleksi Isar baru — cache generik
/// itu memang dibuat supaya fitur baru tidak perlu skema sendiri.
const _manualLocationKey = 'location:manual';

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier(ref.watch(apiCacheProvider));
  },
);

/// Mengelola izin dan pengambilan lokasi pengguna.
///
/// Aturan yang dipegang di sini:
/// - Izin **tidak pernah** diminta otomatis saat halaman dibuka. Beranda hanya
///   memuat lokasi yang tersimpan; permintaan izin baru berjalan setelah
///   pengguna menekan "Aktifkan Lokasi".
/// - Lokasi tersimpan yang masih layak dipakai lebih dulu, sehingga daftar
///   terdekat langsung terisi sementara koordinat baru dimuat.
/// - Penolakan izin bukan jalan buntu: pengguna bisa memilih desa manual.
/// - Tidak ada background location. `LocationAccuracy.medium` sudah cukup
///   untuk mencari toko dalam radius kilometer, dan lebih hemat baterai
///   daripada `high`.
class LocationNotifier extends StateNotifier<LocationState> {
  final ApiCache _cache;

  /// Pembacaan lokasi tersimpan. Ditunggu oleh [refreshIfPermitted] supaya
  /// desa yang dipilih manual tidak tertimpa GPS hanya karena pembacaannya
  /// belum selesai saat beranda terbuka.
  late final Future<void> _restoring;

  LocationNotifier(this._cache) : super(const LocationState()) {
    _restoring = _restoreSavedLocation();
  }

  /// Mengambil koordinat bila izinnya memang sudah ada — tanpa dialog.
  ///
  /// Izin lokasi diminta di luar sini (sekali, saat beranda pertama kali
  /// terbuka) lewat `permission_handler`. Notifier ini tidak ikut tahu
  /// hasilnya, jadi tanpa panggilan ini beranda tetap menampilkan ajakan
  /// "Aktifkan Lokasi" meski izinnya baru saja diberikan.
  Future<void> refreshIfPermitted() async {
    await _restoring;
    if (!mounted) return;

    final saved = state.location;

    // Pilihan desa manual tidak pernah ditimpa GPS. Pengguna memilihnya
    // justru karena koordinat otomatis tidak ia inginkan.
    if (saved != null && saved.isManual) return;

    // Lokasi tersimpan yang masih segar (< 30 menit) dipakai apa adanya.
    // Di luar itu diambil ulang: membuka aplikasi dari desa lain harus
    // memperbarui apa yang tampil di kepala beranda, bukan menampilkan
    // tempat kemarin.
    if (saved != null && saved.isFresh) return;

    final permission = await Geolocator.checkPermission();
    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!mounted || !granted) return;

    await requestLocation();
  }

  /// Dipanggil sekali saat notifier dibuat. Tidak menyentuh izin sama sekali.
  Future<void> _restoreSavedLocation() async {
    final entry = await _cache.read(_manualLocationKey);
    if (entry == null || !mounted) return;

    try {
      final saved = UserLocation.fromJson(
        jsonDecode(entry.data as String) as Map<String, dynamic>,
      );
      state = LocationState(
        status: saved.isManual
            ? LocationStatus.manualLocation
            : LocationStatus.locationAvailable,
        location: saved,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Lokasi tersimpan tidak terbaca: $e');
    }
  }

  /// Alur lengkap: layanan → izin → koordinat.
  ///
  /// Panggil ini **hanya** dari aksi eksplisit pengguna.
  Future<void> requestLocation() async {
    state = state.copyWith(
      status: LocationStatus.checkingService,
      clearError: true,
    );

    if (!await Geolocator.isLocationServiceEnabled()) {
      state = state.copyWith(status: LocationStatus.serviceDisabled);
      return;
    }

    state = state.copyWith(status: LocationStatus.requestingPermission);

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: LocationStatus.permissionPermanentlyDenied,
      );
      return;
    }
    if (permission == LocationPermission.denied) {
      state = state.copyWith(status: LocationStatus.permissionDenied);
      return;
    }

    state = state.copyWith(status: LocationStatus.loadingLocation);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final location = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        capturedAt: DateTime.now(),
      );

      await _persist(location);
      if (!mounted) return;
      state = LocationState(
        status: LocationStatus.locationAvailable,
        location: location,
      );

      // Nama tempatnya menyusul, TIDAK menahan koordinat.
      //
      // Daftar Kopdes terdekat hanya butuh angka lintang-bujur dan sudah bisa
      // berjalan sekarang juga; nama desa cuma hiasan di kepala halaman.
      // Menunggu geocoder — yang menumpang jaringan dan layanan Google Play —
      // berarti menahan seluruh beranda demi satu baris teks.
      unawaited(
        _resolveLabel(location),
        onError: (e) {
          if (kDebugMode) debugPrint('Nama tempat gagal dilengkapi: $e');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Gagal mengambil lokasi: $e');
      if (!mounted) return;
      // Koordinat lama tetap dipertahankan supaya daftar terdekat tidak
      // mendadak kosong hanya karena satu percobaan gagal.
      state = state.copyWith(
        status: LocationStatus.locationError,
        errorMessage: 'Lokasi belum berhasil diambil.',
      );
    }
  }

  /// Melengkapi lokasi dengan nama tempatnya.
  ///
  /// Gagal berarti labelnya tetap kosong, bukan error di layar: kepala
  /// beranda punya tampilan cadangannya sendiri.
  Future<void> _resolveLabel(UserLocation location) async {
    final label = await resolvePlaceName(location.latitude, location.longitude);
    if (label == null || !mounted) return;

    // Hanya bila koordinat yang sedang tampil masih yang ini. Pengguna bisa
    // sudah memilih desa manual selagi geocoder bekerja, dan menimpanya
    // berarti membatalkan pilihannya sendiri.
    final current = state.location;
    if (current == null ||
        current.latitude != location.latitude ||
        current.longitude != location.longitude) {
      return;
    }

    final labelled = UserLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      label: label,
      capturedAt: location.capturedAt,
    );
    await _persist(labelled);
    if (!mounted) return;
    state = state.copyWith(location: labelled);
  }

  /// Menyimpan desa yang dipilih sendiri oleh pengguna.
  Future<void> setManualLocation(VillageOption village) async {
    final location = UserLocation(
      latitude: village.latitude,
      longitude: village.longitude,
      label: village.label,
      isManual: true,
      capturedAt: DateTime.now(),
    );

    await _persist(location);
    if (!mounted) return;
    state = LocationState(
      status: LocationStatus.manualLocation,
      location: location,
    );
  }

  /// Membuka pengaturan aplikasi saat izin ditolak permanen.
  ///
  /// Disediakan geolocator sendiri, jadi tidak perlu package izin terpisah.
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  /// Membuka pengaturan lokasi perangkat saat GPS mati.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Hanya koordinat terakhir yang disimpan, bukan riwayat perpindahan.
  Future<void> _persist(UserLocation location) =>
      _cache.write(_manualLocationKey, jsonEncode(location.toJson()));
}
