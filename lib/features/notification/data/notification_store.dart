import '../../../core/storage/api_cache.dart';
import '../domain/entities/notification_item.dart';

/// Notifikasi tersimpan di perangkat pengguna.
///
/// Memakai [ApiCache] yang sudah ada, bukan koleksi Isar baru — sama seperti
/// pilihan lokasi manual. Isinya JSON biasa dan tidak butuh skemanya sendiri.
///
/// Belum ada endpoint notifikasi di backend. Selama itu belum ada, inilah
/// satu-satunya sumbernya: apa yang terjadi di aplikasi ini, di ponsel ini.
class NotificationStore {
  /// Null bila penyimpanan perangkat belum siap — mis. Isar gagal dibuka.
  ///
  /// Lencana notifikasi bukan alasan yang sah untuk menjatuhkan seluruh
  /// kepala halaman. Tanpa penyimpanan, notifikasi tetap jalan selama sesi
  /// ini berlangsung; yang hilang hanya kemampuannya bertahan.
  final ApiCache? _cache;
  final String _key;

  /// Batas riwayat. Tanpa batas, daftar ini tumbuh selamanya di perangkat
  /// yang tidak pernah dibersihkan.
  static const int maxItems = 200;

  NotificationStore(this._cache, String ownerId)
    : _key = CacheKeys.notifications(ownerId);

  Future<List<NotificationItem>> read() async {
    final cache = _cache;
    if (cache == null) return const [];

    final entry = await cache.read(_key);
    final raw = entry?.data;
    if (raw is! List) return const [];

    final items = <NotificationItem>[];
    for (final row in raw) {
      final item = _fromJson(row);
      // Baris yang tidak terbaca dilewati, bukan menggagalkan seluruh daftar:
      // satu notifikasi bertipe baru dari versi lain tidak boleh membuat
      // riwayat seseorang lenyap.
      if (item != null) items.add(item);
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> write(List<NotificationItem> items) async {
    final cache = _cache;
    if (cache == null) return;

    final trimmed = items.take(maxItems).map(_toJson).toList(growable: false);
    await cache.write(_key, trimmed);
  }

  Future<void> clear() async => _cache?.invalidate(_key);
}

Map<String, dynamic> _toJson(NotificationItem n) => {
  'id': n.id,
  // Nama enum, bukan indeksnya: menambah tipe baru di tengah daftar tidak
  // boleh mengubah arti notifikasi yang sudah tersimpan.
  'type': n.type.name,
  'title': n.title,
  'description': n.description,
  'timestamp': n.timestamp.toIso8601String(),
  'isRead': n.isRead,
};

NotificationItem? _fromJson(Object? row) {
  if (row is! Map) return null;
  final id = row['id'];
  final title = row['title'];
  final timestamp = DateTime.tryParse('${row['timestamp']}');
  if (id is! String || title is! String || timestamp == null) return null;

  NotificationType? type;
  for (final t in NotificationType.values) {
    if (t.name == row['type']) type = t;
  }
  if (type == null) return null;

  return NotificationItem(
    id: id,
    type: type,
    title: title,
    description: '${row['description'] ?? ''}',
    timestamp: timestamp,
    isRead: row['isRead'] == true,
  );
}
