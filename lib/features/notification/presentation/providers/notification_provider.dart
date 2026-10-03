import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/api_cache.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/notification_store.dart';
import '../../domain/entities/notification_item.dart';

/// Penyimpanan notifikasi, dikunci ke pengguna yang sedang masuk.
///
/// Penyimpanan yang gagal dibuka tidak dilempar ke atas: lencana notifikasi
/// dibaca oleh kepala halaman di hampir setiap peran, dan satu `StateError`
/// dari Isar di sana akan mengosongkan seluruh layar alih-alih satu angka
/// kecil. Tanpa penyimpanan, notifikasi tetap jalan selama sesi berlangsung.
final notificationStoreProvider = Provider<NotificationStore>((ref) {
  final ownerId = ref.watch(authProvider.select((s) => s.user?.id)) ?? 'anon';

  ApiCache? cache;
  try {
    cache = ref.watch(apiCacheProvider);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Notifikasi: penyimpanan tidak tersedia, memakai memori. $e');
    }
  }
  return NotificationStore(cache, ownerId);
});

/// Riwayat notifikasi pengguna.
///
/// Dulu daftar ini diisi delapan notifikasi palsu di konstruktor — lengkap
/// dengan tanggal yang sudah lewat — sehingga lencana merah "2" selalu ada
/// sejak pemasangan pertama dan tidak pernah berarti apa pun. Sekarang
/// kosong sampai sesuatu benar-benar terjadi, dan isinya bertahan di
/// perangkat lewat [NotificationStore].
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
      return NotificationsNotifier(ref.watch(notificationStoreProvider));
    });

/// Jumlah yang belum dibaca — sumber tunggal untuk setiap lencana.
///
/// Didefinisikan sekali di sini, bukan dihitung ulang di tiap layar: beranda,
/// halaman pesanan, dan header pegawai dulu masing-masing menulis `.where()`
/// sendiri, dan satu saja yang lupa disesuaikan sudah cukup membuat dua
/// lencana di layar yang sama menunjukkan angka berbeda.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  final NotificationStore _store;

  NotificationsNotifier(this._store) : super(const []) {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await _store.read();
    if (!mounted || saved.isEmpty) return;
    state = saved;
  }

  /// Mencatat satu notifikasi baru, lalu menyimpannya.
  ///
  /// Inilah jalur yang dipakai aplikasi untuk menaikkan lencana: menambah
  /// barang ke keranjang, pesanan berpindah status, dan seterusnya.
  Future<void> add({
    required NotificationType type,
    required String title,
    required String description,
    DateTime? timestamp,
  }) {
    final item = NotificationItem(
      // Waktu mikrodetik + panjang daftar: cukup unik untuk kunci lokal,
      // tanpa menarik paket uuid hanya untuk ini.
      id: '${DateTime.now().microsecondsSinceEpoch}-${state.length}',
      type: type,
      title: title,
      description: description,
      timestamp: timestamp ?? DateTime.now(),
      isRead: false,
    );
    return _commit([item, ...state]);
  }

  Future<void> markAsRead(String id) => _commit([
    for (final item in state)
      if (item.id == id) item.copyWith(isRead: true) else item,
  ]);

  Future<void> markAllAsRead() =>
      _commit([for (final item in state) item.copyWith(isRead: true)]);

  Future<void> clearAll() async {
    state = const [];
    await _store.clear();
  }

  /// Membaca ulang dari perangkat.
  ///
  /// Bukan permintaan jaringan: belum ada endpoint notifikasi. Tarik-untuk-
  /// muat-ulang tetap berguna supaya daftar ikut berubah setelah tab lain
  /// menambah sesuatu.
  Future<void> refreshNotifications() async {
    final saved = await _store.read();
    if (!mounted) return;
    state = saved;
  }

  Future<void> _commit(List<NotificationItem> next) async {
    state = next;
    await _store.write(next);
  }
}
