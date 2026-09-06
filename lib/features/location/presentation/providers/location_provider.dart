import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/storage/api_cache.dart';
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

  LocationNotifier(this._cache) : super(const LocationState()) {
    _restoreSavedLocation();
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
