import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/network/dio_client.dart';

/// Apakah layar izin pertama sudah pernah dilewati.
///
/// Disimpan terpisah dari `onboarding_completed` supaya keduanya bisa
/// dipindahkan sendiri-sendiri, dan supaya menambah izin baru nanti tidak
/// memaksa mengulang seluruh perkenalan.
///
/// "Sudah dilewati" bukan "sudah diizinkan". Layar ini tidak boleh muncul lagi
/// hanya karena seseorang menolak — menanyakan ulang tiap membuka aplikasi
/// adalah cara tercepat membuat orang menolak selamanya, dan Android memang
/// hanya memberi dua kesempatan bertanya sebelum menguncinya.
final permissionsPrimedProvider =
    StateNotifierProvider<PermissionsPrimedNotifier, bool>((ref) {
      return PermissionsPrimedNotifier(ref.watch(secureStorageProvider));
    });

class PermissionsPrimedNotifier extends StateNotifier<bool> {
  final FlutterSecureStorage _storage;
  static const String _key = 'permissions_primed';

  PermissionsPrimedNotifier(this._storage) : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await _storage.read(key: _key) == 'true';
    } catch (_) {
      state = false;
    }
  }

  Future<void> markPrimed() async {
    try {
      await _storage.write(key: _key, value: 'true');
    } catch (_) {
      // Gagal menyimpan tidak boleh menahan orang di layar izin.
    }
    state = true;
  }

  Future<void> reset() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Abaikan: state di bawah yang menentukan.
    }
    state = false;
  }
}

/// Izin yang diminta begitu beranda terbuka.
///
/// Urutannya disengaja: notifikasi lebih dulu karena dialognya paling ringan
/// untuk disetujui, lalu lokasi yang paling terasa gunanya di beranda (Kopdes
/// terdekat), lalu galeri yang baru dipakai jauh di dalam alur.
const startupPermissions = <Permission>[
  Permission.notification,
  Permission.locationWhenInUse,
  Permission.photos,
];

/// Meminta ketiganya berurutan, lalu mengembalikan yang tidak diberikan.
///
/// Diminta langsung, tanpa layar penjelasan lebih dulu: dialog sistemlah yang
/// menanyakan, dan layar penjelasan baru muncul bila ada yang ditolak — orang
/// yang mengizinkan semuanya tidak pernah melihat satu layar pun.
///
/// Yang sudah diberikan tidak diminta ulang, dan yang sudah ditolak permanen
/// juga tidak: pada keduanya `request()` kembali seketika tanpa dialog, jadi
/// memanggilnya hanya menambah bolak-balik ke platform.
Future<List<Permission>> requestStartupPermissions() async {
  final denied = <Permission>[];

  for (final permission in startupPermissions) {
    final current = await permission.status;
    if (current.isGranted) continue;
    if (current.isPermanentlyDenied) {
      denied.add(permission);
      continue;
    }

    final result = await permission.request();
    if (!result.isGranted) denied.add(permission);
  }

  return denied;
}
